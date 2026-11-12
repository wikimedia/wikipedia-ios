import CoreData

/// The "favorite time to explore" slide: the part of the day when the reader read the most articles,
/// and the share of all their reads in that part of the day. Each article page view is one read, in
/// the time zone of the device. Pages outside the main namespace and main pages do not count.
public struct WMFYearInReviewReadingPatternSlideData: Codable, Sendable, Equatable {

    /// The reader must have read at least this number of articles in one part of the day to see the full slide.
    public static let minimumReadCount = 2

    /// The part of the day with the most reads. `nil` without any reading.
    public let timeOfDay: WMFYearInReviewTimeOfDay?
    /// The number of reads in `timeOfDay`.
    public let timeOfDayReadCount: Int
    /// The number of reads in the whole data period.
    public let totalReadCount: Int

    public init(timeOfDay: WMFYearInReviewTimeOfDay?, timeOfDayReadCount: Int, totalReadCount: Int) {
        self.timeOfDay = timeOfDay
        self.timeOfDayReadCount = timeOfDayReadCount
        self.totalReadCount = totalReadCount
    }

    /// The share of all reads that were in `timeOfDay`, from 0 to 1.
    public var share: Double {
        guard totalReadCount > 0 else {
            return 0
        }
        return Double(timeOfDayReadCount) / Double(totalReadCount)
    }

    /// If false, show the empty state ("You read basically whenever").
    public var isEligible: Bool {
        timeOfDay != nil && timeOfDayReadCount >= Self.minimumReadCount && totalReadCount > 0
    }
}

// @unchecked: `isEvaluated` is mutable, but instances are confined to the sequential
// populate flow in WMFYearInReviewDataController (mutated in a loop, then read in a
// single Core Data perform closure) — see YearInReviewSlideDataControllerProtocol.
final class YearInReviewReadingPatternSlideDataController: YearInReviewSlideDataControllerProtocol, @unchecked Sendable {

    typealias SlideData = WMFYearInReviewReadingPatternSlideData

    let id = WMFYearInReviewPersonalizedSlideID.readingPattern.rawValue
    let year: Int
    var isEvaluated: Bool = false
    static let personalizationSources: Set<WMFYearInReviewPersonalizationSource> = [.readingHistory]
    static let shouldFreeze = true

    private var slideData: SlideData?

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

        let pageViews = try await WMFPageViewsDataController().fetchArticlePageViewTimestamps(startDate: startDate, endDate: endDate)
        let readDates = pageViews.filter { !mainPageTitles.isMainPage($0.page) }.map(\.timestamp)
        slideData = Self.slideData(readDates: readDates, calendar: .current)

        isEvaluated = true
    }

    /// The part of the day with the most reads. With two parts of the day with the same number of
    /// reads, the earlier one in `WMFYearInReviewTimeOfDay.allCases` wins, so the slide does not change.
    /// - Parameters:
    ///   - readDates: The time of each read, in any order.
    ///   - calendar: The calendar whose time zone gives the hour of each read.
    static func slideData(readDates: [Date], calendar: Calendar) -> SlideData {
        var readCounts: [WMFYearInReviewTimeOfDay: Int] = [:]
        for date in readDates {
            if let timeOfDay = WMFYearInReviewTimeOfDay(hour: calendar.component(.hour, from: date)) {
                readCounts[timeOfDay, default: 0] += 1
            }
        }

        var top: (timeOfDay: WMFYearInReviewTimeOfDay, readCount: Int)?
        for timeOfDay in WMFYearInReviewTimeOfDay.allCases {
            let readCount = readCounts[timeOfDay, default: 0]
            if readCount > (top?.readCount ?? 0) {
                top = (timeOfDay, readCount)
            }
        }

        return SlideData(timeOfDay: top?.timeOfDay, timeOfDayReadCount: top?.readCount ?? 0, totalReadCount: readDates.count)
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
