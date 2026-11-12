import CoreData

/// The "biggest reading day" slide and the slide with some of the articles of that day.
public struct WMFYearInReviewBiggestReadingDaySlideData: Codable, Sendable, Equatable {

    public struct Article: Codable, Sendable, Equatable {
        /// The title with spaces, not underscores.
        public let title: String
        /// The `WMFProject.id` of the wiki the article is on.
        public let projectID: String
        /// The short description of the article. `nil` if the article has none, or if it did not load.
        public let description: String?

        public var project: WMFProject? {
            WMFProject(id: projectID)
        }
    }

    public static let minimumMinuteCount = 2
    /// A higher total is most likely an error, so the slide does not show.
    public static let maximumMinuteCount = 300_000
    /// The articles slide needs at least this number of different articles on the day.
    public static let minimumArticleCount = 2
    public static let maximumShownArticleCount = 3

    /// The day in the calendar of the device.
    public let year: Int
    public let month: Int
    public let day: Int
    public let minuteCount: Int
    /// The number of different articles with reading time on the day.
    public let articleCount: Int
    /// The articles with the most reading time on the day, most first. At most `maximumShownArticleCount`.
    public let articles: [Article]

    public var dateComponents: DateComponents {
        DateComponents(year: year, month: month, day: day)
    }

    /// If false, neither slide shows.
    public var isEligible: Bool {
        (Self.minimumMinuteCount...Self.maximumMinuteCount).contains(minuteCount)
    }

    public var showsArticles: Bool {
        isEligible && articleCount >= Self.minimumArticleCount
    }
}

// @unchecked: `isEvaluated` is mutable, but instances are confined to the sequential
// populate flow in WMFYearInReviewDataController (mutated in a loop, then read in a
// single Core Data perform closure) — see YearInReviewSlideDataControllerProtocol.
final class YearInReviewBiggestReadingDaySlideDataController: YearInReviewSlideDataControllerProtocol, @unchecked Sendable {

    typealias SlideData = WMFYearInReviewBiggestReadingDaySlideData

    let id = WMFYearInReviewPersonalizedSlideID.biggestReadingDay.rawValue
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

        guard var slideData = Self.slideData(readingTimes: articleReadingTimes, calendar: .current) else {
            isEvaluated = true
            return
        }
        if slideData.showsArticles {
            slideData = await addingDescriptions(to: slideData)
        }
        self.slideData = slideData

        isEvaluated = true
    }

    /// The day with the most reading time, in `calendar`. `nil` without reading time. A tie goes to
    /// the more recent day. On that day, a tie between two articles goes to the more recently read one.
    static func slideData(readingTimes: [WMFPageViewReadingTime], calendar: Calendar) -> SlideData? {
        struct ArticleTime {
            var seconds = 0
            var lastTimestamp = Date.distantPast
        }

        var secondsByDay: [Date: Int] = [:]
        var articleTimesByDay: [Date: [WMFPage: ArticleTime]] = [:]
        for readingTime in readingTimes {
            let day = calendar.startOfDay(for: readingTime.timestamp)
            secondsByDay[day, default: 0] += readingTime.numberOfSeconds
            var articleTime = articleTimesByDay[day]?[readingTime.page] ?? ArticleTime()
            articleTime.seconds += readingTime.numberOfSeconds
            articleTime.lastTimestamp = max(articleTime.lastTimestamp, readingTime.timestamp)
            articleTimesByDay[day, default: [:]][readingTime.page] = articleTime
        }

        guard let (biggestDay, seconds) = secondsByDay.max(by: { ($0.value, $0.key) < ($1.value, $1.key) }) else {
            return nil
        }

        let articleTimes = articleTimesByDay[biggestDay] ?? [:]
        let articles = articleTimes
            .sorted { ($0.value.seconds, $0.value.lastTimestamp) > ($1.value.seconds, $1.value.lastTimestamp) }
            .prefix(SlideData.maximumShownArticleCount)
            .map { SlideData.Article(title: $0.key.title.replacingOccurrences(of: "_", with: " "), projectID: $0.key.projectID, description: nil) }

        let components = calendar.dateComponents([.year, .month, .day], from: biggestDay)
        return SlideData(
            year: components.year ?? 0,
            month: components.month ?? 0,
            day: components.day ?? 0,
            minuteCount: seconds / 60,
            articleCount: articleTimes.count,
            articles: Array(articles)
        )
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
            SlideData.Article(title: article.title, projectID: article.projectID, description: descriptions[index])
        }
        return SlideData(year: slideData.year, month: slideData.month, day: slideData.day, minuteCount: slideData.minuteCount, articleCount: slideData.articleCount, articles: articles)
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
