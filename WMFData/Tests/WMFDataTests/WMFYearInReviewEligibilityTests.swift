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

    private func donateCountSlide(editCount: Int?) throws -> WMFYearInReviewSlide {
        WMFYearInReviewSlide(year: year, id: .donateCount, data: try JSONEncoder().encode(DonateAndEditCounts(donateCount: 0, editCount: editCount)))
    }

    private func viewCountSlide(_ viewCount: Int) throws -> WMFYearInReviewSlide {
        WMFYearInReviewSlide(year: year, id: .viewCount, data: try JSONEncoder().encode(WMFYearInReviewViewCountSlideData(editedPageViewCount: viewCount)))
    }

    private func mostViewedArticlesSlide() throws -> WMFYearInReviewSlide {
        let article = WMFYearInReviewMostViewedArticlesSlideData.Article(title: "Dam", projectID: "wikipedia~en", viewsCount: 800)
        return WMFYearInReviewSlide(year: year, id: .mostViewedArticles, data: try JSONEncoder().encode(WMFYearInReviewMostViewedArticlesSlideData(articles: [article])))
    }

    private func daysVisitedSlide(dayCount: Int) throws -> WMFYearInReviewSlide {
        let data = try JSONEncoder().encode(WMFYearInReviewDaysVisitedSlideData(dayCount: dayCount, peakMonth: nil))
        return WMFYearInReviewSlide(year: year, id: .daysVisited, data: data)
    }

    private func readingStreakSlide(dayCount: Int) throws -> WMFYearInReviewSlide {
        let day = WMFYearInReviewReadingStreakSlideData.Day(year: year, month: 3, day: 4)
        let data = try JSONEncoder().encode(WMFYearInReviewReadingStreakSlideData(dayCount: dayCount, firstDay: day, lastDay: day))
        return WMFYearInReviewSlide(year: year, id: .readingStreak, data: data)
    }

    private func biggestReadingDaySlide(minuteCount: Int, articleCount: Int) throws -> WMFYearInReviewSlide {
        let articles = (0..<min(articleCount, 3)).map { ["title": "Article \($0)", "projectID": "wikipedia~en"] }
        let json: [String: Any] = ["year": 2026, "month": 3, "day": 7, "minuteCount": minuteCount, "articleCount": articleCount, "articles": articles]
        return WMFYearInReviewSlide(year: year, id: .biggestReadingDay, data: try JSONSerialization.data(withJSONObject: json))
    }

    private func nicheInterestSlide(categoryName: String?) throws -> WMFYearInReviewSlide {
        let data = try JSONEncoder().encode(WMFYearInReviewNicheCategorySlideData(categoryName: categoryName))
        return WMFYearInReviewSlide(year: year, id: .mostReadCategories, data: data)
    }

    private func rabbitHolesSlide(count: Int) throws -> WMFYearInReviewSlide {
        typealias SlideData = WMFYearInReviewRabbitHolesSlideData
        let article = SlideData.Article(title: "Article", projectID: "wikipedia~en")
        let rabbitHoles = Array(repeating: SlideData.RabbitHole(firstArticle: article, lastArticle: article, articleCount: 3), count: count)
        let data = try JSONEncoder().encode(SlideData(rabbitHoles: rabbitHoles, deepestIsOnTop: true))
        return WMFYearInReviewSlide(year: year, id: .rabbitHoles, data: data)
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

    func testNicheInterestSlideWithACategoryCountsTowardPersonalized() async throws {
        try await saveReport([try readCountSlide(3), try nicheInterestSlide(categoryName: "Executed female serial killers")])
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .personalized)
    }

    func testNicheInterestSlideWithoutACategoryDoesNotCount() async throws {
        try await saveReport([try readCountSlide(3), try nicheInterestSlide(categoryName: nil)])
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .collective, "the niche interest slide does not show")
    }

    func testZeroEditsDoNotCount() async throws {
        try await saveReport([try readCountSlide(3), try editCountSlide(0)])
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .collective)
    }

    func testEditViewsAndMostViewedArticlesCountAfterAnEdit() async throws {
        try await saveReport([try editCountSlide(1), try viewCountSlide(26), try mostViewedArticlesSlide()])
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .personalized)
    }

    /// The app hides these slides without an edit in the period, so they must not count. Otherwise a
    /// past editor gets the personalized flow and sees only empty slides.
    func testEditViewsAndMostViewedArticlesDoNotCountWithoutAnEdit() async throws {
        try await saveReport([try editCountSlide(0), try viewCountSlide(500), try mostViewedArticlesSlide()])
        var experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .collective)

        try await saveReport([try viewCountSlide(500), try mostViewedArticlesSlide()])
        experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .collective, "no stored edit count")
    }

    /// The app reads the edit count from the donate count slide when the edit count slide is
    /// missing, so the count must too. Otherwise the app shows edit slides that are not counted.
    func testTheEditCountInTheDonateCountSlideCountsLikeTheEditCountSlide() async throws {
        try await saveReport([try donateCountSlide(editCount: 12), try viewCountSlide(26), try mostViewedArticlesSlide()])
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .personalized, "the edits, edit views and most-viewed articles slides show")
    }

    func testTheEditCountSlideWinsOverTheDonateCountSlide() throws {
        let slides = [try editCountSlide(0), try donateCountSlide(editCount: 12)]
        XCTAssertEqual(try WMFYearInReviewDataController.editCount(in: slides), 0)
        XCTAssertEqual(try WMFYearInReviewDataController.editCount(in: [try donateCountSlide(editCount: 12)]), 12)
        XCTAssertNil(try WMFYearInReviewDataController.editCount(in: [try donateCountSlide(editCount: nil)]))
        XCTAssertNil(try WMFYearInReviewDataController.editCount(in: [try readCountSlide(3)]))
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

    func testReadingStreakOfThreeDaysCountsTowardPersonalized() async throws {
        try await saveReport([try readCountSlide(3), try readingStreakSlide(dayCount: 3)])
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .personalized)
    }

    /// The day slide and the articles slide count as two slides, the same as on Android.
    func testBiggestReadingDayWithTwoArticlesCountsAsTwoSlides() async throws {
        try await saveReport([try biggestReadingDaySlide(minuteCount: 45, articleCount: 2)])
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .personalized)
    }

    func testReadingStreakOfTwoDaysIsNotEnoughData() async throws {
        try await saveReport([try readCountSlide(3), try readingStreakSlide(dayCount: 2)])
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .collective, "the reading streak slide shows its empty version")
    }

    func testBiggestReadingDayWithOneArticleCountsAsOneSlide() async throws {
        try await saveReport([try biggestReadingDaySlide(minuteCount: 45, articleCount: 1)])
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .collective, "only the day slide shows")
    }

    func testBiggestReadingDayOverTheMaximumIsNotEnoughData() async throws {
        try await saveReport([try readCountSlide(500), try biggestReadingDaySlide(minuteCount: 300_001, articleCount: 3)])
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .collective, "neither biggest reading day slide shows")
    }

    func testTwoRabbitHolesCountAsOneSlide() async throws {
        try await saveReport([try readCountSlide(2), try rabbitHolesSlide(count: 2)])
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .collective, "the reveal replaces the guess in place, so they are one slide")
    }

    func testRabbitHolesCountTowardPersonalized() async throws {
        try await saveReport([try readCountSlide(3), try rabbitHolesSlide(count: 2)])
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .personalized)
    }

    func testOneRabbitHoleIsNotEnoughData() async throws {
        try await saveReport([try readCountSlide(500), try rabbitHolesSlide(count: 1)])
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .collective, "the rabbit hole slides do not show")
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
            WMFYearInReviewSlide(year: year, id: .viewCount, data: try JSONEncoder().encode(50))
        ])
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .collective, "slides that are not in the 2026 flow do not count")
    }

    func testSavedSlideWithASavedArticleCountsTowardPersonalized() async throws {
        let savedData = SavedArticleSlideData(savedArticlesCount: 1, articles: [
            SavedArticleSlideData.Article(title: "A", pageTitle: "A", articleDescription: nil, projectID: "wikipedia~en")
        ])
        try await saveReport([
            try readCountSlide(3),
            WMFYearInReviewSlide(year: year, id: .saveCount, data: try JSONEncoder().encode(savedData))
        ])
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .personalized)
    }

    func testSavedSlideWithoutSavedArticlesDoesNotCount() async throws {
        try await saveReport([
            try readCountSlide(3),
            WMFYearInReviewSlide(year: year, id: .saveCount, data: try JSONEncoder().encode(SavedArticleSlideData(savedArticlesCount: 0, articles: [])))
        ])
        let experience = try await dataController.fetchSlidesExperience(isLoggedIn: true)
        XCTAssertEqual(experience, .collective)
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
