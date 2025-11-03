import Foundation
import CoreData

protocol YearInReviewSlideDataControllerProtocol {
    /// A unique identifier for the slide (e.g., readCount, editCount).
    var id: String { get }

    /// The year this slide belongs to.
    var year: Int { get }

    /// Whether this slide has been evaluated.
    var isEvaluated: Bool { get set }
    
    /// Whether this data controller contains personalized network data (e.g. edit count, synced saved article count). If so, this data is cleared out upon logout in WMFYearInReviewDataController and will be fetched again the next time they log in.
    static var containsPersonalizedNetworkData: Bool { get }
    
    /// If true, populateYearInReviewReportData will always fetch and update this slide's data each time it is called. If false, populateYearInReviewReportData will skip this slide's data if it already exists in the report, essentially freezing it until the report is deleted.
    static var shouldFreeze: Bool { get }

    /// Populate the slide’s data in the background context, using dependencies like saved data, page views, or edit stats.
    func populateSlideData(in context: NSManagedObjectContext) async throws

    /// Returns an instance of `CDYearInReviewSlide` (used for Core Data storage).
    func makeCDSlide(in context: NSManagedObjectContext) throws -> CDYearInReviewSlide

    /// Used to determine if the slide should be populated based on feature flags, user info, etc.
    static func shouldPopulate(from config: WMFFeatureConfigResponse.Common.YearInReview, userInfo: YearInReviewUserInfo) -> Bool
    
    init(year: Int, yirConfig: WMFFeatureConfigResponse.Common.YearInReview, dependencies: YearInReviewSlideDataControllerDependencies)
}

struct YearInReviewSlideDataControllerDependencies {
    let legacyPageViewsDataDelegate: LegacyPageViewsDataDelegate?
    let savedSlideDataDelegate: SavedArticleSlideDataDelegate?
    let username: String?
    let project: WMFProject?
    let userID: Int?
    let globalUserID: Int?
    let languageCode: String?
}
