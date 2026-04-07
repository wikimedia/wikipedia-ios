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
        
        // Set up calendars for conversion
        let utcTimezone = TimeZone.gmt
        var utcCalendar = Calendar.current
        utcCalendar.timeZone = utcTimezone
        let localCalendar = Calendar.current
        
        let totalPageviewsCount = jsonData["totalPageviewsCount"] as? Int
        
        var finalTopViewedArticles: [WMFUserImpactData.TopViewedArticle] = []
        if let topViewedArticles = jsonData["topViewedArticles"] as? [String: [String: Any]] {
            for (key, value) in topViewedArticles {
                guard let dates = value["views"] as? [String: Int] else {
                    continue
                }
                
                var views: [Date: Int] = [:]
                for (dateKey, dateValue) in dates {
                    guard let utcDate = DateFormatter.growthUserImpactAPIDateFormatter.date(from: dateKey) else {
                        continue
                    }
                    
                    // Convert UTC to local
                    let normalizedUTCDate = utcCalendar.startOfDay(for: utcDate)
                    let localDate = localCalendar.startOfDay(for: normalizedUTCDate)
                    views[localDate] = dateValue
                    
                    views[localDate] = dateValue
                }
                
                guard let viewsCount = value["viewsCount"] as? Int else {
                    continue
                }
                
                finalTopViewedArticles.append(WMFUserImpactData.TopViewedArticle(title: key, views: views, viewsCount: viewsCount))
            }
        }
        
        var localEditCounts: [Date: Int] = [:]
        if let editCountByDay = jsonData["editCountByDay"] as? [String: Int] {
            for (key, value) in editCountByDay {
                guard let utcDate = DateFormatter.growthUserImpactAPIDateFormatter.date(from: key) else {
                    continue
                }
                
                // Extract the date components (year, month, day) from UTC date
                let components = utcCalendar.dateComponents([.year, .month, .day], from: utcDate)
                
                // Create a new date with those same components but in local timezone
                guard let localDate = localCalendar.date(from: components) else {
                    continue
                }
                
                localEditCounts[localDate, default: 0] += value
            }
        }

        let totalEditsCount = jsonData["totalEditsCount"] as? Int
        let receivedThanksCount = jsonData["receivedThanksCount"] as? Int
        
        var longestEditingStreak: Int? = nil
        if let streak = jsonData["longestEditingStreak"] as? [String: Any],
           let datePeriod = streak["datePeriod"] as? [String: Any],
           let days = datePeriod["days"] as? Int {
            longestEditingStreak = days
        }
        
        var lastEditTimestamp: Date? = nil
        if let lastEditTimestampInterval = jsonData["lastEditTimestamp"] as? TimeInterval {
            lastEditTimestamp = Date(timeIntervalSince1970: lastEditTimestampInterval)
        }
        
        var finalDailyTotalViews: [Date: Int] = [:]
        if let dailyTotalViews = jsonData["dailyTotalViews"] as? [String: Int] {
            for (key, value) in dailyTotalViews {
                guard let utcDate = DateFormatter.growthUserImpactAPIDateFormatter.date(from: key) else {
                    continue
                }
                
                // Convert UTC to local
                let normalizedUTCDate = utcCalendar.startOfDay(for: utcDate)
                let localDate = localCalendar.startOfDay(for: normalizedUTCDate)
                finalDailyTotalViews[localDate, default: 0] += value
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
