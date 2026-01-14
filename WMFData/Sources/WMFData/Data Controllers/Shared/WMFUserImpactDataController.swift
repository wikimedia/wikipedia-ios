import Foundation

public actor WMFUserImpactDataController {
    
    public static let shared = WMFUserImpactDataController()

    private let service: WMFService?
    
    init(service: WMFService? = WMFDataEnvironment.current.mediaWikiService) {
        self.service = service
    }
    
    func fetch(userID: Int, project: WMFProject, language: String) async throws -> WMFUserImpactData {
        return try await withCheckedThrowingContinuation { continuation in
            fetch(userID: userID, project: project, language: language) { result in
                switch result {
                case .success(let successResult):
                    continuation.resume(returning: successResult)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func fetch(userID: Int, project: WMFProject, language: String, completion: @escaping (Result<WMFUserImpactData, Error>) -> Void) {
        guard let service = service else {
            completion(.failure(WMFDataControllerError.basicServiceUnavailable))
            return
        }
        
        let prefixedUserID = "#" + String(userID)
        
        guard let baseUrl = URL.mediaWikiRestAPIURL(project: project, additionalPathComponents: ["growthexperiments", "v0", "user-impact", prefixedUserID]) else {
            completion(.failure(WMFDataControllerError.failureCreatingRequestURL))
            return
        }

        var urlComponents = URLComponents(url: baseUrl, resolvingAgainstBaseURL: false)
        urlComponents?.queryItems = [URLQueryItem(name: "lang", value: language)]
        
        guard let url = urlComponents?.url else {
            completion(.failure(WMFDataControllerError.failureCreatingRequestURL))
            return
        }

        let request = WMFMediaWikiServiceRequest(url: url, method: .GET, backend: .mediaWikiREST, tokenType: .none, parameters: nil)

        let completionHandler: (Result<[String: Any]?, Error>) -> Void = { result in
            switch result {
            case .success(let data):
                guard let jsonData = data else {
                    completion(.failure(WMFDataControllerError.unexpectedResponse))
                    return
                }
                
                let totalPageviewsCount = jsonData["totalPageviewsCount"] as? Int
                
                var finalTopViewedArticles: [WMFUserImpactData.TopViewedArticle] = []
                if let topViewedArticles = jsonData["topViewedArticles"] as? [String: [String: Any]] {
                    for (key, value) in topViewedArticles {
                        guard let dates = value["views"] as? [String: Int] else {
                            continue
                        }
                        
                        var views: [Date: Int] = [:]
                        for (dateKey, dateValue) in dates {
                            guard let date = DateFormatter.growthUserImpactAPIDateFormatter.date(from: dateKey) else {
                                continue
                            }
                            
                            views[date] = dateValue
                        }
                        
                        guard let viewsCount = value["viewsCount"] as? Int else {
                            continue
                        }
                        
                        finalTopViewedArticles.append(WMFUserImpactData.TopViewedArticle(title: key, views: views, viewsCount: viewsCount))
                    }
                }
                
                var finalEditCountByDay: [Date: Int] = [:]
                if let editCountByDay = jsonData["editCountByDay"] as? [String: Int] {
                    for (key, value) in editCountByDay {
                        guard let date = DateFormatter.growthUserImpactAPIDateFormatter.date(from: key) else {
                            continue
                        }
                        
                        finalEditCountByDay[date] = value
                    }
                }

                let totalEditsCount = jsonData["totalEditsCount"] as? Int
                let receivedThanksCount = jsonData["receivedThanksCount"] as? Int
                
                var longestEditingStreak: Int?
                if let streak = jsonData["longestEditingStreak"] as? [String: Any],
                   let datePeriod = streak["datePeriod"] as? [String: Any],
                   let days = datePeriod["days"] as? Int {
                    longestEditingStreak = days
                }
                
                var lastEditTimestamp: Date?
                if let lastEditTimestampInterval = jsonData["lastEditTimestamp"] as? TimeInterval {
                    lastEditTimestamp = Date(timeIntervalSince1970: lastEditTimestampInterval)
                }
                
                var finalDailyTotalViews: [Date: Int] = [:]
                if let dailyTotalViews = jsonData["dailyTotalViews"] as? [String: Int] {
                    for (key, value) in dailyTotalViews {
                        guard let date = DateFormatter.growthUserImpactAPIDateFormatter.date(from: key) else {
                            continue
                        }
                        
                        finalDailyTotalViews[date] = value
                    }
                }
                
                completion(.success(WMFUserImpactData(totalPageviewsCount: totalPageviewsCount, topViewedArticles: finalTopViewedArticles, editCountByDay: finalEditCountByDay, totalEditsCount: totalEditsCount, receivedThanksCount: receivedThanksCount, longestEditingStreak: longestEditingStreak, lastEditTimestamp: lastEditTimestamp, dailyTotalViews: finalDailyTotalViews)))

            case .failure(let error):
                completion(.failure(WMFDataControllerError.serviceError(error)))
            }
        }
        service.perform(request: request, completion: completionHandler)
    }
}
