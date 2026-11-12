import CoreData

/// The "longest read article" slide. The reader guesses which of two articles they read the
/// longest, then the slide shows the answer.
public struct WMFYearInReviewLongestReadSlideData: Codable, Sendable, Equatable {

    public struct Article: Codable, Sendable, Equatable {
        /// The title with spaces, not underscores.
        public let title: String
        /// The `WMFProject.id` of the wiki the article is on.
        public let projectID: String
        /// The short description of the article. `nil` if the article has none, or if it did not load.
        public let description: String?
        /// The reading time of all the visits that count.
        public let seconds: Int

        public var project: WMFProject? {
            WMFProject(id: projectID)
        }
    }

    /// An article counts only with more reading time than this.
    public static let minimumSecondsPerArticle = 60
    /// Before September 1, a visit with this reading time or more is most likely wrong: the app
    /// recorded too much time until the fix in wikipedia-ios PR 6045, and the cleanup after the fix
    /// capped the wrong values at this number. So such a visit does not count.
    public static let unreliableVisitSeconds = 60 * 60
    /// From this month of the year, the reading time of every visit counts.
    public static let reliableReadingTimeStartMonth = 9
    public static let articleCount = 2

    /// The articles with the most reading time, most first. At most `articleCount`. Only articles
    /// with more than `minimumSecondsPerArticle`.
    public let articles: [Article]
    /// The guess slide shows the longest read article on the top card if true, on the bottom card if
    /// false. It is chosen at random when the data is made, so it does not change.
    public let longestIsOnTop: Bool

    public var longest: Article? {
        articles.first
    }

    public var other: Article? {
        articles.dropFirst().first
    }

    /// The minutes of the longest read article.
    public var minuteCount: Int {
        (longest?.seconds ?? 0) / 60
    }

    /// If false, the slide does not show. It needs two articles and one clear winner.
    public var isEligible: Bool {
        guard let longest, let other else {
            return false
        }
        return longest.seconds > other.seconds
    }
}

// @unchecked: `isEvaluated` is mutable, but instances are confined to the sequential
// populate flow in WMFYearInReviewDataController (mutated in a loop, then read in a
// single Core Data perform closure) — see YearInReviewSlideDataControllerProtocol.
final class YearInReviewLongestReadSlideDataController: YearInReviewSlideDataControllerProtocol, @unchecked Sendable {

    typealias SlideData = WMFYearInReviewLongestReadSlideData

    let id = WMFYearInReviewPersonalizedSlideID.longestRead.rawValue
    let year: Int
    var isEvaluated: Bool = false
    static let personalizationSources: Set<WMFYearInReviewPersonalizationSource> = [.readingHistory]
    static let shouldFreeze = true

    private var slideData: SlideData?

    /// Gets the short description of one article. Tests replace it.
    var fetchDescription: @Sendable (WMFProject, String) async throws -> String? = { project, title in
        try await WMFArticleSummaryDataController.shared.fetchArticleSummary(project: project, title: title).description
    }

    private let mainPageTitles: YearInReviewMainPageTitles?
    private let yirConfig: WMFFeatureConfigResponse.Common.YearInReview

    init(year: Int, yirConfig: WMFFeatureConfigResponse.Common.YearInReview, dependencies: YearInReviewSlideDataControllerDependencies) {
        self.year = year
        self.yirConfig = yirConfig
        self.mainPageTitles = dependencies.mainPageTitles
    }

    func populateSlideData(in context: NSManagedObjectContext) async throws {
        guard let mainPageTitles else {
            throw YearInReviewMainPageTitles.LookupError.unavailable
        }
        guard let startDate = yirConfig.dataStartDate,
              let endDate = yirConfig.dataEndDate else {
            throw NSError(domain: "", code: 0, userInfo: nil)
        }

        let readingTimes = try await WMFPageViewsDataController().fetchArticleReadingTimes(startDate: startDate, endDate: endDate)
        let articleReadingTimes = readingTimes.filter { !mainPageTitles.isMainPage($0.page) }

        var slideData = Self.slideData(readingTimes: articleReadingTimes, year: year, calendar: .current, longestIsOnTop: Bool.random())
        if slideData.isEligible {
            slideData = await addingDescriptions(to: slideData)
        }
        self.slideData = slideData

        isEvaluated = true
    }

    /// The `articleCount` articles with the most reading time. A visit before September 1 of `year`
    /// in `calendar` with `unreliableVisitSeconds` or more does not count, but the other visits of
    /// the same article do. A tie between two articles goes to the more recently read one.
    static func slideData(readingTimes: [WMFPageViewReadingTime], year: Int, calendar: Calendar, longestIsOnTop: Bool) -> SlideData {
        struct ArticleTime {
            var seconds = 0
            var lastTimestamp = Date.distantPast
        }

        let reliableStart = calendar.date(from: DateComponents(year: year, month: SlideData.reliableReadingTimeStartMonth, day: 1)) ?? .distantPast

        var articleTimes: [WMFPage: ArticleTime] = [:]
        for readingTime in readingTimes {
            if readingTime.timestamp < reliableStart && readingTime.numberOfSeconds >= SlideData.unreliableVisitSeconds {
                continue
            }
            var articleTime = articleTimes[readingTime.page] ?? ArticleTime()
            articleTime.seconds += readingTime.numberOfSeconds
            articleTime.lastTimestamp = max(articleTime.lastTimestamp, readingTime.timestamp)
            articleTimes[readingTime.page] = articleTime
        }

        let articles = articleTimes
            .filter { $0.value.seconds > SlideData.minimumSecondsPerArticle }
            .sorted { ($0.value.seconds, $0.value.lastTimestamp) > ($1.value.seconds, $1.value.lastTimestamp) }
            .prefix(SlideData.articleCount)
            .map { SlideData.Article(title: $0.key.title.replacingOccurrences(of: "_", with: " "), projectID: $0.key.projectID, description: nil, seconds: $0.value.seconds) }

        return SlideData(articles: Array(articles), longestIsOnTop: longestIsOnTop)
    }

    /// A description that fails to load is left out.
    private func addingDescriptions(to slideData: SlideData) async -> SlideData {
        let fetchDescription = fetchDescription
        let descriptions = await withTaskGroup(of: (Int, String?).self) { group in
            for (index, article) in slideData.articles.enumerated() {
                guard let project = article.project else { continue }
                group.addTask {
                    (index, try? await fetchDescription(project, article.title))
                }
            }
            var descriptions: [Int: String] = [:]
            for await (index, description) in group {
                if let description, !description.isEmpty {
                    descriptions[index] = description
                }
            }
            return descriptions
        }

        let articles = slideData.articles.enumerated().map { index, article in
            SlideData.Article(title: article.title, projectID: article.projectID, description: descriptions[index], seconds: article.seconds)
        }
        return SlideData(articles: articles, longestIsOnTop: slideData.longestIsOnTop)
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
