import Foundation
import CoreData

// MARK: - Read Count Slide
final class YearInReviewReadCountSlideDataController: YearInReviewSlideDataControllerProtocol {

    let id = WMFYearInReviewPersonalizedSlideID.readCount.rawValue
    let year: Int
    var isEvaluated: Bool = false
    static var containsPersonalizedNetworkData = false
    
    private var readCount: Int?

    private weak var legacyPageViewsDataDelegate: LegacyPageViewsDataDelegate?
    private let yirConfig: YearInReviewFeatureConfig
    
    init(year: Int, yirConfig: YearInReviewFeatureConfig, dependencies: YearInReviewSlideDataControllerDependencies) {
        self.year = year
        self.yirConfig = yirConfig
        self.legacyPageViewsDataDelegate = dependencies.legacyPageViewsDataDelegate
    }

    func populateSlideData(in context: NSManagedObjectContext) async throws {
        
        guard let startDate = yirConfig.dataPopulationStartDate,
              let endDate = yirConfig.dataPopulationEndDate,
            let pageViews = try await legacyPageViewsDataDelegate?.getLegacyPageViews(from: startDate, to: endDate) else {
            throw NSError(domain: "", code: 0, userInfo: nil)
        }
        
        readCount = pageViews.count
        isEvaluated = true
    }

    func makeCDSlide(in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = id
        slide.year = Int32(year)

        if let readCount {
            let encoder = JSONEncoder()
            slide.data = try encoder.encode(readCount)
        }

        return slide
    }

    static func shouldPopulate(from config: YearInReviewFeatureConfig, userInfo: YearInReviewUserInfo) -> Bool {
        return config.isEnabled && config.slideConfig.readCountIsEnabled
    }
}

// MARK: - Save Count Slide

final class YearInReviewSaveCountSlideDataController: YearInReviewSlideDataControllerProtocol {

    let id = WMFYearInReviewPersonalizedSlideID.saveCount.rawValue
    let year: Int
    var isEvaluated: Bool = false
    static var containsPersonalizedNetworkData = true
    
    private var savedData: SavedArticleSlideData?
    
    private weak var savedSlideDataDelegate: SavedArticleSlideDataDelegate?
    private let yirConfig: YearInReviewFeatureConfig
    
    init(year: Int, yirConfig: YearInReviewFeatureConfig, dependencies: YearInReviewSlideDataControllerDependencies) {
        self.year = year
        self.yirConfig = yirConfig
        self.savedSlideDataDelegate = dependencies.savedSlideDataDelegate
    }

    func populateSlideData(in context: NSManagedObjectContext) async throws {
        
        guard let startDate = yirConfig.dataPopulationStartDate, let endDate = yirConfig.dataPopulationEndDate else {
            return
        }
        
        self.savedData = await savedSlideDataDelegate?.getSavedArticleSlideData(from: startDate, to: endDate)
        
        guard savedData != nil else { return }
        
        isEvaluated = true
    }

    func makeCDSlide(in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = id
        slide.year = Int32(year)

        if let savedData {
            slide.data = try JSONEncoder().encode(savedData)
        }

        return slide
    }

    static func shouldPopulate(from config: YearInReviewFeatureConfig, userInfo: YearInReviewUserInfo) -> Bool {
        return config.isEnabled && config.slideConfig.saveCountIsEnabled
    }
}

// MARK: - Edit count slide

final class YearInReviewEditCountSlideDataController: YearInReviewSlideDataControllerProtocol {

    let id = WMFYearInReviewPersonalizedSlideID.editCount.rawValue
    let year: Int
    var isEvaluated: Bool = false
    static var containsPersonalizedNetworkData = true
    
    private var editCount: Int?

    private let username: String?
    private let project: WMFProject?
    
    private let yirConfig: YearInReviewFeatureConfig
    private let service = WMFDataEnvironment.current.mediaWikiService
    
    init(year: Int, yirConfig: YearInReviewFeatureConfig, dependencies: YearInReviewSlideDataControllerDependencies) {
        self.year = year
        self.yirConfig = yirConfig
        self.username = dependencies.username
        self.project = dependencies.project
    }

    func populateSlideData(in context: NSManagedObjectContext) async throws {
        guard let username, let project else { return }
        
        guard let startDate = yirConfig.dataPopulationStartDateString,
              let endDate = yirConfig.dataPopulationEndDateString else {
            return
        }
        
        let (edits, _) = try await fetchUserContributionsCount(username: username, project: project, startDate: startDate, endDate: endDate)
        
        editCount = edits
        isEvaluated = true
    }

    func makeCDSlide(in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = id
        slide.year = Int32(year)

        if let editCount {
            slide.data = try JSONEncoder().encode(editCount)
        }

        return slide
    }

    static func shouldPopulate(from config: YearInReviewFeatureConfig, userInfo: YearInReviewUserInfo) -> Bool {
        return config.isEnabled && config.slideConfig.editCountIsEnabled && userInfo.username != nil
    }
    
    func fetchUserContributionsCount(username: String, project: WMFProject?, startDate: String, endDate: String) async throws -> (Int, Bool) {
        return try await withCheckedThrowingContinuation { continuation in
            fetchUserContributionsCount(username: username, project: project, startDate: startDate, endDate: endDate) { result in
                switch result {
                case .success(let successResult):
                    continuation.resume(returning: successResult)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func fetchUserContributionsCount(username: String, project: WMFProject?, startDate: String, endDate: String, completion: @escaping (Result<(Int, Bool), Error>) -> Void) {
        guard let service = service else {
            completion(.failure(WMFDataControllerError.mediaWikiServiceUnavailable))
            return
        }

        guard let project = project else {
            completion(.failure(WMFDataControllerError.mediaWikiServiceUnavailable))
            return
        }

        // We have to switch the dates here before sending into the API.
        // It is expected that this method's startDate parameter is chronologically earlier than endDate. This is how the remote feature config is set up.
        // The User Contributions API expects ucend to be chronologically earlier than ucstart, because it pages backwards so that the most recent edits appear on the first page.
        let ucStartDate = endDate
        let ucEndDate = startDate

        let parameters: [String: Any] = [
            "action": "query",
            "format": "json",
            "list": "usercontribs",
            "formatversion": "2",
            "uclimit": "500",
            "ucstart": ucStartDate,
            "ucend": ucEndDate,
            "ucuser": username,
            "ucnamespace": "0",
            "ucprop": "ids|title|timestamp|tags|flags"
        ]

        guard let url = URL.mediaWikiAPIURL(project: project) else {
            completion(.failure(WMFDataControllerError.failureCreatingRequestURL))
            return
        }

        let request = WMFMediaWikiServiceRequest(url: url, method: .GET, backend: .mediaWiki, parameters: parameters)

        service.performDecodableGET(request: request) { (result: Result<UserContributionsAPIResponse, Error>) in
            switch result {
            case .success(let response):
                guard let query = response.query else {
                    completion(.failure(WMFDataControllerError.unexpectedResponse))
                    return
                }

                let editCount = query.usercontribs.count

                let hasMoreEdits = response.continue?.uccontinue != nil

                completion(.success((editCount, hasMoreEdits)))

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    struct UserContributionsAPIResponse: Codable {
        let batchcomplete: Bool?
        let `continue`: ContinueData?
        let query: UserContributionsQuery?

        struct ContinueData: Codable {
            let uccontinue: String?
        }

        struct UserContributionsQuery: Codable {
            let usercontribs: [UserContribution]
        }
    }

    struct UserContribution: Codable {
        let userid: Int
        let user: String
        let pageid: Int
        let revid: Int
        let parentid: Int
        let ns: Int
        let title: String
        let timestamp: String
        let isNew: Bool
        let isMinor: Bool
        let isTop: Bool
        let tags: [String]

        enum CodingKeys: String, CodingKey {
            case userid, user, pageid, revid, parentid, ns, title, timestamp, tags
            case isNew = "new"
            case isMinor = "minor"
            case isTop = "top"
        }
    }

}

// MARK: - Donate Slide

final class YearInReviewDonateCountSlideDataController: YearInReviewSlideDataControllerProtocol {
    let id = WMFYearInReviewPersonalizedSlideID.donateCount.rawValue
    let year: Int
    var isEvaluated: Bool = false
    static var containsPersonalizedNetworkData = false
    
    private var donateCount: Int?
    
    private let yirConfig: YearInReviewFeatureConfig
    
    init(year: Int, yirConfig: YearInReviewFeatureConfig, dependencies: YearInReviewSlideDataControllerDependencies) {
        self.year = year
        self.yirConfig = yirConfig
    }

    func populateSlideData(in context: NSManagedObjectContext) async throws {
        
        guard let startDate = yirConfig.dataPopulationStartDate,
              let endDate = yirConfig.dataPopulationEndDate else {
            return
        }
    
        donateCount = WMFDonateDataController.shared.loadLocalDonationHistory(startDate: startDate, endDate: endDate)?.count
        isEvaluated = true
    }

    func makeCDSlide(in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = id
        slide.year = Int32(year)
        slide.data = try donateCount.map { try JSONEncoder().encode($0) }
        return slide
    }

    static func shouldPopulate(from config: YearInReviewFeatureConfig, userInfo: YearInReviewUserInfo) -> Bool {
        config.isEnabled && config.slideConfig.donateCountIsEnabled
    }
}

// MARK: - Most read day slide

final class YearInReviewMostReadDaySlideDataController: YearInReviewSlideDataControllerProtocol {
    let id = WMFYearInReviewPersonalizedSlideID.mostReadDay.rawValue
    let year: Int
    var isEvaluated: Bool = false
    static var containsPersonalizedNetworkData = false
    
    var mostReadDay: WMFPageViewDay?

    private weak var legacyPageViewsDataDelegate: LegacyPageViewsDataDelegate?
    private let yirConfig: YearInReviewFeatureConfig
    
    init(year: Int, yirConfig: YearInReviewFeatureConfig, dependencies: YearInReviewSlideDataControllerDependencies) {
        self.year = year
        self.yirConfig = yirConfig
        self.legacyPageViewsDataDelegate = dependencies.legacyPageViewsDataDelegate
    }

    func populateSlideData(in context: NSManagedObjectContext) async throws {
        
        guard let startDate = yirConfig.dataPopulationStartDate,
              let endDate = yirConfig.dataPopulationEndDate,
            let pageViews = try await legacyPageViewsDataDelegate?.getLegacyPageViews(from: startDate, to: endDate) else {
            throw NSError(domain: "", code: 0, userInfo: nil)
        }
        
        let dayCounts = pageViews.reduce(into: [Int: Int]()) { dict, view in
            let day = Calendar.current.component(.weekday, from: view.viewedDate)
            dict[day, default: 0] += 1
        }

        if let (day, count) = dayCounts.max(by: { $0.value < $1.value }) {
            mostReadDay = WMFPageViewDay(day: day, viewCount: count)
            isEvaluated = true
        }
    }

    func makeCDSlide(in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = id
        slide.year = Int32(year)
        slide.data = try mostReadDay.map { try JSONEncoder().encode($0) }
        return slide
    }

    static func shouldPopulate(from config: YearInReviewFeatureConfig, userInfo: YearInReviewUserInfo) -> Bool {
        config.isEnabled && config.slideConfig.mostReadDayIsEnabled
    }
}

// MARK: - View count

final class YearInReviewViewCountSlideDataController: YearInReviewSlideDataControllerProtocol {
    let id = WMFYearInReviewPersonalizedSlideID.viewCount.rawValue
    let year: Int
    var isEvaluated: Bool = false
    static var containsPersonalizedNetworkData = true
    
    private var viewCount: Int?
    
    private let userID: String?
    private let languageCode: String?
    private let project: WMFProject?
    
    private let service = WMFDataEnvironment.current.mediaWikiService
    
    init(year: Int, yirConfig: YearInReviewFeatureConfig, dependencies: YearInReviewSlideDataControllerDependencies) {
        self.year = year
        self.userID = dependencies.userID
        self.languageCode = dependencies.languageCode
        self.project = dependencies.project
    }

    func populateSlideData(in context: NSManagedObjectContext) async throws {
        guard let userID, let languageCode else { return }
        viewCount = try await self.fetchEditViews(project: project, userId: userID, language: languageCode)
        isEvaluated = true
    }

    func makeCDSlide(in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = id
        slide.year = Int32(year)
        slide.data = try viewCount.map { try JSONEncoder().encode($0) }
        return slide
    }

    static func shouldPopulate(from config: YearInReviewFeatureConfig, userInfo: YearInReviewUserInfo) -> Bool {
        config.isEnabled && config.slideConfig.viewCountIsEnabled && userInfo.userID != nil
    }
    
    private func fetchEditViews(project: WMFProject?, userId: String, language: String) async throws -> (Int) {
        return try await withCheckedThrowingContinuation { continuation in
            fetchEditViews(project: project, userId: userId, language: language) { result in
                switch result {
                case .success(let views):
                    continuation.resume(returning: views)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func fetchEditViews(project: WMFProject?, userId: String, language: String, completion: @escaping (Result<Int, Error>) -> Void) {

        guard let service else {
            completion(.failure(WMFDataControllerError.mediaWikiServiceUnavailable))
            return
        }
        
        guard let project = project else {
            completion(.failure(WMFDataControllerError.mediaWikiServiceUnavailable))
            return
        }
        
        let prefixedUserID = "#" + userId
        
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

                if let totalPageviews = jsonData["totalPageviewsCount"] as? Int {
                    let totalViews = totalPageviews
                    completion(.success(totalViews))
                } else {
                    // If for any reason we don't get anything
                    completion(.success(0))
                }

            case .failure(let error):
                completion(.failure(WMFDataControllerError.serviceError(error)))
            }
        }
        service.perform(request: request, completion: completionHandler)
    }
}

