import Foundation
import CoreData
import Testing
import WMFDataTestSupport
@testable import WMFData
@testable import WMFDataMocks

/// Covers the reading time side of WMFPageViewsDataController: how stored seconds are summed for a
/// date range, and the one time clamp of values inflated by the pre July 2026 measurement bug.
@Suite
struct WMFPageViewsReadingTimeTests {

    private let fixture = WMFDataTestFixture()
    private let enProject = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))
    private let dayInSeconds = TimeInterval(60 * 60 * 24)

    /// The cleanup is date bounded, so every test that expects it to run must pin `now` inside the
    /// window. Otherwise these tests would pass until August 31st 2026 and fail from then on.
    private let beforeCutoff = WMFPageViewsDataController.inflatedPageViewSecondsCleanupCutoff.addingTimeInterval(-1)

    private var todayDate: Date {
        return Calendar.current.startOfDay(for: Date())
    }

    private func makeDataController(_ store: WMFCoreDataStore) throws -> WMFPageViewsDataController {
        return try WMFPageViewsDataController(coreDataStore: store, userDefaultsStore: WMFMockKeyValueStore())
    }

    // MARK: - Summing minutes

    @Test
    func fetchPageViewMinutesOnlyCountsPageViewsInDateRange() async throws {
        let store = try await fixture.makeTemporaryCoreDataStore()
        let dataController = try makeDataController(store)

        let insideRangeObjectID = try #require(try await dataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: todayDate.addingTimeInterval(60)))
        let outsideRangeObjectID = try #require(try await dataController.addPageView(title: "Dog", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: todayDate.addingTimeInterval(-10 * dayInSeconds)))

        try await dataController.addPageViewSeconds(pageViewManagedObjectID: insideRangeObjectID, numberOfSeconds: 600)
        try await dataController.addPageViewSeconds(pageViewManagedObjectID: outsideRangeObjectID, numberOfSeconds: 6000)

        // Today plus the six preceding days, matching the Activity tab's weekly window.
        let minutes = try await dataController.fetchPageViewMinutes(
            startDate: todayDate.addingTimeInterval(-6 * dayInSeconds),
            endDate: todayDate.addingTimeInterval(dayInSeconds - 1)
        )

        #expect(minutes == 10, "Only the page view inside the range should be counted.")
    }

    @Test
    func addPageViewSecondsAccumulates() async throws {
        let store = try await fixture.makeTemporaryCoreDataStore()
        let dataController = try makeDataController(store)

        let objectID = try #require(try await dataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: todayDate.addingTimeInterval(60)))

        try await dataController.addPageViewSeconds(pageViewManagedObjectID: objectID, numberOfSeconds: 120)
        try await dataController.addPageViewSeconds(pageViewManagedObjectID: objectID, numberOfSeconds: 180)

        let minutes = try await dataController.fetchPageViewMinutes(startDate: todayDate, endDate: todayDate.addingTimeInterval(dayInSeconds - 1))
        #expect(minutes == 5)
    }

    // MARK: - One time clamp

    @Test
    func clampInflatedPageViewSecondsClampsOnlyImplausibleValues() async throws {
        let store = try await fixture.makeTemporaryCoreDataStore()
        let dataController = try makeDataController(store)
        let ceiling = Int64(WMFPageViewsDataController.inflatedPageViewSecondsCeiling)

        let plausibleObjectID = try #require(try await dataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: todayDate.addingTimeInterval(60)))
        let inflatedObjectID = try #require(try await dataController.addPageView(title: "Dog", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: todayDate.addingTimeInterval(60)))

        // 10 minutes of real reading, and 40 hours that could not have come from one article opening.
        try await dataController.addPageViewSeconds(pageViewManagedObjectID: plausibleObjectID, numberOfSeconds: 600)
        try await dataController.addPageViewSeconds(pageViewManagedObjectID: inflatedObjectID, numberOfSeconds: 40 * 60 * 60)

        let clampedCount = try await dataController.clampInflatedPageViewSecondsIfNeeded(now: beforeCutoff)
        #expect(clampedCount == 1, "Only the implausible page view should be clamped.")

        let plausibleSeconds = try #require(try await storedSeconds(for: plausibleObjectID, in: store))
        let inflatedSeconds = try #require(try await storedSeconds(for: inflatedObjectID, in: store))

        #expect(plausibleSeconds == Int64(600), "Plausible reading time should be left alone.")
        #expect(inflatedSeconds == ceiling, "Inflated reading time should be capped at the ceiling.")
    }

    /// The ceiling is only safe to apply to rows the buggy code wrote. After the cutoff, a device
    /// reaching this build for the first time would otherwise trim a genuine long read.
    @Test
    func clampInflatedPageViewSecondsDoesNothingAfterTheCutoff() async throws {
        let store = try await fixture.makeTemporaryCoreDataStore()
        let dataController = try makeDataController(store)

        let objectID = try #require(try await dataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: todayDate.addingTimeInterval(60)))
        try await dataController.addPageViewSeconds(pageViewManagedObjectID: objectID, numberOfSeconds: 3 * 60 * 60)

        let afterCutoff = WMFPageViewsDataController.inflatedPageViewSecondsCleanupCutoff.addingTimeInterval(1)
        let clampedCount = try await dataController.clampInflatedPageViewSecondsIfNeeded(now: afterCutoff)

        #expect(clampedCount == 0)
        #expect(dataController.didClampInflatedPageViewSeconds() == false, "The cutoff must not consume the one time flag.")

        let seconds = try #require(try await storedSeconds(for: objectID, in: store))
        #expect(seconds == Int64(3 * 60 * 60), "A three hour read after the cutoff must survive intact.")
    }

    @Test
    func clampInflatedPageViewSecondsRunsBeforeTheCutoff() async throws {
        let store = try await fixture.makeTemporaryCoreDataStore()
        let dataController = try makeDataController(store)

        let objectID = try #require(try await dataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: todayDate.addingTimeInterval(60)))
        try await dataController.addPageViewSeconds(pageViewManagedObjectID: objectID, numberOfSeconds: 40 * 60 * 60)

        #expect(try await dataController.clampInflatedPageViewSecondsIfNeeded(now: beforeCutoff) == 1)
    }

    @Test
    func cleanupCutoffIsAugust31st2026() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))

        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: WMFPageViewsDataController.inflatedPageViewSecondsCleanupCutoff)

        #expect(components.year == 2026)
        #expect(components.month == 8)
        #expect(components.day == 31)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
    }

    @Test
    func clampInflatedPageViewSecondsOnlyRunsOnce() async throws {
        let store = try await fixture.makeTemporaryCoreDataStore()
        let dataController = try makeDataController(store)

        let objectID = try #require(try await dataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: todayDate.addingTimeInterval(60)))
        try await dataController.addPageViewSeconds(pageViewManagedObjectID: objectID, numberOfSeconds: 40 * 60 * 60)

        #expect(dataController.didClampInflatedPageViewSeconds() == false)
        #expect(try await dataController.clampInflatedPageViewSecondsIfNeeded(now: beforeCutoff) == 1)
        #expect(dataController.didClampInflatedPageViewSeconds())

        // A legitimately long total accumulated after the migration must survive.
        try await dataController.addPageViewSeconds(pageViewManagedObjectID: objectID, numberOfSeconds: 40 * 60 * 60)
        #expect(try await dataController.clampInflatedPageViewSecondsIfNeeded(now: beforeCutoff) == 0, "The migration should not run a second time.")

        let seconds = try #require(try await storedSeconds(for: objectID, in: store))
        #expect(seconds > Int64(WMFPageViewsDataController.inflatedPageViewSecondsCeiling))
    }

    /// Reads `numberOfSeconds` out of Core Data and returns it. Assertions belong outside the
    /// `perform` closure — `#expect` inside one is not attributed to the running test, so a failure
    /// is reported against «unknown» instead of failing the test that caused it.
    private func storedSeconds(for objectID: NSManagedObjectID, in store: WMFCoreDataStore) async throws -> Int64? {
        let viewContext = try store.viewContext
        return await viewContext.perform {
            return (viewContext.object(with: objectID) as? CDPageView)?.numberOfSeconds
        }
    }
}
