import XCTest
@testable import WMFData
@testable import WMFDataMocks
import CoreData

final class WMFYearInReviewUserDataStateTests: XCTestCase {

    private final class MockDeveloperSettingsDataController: WMFDeveloperSettingsDataControlling {
        var forceYiREntryPoint2026 = false
        var forceYiRUserDataState: WMFYearInReviewDataController.YiRUserDataState?
        var forceMaxArticleTabsTo5: Bool { false }
        var forceYiR2026Announcement: Bool { false }
        func loadFeatureConfig() -> WMFFeatureConfigResponse? {
            // Data window 2026-01-01 to 2026-12-01 UTC.
            WMFFeatureConfigResponse(common: WMFFeatureConfigResponse.Common(yir: [.testConfig]), ios: WMFFeatureConfigResponse.IOS(hCaptcha: nil))
        }
    }

    private let project = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))
    private let year = WMFYearInReviewDataController.targetYear

    private var store: WMFCoreDataStore!
    private var developerSettings: MockDeveloperSettingsDataController!
    private var dataController: WMFYearInReviewDataController!
    private var pageViewsDataController: WMFPageViewsDataController!

    override func setUp() async throws {
        try await super.setUp()
        let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        store = try await WMFCoreDataStore(appContainerURL: temporaryDirectory)
        developerSettings = MockDeveloperSettingsDataController()
        dataController = try WMFYearInReviewDataController(coreDataStore: store, userDefaultsStore: WMFMockKeyValueStore(), developerSettingsDataController: developerSettings)
        pageViewsDataController = try WMFPageViewsDataController(coreDataStore: store, userDefaultsStore: WMFMockKeyValueStore())
    }

    /// Noon UTC, to match the UTC data window of the config.
    private func date(month: Int, day: Int, year: Int? = nil) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: DateComponents(year: year ?? self.year, month: month, day: day, hour: 12))!
    }

    private func addPageViews(distinctArticles: Int, on date: Date, prefix: String = "Article") async throws {
        for index in 0..<distinctArticles {
            _ = try await pageViewsDataController.addPageView(title: "\(prefix) \(index)", namespaceID: 0, project: project, previousPageViewObjectID: nil, timestamp: date)
        }
    }

    // MARK: - History proxy

    func testElevenDistinctArticlesIsDataRich() async throws {
        try await addPageViews(distinctArticles: 11, on: date(month: 3, day: 10))
        let state = try await dataController.fetchUserDataState()
        XCTAssertEqual(state, .dataRich)
    }

    func testTenDistinctArticlesIsLowData() async throws {
        try await addPageViews(distinctArticles: 10, on: date(month: 3, day: 10))
        let state = try await dataController.fetchUserDataState()
        XCTAssertEqual(state, .lowData)
    }

    func testRepeatViewsOfOneArticleCountOnce() async throws {
        try await addPageViews(distinctArticles: 10, on: date(month: 3, day: 10))
        for _ in 0..<5 {
            _ = try await pageViewsDataController.addPageView(title: "Article 0", namespaceID: 0, project: project, previousPageViewObjectID: nil, timestamp: date(month: 4, day: 2))
        }
        let state = try await dataController.fetchUserDataState()
        XCTAssertEqual(state, .lowData)
    }

    func testViewsOutsideJanuaryThroughNovemberAreIgnored() async throws {
        try await addPageViews(distinctArticles: 10, on: date(month: 11, day: 30))
        try await addPageViews(distinctArticles: 5, on: date(month: 12, day: 1), prefix: "December")
        try await addPageViews(distinctArticles: 5, on: date(month: 12, day: 31, year: year - 1), prefix: "Last Year")
        let state = try await dataController.fetchUserDataState()
        XCTAssertEqual(state, .lowData)
    }

    // MARK: - Developer settings override

    func testForcedStateWinsWhenYiRToggleIsOn() async throws {
        try await addPageViews(distinctArticles: 11, on: date(month: 3, day: 10))
        developerSettings.forceYiREntryPoint2026 = true
        developerSettings.forceYiRUserDataState = .lowData
        let state = try await dataController.fetchUserDataState()
        XCTAssertEqual(state, .lowData)
    }

    func testNoConfigIsLowData() async throws {
        let dataController = try WMFYearInReviewDataController(coreDataStore: store, userDefaultsStore: WMFMockKeyValueStore(), developerSettingsDataController: WMFMockDeveloperSettingsDataController(featureConfig: WMFFeatureConfigResponse(common: WMFFeatureConfigResponse.Common(yir: []), ios: WMFFeatureConfigResponse.IOS(hCaptcha: nil))))
        try await addPageViews(distinctArticles: 11, on: date(month: 3, day: 10))
        let state = try await dataController.fetchUserDataState()
        XCTAssertEqual(state, .lowData)
    }

    func testForcedStateIsIgnoredWhenYiRToggleIsOff() async throws {
        developerSettings.forceYiREntryPoint2026 = false
        developerSettings.forceYiRUserDataState = .dataRich
        let state = try await dataController.fetchUserDataState()
        XCTAssertEqual(state, .lowData)
    }

    func testNoForcedStateFallsBackToHistoryWhenYiRToggleIsOn() async throws {
        try await addPageViews(distinctArticles: 11, on: date(month: 3, day: 10))
        developerSettings.forceYiREntryPoint2026 = true
        developerSettings.forceYiRUserDataState = nil
        let state = try await dataController.fetchUserDataState()
        XCTAssertEqual(state, .dataRich)
    }
}
