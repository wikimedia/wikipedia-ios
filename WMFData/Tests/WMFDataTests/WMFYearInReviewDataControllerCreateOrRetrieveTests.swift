import XCTest
@testable import WMFData
@testable import WMFDataMocks
import CoreData

final class WMFYearInReviewDataControllerCreateOrRetrieveTests: XCTestCase {
    lazy var store: WMFCoreDataStore = {
        let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        return try! WMFCoreDataStore(appContainerURL: temporaryDirectory)
    }()

    override func setUp() async throws {
        _ = self.store
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }

    lazy var dataController: WMFMockYearInReviewDataController = {
        let dataController = try! WMFMockYearInReviewDataController(coreDataStore: store)
        return dataController
    }()

    lazy var enProject: WMFProject = {
        let language = WMFLanguage(languageCode: "es", languageVariantCode: nil)
        return .wikipedia(language)
    }()

    let year = 2023
    let countryCode = "US"

    func testShouldNotCreateOrRetrieveYearInReview() async throws {
        dataController.shouldCreateOrRetrieve = false
        let report = try await dataController.populateYearInReviewReportData(for: year, countryCode: countryCode, primaryAppLanguageProject: enProject)
        XCTAssertNil(report, "Expected nil when shouldCreateOrRetrieveYearInReview returns false")

    }

    func testShouldCreateOrRetrieveYearInReview() async throws {
        var report = try await dataController.populateYearInReviewReportData(for: year, countryCode: countryCode, primaryAppLanguageProject: enProject)
        dataController.shouldCreateOrRetrieve = true

        let existingSlide = WMFYearInReviewSlide(year: year, id: .readCount, evaluated: true, display: true)
        let existingReport = WMFYearInReviewReport(year: year, slides: [existingSlide])
        try await dataController.saveYearInReviewReport(existingReport)

        report = try await dataController.populateYearInReviewReportData(for: year, countryCode: countryCode, primaryAppLanguageProject: enProject)
        XCTAssertNotNil(report, "Expected a report to be retrieved")
        XCTAssertEqual(report?.year, year)
        XCTAssertEqual(report?.slides.count, 1)
        XCTAssertEqual(report?.slides.first?.id, .readCount)
    }

    func testShouldCreateOrRetrieveYearInReviewWithNewReport() async throws {
        var report = try await dataController.populateYearInReviewReportData(for: year, countryCode: countryCode, primaryAppLanguageProject: enProject)

        try await dataController.deleteYearInReviewReport(year: year)

        let newSlide = WMFYearInReviewSlide(year: year, id: .editCount, evaluated: false, display: true)
        dataController.mockSlides = [newSlide]

        report = try await dataController.populateYearInReviewReportData(for: year, countryCode: countryCode, primaryAppLanguageProject: enProject)
        XCTAssertNotNil(report, "Expected a new report to be created")
        XCTAssertEqual(report?.year, year)
        XCTAssertEqual(report?.slides.count, 1)
        XCTAssertEqual(report?.slides.first?.id, .editCount)
    }
}
