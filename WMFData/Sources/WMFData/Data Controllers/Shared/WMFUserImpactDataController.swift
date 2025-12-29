import Foundation

public actor WMFUserImpactDataController {
    
    public static let shared = WMFUserImpactDataController()

    private let service: WMFService?
    
    init(service: WMFService? = WMFDataEnvironment.current.mediaWikiService) {
        self.service = service
    }
    
    // MARK: - Async API
    
    func fetch(
        userID: Int,
        project: WMFProject,
        language: String
    ) async throws -> WMFUserImpactData {
        try await withCheckedThrowingContinuation { continuation in
            fetch(userID: userID, project: project, language: language) { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Completion-based API
    
    func fetch(
        userID: Int,
        project: WMFProject,
        language: String,
        completion: @escaping @Sendable (Result<WMFUserImpactData, Error>) -> Void
    ) {
        guard let service else {
            completion(.failure(WMFDataControllerError.basicServiceUnavailable))
            return
        }
        
        let prefixedUserID = "#" + String(userID)
        
        guard
            let baseURL = URL.mediaWikiRestAPIURL(
                project: project,
                additionalPathComponents: [
                    "growthexperiments",
                    "v0",
                    "user-impact",
                    prefixedUserID
                ]
            )
        else {
            completion(.failure(WMFDataControllerError.failureCreatingRequestURL))
            return
        }
        
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "lang", value: language)]
        
        guard let url = components?.url else {
            completion(.failure(WMFDataControllerError.failureCreatingRequestURL))
            return
        }
        
        let request = WMFMediaWikiServiceRequest(
            url: url,
            method: .GET,
            backend: .mediaWikiREST,
            tokenType: .none,
            parameters: nil
        )
        
        let handler: @Sendable (Result<[String: Any]?, Error>) -> Void = { [weak self] result in
            guard let self else { return }
            
            let parsedResult: Result<WMFUserImpactData, Error>
            
            switch result {
            case .success(let data):
                guard let jsonData = data else {
                    parsedResult = .failure(WMFDataControllerError.unexpectedResponse)
                    break
                }
                parsedResult = Self.parseUserImpact(jsonData)
                
            case .failure(let error):
                parsedResult = .failure(WMFDataControllerError.serviceError(error))
            }
            
            Task {
                await self.deliver(parsedResult, completion: completion)
            }
        }
        
        service.perform(request: request, completion: handler)
    }
    
    // MARK: - Actor-isolated delivery
    
    private func deliver(
        _ result: Result<WMFUserImpactData, Error>,
        completion: @Sendable (Result<WMFUserImpactData, Error>) -> Void
    ) {
        completion(result)
    }
    
    // MARK: - Parsing (non-concurrent)
    
    private static func parseUserImpact(
        _ jsonData: [String: Any]
    ) -> Result<WMFUserImpactData, Error> {
        
        let totalPageviewsCount = jsonData["totalPageviewsCount"] as? Int
        
        var topViewedArticles: [WMFUserImpactData.TopViewedArticle] = []
        if let articles = jsonData["topViewedArticles"] as? [String: [String: Any]] {
            for (title, value) in articles {
                guard
                    let viewsDict = value["views"] as? [String: Int],
                    let viewsCount = value["viewsCount"] as? Int
                else { continue }
                
                var views: [Date: Int] = [:]
                for (key, count) in viewsDict {
                    guard let date = DateFormatter.growthUserImpactAPIDateFormatter.date(from: key) else { continue }
                    views[date] = count
                }
                
                topViewedArticles.append(
                    WMFUserImpactData.TopViewedArticle(
                        title: title,
                        views: views,
                        viewsCount: viewsCount
                    )
                )
            }
        }
        
        var editCountByDay: [Date: Int] = [:]
        if let edits = jsonData["editCountByDay"] as? [String: Int] {
            for (key, value) in edits {
                guard let date = DateFormatter.growthUserImpactAPIDateFormatter.date(from: key) else { continue }
                editCountByDay[date] = value
            }
        }
        
        let totalEditsCount = jsonData["totalEditsCount"] as? Int
        let receivedThanksCount = jsonData["receivedThanksCount"] as? Int
        
        var longestEditingStreak: Int?
        if
            let streak = jsonData["longestEditingStreak"] as? [String: Any],
            let datePeriod = streak["datePeriod"] as? [String: Any],
            let days = datePeriod["days"] as? Int {
            longestEditingStreak = days
        }
        
        var lastEditTimestamp: Date?
        if let timestamp = jsonData["lastEditTimestamp"] as? TimeInterval {
            lastEditTimestamp = Date(timeIntervalSince1970: timestamp)
        }
        
        var dailyTotalViews: [Date: Int] = [:]
        if let totals = jsonData["dailyTotalViews"] as? [String: Int] {
            for (key, value) in totals {
                guard let date = DateFormatter.growthUserImpactAPIDateFormatter.date(from: key) else { continue }
                dailyTotalViews[date] = value
            }
        }
        
        return .success(
            WMFUserImpactData(
                totalPageviewsCount: totalPageviewsCount,
                topViewedArticles: topViewedArticles,
                editCountByDay: editCountByDay,
                totalEditsCount: totalEditsCount,
                receivedThanksCount: receivedThanksCount,
                longestEditingStreak: longestEditingStreak,
                lastEditTimestamp: lastEditTimestamp,
                dailyTotalViews: dailyTotalViews
            )
        )
    }
}
