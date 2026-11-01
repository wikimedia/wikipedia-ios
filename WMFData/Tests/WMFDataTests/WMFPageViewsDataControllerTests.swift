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
        try await dataController.deleteAllPageViewsCategoriesAndTopics()
        
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

    // MARK: - fetchDistinctPageViewDays(startDate:endDate:calendar:)

    // The window bounds are UTC instants, like the data window in the remote config. These tests use
    // calendars in other time zones, where comparing a local start of day with a bound used to give
    // the wrong answer.

    /// 2026-01-01T00:00:00Z. In the window.
    private var readingDaysWindowStart: Date { Self.utcDate("2026-01-01T00:00:00Z") }

    /// 2026-12-01T00:00:00Z. Out of the window, which is half open.
    private var readingDaysWindowEnd: Date { Self.utcDate("2026-12-01T00:00:00Z") }

    private static func utcDate(_ string: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        guard let date = formatter.date(from: string) else {
            preconditionFailure("Invalid test date: \(string)")
        }
        return date
    }

    private func gregorianCalendar(timeZoneIdentifier: String) throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: timeZoneIdentifier))
        return calendar
    }

    private func addViews(at timestamps: [Date]) async throws {
        for (index, timestamp) in timestamps.enumerated() {
            try await addView(title: "Article \(index)", timestamp: timestamp)
        }
    }

    /// Auckland is UTC+13 in January and in December, so a local day starts 13 hours before UTC does.
    ///
    /// Comparing local starts of day with the bounds got both edges wrong here: local 1 Jan is
    /// 31 Dec in UTC, so it was dropped, and local 1 Dec is 30 Nov in UTC, so it was counted.
    func testReadingDaysEastOfUTCCutsWindowByInstantThenGroupsByLocalDay() async throws {
        guard let dataController else { throw TestsError.missingDataController }
        let auckland = try gregorianCalendar(timeZoneIdentifier: "Pacific/Auckland")

        let justBeforeStart = Self.utcDate("2025-12-31T23:59:59Z")     // 1 Jan 12:59 in Auckland, out
        let atStart = Self.utcDate("2026-01-01T00:00:00Z")             // 1 Jan 13:00 in Auckland, in
        let sameLocalDayAsStart = Self.utcDate("2026-01-01T05:00:00Z") // 1 Jan 18:00 in Auckland, in
        let justBeforeEnd = Self.utcDate("2026-11-30T23:59:59Z")       // 1 Dec 12:59 in Auckland, in
        let atEnd = Self.utcDate("2026-12-01T00:00:00Z")               // 1 Dec 13:00 in Auckland, out

        try await addViews(at: [justBeforeStart, atStart, sameLocalDayAsStart, justBeforeEnd, atEnd])

        let days = try await dataController.fetchDistinctPageViewDays(startDate: readingDaysWindowStart, endDate: readingDaysWindowEnd, calendar: auckland)

        XCTAssertEqual(days, [auckland.startOfDay(for: atStart), auckland.startOfDay(for: justBeforeEnd)])
    }

    /// Los Angeles is UTC-8, so a read at the start of the window is still on 31 Dec locally. The
    /// window is cut by instant, so that read is in, and it is counted on its local day.
    func testReadingDaysWestOfUTCCountsAReadOnItsLocalDay() async throws {
        guard let dataController else { throw TestsError.missingDataController }
        let losAngeles = try gregorianCalendar(timeZoneIdentifier: "America/Los_Angeles")

        let justBeforeStart = Self.utcDate("2025-12-31T23:59:59Z")   // out
        let atStart = Self.utcDate("2026-01-01T00:00:00Z")           // 31 Dec 16:00 in Los Angeles, in
        let atEnd = Self.utcDate("2026-12-01T00:00:00Z")             // out

        try await addViews(at: [justBeforeStart, atStart, atEnd])

        let days = try await dataController.fetchDistinctPageViewDays(startDate: readingDaysWindowStart, endDate: readingDaysWindowEnd, calendar: losAngeles)

        XCTAssertEqual(days, [losAngeles.startOfDay(for: atStart)])
    }

    func testReadingDaysTwoReadsOnTheSameLocalDayCountOnce() async throws {
        guard let dataController else { throw TestsError.missingDataController }
        let auckland = try gregorianCalendar(timeZoneIdentifier: "Pacific/Auckland")

        // 10:00 and 20:00 on 15 Jun in Auckland (UTC+12). In UTC these are 14 Jun 22:00 and 15 Jun 08:00.
        let morning = Self.utcDate("2026-06-14T22:00:00Z")
        let evening = Self.utcDate("2026-06-15T08:00:00Z")

        try await addViews(at: [morning, evening])

        let days = try await dataController.fetchDistinctPageViewDays(startDate: readingDaysWindowStart, endDate: readingDaysWindowEnd, calendar: auckland)

        XCTAssertEqual(days, [auckland.startOfDay(for: morning)])
    }

    /// Control: in UTC, local days and window bounds line up, so nothing shifts.
    func testReadingDaysUTCCalendarMatchesTheWindow() async throws {
        guard let dataController else { throw TestsError.missingDataController }
        let utcCalendar = try gregorianCalendar(timeZoneIdentifier: "UTC")

        let justBeforeStart = Self.utcDate("2025-12-31T23:59:59Z")   // out
        let atStart = Self.utcDate("2026-01-01T00:00:00Z")           // in
        let sameDayAsStart = Self.utcDate("2026-01-01T05:00:00Z")    // in, same day
        let justBeforeEnd = Self.utcDate("2026-11-30T23:59:59Z")     // in
        let atEnd = Self.utcDate("2026-12-01T00:00:00Z")             // out

        try await addViews(at: [justBeforeStart, atStart, sameDayAsStart, justBeforeEnd, atEnd])

        let days = try await dataController.fetchDistinctPageViewDays(startDate: readingDaysWindowStart, endDate: readingDaysWindowEnd, calendar: utcCalendar)

        XCTAssertEqual(days, [utcCalendar.startOfDay(for: atStart), utcCalendar.startOfDay(for: justBeforeEnd)])
    }

    // NOTE: fetchLinkedPageViews() is intentionally left uncovered here. Exercising it with a
    // linked Start -> Middle -> End chain (built via addPageView's previousPageViewObjectID)
    // crashes the test runner when the returned managed objects are accessed off their context's
    // queue. The relationship walk itself completes successfully; track the API issue separately.

}
