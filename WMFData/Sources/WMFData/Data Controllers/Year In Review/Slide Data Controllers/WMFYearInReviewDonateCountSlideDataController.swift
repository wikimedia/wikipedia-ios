import CoreData

// @unchecked: `isEvaluated` is mutable, but instances are confined to the sequential
// populate flow in WMFYearInReviewDataController (mutated in a loop, then read in a
// single Core Data perform closure) — see YearInReviewSlideDataControllerProtocol.
final class YearInReviewDonateCountSlideDataController: YearInReviewSlideDataControllerProtocol, @unchecked Sendable {
    
    let id = WMFYearInReviewPersonalizedSlideID.donateCount.rawValue
    let year: Int
    var isEvaluated: Bool = false
    static let personalizationSources: Set<WMFYearInReviewPersonalizationSource> = [.account, .donations]
    static let shouldFreeze = false
    
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
        guard let dateRange = WMFYearInReviewDataController.contributorDateRange(year: year) else {
            return
        }
        donateCount = getDonateCount(startDate: dateRange.start, endDate: dateRange.end)
        
        if let globalUserID {
            do {
                let dataController = WMFGlobalEditCountDataController(globalUserID: globalUserID)
                editCount = try await dataController.fetchEditCount(startDate: dateRange.start, endDate: dateRange.end)
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
