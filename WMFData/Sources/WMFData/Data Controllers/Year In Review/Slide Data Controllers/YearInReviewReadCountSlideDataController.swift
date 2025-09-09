import CoreData

final class YearInReviewReadCountSlideDataController: YearInReviewSlideDataControllerProtocol {

    let id = WMFYearInReviewPersonalizedSlideID.readCount.rawValue
    let year: Int
    var isEvaluated: Bool = false
    static var containsPersonalizedNetworkData = false
    
    private var readCount: Int?

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
        
        readCount = pageViews.count
        isEvaluated = true
    }

    func makeCDSlide(in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = id
        slide.year = Int32(year)

        if let readCount {
            let encoder = JSONEncoder()
            slide.data = try encoder.encode(readCount)
        }

        return slide
    }

    static func shouldPopulate(from config: YearInReviewFeatureConfig, userInfo: YearInReviewUserInfo) -> Bool {
        return config.isEnabled && config.slideConfig.readCountIsEnabled
    }
}

