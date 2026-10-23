import CoreData

/// The "top topic" slide and the "runners-up" slide. The top topic needs at least
/// `minimumTopTopicArticleCount` distinct articles, and a runner-up needs at least
/// `minimumRunnerUpArticleCount`.
public struct WMFYearInReviewTopTopicsSlideData: Codable, Sendable {

    public struct Article: Codable, Sendable, Equatable {
        /// The title with spaces, not underscores.
        public let title: String
        /// The `WMFProject.id` of the wiki the article is on.
        public let projectID: String

        public var project: WMFProject? {
            WMFProject(id: projectID)
        }
    }

    public struct TopicCount: Codable, Sendable, Equatable {
        /// The raw value of a `WMFArticleTopic`.
        public let topicID: String
        /// The number of distinct articles the user read about the topic.
        public let articleCount: Int

        public var topic: WMFArticleTopic? {
            WMFArticleTopic(rawValue: topicID)
        }
    }

    public struct TopTopic: Codable, Sendable, Equatable {
        public let topicCount: TopicCount
        /// The alphabetically first article about the topic.
        public let firstArticle: Article
        /// The alphabetically last article about the topic.
        public let lastArticle: Article
    }

    /// The user must read at least this number of articles to see the full top topic slide.
    public static let minimumReadCount = 5
    /// The top topic must have at least this number of articles.
    public static let minimumTopTopicArticleCount = 3
    /// A runner-up topic must have at least this number of articles.
    public static let minimumRunnerUpArticleCount = 2
    /// The runners-up slide shows at most this number of topics.
    public static let maximumRunnerUpCount = 3
    /// The runners-up slide shows only if it has at least this number of topics.
    public static let minimumRunnerUpCount = 2

    /// The number of distinct articles the user read, with or without topics.
    public let readCount: Int
    /// The topic with the most articles. `nil` if no topic has `minimumTopTopicArticleCount` articles.
    public let topTopic: TopTopic?
    /// The topics that come after the top topic, most articles first. Fewer than `minimumRunnerUpCount` is possible.
    public let runnerUps: [TopicCount]
    /// The image data of the topic illustrations, keyed by Commons file name. The slide data
    /// controller downloads only the illustrations of the shown topics. A download that fails is
    /// left out. `nil` in slide data from before the illustrations.
    public internal(set) var illustrations: [String: Data]?

    /// The image data of the illustration of `topic`, or `nil` if it did not download.
    public func illustration(for topic: WMFArticleTopic) -> Data? {
        illustrations?[topic.yearInReviewIllustrationFileName]
    }

    /// If false, show the empty state ("Your #1 topic of 2026 is... all of them").
    public var isEligible: Bool {
        readCount >= Self.minimumReadCount && topTopic != nil
    }

    /// If false, do not show the runners-up slide.
    public var showsRunnerUps: Bool {
        isEligible && runnerUps.count >= Self.minimumRunnerUpCount
    }
}

// @unchecked: `isEvaluated` is mutable, but instances are confined to the sequential
// populate flow in WMFYearInReviewDataController (mutated in a loop, then read in a
// single Core Data perform closure) — see YearInReviewSlideDataControllerProtocol.
final class YearInReviewTopTopicsSlideDataController: YearInReviewSlideDataControllerProtocol, @unchecked Sendable {

    typealias SlideData = WMFYearInReviewTopTopicsSlideData

    let id = WMFYearInReviewPersonalizedSlideID.topTopics.rawValue
    let year: Int
    var isEvaluated: Bool = false
    static let personalizationSources: Set<WMFYearInReviewPersonalizationSource> = [.readingHistory]
    static let shouldFreeze = true

    /// The main namespace. Talk, user, template and other pages are left out.
    private static let articleNamespaceID = 0

    private var slideData: SlideData?

    /// Downloads one illustration. Tests replace it.
    var fetchIllustrationData: @Sendable (URL) async throws -> Data = { url in
        try await WMFImageDataController.shared.fetchImageData(url: url)
    }

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

        let pageViewCounts = try await WMFPageViewsDataController().fetchPageViewCounts(startDate: startDate, endDate: endDate)
        let pagesWithTopics = try await WMFPageTopicsDataController().fetchReadPagesWithTopics(startDate: startDate, endDate: endDate)

        let readPages = pageViewCounts.map(\.page).filter { $0.namespaceID == Self.articleNamespaceID }

        // Get the main page title once for each wiki, not once for each article. Each request can go to the main actor.
        var mainPageTitles: [String: String] = [:]
        for projectID in Set(readPages.map(\.projectID)) {
            if let title = await mainPageTitle(projectID: projectID) {
                mainPageTitles[projectID] = WMFMainPageTitle.canonicalized(title)
            }
        }

        func isArticle(_ page: WMFPage) -> Bool {
            guard page.namespaceID == Self.articleNamespaceID else {
                return false
            }
            let title = WMFMainPageTitle.canonicalized(page.title)
            // The app does not record the English main page, but older data can contain it.
            return title != Self.englishMainPageTitle && title != mainPageTitles[page.projectID]
        }

        let readCount = Set(readPages).count(where: isArticle)

        var articlesByTopic: [WMFArticleTopic: [SlideData.Article]] = [:]
        for pageWithTopics in pagesWithTopics where isArticle(pageWithTopics.page) {
            let article = SlideData.Article(title: pageWithTopics.page.title.replacingOccurrences(of: "_", with: " "), projectID: pageWithTopics.page.projectID)
            // A set, so an article with two labels for the same topic counts once.
            let topics = Set(pageWithTopics.topicLabels.compactMap(WMFArticleTopic.init(pageTopicLabel:)).map(Self.yearInReviewTopic))
            for topic in topics {
                articlesByTopic[topic, default: []].append(article)
            }
        }

        var slideData = Self.slideData(readCount: readCount, articlesByTopic: articlesByTopic)
        if slideData.isEligible {
            slideData.illustrations = await downloadIllustrations(for: slideData)
        }
        self.slideData = slideData

        isEvaluated = true
    }

    /// Downloads the illustrations of the top topic and the runners-up. The topics of a region
    /// use the same file, so each file downloads one time.
    private func downloadIllustrations(for slideData: SlideData) async -> [String: Data] {
        var topics = slideData.topTopic.flatMap(\.topicCount.topic).map { [$0] } ?? []
        if slideData.showsRunnerUps {
            topics += slideData.runnerUps.compactMap(\.topic)
        }
        let fileNames = Set(topics.map(\.yearInReviewIllustrationFileName))

        let fetchIllustrationData = fetchIllustrationData
        return await withTaskGroup(of: (String, Data?).self) { group in
            for fileName in fileNames {
                group.addTask {
                    guard let url = URL.commonsUploadURL(fileName: fileName) else {
                        return (fileName, nil)
                    }
                    return (fileName, try? await fetchIllustrationData(url))
                }
            }

            var illustrations: [String: Data] = [:]
            for await (fileName, data) in group {
                if let data {
                    illustrations[fileName] = data
                }
            }
            return illustrations
        }
    }

    /// The Year in Review slides show "Biography (women)" as "Biography (all)", so that the runners-up
    /// do not show both. The two topics have the same sentence on the top topic slide.
    static func yearInReviewTopic(_ topic: WMFArticleTopic) -> WMFArticleTopic {
        topic == .women ? .biography : topic
    }

    static func slideData(readCount: Int, articlesByTopic: [WMFArticleTopic: [SlideData.Article]]) -> SlideData {
        // A runner-up needs fewer articles than the top topic, so this list holds every possible topic.
        let qualifyingTopics = articlesByTopic
            .filter { $0.value.count >= SlideData.minimumRunnerUpArticleCount }
            // The topic ID breaks a tie, so the runners-up have the same order on each run.
            .sorted { ($0.value.count, $1.key.rawValue) > ($1.value.count, $0.key.rawValue) }

        // If topics tie for the most articles, choose one at random. The slide data is frozen,
        // so the choice does not change after the first population.
        let highestCount = qualifyingTopics.first?.value.count
        guard let highestCount, highestCount >= SlideData.minimumTopTopicArticleCount,
              let top = qualifyingTopics.filter({ $0.value.count == highestCount }).randomElement() else {
            return SlideData(readCount: readCount, topTopic: nil, runnerUps: [])
        }

        let sortedArticles = top.value.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        var topTopic: SlideData.TopTopic?
        if let firstArticle = sortedArticles.first, let lastArticle = sortedArticles.last {
            topTopic = SlideData.TopTopic(
                topicCount: SlideData.TopicCount(topicID: top.key.rawValue, articleCount: top.value.count),
                firstArticle: firstArticle,
                lastArticle: lastArticle
            )
        }

        let runnerUps = qualifyingTopics
            .filter { $0.key != top.key }
            .prefix(SlideData.maximumRunnerUpCount)
            .map { SlideData.TopicCount(topicID: $0.key.rawValue, articleCount: $0.value.count) }

        return SlideData(readCount: readCount, topTopic: topTopic, runnerUps: Array(runnerUps))
    }

    private static let englishMainPageTitle = WMFMainPageTitle.canonicalized("Main Page")

    private func mainPageTitle(projectID: String) async -> String? {
        guard let project = WMFProject(id: projectID),
              let mainPageIdentifier else {
            return nil
        }
        return await mainPageIdentifier.mainPageTitle(for: project)
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
