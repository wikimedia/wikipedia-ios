import XCTest
@testable import WMFData
import CoreData

final class WMFSavedArticlesDataControllerTests: XCTestCase {

    enum TestsError: Error {
        case missingStore
    }

    private var store: WMFCoreDataStore?

    private let enProject = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    override func setUp() async throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try await WMFCoreDataStore(appContainerURL: temporaryDirectory)
        self.store = store
        try await super.setUp()
    }

    // MARK: - Helpers

    /// Inserts a CDPage with an attached CDPageSavedInfo (i.e. a saved article).
    private func insertSavedPage(title: String, project: WMFProject, savedDate: Date, namespaceID: Int16 = 0) async throws {
        guard let store else { throw TestsError.missingStore }
        let context = try store.newBackgroundContext
        try await context.perform {
            let page = try store.create(entityType: CDPage.self, in: context)
            page.title = title
            page.namespaceID = namespaceID
            page.projectID = project.id
            page.timestamp = Date()

            let savedInfo = try store.create(entityType: CDPageSavedInfo.self, in: context)
            savedInfo.savedDate = savedDate
            savedInfo.page = page

            try store.saveIfNeeded(moc: context)
        }
    }

    /// Inserts a CDPage without saved info (e.g. a history-only page), which should never appear in saved results.
    private func insertUnsavedPage(title: String, project: WMFProject, namespaceID: Int16 = 0) async throws {
        guard let store else { throw TestsError.missingStore }
        let context = try store.newBackgroundContext
        try await context.perform {
            let page = try store.create(entityType: CDPage.self, in: context)
            page.title = title
            page.namespaceID = namespaceID
            page.projectID = project.id
            page.timestamp = Date()

            try store.saveIfNeeded(moc: context)
        }
    }

    private func makeController() throws -> WMFSavedArticlesDataController {
        guard let store else { throw TestsError.missingStore }
        return WMFSavedArticlesDataController(coreDataStore: store)
    }

    // MARK: - fetchTimelinePages

    func testFetchTimelinePagesOnEmptyStoreReturnsEmpty() async throws {
        let controller = try makeController()
        let pages = try await controller.fetchTimelinePages()
        XCTAssertTrue(pages.isEmpty)
    }

    func testFetchTimelinePagesReturnsOnlySavedPages() async throws {
        try await insertSavedPage(title: "Cat", project: enProject, savedDate: Date())
        try await insertUnsavedPage(title: "Dog", project: enProject)

        let controller = try makeController()
        let pages = try await controller.fetchTimelinePages()

        XCTAssertEqual(pages.count, 1)
        XCTAssertEqual(pages.first?.page.title, "Cat")
    }

    func testFetchTimelinePagesSortedBySavedDateDescending() async throws {
        let now = Date()
        try await insertSavedPage(title: "Oldest", project: enProject, savedDate: now.addingTimeInterval(-3600))
        try await insertSavedPage(title: "Newest", project: enProject, savedDate: now)
        try await insertSavedPage(title: "Middle", project: enProject, savedDate: now.addingTimeInterval(-1800))

        let controller = try makeController()
        let titles = try await controller.fetchTimelinePages().map { $0.page.title }

        XCTAssertEqual(titles, ["Newest", "Middle", "Oldest"])
    }

    func testFetchTimelinePagesDeduplicatesByArticleKeepingNewest() async throws {
        let now = Date()
        try await insertSavedPage(title: "Cat", project: enProject, savedDate: now.addingTimeInterval(-3600))
        try await insertSavedPage(title: "Cat", project: enProject, savedDate: now)

        let controller = try makeController()
        let pages = try await controller.fetchTimelinePages()

        XCTAssertEqual(pages.count, 1)
        // The newest savedDate wins after the descending sort.
        XCTAssertEqual(pages.first?.timestamp.timeIntervalSince1970 ?? 0, now.timeIntervalSince1970, accuracy: 0.001)
    }

    func testFetchTimelinePagesMapsPageFields() async throws {
        let savedDate = Date()
        try await insertSavedPage(title: "Cat", project: enProject, savedDate: savedDate, namespaceID: 0)

        let controller = try makeController()
        let first = try await controller.fetchTimelinePages().first
        let page = try XCTUnwrap(first)

        XCTAssertEqual(page.page.title, "Cat")
        XCTAssertEqual(page.page.projectID, enProject.id)
        XCTAssertEqual(page.page.namespaceID, 0)
        XCTAssertEqual(page.timestamp.timeIntervalSince1970, savedDate.timeIntervalSince1970, accuracy: 0.001)
    }

    // MARK: - getSavedArticleModuleData (network-free cases)

    func testGetSavedArticleModuleDataOnEmptyStoreReturnsZeroCount() async throws {
        let controller = try makeController()
        let result = await controller.getSavedArticleModuleData(from: .distantPast, to: Date())
        let data = try XCTUnwrap(result)

        XCTAssertEqual(data.savedArticlesCount, 0)
        XCTAssertTrue(data.articleTitles.isEmpty)
        XCTAssertTrue(data.articleThumbURLs.isEmpty)
        XCTAssertNil(data.dateLastSaved)
    }

    func testGetSavedArticleModuleDataExcludesSavesOutsideDateRange() async throws {
        // Saved now, but queried for a window entirely in the past -> excluded, so no network is hit.
        try await insertSavedPage(title: "Cat", project: enProject, savedDate: Date())

        let controller = try makeController()
        let result = await controller.getSavedArticleModuleData(from: .distantPast, to: Date().addingTimeInterval(-86400))
        let data = try XCTUnwrap(result)

        XCTAssertEqual(data.savedArticlesCount, 0)
        XCTAssertNil(data.dateLastSaved)
    }
}
