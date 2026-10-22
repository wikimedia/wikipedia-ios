import CoreData

public struct WMFYearInReviewDaysVisitedSlideData: Codable, Sendable, Equatable {

    public struct PeakMonth: Codable, Sendable, Equatable {
        public let month: Int
        public let dayCount: Int
    }

    public static let minimumDayCount = 2
    public static let minimumPeakMonthDayCount = 2

    public let dayCount: Int
    public let peakMonth: PeakMonth?

    public var isEligible: Bool {
        dayCount >= Self.minimumDayCount
    }
}

// @unchecked: `isEvaluated` is mutable, but instances are confined to the sequential
// populate flow in WMFYearInReviewDataController (mutated in a loop, then read in a
// single Core Data perform closure) — see YearInReviewSlideDataControllerProtocol.
final class YearInReviewDaysVisitedSlideDataController: YearInReviewSlideDataControllerProtocol, @unchecked Sendable {

    typealias SlideData = WMFYearInReviewDaysVisitedSlideData

    let id = WMFYearInReviewPersonalizedSlideID.daysVisited.rawValue
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

    static func slideData(days: [Date], calendar: Calendar) -> SlideData {
        var dayCountByMonth: [DateComponents: Int] = [:]
        for day in days {
            dayCountByMonth[calendar.dateComponents([.year, .month], from: day), default: 0] += 1
        }

        // A tie picks a random month. The slide data is frozen, so the choice does not change.
        var peakMonth: SlideData.PeakMonth?
        if let highestCount = dayCountByMonth.values.max(),
           highestCount >= SlideData.minimumPeakMonthDayCount,
           let month = dayCountByMonth.filter({ $0.value == highestCount }).keys.randomElement()?.month {
            peakMonth = SlideData.PeakMonth(month: month, dayCount: highestCount)
        }

        return SlideData(dayCount: days.count, peakMonth: peakMonth)
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
