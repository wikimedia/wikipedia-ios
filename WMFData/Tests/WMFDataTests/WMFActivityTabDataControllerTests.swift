import Foundation
import Testing
import WMFDataTestSupport
@testable import WMFData

@Suite
struct WMFActivityTabDataControllerTests {

    private let fixture = WMFDataTestFixture()
    private let enProject = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    /// The window the Activity tab labels as a week must be seven days, not eight. Reading from
    /// seven days ago is outside it; reading from six days ago is inside.
    @Test
    func timeReadPast7DaysCoversSevenDays() async throws {
        let store = try await fixture.makeTemporaryCoreDataStore()

        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let sixDaysAgo = try #require(calendar.date(byAdding: .day, value: -6, to: startOfToday)?.addingTimeInterval(3600))
        let sevenDaysAgo = try #require(calendar.date(byAdding: .day, value: -7, to: startOfToday)?.addingTimeInterval(3600))

        let pageViewsDataController = try WMFPageViewsDataController(coreDataStore: store)

        let insideObjectID = try #require(try await pageViewsDataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: sixDaysAgo))
        let outsideObjectID = try #require(try await pageViewsDataController.addPageView(title: "Dog", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: sevenDaysAgo))

        try await pageViewsDataController.addPageViewSeconds(pageViewManagedObjectID: insideObjectID, numberOfSeconds: 600)
        try await pageViewsDataController.addPageViewSeconds(pageViewManagedObjectID: outsideObjectID, numberOfSeconds: 1200)

        let dataController = WMFActivityTabDataController(coreDataStore: store)
        let timeRead = try #require(try await dataController.getTimeReadPast7Days())

        #expect(timeRead.0 == 0)
        #expect(timeRead.1 == 10, "Only the reading from inside the seven day window should be counted.")
    }

    @Test
    func timeReadPast7DaysConvertsMinutesToHoursAndMinutes() async throws {
        let store = try await fixture.makeTemporaryCoreDataStore()
        let pageViewsDataController = try WMFPageViewsDataController(coreDataStore: store)

        // Two page views today, each an hour of reading, so 2h 0m — and each at the ceiling, to
        // confirm the ceiling is per page view rather than a cap on the reported total.
        for title in ["Cat", "Dog"] {
            let objectID = try #require(try await pageViewsDataController.addPageView(title: title, namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: Date()))
            try await pageViewsDataController.addPageViewSeconds(pageViewManagedObjectID: objectID, numberOfSeconds: WMFPageViewsDataController.maximumReadingIntervalSeconds)
        }

        let dataController = WMFActivityTabDataController(coreDataStore: store)
        let timeRead = try #require(try await dataController.getTimeReadPast7Days())

        #expect(timeRead.0 == 2)
        #expect(timeRead.1 == 0)
    }
}
