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
    /// `populateSlideData(in:)` must set this to `true` when it succeeds. The populate flow stores
    /// only evaluated slides, so a controller that never sets it is never stored, and one that
    /// returns early without data, for example without a user id, must leave it `false`.
    var isEvaluated: Bool { get set }
    static var personalizationSources: Set<WMFYearInReviewPersonalizationSource> { get }
    static var shouldFreeze: Bool { get }
    /// True if the slide leaves main pages out of the reading history, with
    /// `YearInReviewSlideDataControllerDependencies.mainPageTitles`. The factory looks up the main
    /// pages only when a slide to build sets this.
    static var excludesMainPages: Bool { get }
    
    func populateSlideData(in context: NSManagedObjectContext) async throws

    func makeCDSlide(in context: NSManagedObjectContext) throws -> CDYearInReviewSlide

    static func shouldPopulate(from config: WMFFeatureConfigResponse.Common.YearInReview, userInfo: YearInReviewUserInfo) -> Bool

    /// True if the stored data of this slide uses the current format.
    /// If false, the report builds the slide again, also when the slide is frozen.
    static func hasCurrentFormat(_ data: Data?) -> Bool

    /// True if a stored slide in an older format stays in the report when building it again fails.
    /// If false, the report deletes that slide. Return true only if the slide's data type hides the
    /// parts that the older format got wrong.
    static var keepsOutdatedDataOnFailedRebuild: Bool { get }
    
    init(year: Int, yirConfig: WMFFeatureConfigResponse.Common.YearInReview, dependencies: YearInReviewSlideDataControllerDependencies)
}

extension YearInReviewSlideDataControllerProtocol {
    /// Most slides did not change their format. Thus, the stored data is always current.
    static func hasCurrentFormat(_ data: Data?) -> Bool {
        true
    }

    static var keepsOutdatedDataOnFailedRebuild: Bool {
        false
    }

    static var excludesMainPages: Bool {
        false
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
    /// The main pages to leave out of the reading history. The factory looks them up once for each report build.
    /// `nil` when the lookup failed. Then the slides that need it throw, so they are built again next time.
    var mainPageTitles: YearInReviewMainPageTitles? = .englishOnly
}

protocol YearInReviewUserImpactDataProviding: Sendable {
    func fetchMostViewedArticles(userID: Int, project: WMFProject, language: String) async throws -> [WMFYearInReviewMostViewedArticlesSlideData.Article]
}

extension WMFUserImpactDataController: YearInReviewUserImpactDataProviding {
    func fetchMostViewedArticles(userID: Int, project: WMFProject, language: String) async throws -> [WMFYearInReviewMostViewedArticlesSlideData.Article] {
        try await fetch(userID: userID, project: project, language: language).topViewedArticles.map {
            WMFYearInReviewMostViewedArticlesSlideData.Article(
                title: $0.title.replacingOccurrences(of: "_", with: " "),
                projectID: project.id,
                viewsCount: $0.viewsCount
            )
        }
    }
}
