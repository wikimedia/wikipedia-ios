import CoreData

/// The longest reading streak: the most consecutive calendar days, in the device's time zone, with
/// at least one article read. The same definition as the 25 day reading challenge.
public struct WMFYearInReviewReadingStreakSlideData: Codable, Sendable, Equatable {

    /// A calendar day, kept as its date components so the day does not move when the time zone changes.
    public struct Day: Codable, Sendable, Equatable {
        public let year: Int
        public let month: Int
        public let day: Int

        public init(year: Int, month: Int, day: Int) {
            self.year = year
            self.month = month
            self.day = day
        }

        init?(date: Date, calendar: Calendar) {
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            guard let year = components.year, let month = components.month, let day = components.day else {
                return nil
            }
            self.init(year: year, month: month, day: day)
        }

        /// The start of this day in `calendar`.
        public func date(in calendar: Calendar) -> Date? {
            calendar.date(from: DateComponents(year: year, month: month, day: day))
        }
    }

    /// The reader must have read on at least this number of consecutive days to see the full slide.
    public static let minimumDayCount = 2

    /// The number of days in the longest streak. `0` without any reading.
    public let dayCount: Int
    /// The first day of the longest streak. `nil` without any reading.
    public let firstDay: Day?
    /// The last day of the longest streak. `nil` without any reading.
    public let lastDay: Day?

    public init(dayCount: Int, firstDay: Day?, lastDay: Day?) {
        self.dayCount = dayCount
        self.firstDay = firstDay
        self.lastDay = lastDay
    }

    /// If false, show the empty state ("0 reading streaks... yet").
    public var isEligible: Bool {
        dayCount >= Self.minimumDayCount && firstDay != nil && lastDay != nil
    }
}

// @unchecked: `isEvaluated` is mutable, but instances are confined to the sequential
// populate flow in WMFYearInReviewDataController (mutated in a loop, then read in a
// single Core Data perform closure) — see YearInReviewSlideDataControllerProtocol.
final class YearInReviewReadingStreakSlideDataController: YearInReviewSlideDataControllerProtocol, @unchecked Sendable {

    typealias SlideData = WMFYearInReviewReadingStreakSlideData

    let id = WMFYearInReviewPersonalizedSlideID.readingStreak.rawValue
    let year: Int
    var isEvaluated: Bool = false
    static let personalizationSources: Set<WMFYearInReviewPersonalizationSource> = [.readingHistory]
    static let shouldFreeze = true

    private var slideData: SlideData?

    private let yirConfig: WMFFeatureConfigResponse.Common.YearInReview

    init(year: Int, yirConfig: WMFFeatureConfigResponse.Common.YearInReview, dependencies: YearInReviewSlideDataControllerDependencies) {
        self.year = year
        self.yirConfig = yirConfig
    }

    func populateSlideData(in context: NSManagedObjectContext) async throws {

        guard let startDate = yirConfig.dataStartDate,
              let endDate = yirConfig.dataEndDate else {
            throw NSError(domain: "", code: 0, userInfo: nil)
        }

        let calendar = Calendar.current
        let days = try await WMFPageViewsDataController().fetchDistinctPageViewDays(startDate: startDate, endDate: endDate, calendar: calendar)
        slideData = Self.slideData(days: days, calendar: calendar)

        isEvaluated = true
    }

    /// The longest run of consecutive days in `days`. With two runs of the same length, the earlier one wins.
    /// - Parameter days: The start of each day with a read in `calendar`, in any order.
    static func slideData(days: [Date], calendar: Calendar) -> SlideData {
        let sortedDays = Set(days.map { calendar.startOfDay(for: $0) }).sorted()
        guard let firstReadDay = sortedDays.first else {
            return SlideData(dayCount: 0, firstDay: nil, lastDay: nil)
        }

        var longest = (first: firstReadDay, last: firstReadDay, count: 1)
        var current = longest
        for day in sortedDays.dropFirst() {
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: current.last), calendar.isDate(day, inSameDayAs: nextDay) {
                current = (current.first, day, current.count + 1)
            } else {
                current = (day, day, 1)
            }
            if current.count > longest.count {
                longest = current
            }
        }

        return SlideData(
            dayCount: longest.count,
            firstDay: SlideData.Day(date: longest.first, calendar: calendar),
            lastDay: SlideData.Day(date: longest.last, calendar: calendar)
        )
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
