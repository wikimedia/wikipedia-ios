import Foundation
import CoreData

public struct WMFYearInReviewTopicData: Codable, Sendable {
    /// The language-independent topic name, such as "Biography.Women".
    public let topic: String
    public let articleCount: Int
    /// Articles read in this topic, most recent first. Only filled for the top topic.
    public let articleTitles: [String]
}

// @unchecked: `isEvaluated` is mutable, but instances are confined to the sequential
// populate flow in WMFYearInReviewDataController (mutated in a loop, then read in a
// single Core Data perform closure) — see YearInReviewSlideDataControllerProtocol.
final class YearInReviewTopTopicsSlideDataController: YearInReviewSlideDataControllerProtocol, @unchecked Sendable {

    let id = WMFYearInReviewPersonalizedSlideID.topTopics.rawValue
    let year: Int
    var isEvaluated: Bool = false
    static let containsPersonalizedNetworkData = false
    static let shouldFreeze = true

    /// The top topic plus the three runners-up.
    static let topicLimit = 4

    /// The top topic slide names two articles: "From A to B".
    static let topTopicArticleLimit = 2

    private var topics: [WMFYearInReviewTopicData]?

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

        let dataController = try WMFPageTopicsDataController()
        let summaries = try await dataController.fetchTopTopicsByArticleCount(startDate: startDate, endDate: endDate, limit: Self.topicLimit)

        var topics: [WMFYearInReviewTopicData] = []
        for (index, summary) in summaries.enumerated() {
            var articleTitles: [String] = []
            if index == 0 {
                let pages = try await dataController.fetchPages(forTopic: summary.topic, startDate: startDate, endDate: endDate, limit: Self.topTopicArticleLimit)
                articleTitles = pages.map { $0.page.title.replacingOccurrences(of: "_", with: " ") }
            }

            topics.append(WMFYearInReviewTopicData(topic: summary.topic, articleCount: summary.articleCount, articleTitles: articleTitles))
        }

        self.topics = topics
        isEvaluated = true
    }

    func makeCDSlide(in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = id
        slide.year = Int32(year)

        if let topics {
            slide.data = try JSONEncoder().encode(topics)
        }

        return slide
    }

    static func shouldPopulate(from config: WMFFeatureConfigResponse.Common.YearInReview, userInfo: YearInReviewUserInfo) -> Bool {
        return config.isActive(for: Date())
    }
}
