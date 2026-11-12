import CoreData

/// The "articles visited multiple times" slide. Articles are ranked by number of visits, so the
/// slide is separate from any ranking by minutes read.
public struct WMFYearInReviewTopArticlesSlideData: Codable, Sendable {

    public struct Article: Codable, Sendable, Equatable {
        /// The title with spaces, not underscores.
        public let title: String
        /// The `WMFProject.id` of the wiki the article is on.
        public let projectID: String
        public let visitCount: Int

        public var project: WMFProject? {
            WMFProject(id: projectID)
        }
    }

    /// An article must have at least this number of visits to qualify.
    public static let minimumVisitCount = 2
    /// The user must have at least this number of qualifying articles to see the full slide.
    public static let minimumArticleCount = 2
    /// The slide shows at most this number of articles.
    public static let maximumArticleCount = 3

    /// The qualifying articles, most visits first. Fewer than `minimumArticleCount` is possible.
    public let articles: [Article]

    /// If false, show the empty state ("You're not a re-reader").
    public var isEligible: Bool {
        articles.count >= Self.minimumArticleCount
    }
}

/// Identifies the main page of a wiki. The per-language main page titles live app-side, so the app
/// supplies this.
public protocol WMFMainPageIdentifying: AnyObject {
    /// The title of the main page of `project`, or `nil` if it is not known. The case and the use
    /// of underscores or spaces do not matter.
    func mainPageTitle(for project: WMFProject) async -> String?
}

/// Compares titles the same way as the app-side main page lookup: case and underscores are ignored.
enum WMFMainPageTitle {
    static func canonicalized(_ title: String) -> String {
        title.uppercased().replacingOccurrences(of: "_", with: " ")
    }
}

// @unchecked: `isEvaluated` is mutable, but instances are confined to the sequential
// populate flow in WMFYearInReviewDataController (mutated in a loop, then read in a
// single Core Data perform closure) — see YearInReviewSlideDataControllerProtocol.
final class YearInReviewTopReadArticleSlideDataController: YearInReviewSlideDataControllerProtocol, @unchecked Sendable {

    let id = WMFYearInReviewPersonalizedSlideID.topArticles.rawValue
    let year: Int
    var isEvaluated: Bool = false
    static let personalizationSources: Set<WMFYearInReviewPersonalizationSource> = [.readingHistory]
    static let shouldFreeze = true

    /// The main namespace. Talk, user, template and other pages are left out.
    private static let articleNamespaceID = 0

    private var slideData: WMFYearInReviewTopArticlesSlideData?

    private weak var legacyPageViewsDataDelegate: LegacyPageViewsDataDelegate?
    private let mainPageTitles: YearInReviewMainPageTitles?
    private let yirConfig: WMFFeatureConfigResponse.Common.YearInReview

    init(year: Int, yirConfig: WMFFeatureConfigResponse.Common.YearInReview, dependencies: YearInReviewSlideDataControllerDependencies) {
        self.year = year
        self.yirConfig = yirConfig
        self.legacyPageViewsDataDelegate = dependencies.legacyPageViewsDataDelegate
        self.mainPageTitles = dependencies.mainPageTitles
    }

    func populateSlideData(in context: NSManagedObjectContext) async throws {
        guard let mainPageTitles else {
            throw YearInReviewMainPageTitles.LookupError.unavailable
        }
        let dataController = try WMFPageViewsDataController()

        guard let startDate = yirConfig.dataStartDate,
              let endDate = yirConfig.dataEndDate else {
            throw NSError(domain: "", code: 0, userInfo: nil)
        }
        if let pageViewCounts = try? await dataController.fetchPageViewCounts(startDate: startDate, endDate: endDate) {
            let candidates = pageViewCounts
                .filter { $0.count >= WMFYearInReviewTopArticlesSlideData.minimumVisitCount }
                .filter { $0.page.namespaceID == Self.articleNamespaceID }
                // The title breaks a tie, so the order is the same on each run.
                .sorted { ($0.count, $1.page.title) > ($1.count, $0.page.title) }

            let articles = candidates
                .filter { !mainPageTitles.isMainPage($0.page) }
                .prefix(WMFYearInReviewTopArticlesSlideData.maximumArticleCount)
                .map { WMFYearInReviewTopArticlesSlideData.Article(title: $0.page.title.replacingOccurrences(of: "_", with: " "), projectID: $0.page.projectID, visitCount: $0.count) }

            slideData = WMFYearInReviewTopArticlesSlideData(articles: articles)
        }

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
        return config.isActive(for: Date())
    }
}
