import XCTest
@testable import WMFData
@testable import WMFDataMocks
import CoreData

final class WMFYearInReviewEligibilityTests: XCTestCase {

    private final class MockDeveloperSettingsDataController: WMFDeveloperSettingsDataControlling {
        var forceYiREntryPoint2026 = false
        var forceYiRDataState: WMFYearInReviewDataController.YiRDataState?
        var forceYiRSlidesExperience: WMFYearInReviewDataController.YiRForcedSlidesExperience?
        var forceMaxArticleTabsTo5: Bool { false }
        var forceYiR2026Announcement = false
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

    // MARK: - Helpers

    /// Noon UTC, to match the UTC data window of the config.
    private func date(month: Int, day: Int, year: Int? = nil) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let components = DateComponents(year: year ?? self.year, month: month, day: day, hour: 12)
        return calendar.date(from: components) ?? Date(timeIntervalSince1970: 0)
    }

    private func addPageViews(distinctArticles: Int, on date: Date, prefix: String = "Article", namespaceID: Int16 = 0) async throws {
        for index in 0..<distinctArticles {
            _ = try await pageViewsDataController.addPageView(title: "\(prefix) \(index)", namespaceID: namespaceID, project: project, previousPageViewObjectID: nil, timestamp: date)
        }
    }

    private final class StubMainPageIdentifier: WMFMainPageIdentifying {
        let title: String
        init(title: String) { self.title = title }
        func mainPageTitle(for project: WMFProject) async -> String? { title }
    }

    private func fetchDataState(mainPageIdentifier: WMFMainPageIdentifying? = nil) async throws -> WMFYearInReviewDataController.YiRDataState {
        try await dataController.fetchDataState(mainPageIdentifier: mainPageIdentifier)
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

    private func topTopicsSlide(readCount: Int, hasTopTopic: Bool, runnerUpCount: Int = 0) throws -> WMFYearInReviewSlide {
        typealias SlideData = WMFYearInReviewTopTopicsSlideData
        let article = SlideData.Article(title: "Article", projectID: "wikipedia~en")
        let topTopic = hasTopTopic ? SlideData.TopTopic(topicCount: SlideData.TopicCount(topicID: WMFArticleTopic.history.rawValue, articleCount: 3), firstArticle: article, lastArticle: article) : nil
        let runnerUps = [WMFArticleTopic.biology, .sports, .music].prefix(runnerUpCount).map { SlideData.TopicCount(topicID: $0.rawValue, articleCount: 2) }
        let data = try JSONEncoder().encode(SlideData(readCount: readCount, topTopic: topTopic, runnerUps: runnerUps))
        return WMFYearInReviewSlide(year: year, id: .topTopics, data: data)
    }

    private func editCountSlide(_ editCount: Int) throws -> WMFYearInReviewSlide {
        WMFYearInReviewSlide(year: year, id: .editCount, data: try JSONEncoder().encode(editCount))
    }

    private func daysVisitedSlide(dayCount: Int) throws -> WMFYearInReviewSlide {
        let data = try JSONEncoder().encode(WMFYearInReviewDaysVisitedSlideData(dayCount: dayCount, peakMonth: nil))
        return WMFYearInReviewSlide(year: year, id: .daysVisited, data: data)
    }

    private func saveReport(_ slides: [WMFYearInReviewSlide], year: Int? = nil) async throws {
        try await dataController.createNewYearInReviewReport(year: year ?? self.year, slides: slides)
    }

    // MARK: - Data state

    func testThreeArticlesReadIsDataRich() async throws {
        try await addPageViews(distinctArticles: 3, on: date(month: 3, day: 10))
        let state = try await fetchDataState()
        XCTAssertEqual(state, .dataRich)
    }

    func testTwoArticlesReadIsLowData() async throws {
        try await addPageViews(distinctArticles: 2, on: date(month: 3, day: 10))
        let state = try await fetchDataState()
        XCTAssertEqual(state, .lowData)
    }

    func testNoReadingHistoryIsLowData() async throws {
        let state = try await fetchDataState()
        XCTAssertEqual(state, .lowData)
    }

    func testOneArticleReadManyTimesCountsOnce() async throws {
        for day in 1...5 {
            try await addPageViews(distinctArticles: 1, on: date(month: 3, day: day))
        }
        let state = try await fetchDataState()
        XCTAssertEqual(state, .lowData)
    }

    func testADuplicatePageRowCountsOnce() async throws {
        try await addPageViews(distinctArticles: 2, on: date(month: 3, day: 10))
        // CDPage has no uniqueness constraint, so two concurrent fetchOrCreate calls can make a second row.
        let store = try XCTUnwrap(store)
        let context = try store.newBackgroundContext
        let timestamp = date(month: 3, day: 11)
        let projectID = project.id
        try await context.perform {
            let page = try store.create(entityType: CDPage.self, in: context)
            page.title = "Article 0".normalizedForCoreData
            page.namespaceID = 0
            page.projectID = projectID
            page.timestamp = timestamp

            let pageView = try store.create(entityType: CDPageView.self, in: context)
            pageView.timestamp = timestamp
            pageView.page = page

            try store.saveIfNeeded(moc: context)
        }
        let state = try await fetchDataState()
        XCTAssertEqual(state, .lowData)
    }

    func testArticlesOutsideJanuaryThroughNovemberDoNotCount() async throws {
        try await addPageViews(distinctArticles: 2, on: date(month: 11, day: 30))
        try await addPageViews(distinctArticles: 1, on: date(month: 12, day: 1), prefix: "December")
        try await addPageViews(distinctArticles: 1, on: date(month: 12, day: 31, year: year - 1), prefix: "Last Year")
        let state = try await fetchDataState()
        XCTAssertEqual(state, .lowData)
    }

    func testPagesOutsideTheMainNamespaceDoNotCount() async throws {
        try await addPageViews(distinctArticles: 2, on: date(month: 3, day: 10))
        try await addPageViews(distinctArticles: 1, on: date(month: 3, day: 10), prefix: "Talk", namespaceID: 1)
        let state = try await fetchDataState()
        XCTAssertEqual(state, .lowData)
    }

    func testTheMainPageDoesNotCount() async throws {
        try await addPageViews(distinctArticles: 3, on: date(month: 3, day: 10))
        let state = try await fetchDataState(mainPageIdentifier: StubMainPageIdentifier(title: "Article 0"))
        XCTAssertEqual(state, .lowData)
    }

    func testDataStateIgnoresSlideEligibility() async throws {
        try await saveReport([try readCountSlide(500), try topArticlesSlide(articleCount: 5), try daysVisitedSlide(dayCount: 30)])
        let state = try await fetchDataState()
        XCTAssertEqual(state, .lowData, "only the local reading history decides the data state")
    }

    func testForcedDataStateWinsWhenYiRToggleIsOn() async throws {
        try await addPageViews(distinctArticles: 3, on: date(month: 3, day: 10))
        developerSettings.forceYiREntryPoint2026 = true
        developerSettings.forceYiRDataState = .lowData
        let state = try await fetchDataState()
        XCTAssertEqual(state, .lowData)
    }

    func testForcedDataStateIsIgnoredWhenYiRToggleIsOff() async throws {
        developerSettings.forceYiREntryPoint2026 = false
        developerSettings.forceYiRDataState = .dataRich
        let state = try await fetchDataState()
        XCTAssertEqual(state, .lowData)
    }

    func testForcedSlidesExperienceDoesNotChangeTheDataState() async throws {
        developerSettings.forceYiREntryPoint2026 = true
        developerSettings.forceYiRSlidesExperience = .personalized
        let state = try await fetchDataState()
        XCTAssertEqual(state, .lowData)
    }

    // MARK: - Slides experience

    func testTwoSlidesWithEnoughDataIsPersonalized() async throws {
        try await saveReport([try readCountSlide(3), try topArticlesSlide(articleCount: 2)])
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .personalized)
    }

    func testLoggedOutIsAlwaysCollective() async throws {
        try await saveReport([try readCountSlide(500), try topArticlesSlide(articleCount: 5), try daysVisitedSlide(dayCount: 30)])
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: false)
        XCTAssertEqual(experience, .collective)
    }

    func testOneSlideWithEnoughDataIsCollective() async throws {
        try await saveReport([try readCountSlide(500), try topArticlesSlide(articleCount: 1)])
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .collective, "the articles visited multiple times slide shows its empty version")
    }

    func testTopTopicSlideWithEnoughDataCountsTowardPersonalized() async throws {
        try await saveReport([try readCountSlide(5), try topTopicsSlide(readCount: 5, hasTopTopic: true)])
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .personalized)
    }

    func testAnEditCountsAsAPersonalizedSlide() async throws {
        try await saveReport([try readCountSlide(3), try editCountSlide(1)])
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .personalized, "an editor with one reading slide gets the personalized slides, the same as on Android")
    }

    func testZeroEditsDoNotCount() async throws {
        try await saveReport([try readCountSlide(3), try editCountSlide(0)])
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .collective)
    }

    func testEditsDoNotChangeTheLoggedOutSlides() async throws {
        try await saveReport([try readCountSlide(3), try editCountSlide(10)])
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: false)
        XCTAssertEqual(experience, .collective)
    }

    func testTopTopicAndRunnersUpCountAsTwoSlides() async throws {
        try await saveReport([try readCountSlide(2), try topTopicsSlide(readCount: 2, hasTopTopic: true, runnerUpCount: 2)])
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .personalized, "the top topic and the runners-up are two slides, the same as on Android")
    }

    func testTopTopicWithOneRunnerUpCountsAsOneSlide() async throws {
        try await saveReport([try readCountSlide(2), try topTopicsSlide(readCount: 2, hasTopTopic: true, runnerUpCount: 1)])
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .collective, "one runner-up does not show the runners-up slide")
    }

    func testTopTopicSlideWithoutATopTopicIsNotEnoughData() async throws {
        try await saveReport([try readCountSlide(500), try topTopicsSlide(readCount: 500, hasTopTopic: false)])
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .collective, "the top topic slide shows its empty version")
    }

    func testDaysVisitedSlideWithEnoughDataCountsTowardPersonalized() async throws {
        try await saveReport([try readCountSlide(3), try daysVisitedSlide(dayCount: 2)])
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .personalized)
    }

    func testDaysVisitedSlideWithOneDayIsNotEnoughData() async throws {
        try await saveReport([try readCountSlide(500), try daysVisitedSlide(dayCount: 1)])
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .collective, "the days visited slide does not show")
    }

    func testSlidesBelowTheirMinimumAreCollective() async throws {
        try await saveReport([try readCountSlide(2), try topArticlesSlide(articleCount: 1)])
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .collective)
    }

    func testSlidesWithoutDataDoNotCount() async throws {
        try await saveReport([
            try readCountSlide(3),
            WMFYearInReviewSlide(year: year, id: .topArticles, data: nil),
            WMFYearInReviewSlide(year: year, id: .saveCount, data: try JSONEncoder().encode(SavedArticleSlideData(savedArticlesCount: 50, articleTitles: ["A", "B", "C"])))
        ])
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .collective, "slides that are not in the 2026 flow do not count")
    }

    func testNoReportIsCollective() async throws {
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .collective)
    }

    func testAReportForAnotherYearIsIgnored() async throws {
        try await saveReport([try readCountSlide(3, year: year - 1), try topArticlesSlide(articleCount: 2)], year: year - 1)
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .collective)
    }

    func testSlidesExperienceIgnoresTheDataState() async throws {
        try await addPageViews(distinctArticles: 3, on: date(month: 3, day: 10))
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .collective, "a data-rich reader without slide data sees the collective slides")
    }

    // MARK: - Developer settings override

    func testForcedSlidesExperienceWinsWhenYiRToggleIsOn() async throws {
        try await saveReport([try readCountSlide(3), try topArticlesSlide(articleCount: 2)])
        developerSettings.forceYiREntryPoint2026 = true
        developerSettings.forceYiRSlidesExperience = .collective
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .collective)
    }

    func testForcedPersonalizedWinsForALoggedOutReader() async throws {
        developerSettings.forceYiREntryPoint2026 = true
        developerSettings.forceYiRSlidesExperience = .personalized
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: false)
        XCTAssertEqual(experience, .personalized)
    }

    func testForcedSlidesExperienceIsIgnoredWhenYiRToggleIsOff() async throws {
        developerSettings.forceYiREntryPoint2026 = false
        developerSettings.forceYiRSlidesExperience = .personalized
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .collective)
    }

    func testNoForcedSlidesExperienceFallsBackToTheReportWhenYiRToggleIsOn() async throws {
        try await saveReport([try readCountSlide(3), try topArticlesSlide(articleCount: 2)])
        developerSettings.forceYiREntryPoint2026 = true
        developerSettings.forceYiRSlidesExperience = nil
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .personalized)
    }

    func testForcedDataStateDoesNotChangeTheSlides() async throws {
        developerSettings.forceYiREntryPoint2026 = true
        developerSettings.forceYiRDataState = .dataRich
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .collective)
    }

    func testAllEmptyStatesIsPersonalizedWithEmptySlides() async throws {
        try await saveReport([try readCountSlide(2)])
        developerSettings.forceYiREntryPoint2026 = true
        developerSettings.forceYiRSlidesExperience = .allEmptyStates
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .personalized, "the empty states belong to the personalized slides")
        XCTAssertTrue(dataController.forcesAllEmptyStates)
    }

    func testAllEmptyStatesIsIgnoredWhenYiRToggleIsOff() async throws {
        developerSettings.forceYiREntryPoint2026 = false
        developerSettings.forceYiRSlidesExperience = .allEmptyStates
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .collective)
        XCTAssertFalse(dataController.forcesAllEmptyStates)
    }

    func testOtherForcedSlidesExperiencesDoNotForceEmptyStates() {
        developerSettings.forceYiREntryPoint2026 = true
        for experience in [WMFYearInReviewDataController.YiRForcedSlidesExperience.personalized, .collective] {
            developerSettings.forceYiRSlidesExperience = experience
            XCTAssertFalse(dataController.forcesAllEmptyStates, "\(experience)")
        }
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
