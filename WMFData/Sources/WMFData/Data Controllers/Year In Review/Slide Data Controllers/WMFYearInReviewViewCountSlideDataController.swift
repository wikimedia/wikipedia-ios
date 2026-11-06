import CoreData

/// The "views your edits received" slide: the views on the pages the user edited, across all
/// projects, from the metrics API.
///
/// Older builds stored this slide as a bare `Int` from the Growth user impact API (all time, one
/// wiki). That data does not decode as this type, so `hasCurrentFormat` rejects it and the report
/// never shows it.
public struct WMFYearInReviewViewCountSlideData: Codable, Sendable, Equatable {
    /// The edited articles must have more than this number of views to show the slide.
    public static let minimumViewCount = 25

    public let editedPageViewCount: Int

    public init(editedPageViewCount: Int) {
        self.editedPageViewCount = editedPageViewCount
    }

    public var isEligible: Bool {
        editedPageViewCount > Self.minimumViewCount
    }
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

    private var slideData: WMFYearInReviewViewCountSlideData?

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

        let metricsDataController = WMFGlobalEditorMetricsDataController(globalUserID: globalUserID)
        let viewCount = try await metricsDataController.fetchEditedPageViewCount(startDate: dateRange.start, endDate: dateRange.end)
        slideData = WMFYearInReviewViewCountSlideData(editedPageViewCount: viewCount)
        isEvaluated = true
    }

    func makeCDSlide(in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = id
        slide.year = Int32(year)
        slide.data = try slideData.map { try JSONEncoder().encode($0) }
        return slide
    }

    static func shouldPopulate(from config: WMFFeatureConfigResponse.Common.YearInReview, userInfo: YearInReviewUserInfo) -> Bool {
        return config.isActive(for: Date()) && userInfo.globalUserID != nil
    }

    /// An older build stored a bare `Int` from the Growth API. It does not decode, so the report
    /// deletes it and builds the slide again, also when this run cannot fetch the new count.
    static func hasCurrentFormat(_ data: Data?) -> Bool {
        guard let data else {
            return false
        }
        return (try? JSONDecoder().decode(WMFYearInReviewViewCountSlideData.self, from: data)) != nil
    }
}
