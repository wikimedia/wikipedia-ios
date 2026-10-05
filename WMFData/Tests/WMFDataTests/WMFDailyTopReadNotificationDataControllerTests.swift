import XCTest
@testable import WMFData
@testable import WMFDataMocks

final class WMFDailyTopReadNotificationDataControllerTests: XCTestCase {

    private let project = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))
    private let bodyFormat = "%1$@ is the top trending article today, tap here to see more"

    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private var scheduler: WMFMockLocalNotificationScheduler!
    private var localNotificationDataController: WMFLocalNotificationDataController!
    private var userDefaultsStore: WMFMockKeyValueStore!
    private var sharedCacheStore: WMFMockKeyValueStore!

    override func setUp() async throws {
        scheduler = WMFMockLocalNotificationScheduler()
        userDefaultsStore = WMFMockKeyValueStore()
        sharedCacheStore = WMFMockKeyValueStore()
        localNotificationDataController = makeLocalNotificationDataController(now: Date())
    }

    // MARK: - Helpers

    private func date(hour: Int, minute: Int = 0, day: Int = 29) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour, minute: minute))!
    }

    private func makeResponse(articles: [(title: String, rank: Int)]) throws -> WMFFeedAPIResponse {
        let articlesJSON = articles.map { #"{"title": "\#($0.title)", "normalizedtitle": "\#($0.title.replacingOccurrences(of: "_", with: " "))", "rank": \#($0.rank)}"# }.joined(separator: ",")
        let json = #"{"mostread": {"date": "2026-09-28Z", "articles": [\#(articlesJSON)]}}"#
        return try JSONDecoder().decode(WMFFeedAPIResponse.self, from: Data(json.utf8))
    }

    /// Instances share the scheduler and stores, like successive launches of the app.
    private func makeLocalNotificationDataController(now: Date) -> WMFLocalNotificationDataController {
        WMFLocalNotificationDataController(scheduler: scheduler, userDefaultsStore: userDefaultsStore, sharedCacheStore: sharedCacheStore, calendar: calendar, now: { now })
    }

    private func makeController(now: Date, response: WMFFeedAPIResponse? = nil, isEnabled: Bool = true) throws -> WMFDailyTopReadNotificationDataController {
        let response = try response ?? makeResponse(articles: [("Second_Article", 2), ("Top_Article", 1)])
        localNotificationDataController = makeLocalNotificationDataController(now: now)
        return WMFDailyTopReadNotificationDataController(
            feedDataController: WMFMockFeedDataController(response: response),
            localNotificationDataController: localNotificationDataController,
            isEnabled: { isEnabled })
    }

    private func loggedEvents() async -> [WMFLocalNotificationLogEntry.Event] {
        await localNotificationDataController.loadLog().map { $0.event }
    }

    // MARK: - Tests

    func testSchedulesTopRankedArticleAtTenAM() async throws {
        let controller = try makeController(now: date(hour: 3))
        await controller.scheduleIfNeeded(project: project, bodyFormat: bodyFormat, appState: "background")

        let added = await scheduler.added
        XCTAssertEqual(added.count, 1)
        XCTAssertEqual(added.first?.identifier, "dailyTopRead-2026-09-29")
        XCTAssertEqual(added.first?.body, "Top Article is the top trending article today, tap here to see more")
        XCTAssertEqual(added.first?.fireDate, date(hour: 10))
        XCTAssertEqual(added.first?.userInfo[WMFLocalNotificationType.userInfoKey], "dailyTopRead")

        let events = await loggedEvents()
        XCTAssertEqual(events, [.attempt, .scheduled])
    }

    func testSchedulesShortlyWhenAfterTenAM() async throws {
        let now = date(hour: 14)
        let controller = try makeController(now: now)
        await controller.scheduleIfNeeded(project: project, bodyFormat: bodyFormat, appState: nil)

        let added = await scheduler.added
        XCTAssertEqual(added.first?.fireDate, now.addingTimeInterval(WMFDailyTopReadNotificationDataController.immediateFireDelay))
    }

    func testSkipsWhenTooLate() async throws {
        let controller = try makeController(now: date(hour: 21))
        await controller.scheduleIfNeeded(project: project, bodyFormat: bodyFormat, appState: nil)

        let added = await scheduler.added
        XCTAssertTrue(added.isEmpty)
        let events = await loggedEvents()
        XCTAssertEqual(events, [.attempt, .skippedTooLate])

        // Day was not marked handled, so the next morning still schedules.
        let nextMorning = try makeController(now: date(hour: 1, day: 30))
        await nextMorning.scheduleIfNeeded(project: project, bodyFormat: bodyFormat, appState: nil)
        let addedNextDay = await scheduler.added
        XCTAssertEqual(addedNextDay.first?.identifier, "dailyTopRead-2026-09-30")
    }

    func testSkipsSecondAttemptSameDay() async throws {
        let controller = try makeController(now: date(hour: 3))
        await controller.scheduleIfNeeded(project: project, bodyFormat: bodyFormat, appState: nil)
        await controller.scheduleIfNeeded(project: project, bodyFormat: bodyFormat, appState: nil)

        let added = await scheduler.added
        XCTAssertEqual(added.count, 1)
        let events = await loggedEvents()
        XCTAssertEqual(events, [.attempt, .scheduled, .attempt, .skippedAlreadyHandled])
    }

    func testSkipsWhenNotAuthorized() async throws {
        await scheduler.setStatus(.denied)
        let controller = try makeController(now: date(hour: 3))
        await controller.scheduleIfNeeded(project: project, bodyFormat: bodyFormat, appState: nil)

        let added = await scheduler.added
        XCTAssertTrue(added.isEmpty)
        let log = await localNotificationDataController.loadLog()
        XCTAssertEqual(log.map { $0.event }, [.attempt, .skippedNotAuthorized])
        XCTAssertEqual(log.last?.authorizationStatus, "denied")
    }

    func testFailsWithNoArticles() async throws {
        let controller = try makeController(now: date(hour: 3), response: makeResponse(articles: []))
        await controller.scheduleIfNeeded(project: project, bodyFormat: bodyFormat, appState: nil)

        let events = await loggedEvents()
        XCTAssertEqual(events, [.attempt, .failedNoContent])
    }

    func testViewingTopReadCancelsAndBlocksScheduling() async throws {
        let controller = try makeController(now: date(hour: 3))
        await controller.scheduleIfNeeded(project: project, bodyFormat: bodyFormat, appState: nil)
        await controller.userDidViewTopRead(appState: "active")

        let removed = await scheduler.removed
        XCTAssertEqual(removed, ["dailyTopRead-2026-09-29"])

        // Viewing Top Read again doesn't log a second cancellation.
        await controller.userDidViewTopRead(appState: "active")
        let events = await loggedEvents()
        XCTAssertEqual(events, [.attempt, .scheduled, .cancelledByUserVisit])
    }

    func testViewingTopReadBeforeRefreshBlocksScheduling() async throws {
        let controller = try makeController(now: date(hour: 3))
        await controller.userDidViewTopRead(appState: "active")
        await controller.scheduleIfNeeded(project: project, bodyFormat: bodyFormat, appState: nil)

        let added = await scheduler.added
        XCTAssertTrue(added.isEmpty)
        let events = await loggedEvents()
        XCTAssertEqual(events, [.attempt, .skippedAlreadyHandled])
    }

    func testLogIsCapped() async throws {
        for _ in 0..<(WMFLocalNotificationDataController.maxLogEntries + 5) {
            await localNotificationDataController.log(WMFLocalNotificationLogEntry(type: .dailyTopRead, event: .attempt))
        }
        let log = await localNotificationDataController.loadLog()
        XCTAssertEqual(log.count, WMFLocalNotificationDataController.maxLogEntries)
    }

    func testLogEntryEncodesReadableDates() throws {
        let entry = WMFLocalNotificationLogEntry(timestamp: date(hour: 3), type: .dailyTopRead, event: .scheduled, fireDate: date(hour: 10))
        let json = try XCTUnwrap(String(data: JSONEncoder().encode(entry), encoding: .utf8))
        XCTAssertTrue(json.contains("2026-09-29T03:00:00Z"))
        XCTAssertTrue(json.contains("2026-09-29T10:00:00Z"))

        let decoded = try JSONDecoder().decode(WMFLocalNotificationLogEntry.self, from: Data(json.utf8))
        XCTAssertEqual(decoded, entry)
    }

    func testResetHandledDaysAllowsSchedulingAgain() async throws {
        let controller = try makeController(now: date(hour: 3))
        await controller.scheduleIfNeeded(project: project, bodyFormat: bodyFormat, appState: nil)
        await localNotificationDataController.resetHandledDays()
        await controller.scheduleIfNeeded(project: project, bodyFormat: bodyFormat, appState: nil)

        let added = await scheduler.added
        XCTAssertEqual(added.count, 2)
    }

    func testExportAndClearLog() async throws {
        await localNotificationDataController.log(WMFLocalNotificationLogEntry(timestamp: date(hour: 3), type: .dailyTopRead, event: .attempt))
        let data = try await localNotificationDataController.exportLogData()
        let exported = try JSONDecoder().decode([WMFLocalNotificationLogEntry].self, from: data)
        XCTAssertEqual(exported.map { $0.event }, [.attempt])

        await localNotificationDataController.clearLog()
        let log = await localNotificationDataController.loadLog()
        XCTAssertTrue(log.isEmpty)
    }

    func testDoesNothingWhenDisabled() async throws {
        let controller = try makeController(now: date(hour: 3), isEnabled: false)
        await controller.scheduleIfNeeded(project: project, bodyFormat: bodyFormat, appState: nil)
        await controller.userDidViewTopRead(appState: "active")

        let added = await scheduler.added
        XCTAssertTrue(added.isEmpty)
        let log = await localNotificationDataController.loadLog()
        XCTAssertTrue(log.isEmpty)
    }

    func testDisablingCancelsPendingNotification() async throws {
        let controller = try makeController(now: date(hour: 3))
        await controller.scheduleIfNeeded(project: project, bodyFormat: bodyFormat, appState: nil)
        await controller.userDidDisable()

        let pending = await scheduler.pending
        XCTAssertTrue(pending.isEmpty)
        let events = await loggedEvents()
        XCTAssertEqual(events, [.attempt, .scheduled, .cancelledByDisable])

        // Nothing left to cancel, so a second disable doesn't log.
        await controller.userDidDisable()
        let eventsAfterSecondDisable = await loggedEvents()
        XCTAssertEqual(eventsAfterSecondDisable, events)
    }

    // MARK: - scheduleDaily

    private struct ContentError: Error { }

    func testScheduleDailyLogsFailedFetchWhenContentThrows() async throws {
        localNotificationDataController = makeLocalNotificationDataController(now: date(hour: 3))
        await localNotificationDataController.scheduleDaily(
            type: .dailyTopRead,
            appState: nil,
            fireDate: { now, _ in now },
            content: { _ in throw ContentError() })

        let added = await scheduler.added
        XCTAssertTrue(added.isEmpty)
        let log = await localNotificationDataController.loadLog()
        XCTAssertEqual(log.map { $0.event }, [.attempt, .failedFetch])
        XCTAssertNotNil(log.last?.error)

        // A failed fetch doesn't mark the day handled, so a later refresh can try again.
        let isHandled = await localNotificationDataController.isHandled(type: .dailyTopRead, day: "2026-09-29")
        XCTAssertFalse(isHandled)
    }

    func testScheduleDailyLogsFailedScheduleAndLeavesDayUnhandled() async throws {
        await scheduler.setAddError(ContentError())
        localNotificationDataController = makeLocalNotificationDataController(now: date(hour: 3))
        await localNotificationDataController.scheduleDaily(
            type: .dailyTopRead,
            appState: nil,
            fireDate: { now, _ in now },
            content: { _ in WMFLocalNotificationContent(title: "Title", body: "Body", logSummary: "Summary") })

        let log = await localNotificationDataController.loadLog()
        XCTAssertEqual(log.map { $0.event }, [.attempt, .failedSchedule])
        XCTAssertEqual(log.last?.contentSummary, "Summary")
        let isHandled = await localNotificationDataController.isHandled(type: .dailyTopRead, day: "2026-09-29")
        XCTAssertFalse(isHandled)
    }

    func testScheduleDailyPassesTitleAndDoesNotFetchContentWhenAlreadyHandled() async throws {
        localNotificationDataController = makeLocalNotificationDataController(now: date(hour: 3))
        await localNotificationDataController.scheduleDaily(
            type: .dailyTopRead,
            appState: nil,
            fireDate: { now, _ in now },
            content: { _ in WMFLocalNotificationContent(title: "Title", body: "Body") })

        let added = await scheduler.added
        XCTAssertEqual(added.first?.title, "Title")

        await localNotificationDataController.scheduleDaily(
            type: .dailyTopRead,
            appState: nil,
            fireDate: { now, _ in now },
            content: { _ in
                XCTFail("Content shouldn't be fetched once the day is handled")
                return nil
            })
    }
}
