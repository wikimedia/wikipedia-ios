import Foundation
import CoreData

public struct WMFYearInReviewViewedArticleData: Codable, Sendable {
    public let title: String
    public let viewCount: Int
}

// @unchecked: `isEvaluated` is mutable, but instances are confined to the sequential
// populate flow in WMFYearInReviewDataController (mutated in a loop, then read in a
// single Core Data perform closure) — see YearInReviewSlideDataControllerProtocol.
final class YearInReviewMostViewedEditsSlideDataController: YearInReviewSlideDataControllerProtocol, @unchecked Sendable {

    let id = WMFYearInReviewPersonalizedSlideID.mostViewedEdits.rawValue
    let year: Int
    var isEvaluated: Bool = false
    static let containsPersonalizedNetworkData = true
    static let shouldFreeze = false

    static let articleLimit = 3

    private var articles: [WMFYearInReviewViewedArticleData]?

    private let userID: Int?
    private let languageCode: String?
    private let project: WMFProject?

    private let userImpactDataProvider: any YearInReviewUserImpactDataProviding

    init(year: Int, yirConfig: WMFFeatureConfigResponse.Common.YearInReview, dependencies: YearInReviewSlideDataControllerDependencies) {
        self.year = year
        self.userID = dependencies.userID
        self.languageCode = dependencies.languageCode
        self.project = dependencies.project
        self.userImpactDataProvider = dependencies.userImpactDataProvider ?? WMFUserImpactDataController.shared
    }

    func populateSlideData(in context: NSManagedObjectContext) async throws {
        guard let userID, let languageCode, let project else { return }

        let topViewedArticles = try await userImpactDataProvider.fetchTopViewedArticles(userID: userID, project: project, language: languageCode)

        articles = topViewedArticles
            .sorted { $0.viewsCount > $1.viewsCount }
            .prefix(Self.articleLimit)
            .map { WMFYearInReviewViewedArticleData(title: $0.title.replacingOccurrences(of: "_", with: " "), viewCount: $0.viewsCount) }

        isEvaluated = true
    }

    func makeCDSlide(in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = id
        slide.year = Int32(year)

        if let articles {
            slide.data = try JSONEncoder().encode(articles)
        }

        return slide
    }

    static func shouldPopulate(from config: WMFFeatureConfigResponse.Common.YearInReview, userInfo: YearInReviewUserInfo) -> Bool {
        return config.isActive(for: Date()) && userInfo.userID != nil
    }
}
