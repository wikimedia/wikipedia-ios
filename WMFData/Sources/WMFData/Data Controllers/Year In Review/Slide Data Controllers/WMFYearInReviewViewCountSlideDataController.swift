import CoreData

final class YearInReviewViewCountSlideDataController: YearInReviewSlideDataControllerProtocol {
    let id = WMFYearInReviewPersonalizedSlideID.viewCount.rawValue
    let year: Int
    var isEvaluated: Bool = false
    static var containsPersonalizedNetworkData = true
    static var shouldFreeze = false
    
    private var viewCount: Int?
    
    private let userID: Int?
    
    private let languageCode: String?
    private let project: WMFProject?
    
    private let dataController = WMFUserImpactDataController.shared
    
    init(year: Int, yirConfig: WMFFeatureConfigResponse.Common.YearInReview, dependencies: YearInReviewSlideDataControllerDependencies) {
        self.year = year
        self.userID = dependencies.userID
        self.languageCode = dependencies.languageCode
        self.project = dependencies.project
    }

    func populateSlideData(in context: NSManagedObjectContext) async throws {
        guard let userID, let languageCode else { return }
        viewCount = try await self.fetchEditViews(project: project, userId: userID, language: languageCode)
        isEvaluated = true
    }

    func makeCDSlide(in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = id
        slide.year = Int32(year)
        slide.data = try viewCount.map { try JSONEncoder().encode($0) }
        return slide
    }

    static func shouldPopulate(from config: WMFFeatureConfigResponse.Common.YearInReview, userInfo: YearInReviewUserInfo) -> Bool {
        return config.isActive(for: Date()) && userInfo.userID != nil
    }
    
    private func fetchEditViews(project: WMFProject?, userId: Int, language: String) async throws -> (Int?) {
        
        guard let project = project else {
            throw WMFDataControllerError.mediaWikiServiceUnavailable
        }
        
        let response = try await dataController.fetch(userID: userId, project: project, language: language)
        return response.totalPageviewsCount
    }
}
