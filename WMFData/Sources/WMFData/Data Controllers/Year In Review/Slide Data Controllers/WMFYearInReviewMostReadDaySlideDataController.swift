import CoreData

final class YearInReviewMostReadDaySlideDataController: YearInReviewSlideDataControllerProtocol {
    let id = WMFYearInReviewPersonalizedSlideID.mostReadDay.rawValue
    let year: Int
    var isEvaluated: Bool = false
    static var containsPersonalizedNetworkData = false
    
    var mostReadDay: WMFPageViewDay?

    private weak var legacyPageViewsDataDelegate: LegacyPageViewsDataDelegate?
    private let yirConfig: YearInReviewFeatureConfig
    
    init(year: Int, yirConfig: YearInReviewFeatureConfig, dependencies: YearInReviewSlideDataControllerDependencies) {
        self.year = year
        self.yirConfig = yirConfig
        self.legacyPageViewsDataDelegate = dependencies.legacyPageViewsDataDelegate
    }

    func populateSlideData(in context: NSManagedObjectContext) async throws {
        
        guard let startDate = yirConfig.dataPopulationStartDate,
              let endDate = yirConfig.dataPopulationEndDate,
            let pageViews = try await legacyPageViewsDataDelegate?.getLegacyPageViews(from: startDate, to: endDate, needsLatLong: false) else {
            throw NSError(domain: "", code: 0, userInfo: nil)
        }
        
        let dayCounts = pageViews.reduce(into: [Int: Int]()) { dict, view in
            let day = Calendar.current.component(.weekday, from: view.viewedDate)
            dict[day, default: 0] += 1
        }

        if let (day, count) = dayCounts.max(by: { $0.value < $1.value }) {
            mostReadDay = WMFPageViewDay(day: day, viewCount: count)
            isEvaluated = true
        }
    }

    func makeCDSlide(in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = id
        slide.year = Int32(year)
        slide.data = try mostReadDay.map { try JSONEncoder().encode($0) }
        return slide
    }

    static func shouldPopulate(from config: YearInReviewFeatureConfig, userInfo: YearInReviewUserInfo) -> Bool {
        config.isEnabled && config.slideConfig.mostReadDayIsEnabled
    }
}
