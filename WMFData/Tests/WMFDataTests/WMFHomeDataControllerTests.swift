import XCTest
import CoreData

@testable import WMFData
@testable import WMFDataMocks

final class WMFHomeDataControllerTests: XCTestCase {

    private let enProject = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    override func setUp() async throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try await WMFCoreDataStore(appContainerURL: temporaryDirectory)
        WMFDataEnvironment.current.coreDataStore = store
    }

    override func tearDown() async throws {
        WMFDataEnvironment.current.coreDataStore = nil
    }

    private var dec11: Date {
        var components = DateComponents()
        components.year = 2025
        components.month = 12
        components.day = 11
        return Calendar(identifier: .gregorian).date(from: components)!
    }

    private var dec10: Date {
        var components = DateComponents()
        components.year = 2025
        components.month = 12
        components.day = 10
        return Calendar(identifier: .gregorian).date(from: components)!
    }

    private let stubResponse = WMFFeedAPIResponse(todaysFeaturedArticle: nil, mostRead: nil, image: nil, news: nil)

    private func makeController() -> (WMFHomeDataController, WMFMockFeedDataController) {
        let spy = WMFMockFeedDataController(response: stubResponse)
        let controller = WMFHomeDataController(feedDataController: spy)
        return (controller, spy)
    }

    // MARK: - fetchForYou

    private func makeForYouController(topics: [WMFArticleTopic], relatedPagesDataController: WMFRelatedPagesDataController = WMFRelatedPagesDataController(basicService: WMFMockBasicService(jsonResourceName: "related-pages-get"))) -> WMFHomeDataController {
        let store = WMFMockKeyValueStore()
        let service = WMFMockBasicService(jsonResourceName: "random-articles-get")
        let controller = WMFHomeDataController(
            feedDataController: WMFMockFeedDataController(response: stubResponse),
            basicService: service,
            userDefaultsStore: store,
            relatedPagesDataController: relatedPagesDataController,
            savedArticlesDataController: WMFSavedArticlesDataController()
        )
        controller.setInterestTopics(topics)
        return controller
    }

    private func seedPageInterests(_ titles: [String], project: WMFProject) async throws {
        let pageInterestController = try WMFPageInterestDataController()
        for title in titles {
            try await pageInterestController.addPageInterest(title: title, project: project)
        }
    }

    func testFetchForYouReturnsEmptyPageInterestArticlesWhenNoPageInterestsSaved() async throws {
        let controller = makeForYouController(topics: [])
        let response = try await controller.fetchForYou(project: enProject)
        XCTAssertTrue(response.interestPageRelatedArticles.isEmpty)
    }

    func testFetchForYouReturnsOneGroupPerPageInterest() async throws {
        try await seedPageInterests(["Cat", "Dog", "Fish"], project: enProject)
        let controller = makeForYouController(topics: [])
        let response = try await controller.fetchForYou(project: enProject)
        XCTAssertEqual(response.interestPageRelatedArticles.count, 3)
        let returnedTitles = Set(response.interestPageRelatedArticles.map { $0.pageInterest.title })
        XCTAssertEqual(returnedTitles, ["Cat", "Dog", "Fish"])
    }

    func testFetchForYouCapsAtFivePageInterests() async throws {
        try await seedPageInterests(["Cat", "Dog", "Fish", "Bird", "Lizard", "Snake", "Frog"], project: enProject)
        let controller = makeForYouController(topics: [])
        let response = try await controller.fetchForYou(project: enProject)
        XCTAssertEqual(response.interestPageRelatedArticles.count, 5)
    }

    func testFetchForYouCapsAtFourRelatedArticlesPerPageInterest() async throws {
        try await seedPageInterests(["Cat"], project: enProject)
        let controller = makeForYouController(topics: [])
        let response = try await controller.fetchForYou(project: enProject)
        XCTAssertEqual(response.interestPageRelatedArticles.count, 1)
        XCTAssertLessThanOrEqual(response.interestPageRelatedArticles[0].articles.count, 4)
    }

    func testFetchForYouPageInterestArticlesAreIsolatedByProject() async throws {
        let esProject = WMFProject.wikipedia(WMFLanguage(languageCode: "es", languageVariantCode: nil))
        try await seedPageInterests(["Cat"], project: enProject)
        let controller = makeForYouController(topics: [])
        let response = try await controller.fetchForYou(project: esProject)
        XCTAssertTrue(response.interestPageRelatedArticles.isEmpty)
    }

    // MARK: - fetchForYou becauseYouReadArticles

    private func seedPageViews(_ titles: [String], project: WMFProject, seconds: Double = 90) async throws {
        let pageViewsController = try WMFPageViewsDataController()
        for title in titles {
            if let objectID = try await pageViewsController.addPageView(title: title, namespaceID: 0, project: project, previousPageViewObjectID: nil) {
                try await pageViewsController.addPageViewSeconds(pageViewManagedObjectID: objectID, numberOfSeconds: seconds)
            }
        }
    }

    func testFetchForYouBecauseYouReadArticlesIsNilWhenNoPageViewsExist() async throws {
        let controller = makeForYouController(topics: [])
        let response = try await controller.fetchForYou(project: enProject)
        XCTAssertNil(response.becauseYouReadArticles)
    }

    func testFetchForYouBecauseYouReadArticlesIsNilWhenPageViewsUnderTenSeconds() async throws {
        let pageViewsController = try WMFPageViewsDataController()
        if let objectID = try await pageViewsController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil) {
            try await pageViewsController.addPageViewSeconds(pageViewManagedObjectID: objectID, numberOfSeconds: 5)
        }
        let controller = makeForYouController(topics: [])
        let response = try await controller.fetchForYou(project: enProject)
        XCTAssertNil(response.becauseYouReadArticles)
    }

    func testFetchForYouBecauseYouReadArticlesPopulatedWhenPageViewExists() async throws {
        try await seedPageViews(["Cat"], project: enProject)
        let controller = makeForYouController(topics: [])
        let response = try await controller.fetchForYou(project: enProject)
        XCTAssertNotNil(response.becauseYouReadArticles)
        XCTAssertEqual(response.becauseYouReadArticles?.recentlyRead.title, "Cat")
    }

    func testFetchForYouBecauseYouReadArticlesCapsAtFourRelatedArticles() async throws {
        try await seedPageViews(["Cat"], project: enProject)
        let controller = makeForYouController(topics: [])
        let response = try await controller.fetchForYou(project: enProject)
        XCTAssertLessThanOrEqual(response.becauseYouReadArticles?.articles.count ?? 0, 4)
    }

    func testFetchForYouBecauseYouReadArticlesIsNilForNonMatchingProject() async throws {
        let esProject = WMFProject.wikipedia(WMFLanguage(languageCode: "es", languageVariantCode: nil))
        try await seedPageViews(["Cat"], project: enProject)
        let controller = makeForYouController(topics: [])
        let response = try await controller.fetchForYou(project: esProject)
        XCTAssertNil(response.becauseYouReadArticles)
    }

    func testFetchForYouThrowsWhenCoreDataUnavailable() async throws {
        WMFDataEnvironment.current.coreDataStore = nil
        let controller = makeForYouController(topics: [])
        do {
            _ = try await controller.fetchForYou(project: enProject)
            XCTFail("Expected coreDataStoreUnavailable error")
        } catch WMFDataControllerError.coreDataStoreUnavailable {
            // expected
        }
    }

    // MARK: - fetchForYou continueReading

    private func seedSavedArticles(_ titles: [String], project: WMFProject, savedDate: Date = Date()) async throws {
        guard let store = WMFDataEnvironment.current.coreDataStore else { return }
        let context = try store.newBackgroundContext
        try await context.perform {
            for title in titles {
                let page = try store.create(entityType: CDPage.self, in: context)
                page.title = title
                page.namespaceID = 0
                page.projectID = project.id
                page.timestamp = savedDate

                let savedInfo = try store.create(entityType: CDPageSavedInfo.self, in: context)
                savedInfo.savedDate = savedDate
                savedInfo.page = page
            }
            try store.saveIfNeeded(moc: context)
        }
    }

    func testFetchForYouContinueReadingIsNilWhenNoPageViewsExist() async throws {
        let controller = makeForYouController(topics: [])
        let response = try await controller.fetchForYou(project: enProject)
        XCTAssertNil(response.continueReadingArticles)
    }

    func testFetchForYouContinueReadingIsNilWhenPageViewsUnderSixtySeconds() async throws {
        let pageViewsController = try WMFPageViewsDataController()
        if let objectID = try await pageViewsController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil) {
            try await pageViewsController.addPageViewSeconds(pageViewManagedObjectID: objectID, numberOfSeconds: 30)
        }
        let controller = makeForYouController(topics: [])
        let response = try await controller.fetchForYou(project: enProject)
        XCTAssertNil(response.continueReadingArticles)
    }

    func testFetchForYouContinueReadingIsPopulatedWhenPageViewQualifies() async throws {
        try await seedPageViews(["Cat"], project: enProject, seconds: 90)
        let controller = makeForYouController(topics: [])
        let response = try await controller.fetchForYou(project: enProject)
        XCTAssertNotNil(response.continueReadingArticles)
        XCTAssertEqual(response.continueReadingArticles?.continueReadingArticle.title, "Cat")
    }

    func testFetchForYouContinueReadingCapsAtThreeSavedArticles() async throws {
        try await seedPageViews(["Cat"], project: enProject, seconds: 90)
        try await seedSavedArticles(["Article1", "Article2", "Article3", "Article4"], project: enProject)
        let controller = makeForYouController(topics: [])
        let response = try await controller.fetchForYou(project: enProject)
        XCTAssertEqual(response.continueReadingArticles?.savedArticles.count, 3)
    }

    func testFetchForYouReturnsOneGroupPerTopicWhenFewerThanFive() async throws {
        let topics: [WMFArticleTopic] = [.history, .biology, .music]
        let controller = makeForYouController(topics: topics)
        let response = try await controller.fetchForYou(project: enProject)
        XCTAssertEqual(response.interestTopicRandomArticles.count, 3)
        let returnedTopics = Set(response.interestTopicRandomArticles.map { $0.topic })
        XCTAssertEqual(returnedTopics, Set(topics))
    }

    func testFetchForYouCapsAtFiveTopics() async throws {
        let topics: [WMFArticleTopic] = [.history, .biology, .music, .films, .sports, .physics, .technology]
        let controller = makeForYouController(topics: topics)
        let response = try await controller.fetchForYou(project: enProject)
        XCTAssertEqual(response.interestTopicRandomArticles.count, 5)
    }

    func testFetchForYouCapsAtFourArticlesPerTopic() async throws {
        let controller = makeForYouController(topics: [.history])
        let response = try await controller.fetchForYou(project: enProject)
        XCTAssertEqual(response.interestTopicRandomArticles.count, 1)
        XCTAssertLessThanOrEqual(response.interestTopicRandomArticles[0].articles.count, 4)
    }

    func testFetchForYouFailsForNonWikipediaProject() async throws {
        let controller = makeForYouController(topics: [.history])
        do {
            _ = try await controller.fetchForYou(project: .commons)
            XCTFail("Expected unsupportedProject error")
        } catch WMFDataControllerError.unsupportedProject {
            // expected
        }
    }

    // MARK: - fetchCommunity

    func testFetchCommunitySucceeds() async throws {
        let (controller, _) = makeController()
        _ = try await controller.fetchCommunity(project: enProject, date: dec11)
    }

    func testFetchCommunityRequestsCorrectDate() async throws {
        let (controller, spy) = makeController()
        _ = try await controller.fetchCommunity(project: enProject, date: dec11)
        let calls = await spy.calls
        XCTAssertEqual(calls.count, 1)
        XCTAssertTrue(Calendar(identifier: .gregorian).isDate(calls[0].date, inSameDayAs: dec11))
    }

    func testFetchCommunityDeduplicatesSameDay() async throws {
        let (controller, spy) = makeController()
        _ = try await controller.fetchCommunity(project: enProject, date: dec11)
        _ = try await controller.fetchCommunity(project: enProject, date: dec10)
        _ = try await controller.fetchCommunity(project: enProject, date: dec10) // duplicate — should not be recorded
        // fetchedDates should be [Dec 11, Dec 10]; previousPage anchors off Dec 10 → Dec 9.
        _ = try await controller.fetchCommunityPreviousPage(project: enProject)
        let calls = await spy.calls
        let calendar = Calendar(identifier: .gregorian)
        var dec9Components = DateComponents()
        dec9Components.year = 2025
        dec9Components.month = 12
        dec9Components.day = 9
        let dec9 = calendar.date(from: dec9Components)!
        XCTAssertEqual(calls.count, 4)
        XCTAssertTrue(calendar.isDate(calls[3].date, inSameDayAs: dec9))
    }

    func testFetchCommunityFailsForNonWikipediaProject() async throws {
        let controller = WMFHomeDataController(feedDataController: WMFFeedDataController())
        do {
            _ = try await controller.fetchCommunity(project: .commons, date: dec11)
            XCTFail("Expected unsupportedProject error")
        } catch WMFDataControllerError.unsupportedProject {
            // expected
        }
    }

    // MARK: - fetchCommunityPreviousPage

    func testFetchPreviousPageThrowsWithoutInitialFetch() async throws {
        let (controller, _) = makeController()
        do {
            _ = try await controller.fetchCommunityPreviousPage(project: enProject)
            XCTFail("Expected noFetchedDatesAvailable error")
        } catch WMFHomeDataControllerError.noFetchedDatesAvailable {
            // expected
        }
    }

    func testFetchPreviousPageIsIsolatedByProject() async throws {
        let esProject = WMFProject.wikipedia(WMFLanguage(languageCode: "es", languageVariantCode: nil))
        let (controller, _) = makeController()
        _ = try await controller.fetchCommunity(project: enProject, date: dec11)
        // Fetching en on Dec 11 should not seed the es project's date history.
        do {
            _ = try await controller.fetchCommunityPreviousPage(project: esProject)
            XCTFail("Expected noFetchedDatesAvailable error")
        } catch WMFHomeDataControllerError.noFetchedDatesAvailable {
            // expected
        }
    }

    func testFetchPreviousPageRequestsPreviousDate() async throws {
        let (controller, spy) = makeController()
        _ = try await controller.fetchCommunity(project: enProject, date: dec11)
        _ = try await controller.fetchCommunityPreviousPage(project: enProject)
        let calls = await spy.calls
        XCTAssertEqual(calls.count, 2)
        XCTAssertTrue(Calendar(identifier: .gregorian).isDate(calls[1].date, inSameDayAs: dec10))
    }
}
