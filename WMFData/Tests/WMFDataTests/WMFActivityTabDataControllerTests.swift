import XCTest
@testable import WMFData

final class WMFActivityTabDataControllerTests: XCTestCase {

    enum TestsError: Error {
        case missingStore
        case empty
    }

    var store: WMFCoreDataStore?

    lazy var enProject: WMFProject = {
        let language = WMFLanguage(languageCode: "en", languageVariantCode: nil)
        return .wikipedia(language)
    }()

    override func setUp() async throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        self.store = try await WMFCoreDataStore(appContainerURL: temporaryDirectory)
        try await super.setUp()
    }

    /// The window the Activity tab labels as a week must be seven days, not eight. Reading from
    /// seven days ago is outside it; reading from six days ago is inside.
    func testTimeReadPast7DaysCoversSevenDays() async throws {

        guard let store else {
            throw TestsError.missingStore
        }

        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())

        guard let sixDaysAgo = calendar.date(byAdding: .day, value: -6, to: startOfToday)?.addingTimeInterval(3600),
              let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: startOfToday)?.addingTimeInterval(3600) else {
            throw TestsError.empty
        }

        let pageViewsDataController = try WMFPageViewsDataController(coreDataStore: store)

        guard let insideObjectID = try await pageViewsDataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: sixDaysAgo),
              let outsideObjectID = try await pageViewsDataController.addPageView(title: "Dog", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: sevenDaysAgo) else {
            throw TestsError.empty
        }

        try await pageViewsDataController.addPageViewSeconds(pageViewManagedObjectID: insideObjectID, numberOfSeconds: 600)
        try await pageViewsDataController.addPageViewSeconds(pageViewManagedObjectID: outsideObjectID, numberOfSeconds: 1200)

        let dataController = WMFActivityTabDataController(coreDataStore: store)
        let timeRead = try await dataController.getTimeReadPast7Days()

        XCTAssertEqual(timeRead?.0, 0)
        XCTAssertEqual(timeRead?.1, 10, "Only the reading from inside the seven day window should be counted.")
    }

    func testTimeReadPast7DaysConvertsMinutesToHoursAndMinutes() async throws {

        guard let store else {
            throw TestsError.missingStore
        }

        let pageViewsDataController = try WMFPageViewsDataController(coreDataStore: store)

        // Two page views today, each an hour of reading, so 2h 0m — and each at the ceiling, to
        // confirm the ceiling is per page view rather than a cap on the reported total.
        for title in ["Cat", "Dog"] {
            guard let objectID = try await pageViewsDataController.addPageView(title: title, namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: Date()) else {
                throw TestsError.empty
            }
            try await pageViewsDataController.addPageViewSeconds(pageViewManagedObjectID: objectID, numberOfSeconds: WMFPageViewsDataController.maximumReadingIntervalSeconds)
        }

        let dataController = WMFActivityTabDataController(coreDataStore: store)
        let timeRead = try await dataController.getTimeReadPast7Days()

        XCTAssertEqual(timeRead?.0, 2)
        XCTAssertEqual(timeRead?.1, 0)
    }
}
