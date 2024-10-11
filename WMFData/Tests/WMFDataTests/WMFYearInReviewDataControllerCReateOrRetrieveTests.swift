import XCTest
@testable import WMFData
import CoreData

final class WMFYearInReviewDataControllerCReateOrRetrieveTests: XCTestCase {
    lazy var store: WMFCoreDataStore = {
        let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        return try! WMFCoreDataStore(appContainerURL: temporaryDirectory)
    }()

    override func setUp() async throws {
        _ = self.store
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }

    lazy var dataController: YearInReviewDataControllerMock = {
        let dataController = try! YearInReviewDataControllerMock(coreDataStore: store)
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
        var report = await dataController.createOrRetrieveYearInReview(for: year, countryCode: countryCode, primaryAppLanguageProject: enProject)
        XCTAssertNil(report, "Expected nil when shouldCreateOrRetrieveYearInReview returns false")

    }

    func testShouldCreateOrRetrieveYearInReview() async throws {
        var report = await dataController.createOrRetrieveYearInReview(for: year, countryCode: countryCode, primaryAppLanguageProject: enProject)
        dataController.shouldCreateOrRetrieve = true

        let existingSlide = WMFYearInReviewSlide(year: year, id: .readCount, evaluated: true, display: true)
        let existingReport = WMFYearInReviewReport(year: year, slides: [existingSlide])
        try await dataController.saveYearInReviewReport(existingReport)

        report = await dataController.createOrRetrieveYearInReview(for: year, countryCode: countryCode, primaryAppLanguageProject: enProject)
        XCTAssertNotNil(report, "Expected a report to be retrieved")
        XCTAssertEqual(report?.year, year)
        XCTAssertEqual(report?.slides.count, 1)
        XCTAssertEqual(report?.slides.first?.id, .readCount)
    }

    func testShouldCreateOrRetrieveYearInReviewWithNewReport() async throws {
        var report = await dataController.createOrRetrieveYearInReview(for: year, countryCode: countryCode, primaryAppLanguageProject: enProject)

        try await dataController.deleteYearInReviewReport(year: year)

        let newSlide = WMFYearInReviewSlide(year: year, id: .editCount, evaluated: false, display: true)
        dataController.mockSlides = [newSlide]

        report = await dataController.createOrRetrieveYearInReview(for: year, countryCode: countryCode, primaryAppLanguageProject: enProject)
        XCTAssertNotNil(report, "Expected a new report to be created")
        XCTAssertEqual(report?.year, year)
        XCTAssertEqual(report?.slides.count, 1)
        XCTAssertEqual(report?.slides.first?.id, .editCount)
    }
}

class YearInReviewDataControllerMock: WMFYearInReviewDataController {
    var shouldCreateOrRetrieve = true
    var mockSlides: [WMFYearInReviewSlide] = []

    override func shouldCreateOrRetrieveYearInReview(countryCode: String?, primaryAppLanguageProject: WMFProject?) -> Bool {
        return shouldCreateOrRetrieve
    }

    override func getSlides() -> [WMFYearInReviewSlide] {
        return mockSlides
    }
}
