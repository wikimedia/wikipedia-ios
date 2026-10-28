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

        readData = try await Self.fetchReadData(startDate: startDate, endDate: endDate, pageViewsDataController: dataController, mainPageIdentifier: mainPageIdentifier)
        
        isEvaluated = true
    }

    private static let englishMainPageTitle = WMFMainPageTitle.canonicalized("Main Page")

    /// The number of distinct articles read in the date range. Pages outside the main namespace and
    /// main pages do not count. The Year in Review entry point calls this, and it uses the same query
    /// and rules as `fetchReadData`, so the entry point and the total articles slide always agree.
    static func fetchReadCount(startDate: Date, endDate: Date, pageViewsDataController: WMFPageViewsDataController, mainPageIdentifier: WMFMainPageIdentifying?) async throws -> Int {
        try await fetchReadData(startDate: startDate, endDate: endDate, pageViewsDataController: pageViewsDataController, mainPageIdentifier: mainPageIdentifier).readCount
    }

    /// The articles read and the whole minutes spent reading them in the date range. Both count the same
    /// pages, so the total articles slide and the minutes read slide match. The wiki main page lookups
    /// run once for both.
    static func fetchReadData(startDate: Date, endDate: Date, pageViewsDataController: WMFPageViewsDataController, mainPageIdentifier: WMFMainPageIdentifying?) async throws -> WMFYearInReviewReadData {
        let secondsByPage = try await pageViewsDataController.fetchPageViewSeconds(startDate: startDate, endDate: endDate)
        let articles = await articles(from: Set(secondsByPage.keys), mainPageIdentifier: mainPageIdentifier)
        let totalSeconds = articles.reduce(0) { $0 + (secondsByPage[$1] ?? 0) }
        return WMFYearInReviewReadData(readCount: articles.count, minutesRead: totalSeconds / 60)
    }

    /// The pages that count as articles: pages in the main namespace that are not a main page.
    private static func articles(from pages: Set<WMFPage>, mainPageIdentifier: WMFMainPageIdentifying?) async -> Set<WMFPage> {
        let articles = pages.filter { $0.namespaceID == articleNamespaceID }

        // Get the main page title once for each wiki, not once for each article. Each request can go to the main actor.
        var mainPageTitles: [String: String] = [:]
        for projectID in Set(articles.map(\.projectID)) {
            if let project = WMFProject(id: projectID),
               let title = await mainPageIdentifier?.mainPageTitle(for: project) {
                mainPageTitles[projectID] = WMFMainPageTitle.canonicalized(title)
            }
        }

        return articles.filter { page in
            let title = WMFMainPageTitle.canonicalized(page.title)
            // The app does not record the English main page, but older data can contain it.
            return title != englishMainPageTitle && title != mainPageTitles[page.projectID]
        }
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

