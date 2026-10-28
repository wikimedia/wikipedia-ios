import CoreData

/// The "articles most-viewed since your edit" slide, from the Growth user impact data of the
/// reader's primary language wiki.
public struct WMFYearInReviewMostViewedArticlesSlideData: Codable, Sendable {

    public struct Article: Codable, Sendable, Equatable {
        /// The title with spaces, not underscores.
        public let title: String
        /// The `WMFProject.id` of the wiki the article is on.
        public let projectID: String
        public let viewsCount: Int

        public init(title: String, projectID: String, viewsCount: Int) {
            self.title = title
            self.projectID = projectID
            self.viewsCount = viewsCount
        }

        public var project: WMFProject? {
            WMFProject(id: projectID)
        }
    }

    /// The slide shows at most this number of articles.
    public static let maximumArticleCount = 3

    /// The articles with the most views first, at most `maximumArticleCount`.
    public let articles: [Article]

    /// The slide suppresses itself without articles.
    public var isEligible: Bool {
        !articles.isEmpty
    }
}

// @unchecked: `isEvaluated` is mutable, but instances are confined to the sequential
// populate flow in WMFYearInReviewDataController (mutated in a loop, then read in a
// single Core Data perform closure) — see YearInReviewSlideDataControllerProtocol.
final class YearInReviewMostViewedArticlesSlideDataController: YearInReviewSlideDataControllerProtocol, @unchecked Sendable {
    let id = WMFYearInReviewPersonalizedSlideID.mostViewedArticles.rawValue
    let year: Int
    var isEvaluated: Bool = false
    static let personalizationSources: Set<WMFYearInReviewPersonalizationSource> = [.account]
    static let shouldFreeze = false

    private var slideData: WMFYearInReviewMostViewedArticlesSlideData?

    private let userID: Int?
    private let languageCode: String?
    private let project: WMFProject?
    private let userImpactDataProvider: any YearInReviewUserImpactDataProviding

    init(year: Int, yirConfig: WMFFeatureConfigResponse.Common.YearInReview, dependencies: YearInReviewSlideDataControllerDependencies) {
        self.year = year
        self.userID = dependencies.userID
        self.languageCode = dependencies.languageCode
        self.project = dependencies.project
        self.userImpactDataProvider = dependencies.userImpactDataProvider ?? WMFUserImpactDataController.shared
    }

    func populateSlideData(in context: NSManagedObjectContext) async throws {
        guard let userID, let languageCode else { return }
        guard let project else {
            throw WMFDataControllerError.mediaWikiServiceUnavailable
        }

        let articles = try await userImpactDataProvider.fetchMostViewedArticles(userID: userID, project: project, language: languageCode)
        let topArticles = articles
            .filter { $0.viewsCount > 0 }
            // The title breaks a tie, so the order is the same on each run.
            .sorted { ($0.viewsCount, $1.title) > ($1.viewsCount, $0.title) }
            .prefix(WMFYearInReviewMostViewedArticlesSlideData.maximumArticleCount)
        slideData = WMFYearInReviewMostViewedArticlesSlideData(articles: Array(topArticles))
        isEvaluated = true
    }

    func makeCDSlide(in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = id
        slide.year = Int32(year)
        slide.data = try slideData.map { try JSONEncoder().encode($0) }
        return slide
    }

    static func shouldPopulate(from config: WMFFeatureConfigResponse.Common.YearInReview, userInfo: YearInReviewUserInfo) -> Bool {
        return config.isActive(for: Date()) && userInfo.userID != nil
    }
}
