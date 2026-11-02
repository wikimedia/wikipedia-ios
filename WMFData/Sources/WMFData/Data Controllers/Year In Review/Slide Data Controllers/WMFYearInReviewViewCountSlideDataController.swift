import CoreData

/// Eligibility for the "views your edits received" slide.
public enum WMFYearInReviewViewCountSlideRules {
    /// The edited articles must have more than this number of views to show the slide.
    public static let minimumViewCount = 25
}

// @unchecked: `isEvaluated` is mutable, but instances are confined to the sequential
// populate flow in WMFYearInReviewDataController (mutated in a loop, then read in a
// single Core Data perform closure) — see YearInReviewSlideDataControllerProtocol.
final class YearInReviewViewCountSlideDataController: YearInReviewSlideDataControllerProtocol, @unchecked Sendable {
    let id = WMFYearInReviewPersonalizedSlideID.viewCount.rawValue
    let year: Int
    var isEvaluated: Bool = false
    static let personalizationSources: Set<WMFYearInReviewPersonalizationSource> = [.account]
    static let shouldFreeze = false

    private var viewCount: Int?

    private let globalUserID: Int?

    private let yirConfig: WMFFeatureConfigResponse.Common.YearInReview

    init(year: Int, yirConfig: WMFFeatureConfigResponse.Common.YearInReview, dependencies: YearInReviewSlideDataControllerDependencies) {
        self.year = year
        self.yirConfig = yirConfig
        self.globalUserID = dependencies.globalUserID
    }

    /// The views on the pages the user edited, across all projects, in the same period as the edit count.
    func populateSlideData(in context: NSManagedObjectContext) async throws {
        guard let globalUserID else { return }

        guard let dateRange = WMFYearInReviewDataController.editCountDateRange(config: yirConfig) else {
            return
        }

        let pageViewsDataController = WMFGlobalEditedPageViewsDataController(globalUserID: globalUserID)
        viewCount = try await pageViewsDataController.fetchViewCount(startDate: dateRange.start, endDate: dateRange.end)
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
        return config.isActive(for: Date()) && userInfo.globalUserID != nil
    }
}
