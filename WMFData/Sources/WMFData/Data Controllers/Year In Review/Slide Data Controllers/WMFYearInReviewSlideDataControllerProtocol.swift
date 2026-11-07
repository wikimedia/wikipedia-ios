import Foundation
import CoreData

public enum WMFYearInReviewPersonalizationSource: Sendable {
    case readingHistory
    case account
    case donations
}

protocol YearInReviewSlideDataControllerProtocol: Sendable {
    var id: String { get }
    var year: Int { get }
    var isEvaluated: Bool { get set }
    static var personalizationSources: Set<WMFYearInReviewPersonalizationSource> { get }
    static var shouldFreeze: Bool { get }
    
    func populateSlideData(in context: NSManagedObjectContext) async throws

    func makeCDSlide(in context: NSManagedObjectContext) throws -> CDYearInReviewSlide

    static func shouldPopulate(from config: WMFFeatureConfigResponse.Common.YearInReview, userInfo: YearInReviewUserInfo) -> Bool

    /// True if the stored data of this slide uses the current format.
    /// If false, the report builds the slide again, also when the slide is frozen.
    static func hasCurrentFormat(_ data: Data?) -> Bool
    
    init(year: Int, yirConfig: WMFFeatureConfigResponse.Common.YearInReview, dependencies: YearInReviewSlideDataControllerDependencies)
}

extension YearInReviewSlideDataControllerProtocol {
    /// Most slides did not change their format. Thus, the stored data is always current.
    static func hasCurrentFormat(_ data: Data?) -> Bool {
        true
    }
}

struct YearInReviewSlideDataControllerDependencies {
    let legacyPageViewsDataDelegate: LegacyPageViewsDataDelegate?
    let savedSlideDataDelegate: SavedArticleSlideDataDelegate?
    let username: String?
    let project: WMFProject?
    let userID: Int?
    let globalUserID: Int?
    let languageCode: String?
    let userImpactDataProvider: (any YearInReviewUserImpactDataProviding)?
    var mainPageIdentifier: (any WMFMainPageIdentifying)? = nil
}

protocol YearInReviewUserImpactDataProviding: Sendable {
    func fetchTotalPageViewsCount(userID: Int, project: WMFProject, language: String) async throws -> Int?
}

extension WMFUserImpactDataController: YearInReviewUserImpactDataProviding {
    func fetchTotalPageViewsCount(userID: Int, project: WMFProject, language: String) async throws -> Int? {
        try await fetch(userID: userID, project: project, language: language).totalPageviewsCount
    }
}
