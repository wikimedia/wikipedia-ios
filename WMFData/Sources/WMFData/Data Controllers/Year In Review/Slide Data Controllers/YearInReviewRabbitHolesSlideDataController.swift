import CoreData

/// The "deepest rabbit hole" slides. A rabbit hole is a chain of articles that the reader opened one
/// after the other from links in the app.
public struct WMFYearInReviewRabbitHolesSlideData: Codable, Sendable, Equatable {

    public struct Article: Codable, Sendable, Equatable {
        /// The title with spaces, not underscores.
        public let title: String
        /// The `WMFProject.id` of the wiki the article is on.
        public let projectID: String

        public var project: WMFProject? {
            WMFProject(id: projectID)
        }
    }

    public struct RabbitHole: Codable, Sendable, Equatable {
        public let firstArticle: Article
        public let lastArticle: Article
        /// Includes the first and the last article.
        public let articleCount: Int
    }

    /// A rabbit hole has at least this number of articles: the first article and two more from links.
    public static let minimumArticleCount = 3
    /// The reader must have at least this number of rabbit holes to see the slides.
    public static let minimumRabbitHoleCount = 2
    /// A longer time between two articles ends the rabbit hole.
    public static let maximumTimeBetweenArticles: TimeInterval = 60 * 60

    /// The deepest rabbit holes, deepest first. At most `minimumRabbitHoleCount`.
    public let rabbitHoles: [RabbitHole]
    /// The guess slide shows the deepest rabbit hole on the top card if true, on the bottom card if
    /// false. It is chosen at random when the data is made, so it does not change.
    public let deepestIsOnTop: Bool

    /// If false, the slides do not show.
    public var isEligible: Bool {
        rabbitHoles.count >= Self.minimumRabbitHoleCount
    }
}

// @unchecked: `isEvaluated` is mutable, but instances are confined to the sequential
// populate flow in WMFYearInReviewDataController (mutated in a loop, then read in a
// single Core Data perform closure) — see YearInReviewSlideDataControllerProtocol.
final class YearInReviewRabbitHolesSlideDataController: YearInReviewSlideDataControllerProtocol, @unchecked Sendable {

    typealias SlideData = WMFYearInReviewRabbitHolesSlideData

    let id = WMFYearInReviewPersonalizedSlideID.rabbitHoles.rawValue
    let year: Int
    var isEvaluated: Bool = false
    static let personalizationSources: Set<WMFYearInReviewPersonalizationSource> = [.readingHistory]
    static let shouldFreeze = true

    private static let articleNamespaceID = 0
    private static let englishMainPageTitle = WMFMainPageTitle.canonicalized("Main Page")

    private var slideData: SlideData?

    private weak var mainPageIdentifier: WMFMainPageIdentifying?
    private let yirConfig: WMFFeatureConfigResponse.Common.YearInReview

    init(year: Int, yirConfig: WMFFeatureConfigResponse.Common.YearInReview, dependencies: YearInReviewSlideDataControllerDependencies) {
        self.year = year
        self.yirConfig = yirConfig
        self.mainPageIdentifier = dependencies.mainPageIdentifier
    }

    func populateSlideData(in context: NSManagedObjectContext) async throws {
        guard let startDate = yirConfig.dataStartDate,
              let endDate = yirConfig.dataEndDate else {
            throw NSError(domain: "", code: 0, userInfo: nil)
        }

        let links = try await WMFPageViewsDataController().fetchPageViewLinks(startDate: startDate, endDate: endDate)

        // Get the main page title once for each wiki. Each request can go to the main actor.
        var mainPageTitles: [String: String] = [:]
        for projectID in Set(links.map(\.page.projectID)) {
            if let project = WMFProject(id: projectID),
               let title = await mainPageIdentifier?.mainPageTitle(for: project) {
                mainPageTitles[projectID] = WMFMainPageTitle.canonicalized(title)
            }
        }

        let rabbitHoles = Self.deepestRabbitHoles(in: links) { page in
            guard page.namespaceID == Self.articleNamespaceID else {
                return false
            }
            let title = WMFMainPageTitle.canonicalized(page.title)
            // The app does not record the English main page, but older data can contain it.
            return title != Self.englishMainPageTitle && title != mainPageTitles[page.projectID]
        }
        slideData = SlideData(rabbitHoles: rabbitHoles, deepestIsOnTop: Bool.random())

        isEvaluated = true
    }

    /// One chain of articles while the chains are built.
    private struct Chain {
        let first: WMFPageViewLink
        let last: WMFPageViewLink
        let articleCount: Int
    }

    /// The deepest rabbit holes, deepest first, at most `SlideData.minimumRabbitHoleCount`.
    ///
    /// A page view continues the chain of the page view that it came from, if that page view is an
    /// article and less than `maximumTimeBetweenArticles` before it. Otherwise it starts a chain.
    /// A page that is not an article, such as a main page, ends the chain, so a rabbit hole cannot
    /// start or end on it. Two articles opened from the same article are two branches of one rabbit
    /// hole, so each first article gives at most one rabbit hole: its deepest branch. A tie goes to
    /// the more recent rabbit hole.
    /// - Parameter links: Oldest first.
    static func deepestRabbitHoles(in links: [WMFPageViewLink], isArticle: (WMFPage) -> Bool) -> [SlideData.RabbitHole] {
        var chainsByLastID: [URL: Chain] = [:]
        for link in links where isArticle(link.page) {
            if let previousID = link.previousID,
               let previous = chainsByLastID[previousID],
               link.timestamp.timeIntervalSince(previous.last.timestamp) <= SlideData.maximumTimeBetweenArticles {
                chainsByLastID[link.id] = Chain(first: previous.first, last: link, articleCount: previous.articleCount + 1)
            } else {
                chainsByLastID[link.id] = Chain(first: link, last: link, articleCount: 1)
            }
        }

        func isDeeper(_ lhs: Chain, than rhs: Chain) -> Bool {
            (lhs.articleCount, lhs.last.timestamp) > (rhs.articleCount, rhs.last.timestamp)
        }

        var deepestByFirstID: [URL: Chain] = [:]
        for chain in chainsByLastID.values where chain.articleCount >= SlideData.minimumArticleCount {
            if let deepest = deepestByFirstID[chain.first.id], !isDeeper(chain, than: deepest) {
                continue
            }
            deepestByFirstID[chain.first.id] = chain
        }

        return deepestByFirstID.values
            .sorted(by: isDeeper)
            .prefix(SlideData.minimumRabbitHoleCount)
            .map { chain in
                SlideData.RabbitHole(
                    firstArticle: article(chain.first.page),
                    lastArticle: article(chain.last.page),
                    articleCount: chain.articleCount
                )
            }
    }

    private static func article(_ page: WMFPage) -> SlideData.Article {
        SlideData.Article(title: page.title.replacingOccurrences(of: "_", with: " "), projectID: page.projectID)
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
