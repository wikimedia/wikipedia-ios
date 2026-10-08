import XCTest
@testable import WMFData
@testable import WMFDataMocks
import CoreData

final class WMFYearInReviewUserDataStateTests: XCTestCase {

    private final class MockDeveloperSettingsDataController: WMFDeveloperSettingsDataControlling {
        var forceYiREntryPoint2026 = false
        var forceYiRExperience: WMFYearInReviewDataController.YiRForcedExperience?
        var forceMaxArticleTabsTo5: Bool { false }
        var forceYiR2026Announcement = false
        func loadFeatureConfig() -> WMFFeatureConfigResponse? {
            // Data window 2026-01-01 to 2026-12-01 UTC.
            WMFFeatureConfigResponse(common: WMFFeatureConfigResponse.Common(yir: [.testConfig]), ios: WMFFeatureConfigResponse.IOS(hCaptcha: nil))
        }
    }

    private let year = WMFYearInReviewDataController.targetYear

    private var store: WMFCoreDataStore!
    private var developerSettings: MockDeveloperSettingsDataController!
    private var dataController: WMFYearInReviewDataController!

    override func setUp() async throws {
        try await super.setUp()
        let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        store = try await WMFCoreDataStore(appContainerURL: temporaryDirectory)
        developerSettings = MockDeveloperSettingsDataController()
        dataController = try WMFYearInReviewDataController(coreDataStore: store, userDefaultsStore: WMFMockKeyValueStore(), developerSettingsDataController: developerSettings)
    }

    // MARK: - Slides

    private func readCountSlide(_ readCount: Int, year: Int? = nil) throws -> WMFYearInReviewSlide {
        let data = try JSONEncoder().encode(WMFYearInReviewReadData(readCount: readCount, minutesRead: 0))
        return WMFYearInReviewSlide(year: year ?? self.year, id: .readCount, data: data)
    }

    private func topArticlesSlide(articleCount: Int) throws -> WMFYearInReviewSlide {
        let articles = (0..<articleCount).map {
            WMFYearInReviewTopArticlesSlideData.Article(title: "Article \($0)", projectID: "wikipedia~en", visitCount: 2)
        }
        let data = try JSONEncoder().encode(WMFYearInReviewTopArticlesSlideData(articles: articles))
        return WMFYearInReviewSlide(year: year, id: .topArticles, data: data)
    }

    private func saveReport(_ slides: [WMFYearInReviewSlide], year: Int? = nil) async throws {
        try await dataController.createNewYearInReviewReport(year: year ?? self.year, slides: slides)
    }

    // MARK: - Slides with enough data

    func testTwoSlidesWithEnoughDataIsDataRich() async throws {
        try await saveReport([try readCountSlide(3), try topArticlesSlide(articleCount: 2)])
        let state = try await dataController.fetchUserDataState()
        XCTAssertEqual(state, .dataRich)
    }

    func testOneSlideWithEnoughDataIsLowData() async throws {
        try await saveReport([try readCountSlide(500), try topArticlesSlide(articleCount: 1)])
        let state = try await dataController.fetchUserDataState()
        XCTAssertEqual(state, .lowData, "the articles visited multiple times slide shows its empty version")
    }

    func testSlidesBelowTheirMinimumAreLowData() async throws {
        try await saveReport([try readCountSlide(2), try topArticlesSlide(articleCount: 1)])
        let state = try await dataController.fetchUserDataState()
        XCTAssertEqual(state, .lowData)
    }

    func testSlidesWithoutDataDoNotCount() async throws {
        try await saveReport([
            try readCountSlide(3),
            WMFYearInReviewSlide(year: year, id: .topArticles, data: nil),
            WMFYearInReviewSlide(year: year, id: .saveCount, data: try JSONEncoder().encode(SavedArticleSlideData(savedArticlesCount: 50, articleTitles: ["A", "B", "C"])))
        ])
        let state = try await dataController.fetchUserDataState()
        XCTAssertEqual(state, .lowData, "slides that are not in the 2026 flow do not count")
    }

    func testNoReportIsLowData() async throws {
        let state = try await dataController.fetchUserDataState()
        XCTAssertEqual(state, .lowData)
    }

    func testAReportForAnotherYearIsIgnored() async throws {
        try await saveReport([try readCountSlide(3, year: year - 1), try topArticlesSlide(articleCount: 2)], year: year - 1)
        let state = try await dataController.fetchUserDataState()
        XCTAssertEqual(state, .lowData)
    }

    // MARK: - Developer settings override

    func testForcedStateWinsWhenYiRToggleIsOn() async throws {
        try await saveReport([try readCountSlide(3), try topArticlesSlide(articleCount: 2)])
        developerSettings.forceYiREntryPoint2026 = true
        developerSettings.forceYiRExperience = .lowData
        let state = try await dataController.fetchUserDataState()
        XCTAssertEqual(state, .lowData)
    }

    func testForcedDataRichWinsWithoutAReport() async throws {
        developerSettings.forceYiREntryPoint2026 = true
        developerSettings.forceYiRExperience = .dataRich
        let state = try await dataController.fetchUserDataState()
        XCTAssertEqual(state, .dataRich)
    }

    func testForcedStateIsIgnoredWhenYiRToggleIsOff() async throws {
        developerSettings.forceYiREntryPoint2026 = false
        developerSettings.forceYiRExperience = .dataRich
        let state = try await dataController.fetchUserDataState()
        XCTAssertEqual(state, .lowData)
    }

    func testNoForcedStateFallsBackToTheReportWhenYiRToggleIsOn() async throws {
        try await saveReport([try readCountSlide(3), try topArticlesSlide(articleCount: 2)])
        developerSettings.forceYiREntryPoint2026 = true
        developerSettings.forceYiRExperience = nil
        let state = try await dataController.fetchUserDataState()
        XCTAssertEqual(state, .dataRich)
    }

    func testAllEmptyStatesIsDataRichWithEmptySlides() async throws {
        try await saveReport([try readCountSlide(2)])
        developerSettings.forceYiREntryPoint2026 = true
        developerSettings.forceYiRExperience = .allEmptyStates
        let state = try await dataController.fetchUserDataState()
        XCTAssertEqual(state, .dataRich, "the empty states belong to the personalized slides")
        XCTAssertTrue(dataController.forcesAllEmptyStates)
    }

    func testAllEmptyStatesIsIgnoredWhenYiRToggleIsOff() async throws {
        developerSettings.forceYiREntryPoint2026 = false
        developerSettings.forceYiRExperience = .allEmptyStates
        let state = try await dataController.fetchUserDataState()
        XCTAssertEqual(state, .lowData)
        XCTAssertFalse(dataController.forcesAllEmptyStates)
    }

    func testOtherForcedExperiencesDoNotForceEmptyStates() {
        developerSettings.forceYiREntryPoint2026 = true
        for experience in [WMFYearInReviewDataController.YiRForcedExperience.dataRich, .lowData] {
            developerSettings.forceYiRExperience = experience
            XCTAssertFalse(dataController.forcesAllEmptyStates, "\(experience)")
        }
    }

    /// Values saved before the All Empty States option still decode.
    func testForcedExperienceKeepsTheStoredRawValues() {
        XCTAssertEqual(WMFYearInReviewDataController.YiRForcedExperience(rawValue: "data-rich"), .dataRich)
        XCTAssertEqual(WMFYearInReviewDataController.YiRForcedExperience(rawValue: "low-data"), .lowData)
    }

    // MARK: - Reading day count

    func testReadingDayCountCountsEachDayOnce() async throws {
        try await addPageViews(distinctArticles: 3, on: date(month: 3, day: 10))
        try await addPageViews(distinctArticles: 1, on: date(month: 4, day: 2), prefix: "April")
        let count = try await dataController.fetchReadingDayCount()
        XCTAssertEqual(count, 2)
    }

    func testReadingDayCountIgnoresDaysOutsideJanuaryThroughNovember() async throws {
        try await addPageViews(distinctArticles: 1, on: date(month: 11, day: 30))
        try await addPageViews(distinctArticles: 1, on: date(month: 12, day: 1), prefix: "December")
        try await addPageViews(distinctArticles: 1, on: date(month: 12, day: 31, year: year - 1), prefix: "Last Year")
        let count = try await dataController.fetchReadingDayCount()
        XCTAssertEqual(count, 1)
    }

    func testReadingDayCountIsZeroWithNoHistory() async throws {
        let count = try await dataController.fetchReadingDayCount()
        XCTAssertEqual(count, 0)
    }

    // MARK: - Forced announcement

    func testForcingFeatureAnnouncementNeedsBothToggles() {
        developerSettings.forceYiREntryPoint2026 = true
        developerSettings.forceYiR2026Announcement = false
        XCTAssertFalse(dataController.isForcingFeatureAnnouncement)

        developerSettings.forceYiREntryPoint2026 = false
        developerSettings.forceYiR2026Announcement = true
        XCTAssertFalse(dataController.isForcingFeatureAnnouncement)

        developerSettings.forceYiREntryPoint2026 = true
        developerSettings.forceYiR2026Announcement = true
        XCTAssertTrue(dataController.isForcingFeatureAnnouncement)
    }
}
