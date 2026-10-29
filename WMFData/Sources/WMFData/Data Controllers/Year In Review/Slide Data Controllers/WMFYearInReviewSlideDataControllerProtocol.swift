import Foundation
import CoreData

public enum WMFYearInReviewPersonalizationSource: Sendable {
    case readingHistory
    case account
    case donations
}

protocol YearInReviewSlideDataControllerProtocol: Sendable {
    var id: String { get }
    var year: Int { get }
    /// `populateSlideData(in:)` must set this to `true` when it succeeds. The populate flow stores
    /// only evaluated slides, so a controller that never sets it is never stored, and one that
    /// returns early without data, for example without a user id, must leave it `false`.
    var isEvaluated: Bool { get set }
    static var personalizationSources: Set<WMFYearInReviewPersonalizationSource> { get }
    static var shouldFreeze: Bool { get }
    
    func populateSlideData(in context: NSManagedObjectContext) async throws

    func makeCDSlide(in context: NSManagedObjectContext) throws -> CDYearInReviewSlide

    static func shouldPopulate(from config: WMFFeatureConfigResponse.Common.YearInReview, userInfo: YearInReviewUserInfo) -> Bool
    
    init(year: Int, yirConfig: WMFFeatureConfigResponse.Common.YearInReview, dependencies: YearInReviewSlideDataControllerDependencies)
}

struct YearInReviewSlideDataControllerDependencies {
    let legacyPageViewsDataDelegate: LegacyPageViewsDataDelegate?
    let savedSlideDataDelegate: SavedArticleSlideDataDelegate?
    let username: String?
    let project: WMFProject?
    let userID: Int?
    let globalUserID: Int?
    let languageCode: String?
    let userImpactDataProvider: (any YearInReviewUserImpactDataProviding)?
    var mainPageIdentifier: (any WMFMainPageIdentifying)? = nil
}

protocol YearInReviewUserImpactDataProviding: Sendable {
    func fetchTotalPageViewsCount(userID: Int, project: WMFProject, language: String) async throws -> Int?
    func fetchMostViewedArticles(userID: Int, project: WMFProject, language: String) async throws -> [WMFYearInReviewMostViewedArticlesSlideData.Article]
}

/// Fetches the Growth user impact data once for each user, project and language, so the slides that
/// read it make one request. The slide factory makes one for each populate run, so the data is not
/// kept between runs.
actor YearInReviewUserImpactDataProvider: YearInReviewUserImpactDataProviding {
    typealias Fetch = @Sendable (_ userID: Int, _ project: WMFProject, _ language: String) async throws -> WMFUserImpactData

    private let fetch: Fetch
    private var fetchTasks: [String: Task<WMFUserImpactData, Error>] = [:]

    init(fetch: @escaping Fetch = { userID, project, language in
        try await WMFUserImpactDataController.shared.fetch(userID: userID, project: project, language: language)
    }) {
        self.fetch = fetch
    }

    func fetchTotalPageViewsCount(userID: Int, project: WMFProject, language: String) async throws -> Int? {
        try await userImpactData(userID: userID, project: project, language: language).totalPageviewsCount
    }

    func fetchMostViewedArticles(userID: Int, project: WMFProject, language: String) async throws -> [WMFYearInReviewMostViewedArticlesSlideData.Article] {
        try await userImpactData(userID: userID, project: project, language: language).topViewedArticles.map {
            WMFYearInReviewMostViewedArticlesSlideData.Article(
                title: $0.title.replacingOccurrences(of: "_", with: " "),
                projectID: project.id,
                viewsCount: $0.viewsCount
            )
        }
    }

    private func userImpactData(userID: Int, project: WMFProject, language: String) async throws -> WMFUserImpactData {
        let key = "\(userID)|\(project.id)|\(language)"
        if let fetchTask = fetchTasks[key] {
            return try await fetchTask.value
        }
        let fetch = self.fetch
        let fetchTask = Task { try await fetch(userID, project, language) }
        fetchTasks[key] = fetchTask
        do {
            return try await fetchTask.value
        } catch {
            // A failed fetch is not kept, so a later call tries again.
            fetchTasks[key] = nil
            throw error
        }
    }
}
