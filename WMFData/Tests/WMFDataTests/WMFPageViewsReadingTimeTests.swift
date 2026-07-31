import Foundation
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
        let ceiling = Int64(WMFPageViewsDataController.maximumReadingIntervalSeconds)

        let plausibleObjectID = try #require(try await dataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: todayDate.addingTimeInterval(60)))
        let inflatedObjectID = try #require(try await dataController.addPageView(title: "Dog", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: todayDate.addingTimeInterval(60)))

        // 10 minutes of real reading, and 40 hours that could not have come from one article opening.
        try await dataController.addPageViewSeconds(pageViewManagedObjectID: plausibleObjectID, numberOfSeconds: 600)
        try await dataController.addPageViewSeconds(pageViewManagedObjectID: inflatedObjectID, numberOfSeconds: 40 * 60 * 60)

        let clampedCount = try await dataController.clampInflatedPageViewSecondsIfNeeded()
        #expect(clampedCount == 1, "Only the implausible page view should be clamped.")

        let viewContext = try store.viewContext
        await viewContext.perform {
            let plausible = viewContext.object(with: plausibleObjectID) as? CDPageView
            let inflated = viewContext.object(with: inflatedObjectID) as? CDPageView
            #expect(plausible?.numberOfSeconds == 600, "Plausible reading time should be left alone.")
            #expect(inflated?.numberOfSeconds == ceiling, "Inflated reading time should be capped at the ceiling.")
        }
    }

    @Test
    func clampInflatedPageViewSecondsOnlyRunsOnce() async throws {
        let store = try await fixture.makeTemporaryCoreDataStore()
        let dataController = try makeDataController(store)

        let objectID = try #require(try await dataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: todayDate.addingTimeInterval(60)))
        try await dataController.addPageViewSeconds(pageViewManagedObjectID: objectID, numberOfSeconds: 40 * 60 * 60)

        #expect(dataController.didClampInflatedPageViewSeconds() == false)
        #expect(try await dataController.clampInflatedPageViewSecondsIfNeeded() == 1)
        #expect(dataController.didClampInflatedPageViewSeconds())

        // A legitimately long total accumulated after the migration must survive.
        try await dataController.addPageViewSeconds(pageViewManagedObjectID: objectID, numberOfSeconds: 40 * 60 * 60)
        #expect(try await dataController.clampInflatedPageViewSecondsIfNeeded() == 0, "The migration should not run a second time.")

        let viewContext = try store.viewContext
        await viewContext.perform {
            let pageView = viewContext.object(with: objectID) as? CDPageView
            #expect(pageView?.numberOfSeconds ?? 0 > Int64(WMFPageViewsDataController.maximumReadingIntervalSeconds))
        }
    }
}
