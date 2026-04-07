import CoreData

final class YearInReviewDonateCountSlideDataController: YearInReviewSlideDataControllerProtocol {
    
    let id = WMFYearInReviewPersonalizedSlideID.donateCount.rawValue
    let year: Int
    var isEvaluated: Bool = false
    static var containsPersonalizedNetworkData = false
    static var shouldFreeze = false
    
    private let globalUserID: Int?
    private let project: WMFProject?
    
    private let service = WMFDataEnvironment.current.mediaWikiService
    
    private var donateCount: Int?
    private var editCount: Int?
    
    private let yirConfig: WMFFeatureConfigResponse.Common.YearInReview
    
    init(year: Int, yirConfig: WMFFeatureConfigResponse.Common.YearInReview, dependencies: YearInReviewSlideDataControllerDependencies) {
        self.year = year
        self.yirConfig = yirConfig
        self.globalUserID = dependencies.globalUserID
        self.project = dependencies.project
    }

    func populateSlideData(in context: NSManagedObjectContext) async throws {
        guard let startDate = yirConfig.dataStartDate,
              let endDate = yirConfig.dataEndDate else {
            return
        }
        donateCount = getDonateCount(startDate: startDate, endDate: endDate)
        
        if let globalUserID,
           let startDate = yirConfig.dataStartDate,
           let endDate = yirConfig.dataEndDate {
            do {
                let dataController = WMFGlobalEditCountDataController(globalUserID: globalUserID)
                editCount = try await dataController.fetchEditCount(startDate: startDate, endDate: endDate)
                isEvaluated = true
            } catch {
                isEvaluated = false
            }
        }
    }
    
    func getDonateCount(startDate: Date, endDate: Date) -> Int? {
        return WMFDonateDataController.shared.loadLocalDonationHistory(startDate: startDate, endDate: endDate)?.count
    }
    
    func makeCDSlide(in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = id
        slide.year = Int32(year)
        
        let payload = DonateAndEditCounts(donateCount: donateCount, editCount: editCount)
        slide.data = try JSONEncoder().encode(payload)
        
        return slide
    }

    static func shouldPopulate(from config: WMFFeatureConfigResponse.Common.YearInReview, userInfo: YearInReviewUserInfo) -> Bool {
        return config.isActive(for: Date())
    }
}
