import XCTest
import CoreData
import WMFDataTestSupport
@testable import WMFData
@testable import WMFDataMocks

/// Baseline coverage for `populateSlideData` on every Year in Review slide data controller.
///
/// The sibling suite `YearInReviewSlideDataControllersTests` pins the per-slide constants.
/// This one pins the computed payloads, which had no coverage at all — the reason the
/// most-read-date slide shipped the user's least-read hour, day and month.
final class YearInReviewSlidePopulateTests: XCTestCase {

    private let year = 2026
    private let enProject = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))
    private let fixture = WMFDataTestFixture()
    private var store: WMFCoreDataStore?

    override func setUp() async throws {
        try await super.setUp()
        await fixture.setUp()
        let store = try await fixture.makeTemporaryCoreDataStore()
        self.store = store
        WMFDataEnvironment.current.coreDataStore = store
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.sharedCacheStore = WMFMockKeyValueStore()
        await fixture.resetWMFDataTestState()
    }

    override func tearDown() async throws {
        store = nil
        await fixture.tearDown()
        try await super.tearDown()
    }

    // MARK: - Helpers

    private var config: WMFFeatureConfigResponse.Common.YearInReview { .testConfig }

    private func makeDependencies(
        username: String? = nil,
        userID: Int? = nil,
        globalUserID: Int? = nil,
        savedSlideDataDelegate: SavedArticleSlideDataDelegate? = nil,
        legacyPageViewsDataDelegate: LegacyPageViewsDataDelegate? = nil,
        userImpactDataProvider: (any YearInReviewUserImpactDataProviding)? = nil
    ) -> YearInReviewSlideDataControllerDependencies {
        YearInReviewSlideDataControllerDependencies(
            legacyPageViewsDataDelegate: legacyPageViewsDataDelegate,
            savedSlideDataDelegate: savedSlideDataDelegate,
            username: username,
            project: enProject,
            userID: userID,
            globalUserID: globalUserID,
            languageCode: "en",
            userImpactDataProvider: userImpactDataProvider
        )
    }

    /// A date inside `testConfig`'s data window (2026-01-01 to 2026-12-01).
    private func date(month: Int, day: Int, hour: Int) throws -> Date {
        var components = DateComponents()
        components.year = 2026
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = 30
        let date = Calendar.current.date(from: components)
        return try XCTUnwrap(date)
    }

    private func context() throws -> NSManagedObjectContext {
        try XCTUnwrap(store).newBackgroundContext
    }

    /// Runs the populate step and returns the payload the slide would persist.
    /// The payload is asserted rather than the controller's private properties, so these
    /// tests cover the encode path the app actually reads back.
    private func populatedPayload(_ controller: any YearInReviewSlideDataControllerProtocol) async throws -> Data? {
        let context = try context()
        try await controller.populateSlideData(in: context)
        return try await context.perform {
            try controller.makeCDSlide(in: context).data
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data?) throws -> T {
        try JSONDecoder().decode(type, from: try XCTUnwrap(data))
    }

    private func seedPageViews(_ views: [WMFLegacyPageView]) async throws {
        try await WMFPageViewsDataController().importPageViews(requests: views)
    }

    private func pageView(_ title: String, at date: Date, latitude: Double? = nil, longitude: Double? = nil) -> WMFLegacyPageView {
        WMFLegacyPageView(title: title, project: enProject, viewedDate: date, latitude: latitude, longitude: longitude)
    }

    // MARK: - mostReadDate (regression)

    /// The slide must report the hour, day and month with the MOST views.
    /// Before the fix it sorted ascending and took `.first`, reporting the least-read values.
    func testMostReadDateReportsTheBusiestHourDayAndMonth() async throws {
        let busy = try date(month: 6, day: 10, hour: 14)
        let quiet = try date(month: 2, day: 3, hour: 4)

        var views: [WMFLegacyPageView] = []
        for index in 0..<5 {
            views.append(pageView("Busy_\(index)", at: busy))
        }
        views.append(pageView("Quiet_0", at: quiet))
        try await seedPageViews(views)

        let controller = YearInReviewMostReadDateSlideDataController(year: year, yirConfig: config, dependencies: makeDependencies())
        let payload = try decode(WMFPageViewDates.self, from: try await populatedPayload(controller))
        let busyComponents = Calendar.current.dateComponents([.month, .day, .hour], from: busy)
        let quietComponents = Calendar.current.dateComponents([.month, .day, .hour], from: quiet)

        XCTAssertEqual(payload.times.first?.hour, busyComponents.hour)
        XCTAssertEqual(payload.months.first?.month, busyComponents.month)
        XCTAssertNotEqual(payload.times.first?.hour, quietComponents.hour, "the least-read hour must not be reported")
        XCTAssertNotEqual(payload.months.first?.month, quietComponents.month, "the least-read month must not be reported")
        XCTAssertTrue(controller.isEvaluated)
    }

    /// The slide is frozen, so an empty result is stored and not fetched again on each build.
    func testMostReadDateIsEvaluatedWithoutPageViews() async throws {
        let controller = YearInReviewMostReadDateSlideDataController(year: year, yirConfig: config, dependencies: makeDependencies())

        let payload = try await populatedPayload(controller)

        XCTAssertNil(controller.mostReadDate, "no dates were recorded")
        XCTAssertNil(payload)
        XCTAssertTrue(controller.isEvaluated)
    }

    // MARK: - readCount

    func testReadCountCountsDistinctArticles() async throws {
        let when = try date(month: 3, day: 4, hour: 9)
        try await seedPageViews([
            pageView("Alpha", at: when),
            pageView("Beta", at: when),
            pageView("Alpha", at: try date(month: 3, day: 5, hour: 9))
        ])

        let controller = YearInReviewReadCountSlideDataController(year: year, yirConfig: config, dependencies: makeDependencies())
        let payload = try decode(WMFYearInReviewReadData.self, from: try await populatedPayload(controller))

        XCTAssertEqual(payload.readCount, 2, "two distinct articles were read")
        XCTAssertEqual(payload.minutesRead, 0, "no reading seconds were recorded")
        XCTAssertTrue(controller.isEvaluated)
    }

    /// A moment at the given UTC date. The data range of `testConfig` is in UTC.
    private func utcDate(_ string: String) throws -> Date {
        try XCTUnwrap(DateFormatter.mediaWikiAPIDateFormatter.date(from: string))
    }

    func testReadCountIgnoresViewsOutsideTheInsightsRange() async throws {
        try await seedPageViews([
            pageView("December 2025", at: try utcDate("2025-12-15T12:00:00Z")),
            pageView("January 2026", at: try utcDate("2026-01-01T00:00:00Z")),
            pageView("November 2026", at: try utcDate("2026-11-30T23:59:59Z")),
            pageView("December 2026", at: try utcDate("2026-12-01T12:00:00Z"))
        ])

        let controller = YearInReviewReadCountSlideDataController(year: year, yirConfig: config, dependencies: makeDependencies())
        let payload = try decode(WMFYearInReviewReadData.self, from: try await populatedPayload(controller))

        XCTAssertEqual(payload.readCount, 2, "only the January 1 and November 30 views are inside January 1 to November 30")
    }

    private func readCountPayload(mainPageIdentifier: WMFMainPageIdentifying? = nil) async throws -> WMFYearInReviewReadData {
        var dependencies = makeDependencies()
        dependencies.mainPageIdentifier = mainPageIdentifier
        let controller = YearInReviewReadCountSlideDataController(year: year, yirConfig: config, dependencies: dependencies)
        return try decode(WMFYearInReviewReadData.self, from: try await populatedPayload(controller))
    }

    func testReadCountExcludesPagesOutsideTheMainNamespace() async throws {
        let when = try date(month: 5, day: 1, hour: 10)
        try await seedPageViews([pageView("Kept", at: when)])
        let pageViewsDataController = try WMFPageViewsDataController()
        _ = try await pageViewsDataController.addPageView(title: "Talk_Page", namespaceID: 1, project: enProject, previousPageViewObjectID: nil, timestamp: when)
        _ = try await pageViewsDataController.addPageView(title: "Some_Template", namespaceID: 10, project: enProject, previousPageViewObjectID: nil, timestamp: when)

        let payload = try await readCountPayload()

        XCTAssertEqual(payload.readCount, 1)
    }

    func testReadCountExcludesMainPages() async throws {
        let itProject = WMFProject.wikipedia(WMFLanguage(languageCode: "it", languageVariantCode: nil))
        let when = try date(month: 3, day: 4, hour: 9)
        try await seedPageViews([
            pageView("Main_Page", at: when),
            WMFLegacyPageView(title: "Pagina_principale", project: itProject, viewedDate: when, latitude: nil, longitude: nil),
            // The same title on another wiki is an ordinary article.
            pageView("Pagina_principale", at: when),
            pageView("Kept", at: when)
        ])

        let identifier = StubMainPageIdentifier(mainPages: [(title: "Pagina principale", projectID: itProject.id)])
        let payload = try await readCountPayload(mainPageIdentifier: identifier)

        XCTAssertEqual(payload.readCount, 2, "the English and Italian main pages are left out")
    }

    func testReadCountAsksForTheMainPageOnceForEachWiki() async throws {
        let itProject = WMFProject.wikipedia(WMFLanguage(languageCode: "it", languageVariantCode: nil))
        let when = try date(month: 3, day: 4, hour: 9)
        var views = (1...20).map { pageView("Article_\($0)", at: when) }
        views += (1...5).map { WMFLegacyPageView(title: "Articolo_\($0)", project: itProject, viewedDate: when, latitude: nil, longitude: nil) }
        views.append(WMFLegacyPageView(title: "PAGINA_PRINCIPALE", project: itProject, viewedDate: when, latitude: nil, longitude: nil))
        try await seedPageViews(views)

        // The app returns the title in upper case, so the case of the stored title must not matter.
        let identifier = StubMainPageIdentifier(mainPages: [(title: "Pagina principale", projectID: itProject.id)])
        let payload = try await readCountPayload(mainPageIdentifier: identifier)

        XCTAssertEqual(payload.readCount, 25)
        XCTAssertEqual(identifier.requestedProjectIDs.sorted(), [enProject.id, itProject.id].sorted(), "one request for each wiki, not one for each article")
    }

    func testMinutesReadCountsOnlyArticlesThatAreNotMainPages() async throws {
        let itProject = WMFProject.wikipedia(WMFLanguage(languageCode: "it", languageVariantCode: nil))
        let when = try date(month: 3, day: 4, hour: 9)
        let pageViewsDataController = try WMFPageViewsDataController()

        func addView(_ title: String, namespaceID: Int16 = 0, project: WMFProject, seconds: Double) async throws {
            let addedObjectID = try await pageViewsDataController.addPageView(title: title, namespaceID: namespaceID, project: project, previousPageViewObjectID: nil, timestamp: when)
            let objectID = try XCTUnwrap(addedObjectID)
            try await pageViewsDataController.addPageViewSeconds(pageViewManagedObjectID: objectID, numberOfSeconds: seconds)
        }

        try await addView("Kept", project: enProject, seconds: 90)
        // A second view of the same article adds to it.
        try await addView("Kept", project: enProject, seconds: 90)
        try await addView("Talk_Page", namespaceID: 1, project: enProject, seconds: 600)
        try await addView("Main_Page", project: enProject, seconds: 600)
        try await addView("Pagina_principale", project: itProject, seconds: 600)

        let identifier = StubMainPageIdentifier(mainPages: [(title: "Pagina principale", projectID: itProject.id)])
        let payload = try await readCountPayload(mainPageIdentifier: identifier)

        XCTAssertEqual(payload.readCount, 1)
        XCTAssertEqual(payload.minutesRead, 3, "180 seconds on the article, and nothing from the talk page or the main pages")
    }

    func testMinutesReadCapsEachPageViewBeforeTheTimerFix() async throws {
        let pageViewsDataController = try WMFPageViewsDataController()

        func addView(_ title: String, at timestamp: Date, seconds: Double) async throws {
            let addedObjectID = try await pageViewsDataController.addPageView(title: title, namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: timestamp)
            let objectID = try XCTUnwrap(addedObjectID)
            try await pageViewsDataController.addPageViewSeconds(pageViewManagedObjectID: objectID, numberOfSeconds: seconds)
        }

        // Before the release of the timer fix on August 11: each view adds at most 30 minutes.
        try await addView("Before", at: try date(month: 3, day: 4, hour: 9), seconds: 45 * 60)
        try await addView("Before", at: try date(month: 3, day: 5, hour: 9), seconds: 10 * 60)
        // After the release, also before the cleanup cutoff of August 31: no limit, so a real long read stays.
        try await addView("AfterRelease", at: try date(month: 8, day: 20, hour: 9), seconds: 50 * 60)
        try await addView("After", at: try date(month: 10, day: 4, hour: 9), seconds: 2 * 60 * 60)

        let payload = try await readCountPayload()

        XCTAssertEqual(payload.minutesRead, 30 + 10 + 50 + 120)
    }

    func testMinutesReadLeavesOutArticlesWithMoreThanAnHourFromJanuaryThroughAugust() async throws {
        let pageViewsDataController = try WMFPageViewsDataController()

        func addView(_ title: String, at timestamp: Date, seconds: Double) async throws {
            let addedObjectID = try await pageViewsDataController.addPageView(title: title, namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: timestamp)
            let objectID = try XCTUnwrap(addedObjectID)
            try await pageViewsDataController.addPageViewSeconds(pageViewManagedObjectID: objectID, numberOfSeconds: seconds)
        }

        // 61 stored minutes over two views in the period: none of them count, also though the cap would allow 40.
        try await addView("Spread", at: try date(month: 2, day: 1, hour: 9), seconds: 21 * 60)
        try await addView("Spread", at: try date(month: 6, day: 1, hour: 9), seconds: 40 * 60)
        // One view of 70 minutes after the timer fix, still in the period: it does not count.
        try await addView("LateAugust", at: try date(month: 8, day: 31, hour: 9), seconds: 70 * 60)
        // A view after the period still counts for an article that the rule left out.
        try await addView("LateAugust", at: try date(month: 9, day: 2, hour: 9), seconds: 5 * 60)
        // Exactly 60 minutes is not more than 60 minutes, so it counts, with the cap.
        try await addView("Hour", at: try date(month: 4, day: 1, hour: 9), seconds: 60 * 60)
        // More than an hour after the period is a real read.
        try await addView("After", at: try date(month: 10, day: 4, hour: 9), seconds: 2 * 60 * 60)

        let payload = try await readCountPayload()

        XCTAssertEqual(payload.readCount, 4, "left out articles still count as read")
        XCTAssertEqual(payload.minutesRead, 0 + 5 + 30 + 120)
    }

    func testReadDataFromBeforeTheMinutesReadSlideIsNotTheCurrentFormat() throws {
        let oldData = try JSONSerialization.data(withJSONObject: ["readCount": 10, "minutesRead": 500])
        XCTAssertFalse(YearInReviewReadCountSlideDataController.hasCurrentFormat(oldData), "old reports counted all page views, so they build the slide again")
        XCTAssertFalse(YearInReviewReadCountSlideDataController.hasCurrentFormat(nil))

        let currentData = try JSONEncoder().encode(WMFYearInReviewReadData(readCount: 10, minutesRead: 500))
        XCTAssertTrue(YearInReviewReadCountSlideDataController.hasCurrentFormat(currentData))
    }

    func testReadCountIsEligibleFromThreeArticles() async throws {
        let when = try date(month: 3, day: 4, hour: 9)
        try await seedPageViews([pageView("Alpha", at: when), pageView("Beta", at: when)])
        let twoArticles = try await readCountPayload()
        XCTAssertFalse(twoArticles.isEligible, "two articles show the empty state")

        try await seedPageViews([pageView("Gamma", at: when)])
        let threeArticles = try await readCountPayload()
        XCTAssertTrue(threeArticles.isEligible)
    }

    // MARK: - topArticles

    private typealias TopArticlesData = WMFYearInReviewTopArticlesSlideData

    private final class StubMainPageIdentifier: WMFMainPageIdentifying {
        let mainPages: [(title: String, projectID: String)]
        init(mainPages: [(title: String, projectID: String)]) { self.mainPages = mainPages }
        private(set) var requestedProjectIDs: [String] = []
        func mainPageTitle(for project: WMFProject) async -> String? {
            requestedProjectIDs.append(project.id)
            return mainPages.first { $0.projectID == project.id }?.title
        }
    }

    private func seedVisits(_ title: String, count: Int, month: Int, project: WMFProject? = nil) throws -> [WMFLegacyPageView] {
        try (0..<count).map { index in
            WMFLegacyPageView(title: title, project: project ?? enProject, viewedDate: try date(month: month, day: 1 + index, hour: 10), latitude: nil, longitude: nil)
        }
    }

    private func topArticlesPayload(mainPageIdentifier: WMFMainPageIdentifying? = nil) async throws -> TopArticlesData {
        var dependencies = makeDependencies()
        dependencies.mainPageIdentifier = mainPageIdentifier
        let controller = YearInReviewTopReadArticleSlideDataController(year: year, yirConfig: config, dependencies: dependencies)
        let payload = try decode(TopArticlesData.self, from: try await populatedPayload(controller))
        XCTAssertTrue(controller.isEvaluated)
        return payload
    }

    func testTopArticlesSkipsSingleViewsAndOrdersByVisitCount() async throws {
        var views = try seedVisits("Most_Read", count: 4, month: 4)
        views += try seedVisits("Second", count: 2, month: 5)
        views += try seedVisits("Read_Once", count: 1, month: 6)
        try await seedPageViews(views)

        let payload = try await topArticlesPayload()

        XCTAssertEqual(payload.articles.map(\.title), ["Most Read", "Second"], "underscores become spaces, the busiest article leads, and an article read once is excluded")
        XCTAssertEqual(payload.articles.map(\.visitCount), [4, 2])
        XCTAssertEqual(payload.articles.first?.projectID, enProject.id)
        XCTAssertEqual(payload.articles.first?.project, enProject)
        XCTAssertTrue(payload.isEligible)
    }

    func testTopArticlesShowsAtMostThreeAndBreaksTiesByTitle() async throws {
        var views = try seedVisits("Delta", count: 5, month: 3)
        views += try seedVisits("Charlie", count: 3, month: 4)
        views += try seedVisits("Alpha", count: 3, month: 5)
        views += try seedVisits("Bravo", count: 3, month: 6)
        try await seedPageViews(views)

        let payload = try await topArticlesPayload()

        XCTAssertEqual(payload.articles.map(\.title), ["Delta", "Alpha", "Bravo"])
    }

    func testTopArticlesIsNotEligibleWithOnlyOneArticleVisitedTwice() async throws {
        var views = try seedVisits("Twice", count: 2, month: 4)
        views += try seedVisits("Once", count: 1, month: 5)
        try await seedPageViews(views)

        let payload = try await topArticlesPayload()

        XCTAssertEqual(payload.articles.map(\.title), ["Twice"])
        XCTAssertFalse(payload.isEligible, "two qualifying articles are necessary, so this shows the empty state")
    }

    func testTopArticlesIsNotEligibleWithNoPageViews() async throws {
        let payload = try await topArticlesPayload()

        XCTAssertTrue(payload.articles.isEmpty)
        XCTAssertFalse(payload.isEligible)
    }

    func testTopArticlesExcludesPagesOutsideTheMainNamespace() async throws {
        try await seedPageViews(try seedVisits("Kept", count: 2, month: 4))
        let pageViewsDataController = try WMFPageViewsDataController()
        for index in 0..<5 {
            _ = try await pageViewsDataController.addPageView(title: "Talk_Page", namespaceID: 1, project: enProject, previousPageViewObjectID: nil, timestamp: try date(month: 5, day: 1 + index, hour: 10))
            _ = try await pageViewsDataController.addPageView(title: "Some_Template", namespaceID: 10, project: enProject, previousPageViewObjectID: nil, timestamp: try date(month: 6, day: 1 + index, hour: 10))
        }

        let payload = try await topArticlesPayload()

        XCTAssertEqual(payload.articles.map(\.title), ["Kept"])
    }

    func testTopArticlesExcludesTheEnglishMainPageWithoutAnIdentifier() async throws {
        var views = try seedVisits("Main_Page", count: 9, month: 3)
        views += try seedVisits("Kept", count: 2, month: 4)
        try await seedPageViews(views)

        let payload = try await topArticlesPayload()

        XCTAssertEqual(payload.articles.map(\.title), ["Kept"])
    }

    func testTopArticlesExcludesMainPagesTheAppIdentifies() async throws {
        let itProject = WMFProject.wikipedia(WMFLanguage(languageCode: "it", languageVariantCode: nil))
        var views = try seedVisits("Pagina_principale", count: 9, month: 3, project: itProject)
        // The same title on another wiki is an ordinary article.
        views += try seedVisits("Pagina_principale", count: 3, month: 4)
        views += try seedVisits("Kept", count: 2, month: 5)
        try await seedPageViews(views)

        let identifier = StubMainPageIdentifier(mainPages: [(title: "Pagina principale", projectID: itProject.id)])
        let payload = try await topArticlesPayload(mainPageIdentifier: identifier)

        XCTAssertEqual(payload.articles.map(\.title), ["Pagina principale", "Kept"])
        XCTAssertEqual(payload.articles.first?.projectID, enProject.id)
    }

    // MARK: - topTopics

    private typealias TopTopicsData = WMFYearInReviewTopTopicsSlideData

    /// Reads each article once and stores its topic labels.
    private func seedArticles(_ titles: [String], labels: [String], month: Int = 4, project: WMFProject? = nil) async throws {
        let project = project ?? enProject
        try await seedPageViews(try titles.enumerated().map { index, title in
            WMFLegacyPageView(title: title, project: project, viewedDate: try date(month: month, day: 1 + index, hour: 10), latitude: nil, longitude: nil)
        })
        let topicsDataController = try WMFPageTopicsDataController()
        for title in titles {
            try await topicsDataController.savePageTopics(title: title, namespaceID: 0, project: project, topics: labels.map { WMFPageTopic(topic: $0, score: 0.9) })
        }
    }

    /// Records the illustration downloads. A file name in `failingFileNames` fails.
    private final class StubIllustrationFetcher: @unchecked Sendable {
        private let lock = NSLock()
        private var urls: [URL] = []
        let failingFileNames: Set<String>

        init(failingFileNames: Set<String> = []) {
            self.failingFileNames = failingFileNames
        }

        var requestedFileNames: [String] {
            lock.withLock { urls.map { $0.lastPathComponent.replacingOccurrences(of: "_", with: " ") } }
        }

        func fetch(_ url: URL) throws -> Data {
            lock.withLock { urls.append(url) }
            let fileName = url.lastPathComponent.replacingOccurrences(of: "_", with: " ")
            if failingFileNames.contains(fileName) {
                throw URLError(.notConnectedToInternet)
            }
            return Data(fileName.utf8)
        }
    }

    private func topTopicsPayload(mainPageIdentifier: WMFMainPageIdentifying? = nil, illustrationFetcher: StubIllustrationFetcher = StubIllustrationFetcher()) async throws -> TopTopicsData {
        var dependencies = makeDependencies()
        dependencies.mainPageIdentifier = mainPageIdentifier
        let controller = YearInReviewTopTopicsSlideDataController(year: year, yirConfig: config, dependencies: dependencies)
        controller.fetchIllustrationData = { try illustrationFetcher.fetch($0) }
        let payload = try decode(TopTopicsData.self, from: try await populatedPayload(controller))
        XCTAssertTrue(controller.isEvaluated)
        return payload
    }

    func testTopTopicHasTheMostArticlesAndTheAlphabeticalFirstAndLastArticles() async throws {
        try await seedArticles(["Xia_dynasty", "Battle_of_Gettysburg", "Roman_Empire", "Magna_Carta"], labels: ["History_and_Society.History"])
        try await seedArticles(["Cat", "Dog", "Frog"], labels: ["STEM.Biology"], month: 5)

        let payload = try await topTopicsPayload()

        XCTAssertEqual(payload.readCount, 7)
        XCTAssertEqual(payload.topTopic?.topicCount.topic, .history)
        XCTAssertEqual(payload.topTopic?.topicCount.articleCount, 4)
        XCTAssertEqual(payload.topTopic?.firstArticle.title, "Battle of Gettysburg", "underscores become spaces")
        XCTAssertEqual(payload.topTopic?.lastArticle.title, "Xia dynasty")
        XCTAssertEqual(payload.topTopic?.firstArticle.project, enProject)
        XCTAssertEqual(payload.runnerUps.map(\.topic), [.biology])
        XCTAssertTrue(payload.isEligible)
        XCTAssertFalse(payload.showsRunnerUps, "one runner-up does not show the runners-up slide")
    }

    func testTopTopicIsEligibleWithFewerThanFiveArticles() async throws {
        try await seedArticles(["Alpha", "Beta", "Gamma"], labels: ["STEM.Physics"])

        let payload = try await topTopicsPayload()

        XCTAssertEqual(payload.readCount, 3)
        XCTAssertEqual(payload.topTopic?.topicCount.topic, .physics)
        XCTAssertTrue(payload.isEligible, "a top topic with three articles is enough, the same as on Android")
        XCTAssertFalse(payload.showsRunnerUps)
    }

    func testTopTopicIsNotEligibleWhenNoTopicHasThreeArticles() async throws {
        try await seedArticles(["Alpha", "Beta"], labels: ["STEM.Physics"])
        try await seedArticles(["Gamma", "Delta"], labels: ["STEM.Biology"], month: 5)
        try await seedArticles(["Epsilon", "Zeta"], labels: ["Culture.Sports"], month: 6)

        let payload = try await topTopicsPayload()

        XCTAssertEqual(payload.readCount, 6)
        XCTAssertNil(payload.topTopic)
        XCTAssertTrue(payload.runnerUps.isEmpty, "the runners-up slide needs an eligible top topic slide")
        XCTAssertFalse(payload.isEligible)
        XCTAssertFalse(payload.showsRunnerUps)
    }

    func testRunnerUpsNeedTwoArticlesAndTheTopTopicNeedsThree() async throws {
        try await seedArticles(["History_1", "History_2", "History_3"], labels: ["History_and_Society.History"], month: 2)
        try await seedArticles(["Physics_1", "Physics_2"], labels: ["STEM.Physics"], month: 3)
        try await seedArticles(["Biology_1", "Biology_2"], labels: ["STEM.Biology"], month: 4)
        try await seedArticles(["Sports_1"], labels: ["Culture.Sports"], month: 5)

        let payload = try await topTopicsPayload()

        XCTAssertEqual(payload.topTopic?.topicCount.topic, .history)
        XCTAssertEqual(payload.runnerUps.map(\.topic), [.biology, .physics], "a topic with one article is not a runner-up")
        XCTAssertEqual(payload.runnerUps.map(\.articleCount), [2, 2])
        XCTAssertTrue(payload.showsRunnerUps)
    }

    func testArticlesWithoutTopicsCountTowardTheReadCountOnly() async throws {
        try await seedArticles(["Alpha", "Beta", "Gamma"], labels: ["STEM.Physics"])
        try await seedPageViews([pageView("No_Topics_1", at: try date(month: 7, day: 1, hour: 10)), pageView("No_Topics_2", at: try date(month: 7, day: 2, hour: 10))])

        let payload = try await topTopicsPayload()

        XCTAssertEqual(payload.readCount, 5)
        XCTAssertEqual(payload.topTopic?.topicCount.articleCount, 3)
        XCTAssertTrue(payload.isEligible)
    }

    func testRunnerUpsLeaveOutTheTopTopicAndShowAtMostThree() async throws {
        try await seedArticles((1...6).map { "History_\($0)" }, labels: ["History_and_Society.History"], month: 2)
        try await seedArticles((1...5).map { "Biology_\($0)" }, labels: ["STEM.Biology"], month: 3)
        try await seedArticles((1...4).map { "Sports_\($0)" }, labels: ["Culture.Sports"], month: 4)
        try await seedArticles((1...4).map { "Music_\($0)" }, labels: ["Culture.Media.Music"], month: 5)
        try await seedArticles((1...3).map { "Physics_\($0)" }, labels: ["STEM.Physics"], month: 6)
        try await seedArticles((1...2).map { "Art_\($0)" }, labels: ["Culture.Visual_arts.Visual_arts*"], month: 7)

        let payload = try await topTopicsPayload()

        XCTAssertEqual(payload.topTopic?.topicCount.topic, .history)
        // Sports and music tie, so the topic ID decides the order.
        XCTAssertEqual(payload.runnerUps.map(\.topic), [.biology, .music, .sports])
        XCTAssertEqual(payload.runnerUps.map(\.articleCount), [5, 4, 4])
        XCTAssertTrue(payload.showsRunnerUps)
    }

    func testAnArticleWithTwoLabelsForOneTopicCountsOnce() async throws {
        try await seedArticles(["Tokyo", "Kyoto", "Osaka"], labels: ["Geography.Regions.Asia.Asia*", "Geography.Regions.Asia.East_Asia"])
        try await seedArticles(["Alpha", "Beta"], labels: ["STEM.Physics"], month: 5)

        let payload = try await topTopicsPayload()

        XCTAssertEqual(payload.topTopic?.topicCount.topic, .asia)
        XCTAssertEqual(payload.topTopic?.topicCount.articleCount, 3)
    }

    func testWomenBiographiesCountAsBiographies() async throws {
        try await seedArticles(["Marie_Curie", "Ada_Lovelace"], labels: ["Culture.Biography.Women", "Culture.Biography.Biography*"])
        try await seedArticles(["Albert_Einstein"], labels: ["Culture.Biography.Biography*"], month: 5)
        try await seedArticles(["Alpha", "Beta"], labels: ["STEM.Physics"], month: 6)

        let payload = try await topTopicsPayload()

        XCTAssertEqual(payload.topTopic?.topicCount.topic, .biography)
        XCTAssertEqual(payload.topTopic?.topicCount.articleCount, 3)
        XCTAssertFalse(payload.runnerUps.contains { $0.topic == .women })
    }

    func testTopTopicTieIsOneOfTheTiedTopics() async throws {
        try await seedArticles(["Alpha", "Beta", "Gamma"], labels: ["STEM.Physics"])
        try await seedArticles(["Delta", "Epsilon", "Zeta"], labels: ["STEM.Biology"], month: 5)

        let payload = try await topTopicsPayload()

        let topTopic = try XCTUnwrap(payload.topTopic?.topicCount.topic)
        XCTAssertTrue([.physics, .biology].contains(topTopic))
        XCTAssertEqual(payload.runnerUps.map(\.topic), [topTopic == .physics ? .biology : .physics])
    }

    func testTopTopicsExcludesMainPages() async throws {
        let itProject = WMFProject.wikipedia(WMFLanguage(languageCode: "it", languageVariantCode: nil))
        try await seedArticles(["Main_Page", "Alpha", "Beta"], labels: ["STEM.Physics"])
        try await seedArticles(["Pagina_principale"], labels: ["STEM.Physics"], project: itProject)
        try await seedArticles(["Gamma", "Delta", "Epsilon"], labels: ["STEM.Biology"], month: 5)

        let identifier = StubMainPageIdentifier(mainPages: [(title: "Pagina principale", projectID: itProject.id)])
        let payload = try await topTopicsPayload(mainPageIdentifier: identifier)

        XCTAssertEqual(payload.readCount, 5)
        XCTAssertEqual(payload.topTopic?.topicCount.topic, .biology, "physics has two articles without the main pages")
        XCTAssertEqual(payload.runnerUps.map(\.articleCount), [2], "physics is a runner-up with its two articles")
    }

    func testTopTopicsDownloadsOnlyTheIllustrationsOfTheShownTopics() async throws {
        try await seedArticles((1...5).map { "History_\($0)" }, labels: ["History_and_Society.History"], month: 2)
        try await seedArticles((1...4).map { "Europe_\($0)" }, labels: ["Geography.Regions.Europe.Europe*"], month: 3)
        try await seedArticles((1...3).map { "Asia_\($0)" }, labels: ["Geography.Regions.Asia.Asia*"], month: 4)
        try await seedArticles((1...3).map { "Biology_\($0)" }, labels: ["STEM.Biology"], month: 5)
        // A fourth runner-up is not shown, so its illustration does not download.
        try await seedArticles((1...3).map { "Sports_\($0)" }, labels: ["Culture.Sports"], month: 6)

        let fetcher = StubIllustrationFetcher()
        let payload = try await topTopicsPayload(illustrationFetcher: fetcher)

        XCTAssertEqual(payload.topTopic?.topicCount.topic, .history)
        XCTAssertEqual(payload.runnerUps.map(\.topic), [.europe, .asia, .biology])
        // Europe and Asia use the same file, so it downloads one time.
        XCTAssertEqual(fetcher.requestedFileNames.sorted(), ["17 History.png", "23 Biology.png", "33 - 39 Regional.png"])
        XCTAssertEqual(payload.illustration(for: .history), Data("17 History.png".utf8))
        XCTAssertEqual(payload.illustration(for: .asia), Data("33 - 39 Regional.png".utf8))
        XCTAssertEqual(payload.illustration(for: .europe), payload.illustration(for: .asia))
        XCTAssertNil(payload.illustration(for: .sports))
    }

    func testTopTopicsLeavesOutAnIllustrationThatFailsToDownload() async throws {
        try await seedArticles((1...5).map { "History_\($0)" }, labels: ["History_and_Society.History"])

        let fetcher = StubIllustrationFetcher(failingFileNames: ["17 History.png"])
        let payload = try await topTopicsPayload(illustrationFetcher: fetcher)

        XCTAssertTrue(payload.isEligible, "a failed download does not change the slide data")
        XCTAssertNil(payload.illustration(for: .history))
    }

    func testTopTopicsDoesNotDownloadIllustrationsForTheEmptyState() async throws {
        // No topic has three articles, so there is no top topic.
        try await seedArticles(["Alpha", "Beta"], labels: ["STEM.Physics"])

        let fetcher = StubIllustrationFetcher()
        let payload = try await topTopicsPayload(illustrationFetcher: fetcher)

        XCTAssertFalse(payload.isEligible)
        XCTAssertTrue(fetcher.requestedFileNames.isEmpty)
        XCTAssertNil(payload.illustrations)
    }

    /// Slide data from before the illustrations decodes without them.
    func testTopTopicsDataWithoutIllustrationsDecodes() throws {
        let json = #"{"readCount": 5, "runnerUps": []}"#
        let payload = try JSONDecoder().decode(TopTopicsData.self, from: Data(json.utf8))
        XCTAssertNil(payload.illustrations)
        XCTAssertNil(payload.illustration(for: .history))
    }

    // MARK: - daysVisited

    private typealias DaysVisitedData = WMFYearInReviewDaysVisitedSlideData

    private func daysVisitedPayload() async throws -> DaysVisitedData {
        let controller = YearInReviewDaysVisitedSlideDataController(year: year, yirConfig: config, dependencies: makeDependencies())
        let payload = try decode(DaysVisitedData.self, from: try await populatedPayload(controller))
        XCTAssertTrue(controller.isEvaluated)
        return payload
    }

    func testDaysVisitedCountsDistinctDaysAndThePeakMonth() async throws {
        try await seedPageViews([
            // Two reads on one day count as one day.
            pageView("Alpha", at: try date(month: 3, day: 4, hour: 9)),
            pageView("Beta", at: try date(month: 3, day: 4, hour: 15)),
            pageView("Gamma", at: try date(month: 3, day: 9, hour: 9)),
            pageView("Delta", at: try date(month: 3, day: 20, hour: 9)),
            pageView("Epsilon", at: try date(month: 7, day: 1, hour: 9)),
            pageView("Zeta", at: try date(month: 7, day: 2, hour: 9))
        ])

        let payload = try await daysVisitedPayload()

        XCTAssertEqual(payload.dayCount, 5)
        XCTAssertEqual(payload.peakMonth, DaysVisitedData.PeakMonth(month: 3, dayCount: 3))
        XCTAssertTrue(payload.isEligible)
    }

    func testDaysVisitedIgnoresViewsOutsideTheInsightsRange() async throws {
        let outside = try XCTUnwrap(Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 1, hour: 9)))
        try await seedPageViews([
            pageView("Alpha", at: try date(month: 3, day: 4, hour: 9)),
            pageView("Beta", at: outside)
        ])

        let payload = try await daysVisitedPayload()

        XCTAssertEqual(payload.dayCount, 1)
        XCTAssertFalse(payload.isEligible, "one day is not enough for the slide")
    }

    func testDaysVisitedHasNoPeakMonthWithoutTwoDaysInOneMonth() async throws {
        try await seedPageViews([
            pageView("Alpha", at: try date(month: 3, day: 4, hour: 9)),
            pageView("Beta", at: try date(month: 5, day: 4, hour: 9))
        ])

        let payload = try await daysVisitedPayload()

        XCTAssertEqual(payload.dayCount, 2)
        XCTAssertTrue(payload.isEligible)
        XCTAssertNil(payload.peakMonth)
    }

    func testDaysVisitedPeakMonthTieIsOneOfTheTiedMonths() throws {
        let calendar = Calendar.current
        let days = try [(3, 1), (3, 2), (8, 1), (8, 2), (10, 1)].map { month, day in
            try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: month, day: day)))
        }

        let payload = YearInReviewDaysVisitedSlideDataController.slideData(days: days, calendar: calendar)

        XCTAssertEqual(payload.dayCount, 5)
        let peakMonth = try XCTUnwrap(payload.peakMonth)
        XCTAssertTrue([3, 8].contains(peakMonth.month))
        XCTAssertEqual(peakMonth.dayCount, 2)
    }

    /// The same month in two years does not add up to one peak month. Together, the two Decembers have
    /// four days and would be the peak month.
    func testDaysVisitedCountsTheSameMonthOfTwoYearsApart() throws {
        let calendar = Calendar.current
        let days = try [(2025, 12, 1), (2025, 12, 2), (2026, 12, 1), (2026, 12, 2), (2026, 1, 1), (2026, 1, 2), (2026, 1, 3)].map { year, month, day in
            try XCTUnwrap(calendar.date(from: DateComponents(year: year, month: month, day: day)))
        }

        let payload = YearInReviewDaysVisitedSlideDataController.slideData(days: days, calendar: calendar)

        XCTAssertEqual(payload.peakMonth, DaysVisitedData.PeakMonth(month: 1, dayCount: 3))
    }

    // MARK: - readingStreak

    private typealias ReadingStreakData = WMFYearInReviewReadingStreakSlideData

    private func readingStreakPayload() async throws -> ReadingStreakData {
        let controller = YearInReviewReadingStreakSlideDataController(year: year, yirConfig: config, dependencies: makeDependencies())
        let payload = try decode(ReadingStreakData.self, from: try await populatedPayload(controller))
        XCTAssertTrue(controller.isEvaluated)
        return payload
    }

    private func streakDays(_ days: [(month: Int, day: Int)], calendar: Calendar = .current) throws -> [Date] {
        try days.map { try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: $0.month, day: $0.day))) }
    }

    func testReadingStreakFindsTheLongestRunOfConsecutiveDays() async throws {
        try await seedPageViews([
            pageView("Alpha", at: try date(month: 2, day: 1, hour: 9)),
            pageView("Beta", at: try date(month: 2, day: 2, hour: 9)),
            // Two reads on one day count as one day of the streak.
            pageView("Gamma", at: try date(month: 3, day: 4, hour: 9)),
            pageView("Delta", at: try date(month: 3, day: 4, hour: 22)),
            pageView("Epsilon", at: try date(month: 3, day: 5, hour: 9)),
            pageView("Zeta", at: try date(month: 3, day: 6, hour: 9)),
            pageView("Eta", at: try date(month: 3, day: 8, hour: 9))
        ])

        let payload = try await readingStreakPayload()

        XCTAssertEqual(payload.dayCount, 3)
        XCTAssertEqual(payload.firstDay, ReadingStreakData.Day(year: 2026, month: 3, day: 4))
        XCTAssertEqual(payload.lastDay, ReadingStreakData.Day(year: 2026, month: 3, day: 6))
        XCTAssertTrue(payload.isEligible)
    }

    func testReadingStreakWithoutReadsIsNotEligible() async throws {
        let payload = try await readingStreakPayload()

        XCTAssertEqual(payload, ReadingStreakData(dayCount: 0, firstDay: nil, lastDay: nil))
        XCTAssertFalse(payload.isEligible)
    }

    func testReadingStreakOfTwoDaysIsNotEligible() throws {
        let payload = YearInReviewReadingStreakSlideDataController.slideData(days: try streakDays([(3, 4), (3, 5), (3, 7), (5, 1)]), calendar: .current)

        XCTAssertEqual(payload.dayCount, 2)
        XCTAssertFalse(payload.isEligible, "a streak needs three consecutive days")
    }

    func testReadingStreakOfThreeDaysIsEligible() throws {
        let payload = YearInReviewReadingStreakSlideDataController.slideData(days: try streakDays([(3, 4), (3, 5), (3, 6)]), calendar: .current)

        XCTAssertEqual(payload.dayCount, 3)
        XCTAssertTrue(payload.isEligible)
    }

    func testReadingStreakCrossesMonthsAndTheEarlierStreakWinsATie() throws {
        let days = try streakDays([(3, 30), (3, 31), (4, 1), (6, 10), (6, 11), (6, 12)].reversed())

        let payload = YearInReviewReadingStreakSlideDataController.slideData(days: days, calendar: .current)

        XCTAssertEqual(payload.dayCount, 3)
        XCTAssertEqual(payload.firstDay, ReadingStreakData.Day(year: 2026, month: 3, day: 30))
        XCTAssertEqual(payload.lastDay, ReadingStreakData.Day(year: 2026, month: 4, day: 1))
    }

    /// The days of the streak come from the calendar of the device, so a time zone with a daylight
    /// saving change in the streak still counts each day once.
    func testReadingStreakCountsDaysAcrossADaylightSavingChange() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "America/New_York"))
        let days = try streakDays([(3, 7), (3, 8), (3, 9)], calendar: calendar)

        let payload = YearInReviewReadingStreakSlideDataController.slideData(days: days, calendar: calendar)

        XCTAssertEqual(payload.dayCount, 3)
    }

    func testDaysVisitedIsNotEligibleWithNoPageViews() async throws {
        let payload = try await daysVisitedPayload()

        XCTAssertEqual(payload.dayCount, 0)
        XCTAssertNil(payload.peakMonth)
        XCTAssertFalse(payload.isEligible)
    }

    // MARK: - biggestReadingDay

    private typealias BiggestReadingDayData = WMFYearInReviewBiggestReadingDaySlideData

    private actor DescriptionRecorder {
        private(set) var requestedTitles: [String] = []
        func record(_ title: String) { requestedTitles.append(title) }
    }

    private func biggestReadingDayController(
        mainPageIdentifier: WMFMainPageIdentifying? = nil,
        recorder: DescriptionRecorder = DescriptionRecorder(),
        failingTitles: Set<String> = []
    ) -> YearInReviewBiggestReadingDaySlideDataController {
        var dependencies = makeDependencies()
        dependencies.mainPageIdentifier = mainPageIdentifier
        let controller = YearInReviewBiggestReadingDaySlideDataController(year: year, yirConfig: config, dependencies: dependencies)
        controller.fetchDescription = { _, title in
            await recorder.record(title)
            if failingTitles.contains(title) {
                throw URLError(.notConnectedToInternet)
            }
            return "About \(title)"
        }
        return controller
    }

    private func biggestReadingDayPayload(_ controller: YearInReviewBiggestReadingDaySlideDataController) async throws -> BiggestReadingDayData {
        let payload = try decode(BiggestReadingDayData.self, from: try await populatedPayload(controller))
        XCTAssertTrue(controller.isEvaluated)
        return payload
    }

    private func seedReadingTime(_ title: String, seconds: Int, at date: Date, namespaceID: Int16 = 0, project: WMFProject? = nil) async throws {
        let pageViewsDataController = try WMFPageViewsDataController()
        let pageViewID = try await pageViewsDataController.addPageView(title: title, namespaceID: namespaceID, project: project ?? enProject, previousPageViewObjectID: nil, timestamp: date)
        try await pageViewsDataController.addPageViewSeconds(pageViewManagedObjectID: try XCTUnwrap(pageViewID), numberOfSeconds: Double(seconds))
    }

    func testBiggestReadingDayIsTheDayWithTheMostReadingTime() async throws {
        // March 4: 2 + 3 + 1 + 4 minutes on four articles, Alpha twice.
        try await seedReadingTime("Alpha", seconds: 120, at: try date(month: 3, day: 4, hour: 9))
        try await seedReadingTime("Beta", seconds: 180, at: try date(month: 3, day: 4, hour: 10))
        try await seedReadingTime("Gamma", seconds: 60, at: try date(month: 3, day: 4, hour: 11))
        try await seedReadingTime("Alpha", seconds: 240, at: try date(month: 3, day: 4, hour: 20))
        try await seedReadingTime("Delta", seconds: 30, at: try date(month: 3, day: 4, hour: 21))
        // More page views, but less time.
        for hour in 8...16 {
            try await seedReadingTime("Epsilon", seconds: 60, at: try date(month: 6, day: 1, hour: hour))
        }

        let recorder = DescriptionRecorder()
        let payload = try await biggestReadingDayPayload(biggestReadingDayController(recorder: recorder))

        XCTAssertEqual(payload.dateComponents, DateComponents(year: 2026, month: 3, day: 4))
        XCTAssertEqual(payload.minuteCount, 10, "630 seconds are 10 whole minutes")
        XCTAssertEqual(payload.articleCount, 4)
        XCTAssertEqual(payload.articles, [
            BiggestReadingDayData.Article(title: "Alpha", projectID: enProject.id, description: "About Alpha"),
            BiggestReadingDayData.Article(title: "Beta", projectID: enProject.id, description: "About Beta"),
            BiggestReadingDayData.Article(title: "Gamma", projectID: enProject.id, description: "About Gamma")
        ])
        XCTAssertTrue(payload.isEligible)
        XCTAssertTrue(payload.showsArticles)
        let requestedTitles = await recorder.requestedTitles
        XCTAssertEqual(Set(requestedTitles), ["Alpha", "Beta", "Gamma"])
    }

    func testBiggestReadingDayLeavesOutMainPagesAndOtherNamespaces() async throws {
        let itProject = WMFProject.wikipedia(WMFLanguage(languageCode: "it", languageVariantCode: nil))
        try await seedReadingTime("Alpha", seconds: 120, at: try date(month: 3, day: 4, hour: 9))
        try await seedReadingTime("Beta", seconds: 60, at: try date(month: 3, day: 4, hour: 10))
        try await seedReadingTime("Pagina_principale", seconds: 6000, at: try date(month: 5, day: 1, hour: 9), project: itProject)
        try await seedReadingTime("Main_Page", seconds: 6000, at: try date(month: 5, day: 2, hour: 9))
        try await seedReadingTime("Talk:Alpha", seconds: 6000, at: try date(month: 5, day: 3, hour: 9), namespaceID: 1)

        let identifier = StubMainPageIdentifier(mainPages: [(title: "Pagina principale", projectID: itProject.id)])
        let payload = try await biggestReadingDayPayload(biggestReadingDayController(mainPageIdentifier: identifier))

        XCTAssertEqual(payload.dateComponents, DateComponents(year: 2026, month: 3, day: 4))
        XCTAssertEqual(payload.minuteCount, 3)
        XCTAssertEqual(payload.articles.map(\.title), ["Alpha", "Beta"])
    }

    func testBiggestReadingDayWithOneArticleShowsOnlyTheDay() async throws {
        try await seedReadingTime("Alpha", seconds: 150, at: try date(month: 3, day: 4, hour: 9))

        let recorder = DescriptionRecorder()
        let payload = try await biggestReadingDayPayload(biggestReadingDayController(recorder: recorder))

        XCTAssertTrue(payload.isEligible)
        XCTAssertFalse(payload.showsArticles)
        XCTAssertNil(payload.articles.first?.description)
        let requestedTitles = await recorder.requestedTitles
        XCTAssertTrue(requestedTitles.isEmpty, "descriptions load only for the articles slide")
    }

    func testBiggestReadingDayUnderTwoMinutesIsNotEligible() async throws {
        try await seedReadingTime("Alpha", seconds: 60, at: try date(month: 3, day: 4, hour: 9))
        try await seedReadingTime("Beta", seconds: 59, at: try date(month: 3, day: 4, hour: 10))

        let payload = try await biggestReadingDayPayload(biggestReadingDayController())

        XCTAssertEqual(payload.minuteCount, 1)
        XCTAssertFalse(payload.isEligible)
        XCTAssertFalse(payload.showsArticles)
    }

    func testBiggestReadingDayWithoutReadingTimeHasNoData() async throws {
        try await seedPageViews([pageView("Alpha", at: try date(month: 3, day: 4, hour: 9))])

        let controller = biggestReadingDayController()
        let payload = try await populatedPayload(controller)

        XCTAssertNil(payload)
        XCTAssertTrue(controller.isEvaluated)
    }

    func testBiggestReadingDayLeavesOutADescriptionThatFails() async throws {
        try await seedReadingTime("Alpha", seconds: 120, at: try date(month: 3, day: 4, hour: 9))
        try await seedReadingTime("Beta", seconds: 60, at: try date(month: 3, day: 4, hour: 10))

        let payload = try await biggestReadingDayPayload(biggestReadingDayController(failingTitles: ["Beta"]))

        XCTAssertEqual(payload.articles.map(\.description), ["About Alpha", nil])
        XCTAssertTrue(payload.showsArticles)
    }

    func testBiggestReadingDayOverTheMaximumIsNotEligible() {
        let page = WMFPage(namespaceID: 0, projectID: enProject.id, title: "Alpha")
        let when = Date(timeIntervalSince1970: 1_780_000_000)
        let seconds = (BiggestReadingDayData.maximumMinuteCount + 1) * 60
        let payload = YearInReviewBiggestReadingDaySlideDataController.slideData(readingTimes: [WMFPageViewReadingTime(page: page, timestamp: when, numberOfSeconds: seconds)], calendar: .current)

        XCTAssertEqual(payload?.minuteCount, BiggestReadingDayData.maximumMinuteCount + 1)
        XCTAssertEqual(payload?.isEligible, false)
    }

    func testBiggestReadingDayTieGoesToTheMoreRecentDay() throws {
        let calendar = Calendar.current
        let alpha = WMFPage(namespaceID: 0, projectID: enProject.id, title: "Alpha")
        let beta = WMFPage(namespaceID: 0, projectID: enProject.id, title: "Beta")
        let readingTimes = [
            WMFPageViewReadingTime(page: alpha, timestamp: try date(month: 3, day: 4, hour: 9), numberOfSeconds: 300),
            WMFPageViewReadingTime(page: alpha, timestamp: try date(month: 8, day: 1, hour: 9), numberOfSeconds: 150),
            WMFPageViewReadingTime(page: beta, timestamp: try date(month: 8, day: 1, hour: 10), numberOfSeconds: 150)
        ]

        let payload = try XCTUnwrap(YearInReviewBiggestReadingDaySlideDataController.slideData(readingTimes: readingTimes, calendar: calendar))

        XCTAssertEqual(payload.dateComponents, DateComponents(year: 2026, month: 8, day: 1))
        XCTAssertEqual(payload.articles.map(\.title), ["Beta", "Alpha"], "a tie between articles goes to the more recently read one")
    }

    /// Inserts a second CDPage row for an article, with its own page view and topics. The app does not do this on
    /// purpose, but CDPage has no uniqueness constraint, so two concurrent fetchOrCreate calls can.
    private func insertDuplicatePageRow(title: String, project: WMFProject, viewedAt timestamp: Date, topicLabels: [String]) async throws {
        let store = try XCTUnwrap(store)
        let context = try store.newBackgroundContext
        try await context.perform {
            let page = try store.create(entityType: CDPage.self, in: context)
            page.title = title
            page.namespaceID = 0
            page.projectID = project.id
            page.timestamp = timestamp

            let pageView = try store.create(entityType: CDPageView.self, in: context)
            pageView.timestamp = timestamp
            pageView.page = page

            for label in topicLabels {
                let topic = try store.create(entityType: CDPageTopic.self, in: context)
                topic.topic = label
                topic.score = 0.9
                topic.page = page
            }

            try store.saveIfNeeded(moc: context)
        }
    }

    /// Duplicate page rows must not count one article twice, for the read count or for a topic.
    func testTopTopicsCountsAnArticleWithDuplicatePageRowsOnce() async throws {
        try await seedArticles(["Alpha", "Beta"], labels: ["STEM.Physics"])
        try await seedArticles(["Gamma", "Delta"], labels: ["STEM.Biology"], month: 5)
        let when = try date(month: 6, day: 1, hour: 10)
        try await insertDuplicatePageRow(title: "Alpha", project: enProject, viewedAt: when, topicLabels: ["STEM.Physics"])
        try await insertDuplicatePageRow(title: "Beta", project: enProject, viewedAt: when, topicLabels: ["STEM.Physics"])

        let payload = try await topTopicsPayload()

        // With each row counted, the user would have 6 articles read and 4 about physics, so the slide would be eligible.
        XCTAssertEqual(payload.readCount, 4)
        XCTAssertNil(payload.topTopic, "physics has 2 distinct articles, fewer than the top topic needs")
        XCTAssertFalse(payload.isEligible)
    }

    func testTopTopicsIsNotEligibleWithNoPageViews() async throws {
        let payload = try await topTopicsPayload()

        XCTAssertEqual(payload.readCount, 0)
        XCTAssertNil(payload.topTopic)
        XCTAssertFalse(payload.isEligible)
    }

    // MARK: - mostReadCategories (niche interest)

    /// Reads `articleCount` different articles and puts each one in the category.
    /// `addCategories` needs the page to exist, so the page views come first.
    private func seedCategory(_ categoryName: String, articleCount: Int) async throws {
        let titles = (1...articleCount).map { "\(categoryName)_Article_\($0)" }
        try await seedPageViews(try titles.enumerated().map { index, title in
            pageView(title, at: try date(month: 8, day: 1 + index, hour: 11))
        })

        let categoriesDataController = try WMFCategoriesDataController()
        for title in titles {
            try await categoriesDataController.addCategories(categories: [categoryName], articleTitle: title, project: enProject)
        }
    }

    private func nicheCategoryPayload() async throws -> WMFYearInReviewNicheCategorySlideData {
        let controller = YearInReviewMostReadCategoriesSlideDataController(year: year, yirConfig: config, dependencies: makeDependencies())
        let payload = try decode(WMFYearInReviewNicheCategorySlideData.self, from: try await populatedPayload(controller))
        XCTAssertTrue(controller.isEvaluated)
        return payload
    }

    /// Only one category has 2 or more articles and 2 or more spaces, so the pick is not random here.
    func testNicheInterestPrefersACategoryWithTwoSpacesAndTwoArticles() async throws {
        try await seedCategory("Executed_female_serial_killers", articleCount: 2)
        try await seedCategory("Plain", articleCount: 3)
        try await seedCategory("Two_Words", articleCount: 3)
        try await seedCategory("Single_Article_Category", articleCount: 1)

        let payload = try await nicheCategoryPayload()

        XCTAssertEqual(payload.categoryName, "Executed female serial killers", "underscores become spaces")
        XCTAssertTrue(payload.isEligible)
    }

    func testNicheInterestFallsBackToAnyCategoryWithTwoArticles() async throws {
        try await seedCategory("Plain", articleCount: 2)
        try await seedCategory("Two_Words", articleCount: 2)
        try await seedCategory("Single_Article_Category", articleCount: 1)

        let payload = try await nicheCategoryPayload()

        let categoryName = try XCTUnwrap(payload.categoryName)
        XCTAssertTrue(["Plain", "Two Words"].contains(categoryName), "a category with one article is never picked: \(categoryName)")
        XCTAssertTrue(payload.isEligible)
    }

    func testNicheInterestIsNotEligibleWhenNoCategoryHasTwoArticles() async throws {
        try await seedCategory("Single_Article_Category", articleCount: 1)
        try await seedCategory("Another_Single_Category", articleCount: 1)

        let payload = try await nicheCategoryPayload()

        XCTAssertNil(payload.categoryName)
        XCTAssertFalse(payload.isEligible, "the slide does not show")
    }

    func testNicheInterestIsNotEligibleWithNoPageViews() async throws {
        let payload = try await nicheCategoryPayload()

        XCTAssertNil(payload.categoryName)
        XCTAssertFalse(payload.isEligible)
    }

    func testNicheInterestSelectionIgnoresCategoriesWithOneArticle() {
        var generator = SeededRandomNumberGenerator(seed: 1)
        let counts: [(name: String, count: Int)] = [
            (name: "One article with many words", count: 1),
            (name: "Plain", count: 5)
        ]

        let name = YearInReviewMostReadCategoriesSlideDataController.selectCategoryName(from: counts, using: &generator)

        XCTAssertEqual(name, "Plain", "the category with many words has only one article, so the fallback uses Plain")
    }

    func testNicheInterestSelectionReturnsNilForNoCandidates() {
        var generator = SeededRandomNumberGenerator(seed: 1)

        XCTAssertNil(YearInReviewMostReadCategoriesSlideDataController.selectCategoryName(from: [], using: &generator))
        XCTAssertNil(YearInReviewMostReadCategoriesSlideDataController.selectCategoryName(from: [(name: "Only one", count: 1)], using: &generator))
    }

    func testNicheInterestSelectionGivesTheSameResultForTheSameSeed() {
        let counts: [(name: String, count: Int)] = [
            (name: "Category one two", count: 2),
            (name: "Category three four", count: 4),
            (name: "Category five six", count: 3)
        ]
        let reversedCounts = Array(counts.reversed())

        var first = SeededRandomNumberGenerator(seed: 42)
        var second = SeededRandomNumberGenerator(seed: 42)
        let firstName = YearInReviewMostReadCategoriesSlideDataController.selectCategoryName(from: counts, using: &first)
        let secondName = YearInReviewMostReadCategoriesSlideDataController.selectCategoryName(from: reversedCounts, using: &second)

        XCTAssertNotNil(firstName)
        XCTAssertEqual(firstName, secondName, "the order of the input does not change the result")
    }

    // MARK: - saveCount

    private final class StubSavedArticleDelegate: SavedArticleSlideDataDelegate {
        let data: SavedArticleSlideData?
        init(data: SavedArticleSlideData?) { self.data = data }
        func getSavedArticleSlideData(from startDate: Date, to endEnd: Date) async -> SavedArticleSlideData? { data }
    }

    func testSaveCountTakesItsPayloadFromTheHostDelegate() async throws {
        let articles = ["A", "B", "C"].map { SavedArticleSlideData.Article(title: $0, pageTitle: $0, articleDescription: nil, projectID: "wikipedia~en") }
        let delegate = StubSavedArticleDelegate(data: SavedArticleSlideData(savedArticlesCount: 7, articles: articles))
        let controller = YearInReviewSaveCountSlideDataController(year: year, yirConfig: config, dependencies: makeDependencies(savedSlideDataDelegate: delegate))

        let payload = try decode(SavedArticleSlideData.self, from: try await populatedPayload(controller))

        XCTAssertEqual(payload.savedArticlesCount, 7)
        XCTAssertEqual(payload.articleTitles, ["A", "B", "C"])
        XCTAssertTrue(controller.isEvaluated)
    }

    func testSaveCountStoresTheArticlesWithTheirDescriptionsAndWikis() async throws {
        let articles = [
            SavedArticleSlideData.Article(title: "Cat", pageTitle: "Cat", articleDescription: "Small mammal", projectID: "wikipedia~en"),
            SavedArticleSlideData.Article(title: "Hund", pageTitle: "Hund", articleDescription: nil, projectID: "wikipedia~de")
        ]
        let delegate = StubSavedArticleDelegate(data: SavedArticleSlideData(savedArticlesCount: 2, articles: articles))
        let controller = YearInReviewSaveCountSlideDataController(year: year, yirConfig: config, dependencies: makeDependencies(savedSlideDataDelegate: delegate))

        let payload = try decode(SavedArticleSlideData.self, from: try await populatedPayload(controller))

        XCTAssertEqual(payload.articles, articles)
        XCTAssertEqual(payload.articles?.last?.project, .wikipedia(WMFLanguage(languageCode: "de", languageVariantCode: nil)))
        XCTAssertTrue(payload.isEligible)
    }

    func testSaveCountIsNotEligibleWithoutSavedArticles() throws {
        XCTAssertFalse(SavedArticleSlideData(savedArticlesCount: 0, articles: []).isEligible)
        let legacy = try JSONDecoder().decode(SavedArticleSlideData.self, from: Data(#"{"savedArticlesCount":4,"articleTitles":["Cat"]}"#.utf8))
        XCTAssertFalse(legacy.isEligible, "older data has no articles to list")
        XCTAssertEqual(legacy.articleTitles, ["Cat"], "older data keeps its stored titles")
        XCTAssertTrue(SavedArticleSlideData(savedArticlesCount: 1, articles: [
            SavedArticleSlideData.Article(title: "Cat", pageTitle: nil, articleDescription: nil, projectID: nil)
        ]).isEligible)
    }

    func testSaveCountIsNotEvaluatedWithoutADelegate() async throws {
        let controller = YearInReviewSaveCountSlideDataController(year: year, yirConfig: config, dependencies: makeDependencies())

        let payload = try await populatedPayload(controller)

        XCTAssertNil(payload, "no delegate means no payload")
        XCTAssertFalse(controller.isEvaluated)
    }

    func testSaveCountIsNotEvaluatedWhenTheSavedArticlesCannotBeRead() async throws {
        let controller = YearInReviewSaveCountSlideDataController(year: year, yirConfig: config, dependencies: makeDependencies(savedSlideDataDelegate: StubSavedArticleDelegate(data: nil)))

        let payload = try await populatedPayload(controller)

        XCTAssertNil(payload, "a failed read must not freeze an empty slide")
        XCTAssertFalse(controller.isEvaluated)
    }

    func testSavedDataStoresTheTitlesOnlyInTheArticles() throws {
        let data = try JSONEncoder().encode(SavedArticleSlideData(savedArticlesCount: 1, articles: [
            SavedArticleSlideData.Article(title: "Cat", pageTitle: "Cat", articleDescription: nil, projectID: "wikipedia~en")
        ]))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertNil(json["articleTitles"], "the titles are not stored twice")
        XCTAssertEqual(try JSONDecoder().decode(SavedArticleSlideData.self, from: data).articleTitles, ["Cat"])
    }

    // MARK: - location

    private final class StubLegacyPageViewsDelegate: LegacyPageViewsDataDelegate {
        let views: [WMFLegacyPageView]
        var requestedLatLong: Bool?
        init(views: [WMFLegacyPageView]) { self.views = views }
        func getLegacyPageViews(from startDate: Date, to endDate: Date, needsLatLong: Bool) async throws -> [WMFLegacyPageView] {
            requestedLatLong = needsLatLong
            return views
        }
    }

    func testLocationAsksForCoordinatesAndKeepsTheViews() async throws {
        let when = try date(month: 7, day: 2, hour: 12)
        let delegate = StubLegacyPageViewsDelegate(views: [
            pageView("Paris", at: when, latitude: 48.8, longitude: 2.3),
            pageView("Lisbon", at: when, latitude: 38.7, longitude: -9.1)
        ])
        let controller = YearInReviewLocationSlideDataController(year: year, yirConfig: config, dependencies: makeDependencies(legacyPageViewsDataDelegate: delegate))

        let payload = try decode([WMFLegacyPageView].self, from: try await populatedPayload(controller))

        XCTAssertEqual(delegate.requestedLatLong, true, "the slide needs coordinates to draw the map")
        XCTAssertEqual(payload.count, 2)
        XCTAssertEqual(payload.first?.title, "Paris")
        XCTAssertEqual(payload.first?.latitude, 48.8)
        XCTAssertTrue(controller.isEvaluated)
    }

    func testLocationThrowsWithoutADelegate() async throws {
        let controller = YearInReviewLocationSlideDataController(year: year, yirConfig: config, dependencies: makeDependencies())

        do {
            try await controller.populateSlideData(in: try context())
            XCTFail("the slide must throw when the host cannot supply page views")
        } catch {
            XCTAssertFalse(controller.isEvaluated)
        }
    }

    // MARK: - editCount

    func testEditCountSumsTheMonthlyCountsFromTheMetricsAPI() async throws {
        WMFDataEnvironment.current.basicService = WMFMockBasicService(jsonResourceName: "yir-metrics-edit-count-get")
        let controller = YearInReviewEditCountSlideDataController(year: year, yirConfig: config, dependencies: makeDependencies(username: "Editor", globalUserID: 1))

        let payload = try decode(Int.self, from: try await populatedPayload(controller))

        XCTAssertEqual(payload, 47, "12 + 30 + 5 across the three monthly buckets")
        XCTAssertTrue(controller.isEvaluated)
    }

    private var configWithContribDates: WMFFeatureConfigResponse.Common.YearInReview {
        var config = config
        config.contribStartDateString = "2025-12-01T00:00:00Z"
        config.contribEndDateString = "2026-12-01T00:00:00Z"
        return config
    }

    func testEditCountRequestsTheContribDatesOfTheConfig() async throws {
        let service = WMFRecordingMockBasicService(jsonResourceName: "yir-metrics-edit-count-get")
        WMFDataEnvironment.current.basicService = service
        let controller = YearInReviewEditCountSlideDataController(year: year, yirConfig: configWithContribDates, dependencies: makeDependencies(username: "Editor", globalUserID: 1))

        _ = try await populatedPayload(controller)

        let path = try XCTUnwrap(service.requestedURLs.first?.path)
        XCTAssertTrue(path.hasSuffix("/monthly/20251201/20261201"), "contribStartDate to contribEndDate: \(path)")
    }

    func testEditCountIsNotEvaluatedWithoutAGlobalUserID() async throws {
        WMFDataEnvironment.current.basicService = WMFMockBasicService(jsonResourceName: "yir-metrics-edit-count-get")
        let controller = YearInReviewEditCountSlideDataController(year: year, yirConfig: config, dependencies: makeDependencies(username: "Editor"))

        let payload = try await populatedPayload(controller)

        XCTAssertNil(payload, "no global user id means no payload")
        XCTAssertFalse(controller.isEvaluated)
    }

    // MARK: - donateCount

    func testDonateCountReportsNoDonationsAndTheEditCount() async throws {
        WMFDataEnvironment.current.basicService = WMFMockBasicService(jsonResourceName: "yir-metrics-edit-count-get")
        let controller = YearInReviewDonateCountSlideDataController(year: year, yirConfig: config, dependencies: makeDependencies(globalUserID: 1))

        let payload = try decode(DonateAndEditCounts.self, from: try await populatedPayload(controller))

        XCTAssertEqual(payload.editCount, 47)
        XCTAssertNil(payload.donateCount, "no local donation history was seeded")
        XCTAssertTrue(controller.isEvaluated)
    }

    func testDonateCountIsEvaluatedForALoggedOutUser() async throws {
        let controller = YearInReviewDonateCountSlideDataController(year: year, yirConfig: config, dependencies: makeDependencies())

        let payload = try decode(DonateAndEditCounts.self, from: try await populatedPayload(controller))

        XCTAssertNil(payload.editCount, "no global user id means no edit count")
        XCTAssertTrue(controller.isEvaluated, "the donations are on the device, so the slide is stored")
    }

    func testDonateCountIsNotEvaluatedWhenTheEditCountFails() async throws {
        WMFDataEnvironment.current.basicService = WMFMockBasicService(jsonResourceName: "missing-resource")
        let controller = YearInReviewDonateCountSlideDataController(year: year, yirConfig: config, dependencies: makeDependencies(globalUserID: 1))

        try await controller.populateSlideData(in: try context())

        XCTAssertFalse(controller.isEvaluated, "the stored slide keeps its last edit count")
    }

    func testDonateCountRequestsTheContribDatesForItsEditCount() async throws {
        let service = WMFRecordingMockBasicService(jsonResourceName: "yir-metrics-edit-count-get")
        WMFDataEnvironment.current.basicService = service
        let controller = YearInReviewDonateCountSlideDataController(year: year, yirConfig: configWithContribDates, dependencies: makeDependencies(globalUserID: 1))

        _ = try await populatedPayload(controller)

        let path = try XCTUnwrap(service.requestedURLs.first?.path)
        XCTAssertTrue(path.hasSuffix("/monthly/20251201/20261201"), "contribStartDate to contribEndDate: \(path)")
    }

    func testDonateCountCountsOnlyDonationsInTheContributorRange() async throws {
        WMFDataEnvironment.current.basicService = WMFMockBasicService(jsonResourceName: "yir-metrics-edit-count-get")
        let timestamps = [
            "2025-11-30T23:59:59Z", // before the range
            "2025-12-01T00:00:00Z", // first moment of the range
            "2026-06-15T12:00:00Z",
            "2026-11-30T23:59:59Z", // last moment of the range
            "2026-12-02T12:00:00Z"  // after the range
        ]
        let donations = timestamps.map {
            WMFDonateLocalHistory(donationTimestamp: $0, donationType: .oneTime, donationAmount: 5, currencyCode: "USD", isNative: true, isFirstDonation: false)
        }
        try WMFDataEnvironment.current.sharedCacheStore?.save(key: WMFSharedCacheDirectoryNames.donorExperience.rawValue, "AppLocalDonationHistory", value: donations)

        let controller = YearInReviewDonateCountSlideDataController(year: year, yirConfig: config, dependencies: makeDependencies(globalUserID: 1))
        let payload = try decode(DonateAndEditCounts.self, from: try await populatedPayload(controller))

        XCTAssertEqual(payload.donateCount, 3, "only the donations from December 1, 2025 to November 30, 2026 count")
    }

    // MARK: - viewCount

    func testViewCountSumsTheMonthlyViewsFromTheMetricsAPI() async throws {
        WMFDataEnvironment.current.basicService = WMFMockBasicService(jsonResourceName: "yir-metrics-edited-page-views-get")
        let controller = YearInReviewViewCountSlideDataController(year: year, yirConfig: config, dependencies: makeDependencies(globalUserID: 1))

        let payload = try decode(WMFYearInReviewViewCountSlideData.self, from: try await populatedPayload(controller))

        XCTAssertEqual(payload.editedPageViewCount, 1234, "1000 + 200 + 34 across the three monthly buckets")
        XCTAssertTrue(controller.isEvaluated)
    }

    func testViewCountRequestsTheEditedPageViewsOfTheGlobalUserInTheContribDates() async throws {
        let service = WMFRecordingMockBasicService(jsonResourceName: "yir-metrics-edited-page-views-get")
        WMFDataEnvironment.current.basicService = service
        let controller = YearInReviewViewCountSlideDataController(year: year, yirConfig: configWithContribDates, dependencies: makeDependencies(globalUserID: 1))

        _ = try await populatedPayload(controller)

        let path = try XCTUnwrap(service.requestedURLs.first?.path)
        XCTAssertTrue(path.hasSuffix("/metrics/pageviews/v3/per_editor/1/monthly/20251201/20261201"), "contribStartDate to contribEndDate: \(path)")
    }

    func testViewCountIsNotEvaluatedWithoutAGlobalUserID() async throws {
        WMFDataEnvironment.current.basicService = WMFMockBasicService(jsonResourceName: "yir-metrics-edited-page-views-get")
        let controller = YearInReviewViewCountSlideDataController(year: year, yirConfig: config, dependencies: makeDependencies(userID: 42))

        let payload = try await populatedPayload(controller)

        XCTAssertNil(payload, "no global user id means no payload")
        XCTAssertFalse(controller.isEvaluated)
    }

    func testViewCountPropagatesAFetchFailure() async throws {
        WMFDataEnvironment.current.basicService = WMFMockBasicService(jsonResourceName: "missing-resource")
        let controller = YearInReviewViewCountSlideDataController(year: year, yirConfig: config, dependencies: makeDependencies(globalUserID: 1))

        do {
            _ = try await populatedPayload(controller)
            XCTFail("the slide must surface a failed fetch")
        } catch {
            XCTAssertFalse(controller.isEvaluated)
        }
    }

    /// Older builds stored a bare Growth page view count (all time, one wiki). It must not pass as
    /// the current format, or a run that cannot fetch the new count would keep it.
    func testViewCountRejectsTheOlderGrowthFormat() throws {
        XCTAssertFalse(YearInReviewViewCountSlideDataController.hasCurrentFormat(try JSONEncoder().encode(Int?.some(5000))))
        XCTAssertFalse(YearInReviewViewCountSlideDataController.hasCurrentFormat(try JSONEncoder().encode(Int?.none)))
        XCTAssertFalse(YearInReviewViewCountSlideDataController.hasCurrentFormat(nil))
        XCTAssertTrue(YearInReviewViewCountSlideDataController.hasCurrentFormat(try JSONEncoder().encode(WMFYearInReviewViewCountSlideData(editedPageViewCount: 5000))))
    }

    // MARK: - mostViewedArticles

    private struct StubUserImpactProvider: YearInReviewUserImpactDataProviding {
        let mostViewedArticles: [WMFYearInReviewMostViewedArticlesSlideData.Article]

        func fetchMostViewedArticles(userID: Int, project: WMFProject, language: String) async throws -> [WMFYearInReviewMostViewedArticlesSlideData.Article] {
            return mostViewedArticles
        }
    }

    func testMostViewedArticlesSortsByViewsAndDropsArticlesWithoutViews() async throws {
        let articles = [
            WMFYearInReviewMostViewedArticlesSlideData.Article(title: "B", projectID: "wikipedia~en", viewsCount: 10),
            WMFYearInReviewMostViewedArticlesSlideData.Article(title: "A", projectID: "wikipedia~en", viewsCount: 10),
            WMFYearInReviewMostViewedArticlesSlideData.Article(title: "C", projectID: "wikipedia~en", viewsCount: 500),
            WMFYearInReviewMostViewedArticlesSlideData.Article(title: "D", projectID: "wikipedia~en", viewsCount: 1),
            WMFYearInReviewMostViewedArticlesSlideData.Article(title: "E", projectID: "wikipedia~en", viewsCount: 0)
        ]
        let controller = YearInReviewMostViewedArticlesSlideDataController(
            year: year,
            yirConfig: config,
            dependencies: makeDependencies(userID: 42, userImpactDataProvider: StubUserImpactProvider(mostViewedArticles: articles))
        )

        let payload = try decode(WMFYearInReviewMostViewedArticlesSlideData.self, from: try await populatedPayload(controller))

        XCTAssertEqual(payload.articles.map(\.title), ["C", "A", "B", "D"], "the slide decides how many it shows")
        XCTAssertTrue(controller.isEvaluated)
    }

    // MARK: - rabbitHoles

    private typealias RabbitHolesData = WMFYearInReviewRabbitHolesSlideData

    private func rabbitHolesPayload(mainPageIdentifier: WMFMainPageIdentifying? = nil) async throws -> RabbitHolesData {
        var dependencies = makeDependencies()
        dependencies.mainPageIdentifier = mainPageIdentifier
        let controller = YearInReviewRabbitHolesSlideDataController(year: year, yirConfig: config, dependencies: dependencies)
        let payload = try decode(RabbitHolesData.self, from: try await populatedPayload(controller))
        XCTAssertTrue(controller.isEvaluated)
        return payload
    }

    /// Opens each title from a link in the one before it, `minutesApart` apart, and returns the last page view.
    @discardableResult
    private func followLinks(_ titles: [String], from start: Date, minutesApart: Double = 5, namespaceIDs: [String: Int16] = [:], after previous: NSManagedObjectID? = nil) async throws -> NSManagedObjectID? {
        let pageViewsDataController = try WMFPageViewsDataController()
        var previousID = previous
        for (index, title) in titles.enumerated() {
            previousID = try await pageViewsDataController.addPageView(title: title, namespaceID: namespaceIDs[title] ?? 0, project: enProject, previousPageViewObjectID: previousID, timestamp: start.addingTimeInterval(Double(index) * minutesApart * 60))
        }
        return previousID
    }

    func testRabbitHolesAreTheTwoDeepestChainsDeepestFirst() async throws {
        try await followLinks(["Moon", "Earth", "Mammal", "Felidae", "Cat"], from: try date(month: 3, day: 1, hour: 9))
        try await followLinks(["Paris", "France", "Europe"], from: try date(month: 4, day: 1, hour: 9))
        try await followLinks(["Rome", "Italy", "Pasta", "Wheat"], from: try date(month: 5, day: 1, hour: 9))

        let payload = try await rabbitHolesPayload()

        XCTAssertEqual(payload.rabbitHoles.map(\.firstArticle.title), ["Moon", "Rome"])
        XCTAssertEqual(payload.rabbitHoles.map(\.lastArticle.title), ["Cat", "Wheat"])
        XCTAssertEqual(payload.rabbitHoles.map(\.articleCount), [5, 4], "the count includes the first and the last article")
        XCTAssertEqual(payload.rabbitHoles.first?.firstArticle.project, enProject)
        XCTAssertTrue(payload.isEligible)
    }

    func testRabbitHolesNeedThreeArticlesAndTwoRabbitHoles() async throws {
        try await followLinks(["Moon", "Earth", "Mammal"], from: try date(month: 3, day: 1, hour: 9))
        try await followLinks(["Paris", "France"], from: try date(month: 4, day: 1, hour: 9))
        try await followLinks(["Rome"], from: try date(month: 5, day: 1, hour: 9))

        let payload = try await rabbitHolesPayload()

        XCTAssertEqual(payload.rabbitHoles.map(\.firstArticle.title), ["Moon"], "two articles are not a rabbit hole")
        XCTAssertFalse(payload.isEligible)
    }

    func testRabbitHolesAreNotEligibleWithNoPageViews() async throws {
        let payload = try await rabbitHolesPayload()

        XCTAssertTrue(payload.rabbitHoles.isEmpty)
        XCTAssertFalse(payload.isEligible)
    }

    func testMoreThanAnHourBetweenArticlesEndsTheRabbitHole() async throws {
        let last = try await followLinks(["Moon", "Earth", "Mammal"], from: try date(month: 3, day: 1, hour: 9))
        // Continues from Mammal 61 minutes later, so Felidae starts a new rabbit hole.
        try await followLinks(["Felidae", "Cat", "Lion"], from: try date(month: 3, day: 1, hour: 9).addingTimeInterval(10 * 60 + 61 * 60), after: last)

        let payload = try await rabbitHolesPayload()

        XCTAssertEqual(payload.rabbitHoles.map(\.articleCount), [3, 3])
        XCTAssertEqual(Set(payload.rabbitHoles.map(\.firstArticle.title)), ["Moon", "Felidae"])
    }

    func testAnHourBetweenArticlesContinuesTheRabbitHole() async throws {
        try await followLinks(["Moon", "Earth", "Mammal"], from: try date(month: 3, day: 1, hour: 9), minutesApart: 60)

        let payload = try await rabbitHolesPayload()

        XCTAssertEqual(payload.rabbitHoles.map(\.articleCount), [3])
    }

    func testAPageOutsideTheMainNamespaceEndsTheRabbitHole() async throws {
        try await followLinks(["Moon", "Earth", "Talk:Earth", "Mammal", "Felidae", "Cat"], from: try date(month: 3, day: 1, hour: 9), namespaceIDs: ["Talk:Earth": 1])

        let payload = try await rabbitHolesPayload()

        XCTAssertEqual(payload.rabbitHoles.map(\.firstArticle.title), ["Mammal"], "a rabbit hole cannot start or end on a talk page")
        XCTAssertEqual(payload.rabbitHoles.map(\.lastArticle.title), ["Cat"])
    }

    func testMainPagesEndTheRabbitHole() async throws {
        try await followLinks(["Main_Page", "Moon", "Earth", "Mammal"], from: try date(month: 3, day: 1, hour: 9))
        try await followLinks(["Hauptseite", "Paris", "France", "Europe"], from: try date(month: 4, day: 1, hour: 9))

        let identifier = StubMainPageIdentifier(mainPages: [(title: "Hauptseite", projectID: enProject.id)])
        let payload = try await rabbitHolesPayload(mainPageIdentifier: identifier)

        XCTAssertEqual(Set(payload.rabbitHoles.map(\.firstArticle.title)), ["Moon", "Paris"])
        XCTAssertEqual(payload.rabbitHoles.map(\.articleCount), [3, 3])
        XCTAssertEqual(identifier.requestedProjectIDs, [enProject.id], "the main page is asked once for each wiki")
    }

    func testTwoBranchesFromOneArticleAreOneRabbitHole() async throws {
        let earth = try await followLinks(["Moon", "Earth"], from: try date(month: 3, day: 1, hour: 9))
        try await followLinks(["Mammal", "Felidae", "Cat"], from: try date(month: 3, day: 1, hour: 9).addingTimeInterval(10 * 60), after: earth)
        try await followLinks(["Ocean", "Whale"], from: try date(month: 3, day: 1, hour: 9).addingTimeInterval(30 * 60), after: earth)

        let payload = try await rabbitHolesPayload()

        XCTAssertEqual(payload.rabbitHoles.map(\.lastArticle.title), ["Cat"], "the deepest branch is the rabbit hole")
        XCTAssertEqual(payload.rabbitHoles.map(\.articleCount), [5])
    }

    func testATieGoesToTheMoreRecentRabbitHole() async throws {
        try await followLinks(["Moon", "Earth", "Mammal"], from: try date(month: 3, day: 1, hour: 9))
        try await followLinks(["Paris", "France", "Europe"], from: try date(month: 4, day: 1, hour: 9))
        try await followLinks(["Rome", "Italy", "Pasta"], from: try date(month: 5, day: 1, hour: 9))

        let payload = try await rabbitHolesPayload()

        XCTAssertEqual(payload.rabbitHoles.map(\.firstArticle.title), ["Rome", "Paris"])
    }

    func testRabbitHolesIgnoreViewsOutsideTheInsightsRange() async throws {
        let outside = try XCTUnwrap(Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 1, hour: 9)))
        try await followLinks(["Moon", "Earth", "Mammal"], from: outside)
        try await followLinks(["Paris", "France", "Europe"], from: try date(month: 4, day: 1, hour: 9))

        let payload = try await rabbitHolesPayload()

        XCTAssertEqual(payload.rabbitHoles.map(\.firstArticle.title), ["Paris"])
    }

    // MARK: - readingPattern

    private typealias ReadingPatternData = WMFYearInReviewReadingPatternSlideData

    private func readingPatternPayload(mainPageIdentifier: WMFMainPageIdentifying? = nil) async throws -> ReadingPatternData {
        var dependencies = makeDependencies()
        dependencies.mainPageIdentifier = mainPageIdentifier
        let controller = YearInReviewReadingPatternSlideDataController(year: year, yirConfig: config, dependencies: dependencies)
        let payload = try decode(ReadingPatternData.self, from: try await populatedPayload(controller))
        XCTAssertTrue(controller.isEvaluated)
        return payload
    }

    private func addRead(_ title: String, namespaceID: Int16 = 0, at date: Date) async throws {
        _ = try await WMFPageViewsDataController().addPageView(title: title, namespaceID: namespaceID, project: enProject, previousPageViewObjectID: nil, timestamp: date)
    }

    private func readDates(hours: [Int], minute: Int = 0, calendar: Calendar = .current) throws -> [Date] {
        try hours.enumerated().map { index, hour in
            try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 3, day: 1 + index, hour: hour, minute: minute)))
        }
    }

    func testReadingPatternFindsTheTimeOfDayWithTheMostReads() async throws {
        try await addRead("Moon", at: try date(month: 2, day: 1, hour: 18))
        try await addRead("Moon", at: try date(month: 2, day: 2, hour: 19))
        try await addRead("Cat", at: try date(month: 2, day: 3, hour: 20))
        try await addRead("Paris", at: try date(month: 2, day: 4, hour: 9))

        let payload = try await readingPatternPayload()

        XCTAssertEqual(payload, ReadingPatternData(timeOfDay: .evenings, timeOfDayReadCount: 3, totalReadCount: 4))
        XCTAssertEqual(payload.share, 0.75)
        XCTAssertTrue(payload.isEligible)
    }

    func testReadingPatternLeavesOutMainPagesAndPagesThatAreNotArticles() async throws {
        try await addRead("Hauptseite", at: try date(month: 2, day: 1, hour: 9))
        try await addRead("Main_Page", at: try date(month: 2, day: 2, hour: 9))
        try await addRead("Talk:Moon", namespaceID: 1, at: try date(month: 2, day: 3, hour: 9))
        try await addRead("Moon", at: try date(month: 2, day: 4, hour: 22))
        try await addRead("Cat", at: try date(month: 2, day: 5, hour: 23))

        let identifier = StubMainPageIdentifier(mainPages: [(title: "Hauptseite", projectID: enProject.id)])
        let payload = try await readingPatternPayload(mainPageIdentifier: identifier)

        XCTAssertEqual(payload, ReadingPatternData(timeOfDay: .nights, timeOfDayReadCount: 2, totalReadCount: 2))
    }

    func testReadingPatternWithoutReadsIsNotEligible() async throws {
        let payload = try await readingPatternPayload()

        XCTAssertEqual(payload, ReadingPatternData(timeOfDay: nil, timeOfDayReadCount: 0, totalReadCount: 0))
        XCTAssertEqual(payload.share, 0)
        XCTAssertFalse(payload.isEligible)
    }

    func testReadingPatternWithOneReadInEachTimeOfDayIsNotEligible() throws {
        let payload = YearInReviewReadingPatternSlideDataController.slideData(readDates: try readDates(hours: [0, 6, 12, 14, 18, 22]), calendar: .current)

        XCTAssertEqual(payload.timeOfDayReadCount, 1)
        XCTAssertEqual(payload.totalReadCount, 6)
        XCTAssertFalse(payload.isEligible, "a time of day needs two reads")
    }

    func testReadingPatternTieGoesToTheEarlierTimeOfDayInTheList() throws {
        let payload = YearInReviewReadingPatternSlideDataController.slideData(readDates: try readDates(hours: [2, 3, 15, 16]), calendar: .current)

        XCTAssertEqual(payload.timeOfDay, .afternoons, "afternoons come before late nights in the list")
        XCTAssertEqual(payload.timeOfDayReadCount, 2)
    }

    /// The first and the last minute of each time of day.
    func testReadingPatternTimeOfDayBounds() throws {
        let bounds: [(hour: Int, minute: Int, timeOfDay: WMFYearInReviewTimeOfDay)] = [
            (0, 0, .lateNights), (4, 59, .lateNights),
            (5, 0, .mornings), (11, 59, .mornings),
            (12, 0, .middays), (12, 59, .middays),
            (13, 0, .afternoons), (16, 59, .afternoons),
            (17, 0, .evenings), (20, 59, .evenings),
            (21, 0, .nights), (23, 59, .nights)
        ]
        for bound in bounds {
            let dates = try readDates(hours: [bound.hour, bound.hour], minute: bound.minute)
            let payload = YearInReviewReadingPatternSlideDataController.slideData(readDates: dates, calendar: .current)
            XCTAssertEqual(payload.timeOfDay, bound.timeOfDay, "\(bound.hour):\(bound.minute)")
        }
    }

    /// The hour comes from the time zone of the calendar, not from UTC.
    func testReadingPatternUsesTheTimeZoneOfTheCalendar() throws {
        var newYork = Calendar(identifier: .gregorian)
        newYork.timeZone = try XCTUnwrap(TimeZone(identifier: "America/New_York"))
        // 19:00 in New York is 23:00 or 0:00 in UTC.
        let dates = try readDates(hours: [19, 19], calendar: newYork)

        XCTAssertEqual(YearInReviewReadingPatternSlideDataController.slideData(readDates: dates, calendar: newYork).timeOfDay, .evenings)
    }

    func testEveryHourHasOneTimeOfDay() {
        for hour in 0..<24 {
            let timesOfDay = WMFYearInReviewTimeOfDay.allCases.filter { $0.hours.contains(hour) }
            XCTAssertEqual(timesOfDay.count, 1, "hour \(hour)")
            XCTAssertEqual(WMFYearInReviewTimeOfDay(hour: hour), timesOfDay.first)
        }
        XCTAssertNil(WMFYearInReviewTimeOfDay(hour: 24))
        XCTAssertNil(WMFYearInReviewTimeOfDay(hour: -1))
    }
}

/// A random number generator that gives the same numbers for the same seed. Tests use it to make a random pick repeatable.
private struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }
}

/// Records the URL of each request, then answers with the JSON resource of `WMFMockBasicService`.
private final class WMFRecordingMockBasicService: WMFService, @unchecked Sendable {
    private let wrapped: WMFMockBasicService
    private let lock = NSLock()
    private var _requestedURLs: [URL] = []

    var requestedURLs: [URL] {
        lock.lock()
        defer { lock.unlock() }
        return _requestedURLs
    }

    init(jsonResourceName: String) {
        self.wrapped = WMFMockBasicService(jsonResourceName: jsonResourceName)
    }

    private func record(_ request: WMFServiceRequest) {
        guard let url = request.url else { return }
        lock.lock()
        _requestedURLs.append(url)
        lock.unlock()
    }

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<Data, Error>) -> Void) {
        record(request)
        wrapped.perform(request: request, completion: completion)
    }

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<[String: Any]?, Error>) -> Void) {
        record(request)
        wrapped.perform(request: request, completion: completion)
    }

    func performDecodableGET<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        record(request)
        wrapped.performDecodableGET(request: request, completion: completion)
    }

    func performDecodablePOST<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        record(request)
        wrapped.performDecodablePOST(request: request, completion: completion)
    }

    func clearCachedData() {}
}
