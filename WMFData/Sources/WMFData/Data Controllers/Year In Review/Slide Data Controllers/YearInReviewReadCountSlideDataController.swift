import CoreData

// @unchecked: `isEvaluated` is mutable, but instances are confined to the sequential
// populate flow in WMFYearInReviewDataController (mutated in a loop, then read in a
// single Core Data perform closure) — see YearInReviewSlideDataControllerProtocol.
final class YearInReviewReadCountSlideDataController: YearInReviewSlideDataControllerProtocol, @unchecked Sendable {

    let id = WMFYearInReviewPersonalizedSlideID.readCount.rawValue
    let year: Int
    var isEvaluated: Bool = false
    static let personalizationSources: Set<WMFYearInReviewPersonalizationSource> = [.readingHistory]
    static let shouldFreeze = true

    private static let articleNamespaceID = 0

    private var readData: WMFYearInReviewReadData?

    private weak var legacyPageViewsDataDelegate: LegacyPageViewsDataDelegate?
    private weak var mainPageIdentifier: WMFMainPageIdentifying?
    private let yirConfig: WMFFeatureConfigResponse.Common.YearInReview
    
    init(year: Int, yirConfig: WMFFeatureConfigResponse.Common.YearInReview, dependencies: YearInReviewSlideDataControllerDependencies) {
        self.year = year
        self.yirConfig = yirConfig
        self.legacyPageViewsDataDelegate = dependencies.legacyPageViewsDataDelegate
        self.mainPageIdentifier = dependencies.mainPageIdentifier
    }

    func populateSlideData(in context: NSManagedObjectContext) async throws {
        
        guard let startDate = yirConfig.dataStartDate,
              let endDate = yirConfig.dataEndDate else {
            throw NSError(domain: "", code: 0, userInfo: nil)
        }
        
        let dataController = try WMFPageViewsDataController()
        
        let pageViewCounts = try await dataController.fetchPageViewCounts(startDate: startDate, endDate: endDate)
        let articles = pageViewCounts.filter { $0.page.namespaceID == Self.articleNamespaceID }

        // Get the main page title once for each wiki, not once for each article. Each request can go to the main actor.
        var mainPageTitles: [String: String] = [:]
        for projectID in Set(articles.map(\.page.projectID)) {
            if let title = await mainPageTitle(projectID: projectID) {
                mainPageTitles[projectID] = WMFMainPageTitle.canonicalized(title)
            }
        }

        let readCount = articles.count(where: { item in
            let title = WMFMainPageTitle.canonicalized(item.page.title)
            // The app does not record the English main page, but older data can contain it.
            return title != Self.englishMainPageTitle && title != mainPageTitles[item.page.projectID]
        })
        let minutesRead = try await dataController.fetchPageViewMinutes(startDate: startDate, endDate: endDate)
        
        readData = WMFYearInReviewReadData(readCount: readCount, minutesRead: minutesRead)
        
        isEvaluated = true
    }

    private static let englishMainPageTitle = WMFMainPageTitle.canonicalized("Main Page")

    private func mainPageTitle(projectID: String) async -> String? {
        guard let project = WMFProject(id: projectID),
              let mainPageIdentifier else {
            return nil
        }
        return await mainPageIdentifier.mainPageTitle(for: project)
    }

    func makeCDSlide(in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = id
        slide.year = Int32(year)

        if let readData {
            let encoder = JSONEncoder()
            slide.data = try encoder.encode(readData)
        }

        return slide
    }

    static func shouldPopulate(from config: WMFFeatureConfigResponse.Common.YearInReview, userInfo: YearInReviewUserInfo) -> Bool {
        return config.isActive(for: Date())
    }
}

