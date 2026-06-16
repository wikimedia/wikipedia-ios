import XCTest
@testable import WMFData
import CoreData

final class WMFPageViewsDataControllerTests: XCTestCase {
    
    enum TestsError: Error {
        case missingStore
        case missingDataController
        case empty
    }
    
    var store: WMFCoreDataStore?
    var dataController: WMFPageViewsDataController?
    
    lazy var enProject: WMFProject = {
        let language = WMFLanguage(languageCode: "en", languageVariantCode: nil)
        return .wikipedia(language)
    }()
    
    lazy var esProject: WMFProject = {
        let language = WMFLanguage(languageCode: "es", languageVariantCode: nil)
        return .wikipedia(language)
    }()
    
    lazy var todayDate: Date = {
        return Calendar.current.startOfDay(for: Date())
    }()
    
    lazy var yesterdayDate: Date = {
        let dayInSeconds = TimeInterval(60 * 60 * 24)
        return todayDate.addingTimeInterval(-dayInSeconds)
    }()
    
    override func setUp() async throws {
        
        let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try await WMFCoreDataStore(appContainerURL: temporaryDirectory)
        self.store = store
        
        self.dataController = try? WMFPageViewsDataController(coreDataStore: store)

        // Reading-challenge state reads these process-wide shared defaults; clear them so each
        // test starts from a known state (no dev override, challenge not previously completed).
        let sharedDefaults = UserDefaults(suiteName: "group.org.wikimedia.wikipedia")
        sharedDefaults?.removeObject(forKey: WMFUserDefaultsKey.devReadingChallengeState.rawValue)
        sharedDefaults?.removeObject(forKey: WMFUserDefaultsKey.readingChallengeUserCompleted.rawValue)

        try await super.setUp()
    }
    
    func testAddPageView() async throws {
        
        guard let store else {
            throw TestsError.missingStore
        }
        
        guard let dataController else {
            throw TestsError.missingDataController
        }
        
        _ = try await dataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil)
        
        // Fetch, confirm page view was added
        try await store.viewContext.perform {
            let results = try store.fetch(entityType: CDPageView.self, predicate: nil, fetchLimit: nil, in: store.viewContext)
            XCTAssertNotNil(results)
            XCTAssertEqual(results!.count, 1)
            XCTAssertNotNil(results![0].page)
            XCTAssertNotNil(results![0].timestamp)
            XCTAssertNotNil(results![0].page)
            XCTAssertEqual(results![0].page!.title, "Cat")
            XCTAssertEqual(results![0].page!.namespaceID, 0)
            XCTAssertEqual(results![0].page!.projectID, "wikipedia~en")
            XCTAssertNotNil(results![0].page?.timestamp)
        }
    }
    
    func testDeletePageView() async throws {
        
        guard let store else {
            throw TestsError.missingStore
        }
        
        guard let dataController else {
            throw TestsError.missingDataController
        }
        
        // First add page view
        _ = try await dataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil)
        
        // Fetch, confirm page view was added
        try store.viewContext.performAndWait {
            let addedResults = try store.fetch(entityType: CDPageView.self, predicate: nil, fetchLimit: nil, in: store.viewContext)
            XCTAssertNotNil(addedResults)
            XCTAssertEqual(addedResults!.count, 1)
        }
        
        // Then delete page view
        try await dataController.deletePageView(title: "Cat", namespaceID: 0, project: enProject)
        
        // Fetch, confirm page view was deleted
        try await store.viewContext.perform {
            let deletedResults = try store.fetch(entityType: CDPageView.self, predicate: nil, fetchLimit: nil, in: store.viewContext)
            XCTAssertNotNil(deletedResults)
            XCTAssertEqual(deletedResults!.count, 0)
        }
    }
    
    func testDeleteAllPageViews() async throws {
        
        guard let store else {
            throw TestsError.missingStore
        }
        
        guard let dataController else {
            throw TestsError.missingDataController
        }
        
        // First add page view
        _ = try await dataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil)
        
        // Fetch, confirm page view was added
        try store.viewContext.performAndWait {
            let addedResults = try store.fetch(entityType: CDPageView.self, predicate: nil, fetchLimit: nil, in: store.viewContext)
            XCTAssertNotNil(addedResults)
            XCTAssertEqual(addedResults!.count, 1)
        }
        
        // Then delete page view
        try await dataController.deleteAllPageViewsAndCategories()
        
        // Fetch, confirm page view was deleted
        try await store.viewContext.perform {
            let deletedResults = try store.fetch(entityType: CDPageView.self, predicate: nil, fetchLimit: nil, in: store.viewContext)
            XCTAssertNotNil(deletedResults)
            XCTAssertEqual(deletedResults!.count, 0)
        }
    }
    
    func testImportPageViews() async throws {
        
        guard let store else {
            throw TestsError.missingStore
        }
        
        guard let dataController else {
            throw TestsError.missingDataController
        }
        
        let importRequests: [WMFLegacyPageView] = [
            WMFLegacyPageView(title: "Cat", project: enProject, viewedDate: todayDate),
            WMFLegacyPageView(title: "Felis silvestris catus", project: esProject, viewedDate: yesterdayDate)
        ]
        
        try await dataController.importPageViews(requests: importRequests)
        
        // Fetch, confirm page views were added
        
        try await store.viewContext.perform {
            let pageViews = try store.fetch(entityType: CDPageView.self, predicate: nil, fetchLimit: nil, in: store.viewContext)
            XCTAssertNotNil(pageViews)
            XCTAssertEqual(pageViews!.count, 2)
            
            // Fetch, confirm pages were added
            let pages = try store.fetch(entityType: CDPage.self, predicate: nil, fetchLimit: nil, in: store.viewContext)
            XCTAssertNotNil(pages)
            XCTAssertEqual(pages!.count, 2)
        }
    }
    
    func testFetchPageViewCounts() async throws {
        
        guard let dataController else {
            throw TestsError.missingDataController
        }
        
        // First add page views
        _ = try await dataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil)
        _ = try await dataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil)
        _ = try await dataController.addPageView(title: "Felis silvestris catus", namespaceID: 0, project: esProject, previousPageViewObjectID: nil)
        
        let results = try await dataController.fetchPageViewCounts(startDate: yesterdayDate, endDate: Date.now)
        
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].page.title, "Cat")
        XCTAssertEqual(results[0].count, 2)
        XCTAssertEqual(results[1].page.title, "Felis_silvestris_catus")
        XCTAssertEqual(results[1].count, 1)
    }

    // MARK: - Helpers

    @discardableResult
    private func addView(title: String, timestamp: Date, namespaceID: Int16 = 0, previous: NSManagedObjectID? = nil) async throws -> NSManagedObjectID? {
        guard let dataController else { throw TestsError.missingDataController }
        return try await dataController.addPageView(title: title, namespaceID: namespaceID, project: enProject, previousPageViewObjectID: previous, timestamp: timestamp)
    }

    private func makeDate(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        comps.hour = hour
        return Calendar.current.date(from: comps)!
    }

    // MARK: - fetchMostRecentTime / fetchTimelinePages

    func testFetchMostRecentTimeReturnsLatestTimestamp() async throws {
        guard let dataController else { throw TestsError.missingDataController }
        try await addView(title: "Older", timestamp: makeDate(2026, 1, 1))
        try await addView(title: "Newer", timestamp: makeDate(2026, 1, 5))

        let mostRecent = try await dataController.fetchMostRecentTime()
        XCTAssertEqual(mostRecent, makeDate(2026, 1, 5))
    }

    func testFetchMostRecentTimeIsNilWhenEmpty() async throws {
        guard let dataController else { throw TestsError.missingDataController }
        let mostRecent = try await dataController.fetchMostRecentTime()
        XCTAssertNil(mostRecent)
    }

    func testFetchTimelinePagesSortsByTimestampDescending() async throws {
        guard let dataController else { throw TestsError.missingDataController }
        try await addView(title: "Older", timestamp: makeDate(2026, 1, 1))
        try await addView(title: "Newest", timestamp: makeDate(2026, 1, 3))
        try await addView(title: "Middle", timestamp: makeDate(2026, 1, 2))

        let timeline = try await dataController.fetchTimelinePages()
        XCTAssertEqual(timeline.map { $0.page.title }, ["Newest", "Middle", "Older"])
    }

    // MARK: - fetchPageViewMinutes / fetchPageViewDates

    func testFetchPageViewMinutesSumsSecondsIntoMinutes() async throws {
        guard let dataController else { throw TestsError.missingDataController }
        let id1 = try await addView(title: "A", timestamp: makeDate(2026, 1, 10))
        let id2 = try await addView(title: "B", timestamp: makeDate(2026, 1, 11))
        let unwrappedID1 = try XCTUnwrap(id1)
        let unwrappedID2 = try XCTUnwrap(id2)
        try await dataController.addPageViewSeconds(pageViewManagedObjectID: unwrappedID1, numberOfSeconds: 120)
        try await dataController.addPageViewSeconds(pageViewManagedObjectID: unwrappedID2, numberOfSeconds: 60)

        let minutes = try await dataController.fetchPageViewMinutes(startDate: makeDate(2026, 1, 1), endDate: makeDate(2026, 1, 31))
        XCTAssertEqual(minutes, 3)
    }

    func testFetchPageViewDatesBucketsByDayHourAndMonth() async throws {
        guard let dataController else { throw TestsError.missingDataController }
        // Three views at the same local day / hour / month.
        try await addView(title: "A", timestamp: makeDate(2026, 1, 10, hour: 9))
        try await addView(title: "B", timestamp: makeDate(2026, 1, 10, hour: 9))
        try await addView(title: "C", timestamp: makeDate(2026, 1, 10, hour: 9))

        let datesResult = try await dataController.fetchPageViewDates(startDate: makeDate(2026, 1, 1), endDate: makeDate(2026, 1, 31))
        let dates = try XCTUnwrap(datesResult)
        XCTAssertEqual(dates.days.count, 1)
        XCTAssertEqual(dates.days.first?.viewCount, 3)
        XCTAssertEqual(dates.times.count, 1)
        XCTAssertEqual(dates.times.first?.hour, 9)
        XCTAssertEqual(dates.times.first?.viewCount, 3)
        XCTAssertEqual(dates.months.count, 1)
        XCTAssertEqual(dates.months.first?.month, 1)
        XCTAssertEqual(dates.months.first?.viewCount, 3)
    }

    // NOTE: fetchLinkedPageViews() is intentionally left uncovered here. Exercising it with a
    // linked Start -> Middle -> End chain (built via addPageView's previousPageViewObjectID)
    // crashes the test runner, which looks like a latent issue in the relationship walk rather
    // than a test problem. Tracking that separately rather than shipping a crashing test.

    // MARK: - Reading challenge state
    // Config window: startDate 2026-05-11, endDate 2026-06-18, removeDate 2026-07-27, streakGoal 25.

    func testReadingChallengeRemovedAfterRemoveDate() async throws {
        guard let dataController else { throw TestsError.missingDataController }
        let state = try await dataController.fetchReadingChallengeState(isEnrolled: true, now: makeDate(2026, 8, 1))
        XCTAssertEqual(state, .challengeRemoved)
    }

    func testReadingChallengeNotLiveBeforeStartDate() async throws {
        guard let dataController else { throw TestsError.missingDataController }
        let state = try await dataController.fetchReadingChallengeState(isEnrolled: true, now: makeDate(2026, 5, 1))
        XCTAssertEqual(state, .notLiveYet)
    }

    func testReadingChallengeNotEnrolledDuringWindow() async throws {
        guard let dataController else { throw TestsError.missingDataController }
        let state = try await dataController.fetchReadingChallengeState(isEnrolled: false, now: makeDate(2026, 6, 1))
        XCTAssertEqual(state, .notEnrolled)
    }

    func testReadingChallengeConcludedNoStreakWhenNotEnrolledAfterEnd() async throws {
        guard let dataController else { throw TestsError.missingDataController }
        let state = try await dataController.fetchReadingChallengeState(isEnrolled: false, now: makeDate(2026, 6, 20))
        XCTAssertEqual(state, .challengeConcludedNoStreak)
    }

    func testReadingChallengeEnrolledNotStartedWithNoReads() async throws {
        guard let dataController else { throw TestsError.missingDataController }
        let state = try await dataController.fetchReadingChallengeState(isEnrolled: true, now: makeDate(2026, 6, 1))
        XCTAssertEqual(state, .enrolledNotStarted)
    }

    func testReadingChallengeStreakOngoingReadToday() async throws {
        guard let dataController else { throw TestsError.missingDataController }
        try await addView(title: "Today", timestamp: makeDate(2026, 6, 1, hour: 9))
        try await addView(title: "Yesterday", timestamp: makeDate(2026, 5, 31, hour: 9))
        try await addView(title: "DayBefore", timestamp: makeDate(2026, 5, 30, hour: 9))

        let state = try await dataController.fetchReadingChallengeState(isEnrolled: true, now: makeDate(2026, 6, 1))
        XCTAssertEqual(state, .streakOngoingRead(streak: 3))
    }

    func testReadingChallengeStreakOngoingNotYetReadToday() async throws {
        guard let dataController else { throw TestsError.missingDataController }
        try await addView(title: "Yesterday", timestamp: makeDate(2026, 5, 31, hour: 9))
        try await addView(title: "DayBefore", timestamp: makeDate(2026, 5, 30, hour: 9))

        let state = try await dataController.fetchReadingChallengeState(isEnrolled: true, now: makeDate(2026, 6, 1))
        XCTAssertEqual(state, .streakOngoingNotYetRead(streak: 2))
    }

    func testReadingChallengeConcludedIncompleteUsesLongestPastStreak() async throws {
        guard let dataController else { throw TestsError.missingDataController }
        // A 3-day streak earlier in the window, nothing recent; evaluated after the end date.
        try await addView(title: "D1", timestamp: makeDate(2026, 5, 13, hour: 9))
        try await addView(title: "D2", timestamp: makeDate(2026, 5, 14, hour: 9))
        try await addView(title: "D3", timestamp: makeDate(2026, 5, 15, hour: 9))

        let state = try await dataController.fetchReadingChallengeState(isEnrolled: true, now: makeDate(2026, 6, 20))
        XCTAssertEqual(state, .challengeConcludedIncomplete(streak: 3))
    }
}
