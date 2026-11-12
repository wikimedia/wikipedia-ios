import CoreData

// @unchecked: `isEvaluated` is mutable, but instances are confined to the sequential
// populate flow in WMFYearInReviewDataController (mutated in a loop, then read in a
// single Core Data perform closure) — see YearInReviewSlideDataControllerProtocol.
final class YearInReviewReadCountSlideDataController: YearInReviewSlideDataControllerProtocol, @unchecked Sendable {

    let id = WMFYearInReviewPersonalizedSlideID.readCount.rawValue
    let year: Int
    var isEvaluated: Bool = false
    static let personalizationSources: Set<WMFYearInReviewPersonalizationSource> = [.readingHistory]
    static let shouldFreeze = true
    /// `WMFYearInReviewReadData` hides the minutes read slide for data in an older format, so the
    /// total articles slide in that data can still show.
    static let keepsOutdatedDataOnFailedRebuild = true

    private static let articleNamespaceID = 0

    private var readData: WMFYearInReviewReadData?

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
        guard let startDate = yirConfig.dataStartDate,
              let endDate = yirConfig.dataEndDate else {
            throw NSError(domain: "", code: 0, userInfo: nil)
        }
        
        let dataController = try WMFPageViewsDataController()

        readData = try await Self.fetchReadData(startDate: startDate, endDate: endDate, pageViewsDataController: dataController, mainPageTitles: mainPageTitles)
        
        isEvaluated = true
    }

    /// The number of distinct articles read in the date range. Pages outside the main namespace and
    /// main pages do not count. The Year in Review entry point calls this. It needs no reading time, so it
    /// skips the seconds, but it uses the same `articles(from:)` rule as `fetchReadData`, so the entry
    /// point and the total articles slide always agree.
    static func fetchReadCount(startDate: Date, endDate: Date, pageViewsDataController: WMFPageViewsDataController, mainPageTitles: YearInReviewMainPageTitles) async throws -> Int {
        let pageViewCounts = try await pageViewsDataController.fetchPageViewCounts(startDate: startDate, endDate: endDate)
        // A page can have more than one stored row, so count each page once.
        return articles(from: Set(pageViewCounts.map(\.page)), mainPageTitles: mainPageTitles).count
    }

    /// The most seconds that one page view from before the July 2026 timer fix adds to the minutes read.
    /// That bug added the length of each foreground session to every article in memory. The one time clamp
    /// in `WMFPageViewsDataController` only removes values above one hour, so this lower limit also reduces
    /// inflation that is spread over many page views. Page views from `timerFixReleaseDate` on have no limit.
    static let maximumSecondsPerPageViewBeforeTimerFix = 30 * 60

    /// The App Store release of the timer fix (2026.08.11). Every page view before it comes from a build
    /// with the bug, so the limit applies. Page views from this date on can come from the fixed build, so
    /// a real long read is not cut.
    ///
    /// This is not `WMFPageViewsDataController.inflatedPageViewSecondsCleanupCutoff` (August 31). That date
    /// is late on purpose, so the one time clamp reaches slow upgrades. Here, a late date would also cut
    /// real reads from the fixed build. A reader who upgraded after this date can keep some inflated time
    /// from before the upgrade, but the one time clamp already limits each of those page views to one hour.
    static let timerFixReleaseDate: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 11
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current

        // 2026-08-11T00:00:00Z
        return calendar.date(from: components) ?? Date(timeIntervalSince1970: 1_786_406_400)
    }()

    /// An article whose page views from January 1 through August 31, 2026 add up to more than this many
    /// seconds gets no minutes from those page views. Most of that time likely comes from the timer bug.
    static let maximumSecondsPerArticleInExclusionPeriod = 60 * 60

    /// The start of the period for `maximumSecondsPerArticleInExclusionPeriod`: 2026-01-01T00:00:00Z.
    static let exclusionPeriodStartDate: Date = utcDate(year: 2026, month: 1, day: 1) ?? Date(timeIntervalSince1970: 1_767_225_600)

    /// The end of the period for `maximumSecondsPerArticleInExclusionPeriod`, not included:
    /// 2026-09-01T00:00:00Z, so all of August 31 is in the period.
    static let exclusionPeriodEndDate: Date = utcDate(year: 2026, month: 9, day: 1) ?? Date(timeIntervalSince1970: 1_788_220_800)

    private static func utcDate(year: Int, month: Int, day: Int) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar.date(from: components)
    }

    /// The articles read and the whole minutes spent reading them in the date range. Both count the same
    /// pages, so the total articles slide and the minutes read slide match. The wiki main page lookups
    /// run once for both.
    ///
    /// The minutes count only articles, not talk pages or main pages. This is on purpose: the slide
    /// describes time spent reading articles, next to the total articles. The Activity tab uses
    /// `WMFPageViewsDataController.fetchPageViewMinutes`, which counts all page views, so its value can be higher.
    ///
    /// Two rules reduce time that the timer bug inflated:
    /// - Each page view before `timerFixReleaseDate` adds at most `maximumSecondsPerPageViewBeforeTimerFix`.
    /// - An article with more than `maximumSecondsPerArticleInExclusionPeriod` of stored time from
    ///   `exclusionPeriodStartDate` up to `exclusionPeriodEndDate` gets no minutes from that period. It still
    ///   counts in `readCount`, and its page views after that period still add minutes.
    static func fetchReadData(startDate: Date, endDate: Date, pageViewsDataController: WMFPageViewsDataController, mainPageTitles: YearInReviewMainPageTitles) async throws -> WMFYearInReviewReadData {
        let cap = WMFPageViewsDataController.PageViewSecondsCap(
            maximumSeconds: maximumSecondsPerPageViewBeforeTimerFix,
            before: timerFixReleaseDate
        )
        let exclusion = WMFPageViewsDataController.PageViewSecondsExclusion(
            from: exclusionPeriodStartDate,
            upTo: exclusionPeriodEndDate,
            maximumSeconds: maximumSecondsPerArticleInExclusionPeriod
        )
        let secondsByPage = try await pageViewsDataController.fetchPageViewSeconds(startDate: startDate, endDate: endDate, cap: cap, exclusion: exclusion)
        let articles = articles(from: Set(secondsByPage.keys), mainPageTitles: mainPageTitles)
        let totalSeconds = articles.reduce(0) { $0 + (secondsByPage[$1] ?? 0) }
        return WMFYearInReviewReadData(readCount: articles.count, minutesRead: totalSeconds / 60)
    }

    /// The pages that count as articles: pages in the main namespace that are not a main page.
    private static func articles(from pages: Set<WMFPage>, mainPageTitles: YearInReviewMainPageTitles) -> Set<WMFPage> {
        pages.filter { $0.namespaceID == articleNamespaceID && !mainPageTitles.isMainPage($0) }
    }

    func makeCDSlide(in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = id
        slide.year = Int32(year)

        if let readData {
            let encoder = JSONEncoder()
            slide.data = try encoder.encode(readData)
        }

        return slide
    }

    static func shouldPopulate(from config: WMFFeatureConfigResponse.Common.YearInReview, userInfo: YearInReviewUserInfo) -> Bool {
        return config.isActive(for: Date())
    }

    /// Older builds stored `minutesRead` for all page views, with no limit per page view. That data has no
    /// `minutesReadFormat`, or an older one, so the report builds the slide again with the current rules,
    /// also when the slide is frozen.
    static func hasCurrentFormat(_ data: Data?) -> Bool {
        guard let data,
              let readData = try? JSONDecoder().decode(WMFYearInReviewReadData.self, from: data) else {
            return false
        }
        return readData.minutesReadFormat == WMFYearInReviewReadData.currentMinutesReadFormat
    }
}

