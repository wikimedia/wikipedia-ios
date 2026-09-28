import Foundation
import CoreData

// @unchecked: `isEvaluated` is mutable, but instances are confined to the sequential
// populate flow in WMFYearInReviewDataController (mutated in a loop, then read in a
// single Core Data perform closure) — see YearInReviewSlideDataControllerProtocol.
final class YearInReviewArticleSampleSlideDataController: YearInReviewSlideDataControllerProtocol, @unchecked Sendable {

    let id = WMFYearInReviewPersonalizedSlideID.articleSample.rawValue
    let year: Int
    var isEvaluated: Bool = false
    static let containsPersonalizedNetworkData = false
    /// The sample is random, so it is kept once saved instead of changing every night.
    static let shouldFreeze = true

    static let articleLimit = 3

    private var articleTitles: [String]?

    private let yirConfig: WMFFeatureConfigResponse.Common.YearInReview

    init(year: Int, yirConfig: WMFFeatureConfigResponse.Common.YearInReview, dependencies: YearInReviewSlideDataControllerDependencies) {
        self.year = year
        self.yirConfig = yirConfig
    }

    func populateSlideData(in context: NSManagedObjectContext) async throws {

        guard let startDate = yirConfig.dataStartDate,
              let endDate = yirConfig.dataEndDate else {
            throw NSError(domain: "", code: 0, userInfo: nil)
        }

        let pageViewCounts = try await WMFPageViewsDataController().fetchPageViewCounts(startDate: startDate, endDate: endDate)

        articleTitles = pageViewCounts
            .shuffled()
            .prefix(Self.articleLimit)
            .map { $0.page.title.replacingOccurrences(of: "_", with: " ") }

        isEvaluated = true
    }

    func makeCDSlide(in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = id
        slide.year = Int32(year)

        if let articleTitles {
            slide.data = try JSONEncoder().encode(articleTitles)
        }

        return slide
    }

    static func shouldPopulate(from config: WMFFeatureConfigResponse.Common.YearInReview, userInfo: YearInReviewUserInfo) -> Bool {
        return config.isActive(for: Date())
    }
}
