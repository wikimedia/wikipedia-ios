import XCTest
@testable import WMFData
import CoreData

final class WMFPageTopicsDataControllerTests: XCTestCase {

    enum TestsError: Error {
        case missingStore
        case missingDataController
    }

    var store: WMFCoreDataStore?
    var dataController: WMFPageTopicsDataController?
    var pageViewsDataController: WMFPageViewsDataController?

    lazy var enProject: WMFProject = {
        let language = WMFLanguage(languageCode: "en", languageVariantCode: nil)
        return .wikipedia(language)
    }()

    lazy var todayDate: Date = {
        return Calendar.current.startOfDay(for: Date())
    }()

    lazy var yesterdayDate: Date = {
        let dayInSeconds = TimeInterval(60 * 60 * 24)
        return todayDate.addingTimeInterval(-dayInSeconds)
    }()

    lazy var lastWeekDate: Date = {
        let weekInSeconds = TimeInterval(60 * 60 * 24 * 7)
        return todayDate.addingTimeInterval(-weekInSeconds)
    }()

    override func setUp() async throws {

        let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try await WMFCoreDataStore(appContainerURL: temporaryDirectory)
        self.store = store

        self.dataController = try? WMFPageTopicsDataController(coreDataStore: store)
        self.pageViewsDataController = try? WMFPageViewsDataController(coreDataStore: store)

        try await super.setUp()
    }

    // MARK: - Sanitizing

    func testSanitizeDropsEmptyTopics() {
        let topics = [
            WMFPageTopic(topic: "STEM.Biology", score: 0.9),
            WMFPageTopic(topic: "", score: 0.8),
            WMFPageTopic(topic: "   ", score: 0.7)
        ]

        let results = WMFPageTopicsDataController.sanitized(topics)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].topic, "STEM.Biology")
    }

    func testSanitizeDedupesKeepingHighestScore() {
        let topics = [
            WMFPageTopic(topic: "Biography.Women", score: 0.4),
            WMFPageTopic(topic: "Biography.Women", score: 0.92),
            WMFPageTopic(topic: "Biography.Women", score: 0.6)
        ]

        let results = WMFPageTopicsDataController.sanitized(topics)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].score, 0.92, accuracy: 0.0001)
    }

    func testSanitizeSortsByScoreDescendingAndCapsAtFive() {
        let topics = [
            WMFPageTopic(topic: "One", score: 0.1),
            WMFPageTopic(topic: "Two", score: 0.2),
            WMFPageTopic(topic: "Three", score: 0.3),
            WMFPageTopic(topic: "Four", score: 0.4),
            WMFPageTopic(topic: "Five", score: 0.5),
            WMFPageTopic(topic: "Six", score: 0.6),
            WMFPageTopic(topic: "Seven", score: 0.7)
        ]

        let results = WMFPageTopicsDataController.sanitized(topics)

        XCTAssertEqual(results.count, 5)
        XCTAssertEqual(results.map { $0.topic }, ["Seven", "Six", "Five", "Four", "Three"])
    }

    // MARK: - Saving

    func testSavePageTopicsAndFetch() async throws {

        guard let dataController else {
            throw TestsError.missingDataController
        }

        try await dataController.savePageTopics(title: "Cat", namespaceID: 0, project: enProject, topics: [
            WMFPageTopic(topic: "STEM.Biology", score: 0.7),
            WMFPageTopic(topic: "Culture.Internet culture", score: 0.9)
        ])

        let results = try await dataController.fetchTopics(title: "Cat", namespaceID: 0, project: enProject)

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].topic, "Culture.Internet culture")
        XCTAssertEqual(results[0].score, 0.9, accuracy: 0.0001)
        XCTAssertEqual(results[1].topic, "STEM.Biology")
    }

    func testSavePageTopicsReplacesPreviousTopics() async throws {

        guard let store, let dataController else {
            throw TestsError.missingStore
        }

        try await dataController.savePageTopics(title: "Cat", namespaceID: 0, project: enProject, topics: [
            WMFPageTopic(topic: "STEM.Biology", score: 0.7),
            WMFPageTopic(topic: "History and Society.History", score: 0.5)
        ])

        try await dataController.savePageTopics(title: "Cat", namespaceID: 0, project: enProject, topics: [
            WMFPageTopic(topic: "STEM.Biology", score: 0.8)
        ])

        let results = try await dataController.fetchTopics(title: "Cat", namespaceID: 0, project: enProject)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].topic, "STEM.Biology")
        XCTAssertEqual(results[0].score, 0.8, accuracy: 0.0001)

        // No stale rows left behind in the store
        try await store.viewContext.perform {
            let cdTopics = try store.fetch(entityType: CDPageTopic.self, predicate: nil, fetchLimit: nil, in: store.viewContext)
            XCTAssertEqual(cdTopics?.count, 1)
        }
    }

    func testSaveEmptyPageTopicsLeavesExistingTopicsAlone() async throws {

        guard let dataController else {
            throw TestsError.missingDataController
        }

        try await dataController.savePageTopics(title: "Cat", namespaceID: 0, project: enProject, topics: [
            WMFPageTopic(topic: "STEM.Biology", score: 0.7)
        ])

        try await dataController.savePageTopics(title: "Cat", namespaceID: 0, project: enProject, topics: [])

        let results = try await dataController.fetchTopics(title: "Cat", namespaceID: 0, project: enProject)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].topic, "STEM.Biology")
    }

    func testSavePageTopicsBeforePageViewSharesTheSamePage() async throws {

        guard let store, let dataController, let pageViewsDataController else {
            throw TestsError.missingStore
        }

        // Topics can arrive before the page view is written
        try await dataController.savePageTopics(title: "Cat", namespaceID: 0, project: enProject, topics: [
            WMFPageTopic(topic: "STEM.Biology", score: 0.7)
        ])

        _ = try await pageViewsDataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil)

        try await store.viewContext.perform {
            let pages = try store.fetch(entityType: CDPage.self, predicate: nil, fetchLimit: nil, in: store.viewContext)
            XCTAssertEqual(pages?.count, 1)
            XCTAssertEqual(pages?.first?.topics?.count, 1)
            XCTAssertEqual(pages?.first?.pageViews?.count, 1)
        }
    }

    // MARK: - Aggregates

    func testFetchTopTopicsCountsRepeatedlyReadArticlesOnce() async throws {

        guard let dataController, let pageViewsDataController else {
            throw TestsError.missingDataController
        }

        // "Cat" is read three times for 30 seconds each, "Dog" once for 10 seconds
        for _ in 0..<3 {
            let objectID = try await pageViewsDataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: yesterdayDate)
            if let objectID {
                try await pageViewsDataController.addPageViewSeconds(pageViewManagedObjectID: objectID, numberOfSeconds: 30)
            }
        }

        let dogObjectID = try await pageViewsDataController.addPageView(title: "Dog", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: yesterdayDate)
        if let dogObjectID {
            try await pageViewsDataController.addPageViewSeconds(pageViewManagedObjectID: dogObjectID, numberOfSeconds: 10)
        }

        try await dataController.savePageTopics(title: "Cat", namespaceID: 0, project: enProject, topics: [WMFPageTopic(topic: "STEM.Biology", score: 0.9)])
        try await dataController.savePageTopics(title: "Dog", namespaceID: 0, project: enProject, topics: [WMFPageTopic(topic: "STEM.Biology", score: 0.8)])

        let results = try await dataController.fetchTopTopicsByArticleCount(startDate: lastWeekDate, endDate: Date(), limit: 10)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].topic, "STEM.Biology")

        // Two distinct articles, despite four page views
        XCTAssertEqual(results[0].articleCount, 2)

        // Seconds are totalled per article, not multiplied by the number of views
        XCTAssertEqual(results[0].timeSpentSeconds, 100)
    }

    func testFetchTopTopicsOrdering() async throws {

        guard let dataController, let pageViewsDataController else {
            throw TestsError.missingDataController
        }

        // Two short reads about "Popular", one long read about "Absorbing"
        for title in ["Cat", "Dog"] {
            let objectID = try await pageViewsDataController.addPageView(title: title, namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: yesterdayDate)
            if let objectID {
                try await pageViewsDataController.addPageViewSeconds(pageViewManagedObjectID: objectID, numberOfSeconds: 5)
            }
            try await dataController.savePageTopics(title: title, namespaceID: 0, project: enProject, topics: [WMFPageTopic(topic: "Popular", score: 0.9)])
        }

        let objectID = try await pageViewsDataController.addPageView(title: "Physics", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: yesterdayDate)
        if let objectID {
            try await pageViewsDataController.addPageViewSeconds(pageViewManagedObjectID: objectID, numberOfSeconds: 600)
        }
        try await dataController.savePageTopics(title: "Physics", namespaceID: 0, project: enProject, topics: [WMFPageTopic(topic: "Absorbing", score: 0.9)])

        let byCount = try await dataController.fetchTopTopicsByArticleCount(startDate: lastWeekDate, endDate: Date(), limit: 10)
        XCTAssertEqual(byCount.map { $0.topic }, ["Popular", "Absorbing"])

        let byTimeSpent = try await dataController.fetchTopTopicsByTimeSpent(startDate: lastWeekDate, endDate: Date(), limit: 10)
        XCTAssertEqual(byTimeSpent.map { $0.topic }, ["Absorbing", "Popular"])

        let limited = try await dataController.fetchTopTopicsByArticleCount(startDate: lastWeekDate, endDate: Date(), limit: 1)
        XCTAssertEqual(limited.map { $0.topic }, ["Popular"])
    }

    func testFetchTopTopicsExcludesReadingOutsideThePeriod() async throws {

        guard let dataController, let pageViewsDataController else {
            throw TestsError.missingDataController
        }

        _ = try await pageViewsDataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: lastWeekDate)
        try await dataController.savePageTopics(title: "Cat", namespaceID: 0, project: enProject, topics: [WMFPageTopic(topic: "STEM.Biology", score: 0.9)])

        let results = try await dataController.fetchTopTopicsByArticleCount(startDate: yesterdayDate, endDate: Date(), limit: 10)

        XCTAssertEqual(results.count, 0)
    }

    func testFetchPagesForTopic() async throws {

        guard let dataController, let pageViewsDataController else {
            throw TestsError.missingDataController
        }

        _ = try await pageViewsDataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: lastWeekDate)
        _ = try await pageViewsDataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: yesterdayDate)
        _ = try await pageViewsDataController.addPageView(title: "Dog", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: todayDate)
        _ = try await pageViewsDataController.addPageView(title: "Physics", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: todayDate)

        try await dataController.savePageTopics(title: "Cat", namespaceID: 0, project: enProject, topics: [WMFPageTopic(topic: "STEM.Biology", score: 0.9)])
        try await dataController.savePageTopics(title: "Dog", namespaceID: 0, project: enProject, topics: [WMFPageTopic(topic: "STEM.Biology", score: 0.8)])
        try await dataController.savePageTopics(title: "Physics", namespaceID: 0, project: enProject, topics: [WMFPageTopic(topic: "STEM.Physics", score: 0.8)])

        let results = try await dataController.fetchPages(forTopic: "STEM.Biology", startDate: lastWeekDate.addingTimeInterval(-1), endDate: Date(), limit: 10)

        // Most recent first, and "Cat" appears once despite two views
        XCTAssertEqual(results.map { $0.page.title }, ["Dog", "Cat"])
        XCTAssertEqual(results[1].timestamp, yesterdayDate)

        let limited = try await dataController.fetchPages(forTopic: "STEM.Biology", startDate: lastWeekDate.addingTimeInterval(-1), endDate: Date(), limit: 1)
        XCTAssertEqual(limited.map { $0.page.title }, ["Dog"])
    }

    // MARK: - Deleting

    func testDeletePageViewDeletesItsTopics() async throws {

        guard let store, let dataController, let pageViewsDataController else {
            throw TestsError.missingStore
        }

        _ = try await pageViewsDataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil)
        try await dataController.savePageTopics(title: "Cat", namespaceID: 0, project: enProject, topics: [WMFPageTopic(topic: "STEM.Biology", score: 0.9)])
        try await dataController.savePageTopics(title: "Dog", namespaceID: 0, project: enProject, topics: [WMFPageTopic(topic: "STEM.Biology", score: 0.8)])

        try await pageViewsDataController.deletePageView(title: "Cat", namespaceID: 0, project: enProject)

        let catTopics = try await dataController.fetchTopics(title: "Cat", namespaceID: 0, project: enProject)
        XCTAssertEqual(catTopics.count, 0)

        // Other articles are untouched
        try await store.viewContext.perform {
            let cdTopics = try store.fetch(entityType: CDPageTopic.self, predicate: nil, fetchLimit: nil, in: store.viewContext)
            XCTAssertEqual(cdTopics?.count, 1)
        }
    }

    func testDeleteAllPageViewsCategoriesAndTopics() async throws {

        guard let store, let dataController, let pageViewsDataController else {
            throw TestsError.missingStore
        }

        _ = try await pageViewsDataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil)
        try await dataController.savePageTopics(title: "Cat", namespaceID: 0, project: enProject, topics: [WMFPageTopic(topic: "STEM.Biology", score: 0.9)])

        try await pageViewsDataController.deleteAllPageViewsCategoriesAndTopics()

        try await store.viewContext.perform {
            let cdTopics = try store.fetch(entityType: CDPageTopic.self, predicate: nil, fetchLimit: nil, in: store.viewContext)
            XCTAssertEqual(cdTopics?.count, 0)
        }
    }
}
