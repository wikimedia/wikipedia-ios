import XCTest
@testable import WMFData
@testable import WMFDataMocks
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
    
    func testFetchPageViewMinutesOnlyCountsPageViewsInDateRange() async throws {

        guard let dataController else {
            throw TestsError.missingDataController
        }

        let dayInSeconds = TimeInterval(60 * 60 * 24)
        let insideRangeDate = todayDate.addingTimeInterval(60)
        let outsideRangeDate = todayDate.addingTimeInterval(-10 * dayInSeconds)

        guard let insideRangeObjectID = try await dataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: insideRangeDate) else {
            throw TestsError.empty
        }
        guard let outsideRangeObjectID = try await dataController.addPageView(title: "Dog", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: outsideRangeDate) else {
            throw TestsError.empty
        }

        try await dataController.addPageViewSeconds(pageViewManagedObjectID: insideRangeObjectID, numberOfSeconds: 600)
        try await dataController.addPageViewSeconds(pageViewManagedObjectID: outsideRangeObjectID, numberOfSeconds: 6000)

        // Today plus the six preceding days, matching the Activity tab's weekly window.
        let startDate = todayDate.addingTimeInterval(-6 * dayInSeconds)
        let endDate = todayDate.addingTimeInterval(dayInSeconds - 1)

        let minutes = try await dataController.fetchPageViewMinutes(startDate: startDate, endDate: endDate)
        XCTAssertEqual(minutes, 10, "Only the page view inside the range should be counted.")
    }

    func testAddPageViewSecondsAccumulates() async throws {

        guard let dataController else {
            throw TestsError.missingDataController
        }

        guard let objectID = try await dataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: todayDate.addingTimeInterval(60)) else {
            throw TestsError.empty
        }

        try await dataController.addPageViewSeconds(pageViewManagedObjectID: objectID, numberOfSeconds: 120)
        try await dataController.addPageViewSeconds(pageViewManagedObjectID: objectID, numberOfSeconds: 180)

        let dayInSeconds = TimeInterval(60 * 60 * 24)
        let minutes = try await dataController.fetchPageViewMinutes(startDate: todayDate, endDate: todayDate.addingTimeInterval(dayInSeconds - 1))
        XCTAssertEqual(minutes, 5)
    }

    func testClampInflatedPageViewSecondsClampsOnlyImplausibleValues() async throws {

        guard let store else {
            throw TestsError.missingStore
        }

        let ceiling = Int64(WMFPageViewsDataController.maximumReadingIntervalSeconds)
        let dataController = try WMFPageViewsDataController(coreDataStore: store, userDefaultsStore: WMFMockKeyValueStore())

        guard let plausibleObjectID = try await dataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: todayDate.addingTimeInterval(60)) else {
            throw TestsError.empty
        }
        guard let inflatedObjectID = try await dataController.addPageView(title: "Dog", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: todayDate.addingTimeInterval(60)) else {
            throw TestsError.empty
        }

        // 10 minutes of real reading, and 40 hours that could not have come from one article opening.
        try await dataController.addPageViewSeconds(pageViewManagedObjectID: plausibleObjectID, numberOfSeconds: 600)
        try await dataController.addPageViewSeconds(pageViewManagedObjectID: inflatedObjectID, numberOfSeconds: 40 * 60 * 60)

        let clampedCount = try await dataController.clampInflatedPageViewSecondsIfNeeded()
        XCTAssertEqual(clampedCount, 1, "Only the implausible page view should be clamped.")

        let viewContext = try store.viewContext
        await viewContext.perform {
            let plausible = viewContext.object(with: plausibleObjectID) as? CDPageView
            let inflated = viewContext.object(with: inflatedObjectID) as? CDPageView
            XCTAssertEqual(plausible?.numberOfSeconds, 600, "Plausible reading time should be left alone.")
            XCTAssertEqual(inflated?.numberOfSeconds, ceiling, "Inflated reading time should be capped at the ceiling.")
        }
    }

    func testClampInflatedPageViewSecondsOnlyRunsOnce() async throws {

        guard let store else {
            throw TestsError.missingStore
        }

        let dataController = try WMFPageViewsDataController(coreDataStore: store, userDefaultsStore: WMFMockKeyValueStore())

        guard let objectID = try await dataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: todayDate.addingTimeInterval(60)) else {
            throw TestsError.empty
        }
        try await dataController.addPageViewSeconds(pageViewManagedObjectID: objectID, numberOfSeconds: 40 * 60 * 60)

        XCTAssertFalse(dataController.didClampInflatedPageViewSeconds())

        let firstRunClampedCount = try await dataController.clampInflatedPageViewSecondsIfNeeded()
        XCTAssertEqual(firstRunClampedCount, 1)
        XCTAssertTrue(dataController.didClampInflatedPageViewSeconds())

        // A legitimately long total accumulated after the migration must survive.
        try await dataController.addPageViewSeconds(pageViewManagedObjectID: objectID, numberOfSeconds: 40 * 60 * 60)

        let secondRunClampedCount = try await dataController.clampInflatedPageViewSecondsIfNeeded()
        XCTAssertEqual(secondRunClampedCount, 0, "The migration should not run a second time.")

        let viewContext = try store.viewContext
        await viewContext.perform {
            let pageView = viewContext.object(with: objectID) as? CDPageView
            XCTAssertGreaterThan(pageView?.numberOfSeconds ?? 0, Int64(WMFPageViewsDataController.maximumReadingIntervalSeconds))
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
}
