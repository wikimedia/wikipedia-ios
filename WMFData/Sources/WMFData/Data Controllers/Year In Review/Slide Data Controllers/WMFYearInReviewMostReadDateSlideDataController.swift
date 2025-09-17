import CoreData

final class YearInReviewMostReadDateSlideDataController: YearInReviewSlideDataControllerProtocol {
    let id = WMFYearInReviewPersonalizedSlideID.mostReadDate.rawValue
    let year: Int
    var isEvaluated: Bool = false
    static var containsPersonalizedNetworkData = false
    
    var mostReadDate: WMFPageViewDates?

    private weak var legacyPageViewsDataDelegate: LegacyPageViewsDataDelegate?
    private let yirConfig: YearInReviewFeatureConfig
    
    init(year: Int, yirConfig: YearInReviewFeatureConfig, dependencies: YearInReviewSlideDataControllerDependencies) {
        self.year = year
        self.yirConfig = yirConfig
        self.legacyPageViewsDataDelegate = dependencies.legacyPageViewsDataDelegate
    }

    func populateSlideData(in context: NSManagedObjectContext) async throws {
        
        guard let startDate = yirConfig.dataPopulationStartDate,
              let endDate = yirConfig.dataPopulationEndDate else {
            throw NSError(domain: "", code: 0, userInfo: nil)
        }
        
        let dates = try await WMFPageViewsDataController().fetchPageViewDates(startDate: startDate, endDate: endDate)
        
        if let mostReadHour = dates?.times.sorted(by: { $0.viewCount < $1.viewCount }).first,
           let mostReadDay = dates?.days.sorted(by: { $0.viewCount < $1.viewCount }).first,
           let mostReadMonth = dates?.months.sorted(by: { $0.viewCount < $1.viewCount }).first {
                self.mostReadDate = WMFPageViewDates(days: [WMFPageViewDay(day: 4, viewCount: 30)], times: [WMFPageViewTime(hour: 13, viewCount: 30)], months: [WMFPageViewMonth(month: 12, viewCount: 38)])
                isEvaluated = true
            }
    }

    func makeCDSlide(in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = id
        slide.year = Int32(year)
        slide.data = try mostReadDate.map { try JSONEncoder().encode($0) }
        return slide
    }

    static func shouldPopulate(from config: YearInReviewFeatureConfig, userInfo: YearInReviewUserInfo) -> Bool {
        config.isEnabled && config.slideConfig.mostReadDateIsEnabled
    }
}
