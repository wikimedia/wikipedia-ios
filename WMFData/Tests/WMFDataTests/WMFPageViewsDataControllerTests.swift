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
        
        try await dataController.addPageView(title: "Cat", namespaceID: 0, project: enProject)
        
        // Fetch, confirm page view was added
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
    
    func testDeletePageView() async throws {
        
        guard let store else {
            throw TestsError.missingStore
        }
        
        guard let dataController else {
            throw TestsError.missingDataController
        }
        
        // First add page view
        try await dataController.addPageView(title: "Cat", namespaceID: 0, project: enProject)
        
        // Fetch, confirm page view was added
        let addedResults = try store.fetch(entityType: CDPageView.self, predicate: nil, fetchLimit: nil, in: store.viewContext)
        XCTAssertNotNil(addedResults)
        XCTAssertEqual(addedResults!.count, 1)
        
        // Then delete page view
        try await dataController.deletePageView(title: "Cat", namespaceID: 0, project: enProject)
        
        // Fetch, confirm page view was deleted
        let deletedResults = try store.fetch(entityType: CDPageView.self, predicate: nil, fetchLimit: nil, in: store.viewContext)
        XCTAssertNotNil(deletedResults)
        XCTAssertEqual(deletedResults!.count, 0)
    }
    
    func testDeleteAllPageViews() async throws {
        
        guard let store else {
            throw TestsError.missingStore
        }
        
        guard let dataController else {
            throw TestsError.missingDataController
        }
        
        // First add page view
        try await dataController.addPageView(title: "Cat", namespaceID: 0, project: enProject)
        
        // Fetch, confirm page view was added
        let addedResults = try store.fetch(entityType: CDPageView.self, predicate: nil, fetchLimit: nil, in: store.viewContext)
        XCTAssertNotNil(addedResults)
        XCTAssertEqual(addedResults!.count, 1)
        
        // Then delete page view
        try await dataController.deleteAllPageViews()
        
        // Fetch, confirm page view was deleted
        let deletedResults = try store.fetch(entityType: CDPageView.self, predicate: nil, fetchLimit: nil, in: store.viewContext)
        XCTAssertNotNil(deletedResults)
        XCTAssertEqual(deletedResults!.count, 0)
    }
    
    func testImportPageViews() async throws {
        
        guard let store else {
            throw TestsError.missingStore
        }
        
        guard let dataController else {
            throw TestsError.missingDataController
        }
        
        let importRequests: [WMFPageViewImportRequest] = [
            WMFPageViewImportRequest(title: "Cat", project: enProject, viewedDate: todayDate),
            WMFPageViewImportRequest(title: "Felis silvestris catus", project: esProject, viewedDate: yesterdayDate)
        ]
        
        try await dataController.importPageViews(requests: importRequests)
        
        // Fetch, confirm page views were added
        let pageViews = try store.fetch(entityType: CDPageView.self, predicate: nil, fetchLimit: nil, in: store.viewContext)
        XCTAssertNotNil(pageViews)
        XCTAssertEqual(pageViews!.count, 2)
        
        // Fetch, confirm pages were added
        let pages = try store.fetch(entityType: CDPage.self, predicate: nil, fetchLimit: nil, in: store.viewContext)
        XCTAssertNotNil(pages)
        XCTAssertEqual(pages!.count, 2)
    }
    
    func testFetchPageViewCounts() async throws {
        
        guard let dataController else {
            throw TestsError.missingDataController
        }
        
        // First add page views
        try await dataController.addPageView(title: "Cat", namespaceID: 0, project: enProject)
        try await dataController.addPageView(title: "Cat", namespaceID: 0, project: enProject)
        try await dataController.addPageView(title: "Felis silvestris catus", namespaceID: 0, project: esProject)
        
        let results = try dataController.fetchPageViewCounts(startDate: yesterdayDate, endDate: Date.now)
        
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].page.title, "Cat")
        XCTAssertEqual(results[0].count, 2)
        XCTAssertEqual(results[1].page.title, "Felis_silvestris_catus")
        XCTAssertEqual(results[1].count, 1)
    }
}
