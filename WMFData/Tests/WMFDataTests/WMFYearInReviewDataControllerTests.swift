import XCTest
@testable import WMFData
import CoreData

final class YearInReviewDataControllerTests: XCTestCase {

    enum CoreDataStoreTestsError: Error {
        case empty
    }

    lazy var store: WMFCoreDataStore = {
        let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        return try! WMFCoreDataStore(appContainerURL: temporaryDirectory)
    }()

    lazy var dataController: WMFYearInReviewDataController = {
        let dataController = try! WMFYearInReviewDataController(coreDataStore: store)
        return dataController
    }()

    override func setUp() async throws {
        _ = self.store
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }

    func testCreateNewYearInReviewReport() async throws {
        let slide1 = WMFYearInReviewSlide(year: 2024, id: .editCount,  evaluated: true, display: true, data: nil)
        let slide2 = WMFYearInReviewSlide(year: 2023, id: .readCount, evaluated: false, display: true, data: nil)

        try await dataController.createNewYearInReviewReport(year: 2023, slides: [slide1, slide2])

        let reports = try store.fetch(entityType: CDYearInReviewReport.self, entityName: "CDYearInReviewReport", predicate: nil, fetchLimit: 1, in: store.viewContext)
        XCTAssertEqual(reports!.count, 1)
        XCTAssertEqual(reports![0].year, 2023)
        XCTAssertEqual(reports![0].slides!.count, 2)
    }

    func testSaveYearInReviewReport() async throws {
        let slide = WMFYearInReviewSlide(year: 2024, id: .editCount,  evaluated: true, display: true, data: nil)
        let report = WMFYearInReviewReport(year: 2024, slides: [slide])

        try await dataController.saveYearInReviewReport(report)

        let reports = try store.fetch(entityType: CDYearInReviewReport.self, entityName: "CDYearInReviewReport", predicate: nil, fetchLimit: 1, in: store.viewContext)

        XCTAssertEqual(reports!.count, 1)
        XCTAssertEqual(reports![0].year, 2024)
        XCTAssertEqual(reports![0].slides!.count, 1)
    }


    func testFetchYearInReviewReports() async throws {
        let slide = WMFYearInReviewSlide(year: 2024, id: .editCount,  evaluated: true, display: true, data: nil)
        let report = WMFYearInReviewReport(year: 2024, slides: [slide])

        try await dataController.saveYearInReviewReport(report)

        let reports = try store.fetch(entityType: CDYearInReviewReport.self, entityName: "CDYearInReviewReport", predicate: nil, fetchLimit: 1, in: store.viewContext)
        XCTAssertEqual(reports!.count, 1)
        XCTAssertEqual(reports![0].year, 2024)
        XCTAssertEqual(reports![0].slides!.count, 1)
    }

    func testDeleteYearInReviewReport() async throws {
        let slide = WMFYearInReviewSlide(year: 2021, id: .readCount,  evaluated: true, display: true, data: nil)
        try await dataController.createNewYearInReviewReport(year: 2021, slides: [slide])

        var reports = try store.fetch(entityType: CDYearInReviewReport.self, entityName: "CDYearInReviewReport", predicate: nil, fetchLimit: 1, in: store.viewContext)
        XCTAssertEqual(reports!.count, 1)

        try await dataController.deleteYearInReviewReport(year: 2021)

        reports = try store.fetch(entityType: CDYearInReviewReport.self, entityName: "CDYearInReviewReport", predicate: nil, fetchLimit: 1, in: store.viewContext)
        XCTAssertEqual(reports!.count, 0)
    }

    func testDeleteAllYearInReviewReports() async throws {
        let slide1 = WMFYearInReviewSlide(year: 2024, id: .editCount,  evaluated: true, display: true, data: nil)
        let slide2 = WMFYearInReviewSlide(year: 2023, id: .readCount, evaluated: false, display: true, data: nil)

        try await dataController.createNewYearInReviewReport(year: 2024, slides: [slide1])
        try await dataController.createNewYearInReviewReport(year: 2023, slides: [slide2])

        var reports = try store.fetch(entityType: CDYearInReviewReport.self, entityName: "CDYearInReviewReport", predicate: nil, fetchLimit: 1, in: store.viewContext)
        XCTAssertEqual(reports!.count, 1)

        try await dataController.deleteAllYearInReviewReports()

        reports = try store.fetch(entityType: CDYearInReviewReport.self, entityName: "CDYearInReviewReport", predicate: nil, fetchLimit: 1, in: store.viewContext)
        XCTAssertEqual(reports!.count, 0)
    }

}
