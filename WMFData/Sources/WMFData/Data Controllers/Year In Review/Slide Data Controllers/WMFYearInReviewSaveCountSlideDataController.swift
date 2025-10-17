import CoreData

final class YearInReviewSaveCountSlideDataController: YearInReviewSlideDataControllerProtocol {

    let id = WMFYearInReviewPersonalizedSlideID.saveCount.rawValue
    let year: Int
    var isEvaluated: Bool = false
    static var containsPersonalizedNetworkData = true
    static var shouldFreeze = true
    
    private var savedData: SavedArticleSlideData?
    
    private weak var savedSlideDataDelegate: SavedArticleSlideDataDelegate?
    private let yirConfig: WMFFeatureConfigResponse.Common.YearInReview
    
    init(year: Int, yirConfig: WMFFeatureConfigResponse.Common.YearInReview, dependencies: YearInReviewSlideDataControllerDependencies) {
        self.year = year
        self.yirConfig = yirConfig
        self.savedSlideDataDelegate = dependencies.savedSlideDataDelegate
    }

    func populateSlideData(in context: NSManagedObjectContext) async throws {
        
        guard let startDate = yirConfig.dataStartDate, let endDate = yirConfig.dataEndDate else {
            return
        }
        
        self.savedData = await savedSlideDataDelegate?.getSavedArticleSlideData(from: startDate, to: endDate)
        
        guard savedData != nil else { return }
        
        isEvaluated = true
    }

    func makeCDSlide(in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = id
        slide.year = Int32(year)

        if let savedData {
            slide.data = try JSONEncoder().encode(savedData)
        }

        return slide
    }

    static func shouldPopulate(from config: WMFFeatureConfigResponse.Common.YearInReview, userInfo: YearInReviewUserInfo) -> Bool {
        return config.isActive(for: Date())
    }
}
