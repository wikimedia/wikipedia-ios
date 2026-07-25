import XCTest
@testable import WMFData
import CoreData

final class WMFPageInterestDataControllerTests: XCTestCase {

    enum TestsError: Error {
        case missingStore
    }

    private var store: WMFCoreDataStore?

    private let enProject = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))
    private let esProject = WMFProject.wikipedia(WMFLanguage(languageCode: "es", languageVariantCode: nil))

    override func setUp() async throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try await WMFCoreDataStore(appContainerURL: temporaryDirectory)
        self.store = store
        try await super.setUp()
    }

    private func makeController() throws -> WMFPageInterestDataController {
        guard let store else { throw TestsError.missingStore }
        return try WMFPageInterestDataController(coreDataStore: store)
    }

    // MARK: - fetchPageInterests

    func testFetchPageInterestsOnlyReturnsMatchingProject() async throws {
        let controller = try makeController()
        try await controller.addPageInterest(title: "Cat", project: enProject)
        try await controller.addPageInterest(title: "Gato", project: esProject)

        let enInterests = try await controller.fetchPageInterests(project: enProject)
        let esInterests = try await controller.fetchPageInterests(project: esProject)

        XCTAssertEqual(enInterests.map { $0.title }, ["Cat"])
        XCTAssertEqual(esInterests.map { $0.title }, ["Gato"])
    }

    func testFetchPageInterestsDoesNotCrossContaminate() async throws {
        let controller = try makeController()
        try await controller.addPageInterest(title: "Cat", project: enProject)

        let esInterests = try await controller.fetchPageInterests(project: esProject)
        XCTAssertTrue(esInterests.isEmpty)
    }

    // MARK: - addPageInterest

    func testAddPageInterestPersists() async throws {
        let controller = try makeController()
        try await controller.addPageInterest(title: "Cat", project: enProject)

        let interests = try await controller.fetchPageInterests(project: enProject)
        XCTAssertEqual(interests.count, 1)
        XCTAssertEqual(interests.first?.title, "Cat")
    }

    func testAddPageInterestDoesNotCreateDuplicate() async throws {
        let controller = try makeController()
        try await controller.addPageInterest(title: "Cat", project: enProject)
        try await controller.addPageInterest(title: "Cat", project: enProject)

        let interests = try await controller.fetchPageInterests(project: enProject)
        XCTAssertEqual(interests.count, 1)
    }

    // MARK: - removePageInterest

    func testRemovePageInterestDeletesIt() async throws {
        let controller = try makeController()
        try await controller.addPageInterest(title: "Cat", project: enProject)
        try await controller.removePageInterest(title: "Cat", project: enProject)

        let interests = try await controller.fetchPageInterests(project: enProject)
        XCTAssertTrue(interests.isEmpty)
    }

    func testRemovePageInterestDoesNotAffectOtherProjects() async throws {
        let controller = try makeController()
        try await controller.addPageInterest(title: "Cat", project: enProject)
        try await controller.addPageInterest(title: "Cat", project: esProject)

        try await controller.removePageInterest(title: "Cat", project: enProject)

        let enInterests = try await controller.fetchPageInterests(project: enProject)
        let esInterests = try await controller.fetchPageInterests(project: esProject)

        XCTAssertTrue(enInterests.isEmpty)
        XCTAssertEqual(esInterests.count, 1)
    }

    func testRemovePageInterestDoesNotAffectOtherArticles() async throws {
        let controller = try makeController()
        try await controller.addPageInterest(title: "Cat", project: enProject)
        try await controller.addPageInterest(title: "Dog", project: enProject)

        try await controller.removePageInterest(title: "Cat", project: enProject)

        let interests = try await controller.fetchPageInterests(project: enProject)
        XCTAssertEqual(interests.map { $0.title }, ["Dog"])
    }
}
