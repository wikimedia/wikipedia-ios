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

class YearInReviewDataControllerMock: WMFYearInReviewDataController {
    var shouldCreateOrRetrieve = true
    var mockSlides: [WMFYearInReviewSlide] = []
    
    override init(coreDataStore: WMFCoreDataStore? = WMFDataEnvironment.current.coreDataStore, developerSettingsDataController: any WMFDeveloperSettingsDataControlling = WMFDeveloperSettingsDataController.shared) throws {
        
        let readCountSlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: true)
        let editCountSlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: true)
        let personalizedSlides = WMFFeatureConfigResponse.IOS.YearInReview.PersonalizedSlides(readCount: readCountSlideSettings, editCount: editCountSlideSettings)
        let yearInReview = WMFFeatureConfigResponse.IOS.YearInReview(isEnabled: false, countryCodes: ["FR", "IT"], primaryAppLanguageCodes: ["fr", "it"], dataPopulationStartDateString: "2024-01-01T00:00:00Z", dataPopulationEndDateString: "2024-11-01T00:00:00Z", personalizedSlides: personalizedSlides)
        let ios = WMFFeatureConfigResponse.IOS(version: 1, yir: yearInReview)
        let config = WMFFeatureConfigResponse(ios: [ios])
        let developerSettingsDataController = WMFMockDeveloperSettingsDataController(featureConfig: config)
        
        try super.init(coreDataStore: coreDataStore, developerSettingsDataController: developerSettingsDataController)
    }

    override func shouldPopulateYearInReviewReportData(countryCode: String?, primaryAppLanguageProject: WMFProject?) -> Bool {
        return shouldCreateOrRetrieve
    }

    override func initialSlides(year: Int, moc: NSManagedObjectContext) throws -> Set<CDYearInReviewSlide> {
        
        var results = Set<CDYearInReviewSlide>()

        let editCountSlide = try coreDataStore.create(entityType: CDYearInReviewSlide.self, in: moc)
        editCountSlide.year = 2023
        editCountSlide.id = WMFYearInReviewPersonalizedSlideID.editCount.rawValue
        editCountSlide.evaluated = false
        editCountSlide.display = false
        editCountSlide.data = nil
        results.insert(editCountSlide)
        return results
    }
}
