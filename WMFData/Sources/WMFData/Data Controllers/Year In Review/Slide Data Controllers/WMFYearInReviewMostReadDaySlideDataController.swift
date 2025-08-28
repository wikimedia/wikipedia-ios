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
              let endDate = yirConfig.dataPopulationEndDate else {
            throw NSError(domain: "", code: 0, userInfo: nil)
        }
        
        mostReadDay = try await WMFPageViewsDataController().fetchPageViewDates(startDate: startDate, endDate: endDate).sorted { $0.viewCount < $1.viewCount }.first
        isEvaluated = true
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
