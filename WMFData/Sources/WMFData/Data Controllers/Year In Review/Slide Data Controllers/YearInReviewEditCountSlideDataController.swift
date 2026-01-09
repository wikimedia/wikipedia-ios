import CoreData

final class YearInReviewEditCountSlideDataController: YearInReviewSlideDataControllerProtocol {

    let id = WMFYearInReviewPersonalizedSlideID.editCount.rawValue
    let year: Int
    var isEvaluated: Bool = false
    static var containsPersonalizedNetworkData = true
    static var shouldFreeze = false
    
    private var editCount: Int?

    private let globalUserID: Int?
    
    private let project: WMFProject?
    
    private let yirConfig: WMFFeatureConfigResponse.Common.YearInReview
    private let service = WMFDataEnvironment.current.basicService
    
    init(year: Int, yirConfig: WMFFeatureConfigResponse.Common.YearInReview, dependencies: YearInReviewSlideDataControllerDependencies) {
        self.year = year
        self.yirConfig = yirConfig
        self.globalUserID = dependencies.globalUserID
        self.project = dependencies.project
    }

    func populateSlideData(in context: NSManagedObjectContext) async throws {
        guard let globalUserID else { return }
        
        guard let startDate = yirConfig.dataStartDate,
        let endDate = yirConfig.dataEndDate else {
            return
        }
        
        let editCountDataController = WMFGlobalEditCountDataController(globalUserID: globalUserID)
        self.editCount = try await editCountDataController.fetchEditCount(startDate: startDate, endDate: endDate)

        isEvaluated = true
    }

    func makeCDSlide(in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = id
        slide.year = Int32(year)

        if let editCount {
            slide.data = try JSONEncoder().encode(editCount)
        }

        return slide
    }

    static func shouldPopulate(from config: WMFFeatureConfigResponse.Common.YearInReview, userInfo: YearInReviewUserInfo) -> Bool {
        return config.isActive(for: Date()) && userInfo.username != nil
    }
}
