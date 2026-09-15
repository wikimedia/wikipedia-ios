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

    private let year = 2025
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

    /// A date inside `testConfig`'s data window (2025-01-01 to 2025-12-01).
    private func date(month: Int, day: Int, hour: Int) throws -> Date {
        var components = DateComponents()
        components.year = 2025
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

    func testMostReadDateIsNotEvaluatedWithoutPageViews() async throws {
        let controller = YearInReviewMostReadDateSlideDataController(year: year, yirConfig: config, dependencies: makeDependencies())

        try await controller.populateSlideData(in: try context())

        XCTAssertNil(controller.mostReadDate, "no dates were recorded")
        XCTAssertFalse(controller.isEvaluated)
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

    // MARK: - topArticles

    func testTopArticlesSkipsSingleViewsAndOrdersByCount() async throws {
        var views: [WMFLegacyPageView] = []
        for index in 0..<4 { views.append(pageView("Most_Read", at: try date(month: 4, day: 1 + index, hour: 10))) }
        for index in 0..<2 { views.append(pageView("Second", at: try date(month: 5, day: 1 + index, hour: 10))) }
        views.append(pageView("Read_Once", at: try date(month: 6, day: 1, hour: 10)))
        try await seedPageViews(views)

        let controller = YearInReviewTopReadArticleSlideDataController(year: year, yirConfig: config, dependencies: makeDependencies())
        let articles = try decode([String].self, from: try await populatedPayload(controller))

        XCTAssertEqual(articles.first, "Most Read", "underscores become spaces and the busiest article leads")
        XCTAssertTrue(articles.contains("Second"))
        XCTAssertFalse(articles.contains("Read Once"), "an article read once is excluded")
        XCTAssertLessThanOrEqual(articles.count, 5)
        XCTAssertTrue(controller.isEvaluated)
    }

    // MARK: - mostReadCategories

    func testMostReadCategoriesPrefersNamesWithTwoUnderscoresAndCapsAtFive() async throws {
        // addCategories requires the article's page to exist already, so seed views first.
        let titles = (1...6).map { "Article\($0)" } + ["ArticlePlain"]
        try await seedPageViews(try titles.enumerated().map { index, title in
            pageView(title, at: try date(month: 8, day: 1 + index, hour: 11))
        })

        let categoriesDataController = try WMFCategoriesDataController()
        for index in 1...6 {
            try await categoriesDataController.addCategories(categories: ["Category_Number_\(index)"], articleTitle: "Article\(index)", project: enProject)
        }
        try await categoriesDataController.addCategories(categories: ["Plain"], articleTitle: "ArticlePlain", project: enProject)

        let controller = YearInReviewMostReadCategoriesSlideDataController(year: year, yirConfig: config, dependencies: makeDependencies())
        let categories = try decode([String].self, from: try await populatedPayload(controller))

        XCTAssertEqual(categories.count, 5, "the slide shows at most five categories")
        XCTAssertFalse(categories.contains("Plain"), "a name with fewer than two underscores is filtered out")
        XCTAssertTrue(categories.allSatisfy { !$0.contains("_") }, "underscores become spaces")
        XCTAssertTrue(controller.isEvaluated)
    }

    // MARK: - saveCount

    private final class StubSavedArticleDelegate: SavedArticleSlideDataDelegate {
        let data: SavedArticleSlideData
        init(data: SavedArticleSlideData) { self.data = data }
        func getSavedArticleSlideData(from startDate: Date, to endEnd: Date) async -> SavedArticleSlideData { data }
    }

    func testSaveCountTakesItsPayloadFromTheHostDelegate() async throws {
        let delegate = StubSavedArticleDelegate(data: SavedArticleSlideData(savedArticlesCount: 7, articleTitles: ["A", "B", "C"]))
        let controller = YearInReviewSaveCountSlideDataController(year: year, yirConfig: config, dependencies: makeDependencies(savedSlideDataDelegate: delegate))

        let payload = try decode(SavedArticleSlideData.self, from: try await populatedPayload(controller))

        XCTAssertEqual(payload.savedArticlesCount, 7)
        XCTAssertEqual(payload.articleTitles, ["A", "B", "C"])
        XCTAssertTrue(controller.isEvaluated)
    }

    func testSaveCountIsNotEvaluatedWithoutADelegate() async throws {
        let controller = YearInReviewSaveCountSlideDataController(year: year, yirConfig: config, dependencies: makeDependencies())

        let payload = try await populatedPayload(controller)

        XCTAssertNil(payload, "no delegate means no payload")
        XCTAssertFalse(controller.isEvaluated)
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

    // MARK: - viewCount

    private struct StubUserImpactProvider: YearInReviewUserImpactDataProviding {
        let totalPageviewsCount: Int?
        let error: (any Error)?

        init(totalPageviewsCount: Int?, error: (any Error)? = nil) {
            self.totalPageviewsCount = totalPageviewsCount
            self.error = error
        }

        func fetchTotalPageviewsCount(userID: Int, project: WMFProject, language: String) async throws -> Int? {
            if let error { throw error }
            return totalPageviewsCount
        }
    }

    private struct StubUserImpactError: Error {}

    func testViewCountReportsTheTotalPageviewsOnTheUsersEdits() async throws {
        let controller = YearInReviewViewCountSlideDataController(
            year: year,
            yirConfig: config,
            dependencies: makeDependencies(userID: 42, userImpactDataProvider: StubUserImpactProvider(totalPageviewsCount: 1234))
        )

        let payload = try decode(Int.self, from: try await populatedPayload(controller))

        XCTAssertEqual(payload, 1234)
        XCTAssertTrue(controller.isEvaluated)
    }

    func testViewCountIsNotEvaluatedWithoutAUserID() async throws {
        let controller = YearInReviewViewCountSlideDataController(
            year: year,
            yirConfig: config,
            dependencies: makeDependencies(userImpactDataProvider: StubUserImpactProvider(totalPageviewsCount: 1234))
        )

        let payload = try await populatedPayload(controller)

        XCTAssertNil(payload, "no user id means no payload")
        XCTAssertFalse(controller.isEvaluated)
    }

    func testViewCountPropagatesAFetchFailure() async throws {
        let controller = YearInReviewViewCountSlideDataController(
            year: year,
            yirConfig: config,
            dependencies: makeDependencies(userID: 42, userImpactDataProvider: StubUserImpactProvider(totalPageviewsCount: nil, error: StubUserImpactError()))
        )

        do {
            _ = try await populatedPayload(controller)
            XCTFail("the slide must surface a failed fetch")
        } catch {
            XCTAssertFalse(controller.isEvaluated)
        }
    }
}
