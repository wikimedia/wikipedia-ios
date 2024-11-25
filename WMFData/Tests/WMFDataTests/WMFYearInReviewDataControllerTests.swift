import XCTest
@testable import WMFData
@testable import WMFDataMocks
import CoreData

final class WMFYearInReviewDataControllerTests: XCTestCase {
    
    enum TestError: Error {
        case missingDataController
        case missingStore
    }

    var store: WMFCoreDataStore?
    var dataController: WMFYearInReviewDataController?
    
    private var enProject: WMFProject {
        let language = WMFLanguage(languageCode: "en", languageVariantCode: nil)
        return WMFProject.wikipedia(language)
    }
    
    private var usCountryCode: String? {
        return Locale(identifier: "en_US").region?.identifier
    }
    
    private var frCountryCode: String? {
        return Locale(identifier: "fr_FR").region?.identifier
    }
    
    private var frProject: WMFProject {
        let language = WMFLanguage(languageCode: "fr", languageVariantCode: nil)
        return WMFProject.wikipedia(language)
    }

    override func setUp() async throws {
        
        let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try await WMFCoreDataStore(appContainerURL: temporaryDirectory)
        self.store = store
        
        self.dataController = try WMFYearInReviewDataController(coreDataStore: store)
        
        try await super.setUp()
    }

    func testCreateNewYearInReviewReport() async throws {
        
        guard let dataController else {
            throw TestError.missingDataController
        }
        
        guard let store else {
            throw TestError.missingStore
        }
        
        let slide1 = WMFYearInReviewSlide(year: 2024, id: .editCount,  evaluated: true, display: true, data: nil)
        let slide2 = WMFYearInReviewSlide(year: 2023, id: .readCount, evaluated: false, display: true, data: nil)

        try await dataController.createNewYearInReviewReport(year: 2023, slides: [slide1, slide2])

        let reports = try store.fetch(entityType: CDYearInReviewReport.self, predicate: nil, fetchLimit: 1, in: store.viewContext)
        XCTAssertEqual(reports!.count, 1)
        XCTAssertEqual(reports![0].year, 2023)
        XCTAssertEqual(reports![0].slides!.count, 2)
    }

    func testSaveYearInReviewReport() async throws {
        
        guard let dataController else {
            throw TestError.missingDataController
        }
        
        guard let store else {
            throw TestError.missingStore
        }
        
        let slide = WMFYearInReviewSlide(year: 2024, id: .editCount,  evaluated: true, display: true, data: nil)
        let report = WMFYearInReviewReport(year: 2024, slides: [slide])

        try await dataController.saveYearInReviewReport(report)

        let reports = try store.fetch(entityType: CDYearInReviewReport.self, predicate: nil, fetchLimit: 1, in: store.viewContext)

        XCTAssertEqual(reports!.count, 1)
        XCTAssertEqual(reports![0].year, 2024)
        XCTAssertEqual(reports![0].slides!.count, 1)
    }

    func testFetchYearInReviewReports() async throws {
        
        guard let dataController else {
            throw TestError.missingDataController
        }
        
        guard let store else {
            throw TestError.missingStore
        }
        
        let slide = WMFYearInReviewSlide(year: 2024, id: .editCount,  evaluated: true, display: true, data: nil)
        let slide2 = WMFYearInReviewSlide(year: 2024, id: .readCount,  evaluated: true, display: true, data: nil)
        let report = WMFYearInReviewReport(year: 2024, slides: [slide, slide2])

        try await dataController.saveYearInReviewReport(report)

        let reports = try store.fetch(entityType: CDYearInReviewReport.self, predicate: nil, fetchLimit: 1, in: store.viewContext)
        XCTAssertEqual(reports!.count, 1)
        XCTAssertEqual(reports![0].year, 2024)
        XCTAssertEqual(reports![0].slides!.count, 2)
    }

    func testFetchYearInReviewReportForYear() async throws {
        
        guard let dataController else {
            throw TestError.missingDataController
        }
        
        let slide1 = WMFYearInReviewSlide(year: 2021, id: .editCount, evaluated: true, display: true)
        let slide2 = WMFYearInReviewSlide(year: 2021, id: .readCount, evaluated: false, display: true)

        let report = WMFYearInReviewReport(year: 2021, slides: [slide1, slide2])
        try await dataController.saveYearInReviewReport(report)

        // Switch back to main thread
        try await MainActor.run {
            let fetchedReport = try dataController.fetchYearInReviewReport(forYear: 2021)

            XCTAssertNotNil(fetchedReport, "Expected to fetch a report for year 2021")

            XCTAssertEqual(fetchedReport?.year, 2021)
            XCTAssertEqual(fetchedReport?.slides.count, 2)

            let fetchedSlideIDs = fetchedReport?.slides.map { $0.id }.sorted()
            let originalSlideIDs = [slide1.id, slide2.id].sorted()
            XCTAssertEqual(fetchedSlideIDs, originalSlideIDs)

            let noReport = try dataController.fetchYearInReviewReport(forYear: 2020)
            XCTAssertNil(noReport, "Expected no report for year 2020")
        }
    }

    func testDeleteYearInReviewReport() async throws {
        
        guard let dataController else {
            throw TestError.missingDataController
        }
        
        guard let store else {
            throw TestError.missingStore
        }
        
        let slide = WMFYearInReviewSlide(year: 2021, id: .readCount,  evaluated: true, display: true, data: nil)
        try await dataController.createNewYearInReviewReport(year: 2021, slides: [slide])

        var reports = try store.fetch(entityType: CDYearInReviewReport.self, predicate: nil, fetchLimit: 1, in: store.viewContext)
        XCTAssertEqual(reports!.count, 1)

        try await dataController.deleteYearInReviewReport(year: 2021)

        reports = try store.fetch(entityType: CDYearInReviewReport.self, predicate: nil, fetchLimit: 1, in: store.viewContext)
        XCTAssertEqual(reports!.count, 0)
    }

    func testDeleteAllYearInReviewReports() async throws {
        
        guard let dataController else {
            throw TestError.missingDataController
        }
        
        guard let store else {
            throw TestError.missingStore
        }
        
        let slide1 = WMFYearInReviewSlide(year: 2024, id: .editCount,  evaluated: true, display: true, data: nil)
        let slide2 = WMFYearInReviewSlide(year: 2023, id: .readCount, evaluated: false, display: true, data: nil)

        try await dataController.createNewYearInReviewReport(year: 2024, slides: [slide1])
        try await dataController.createNewYearInReviewReport(year: 2023, slides: [slide2])

        var reports = try store.fetch(entityType: CDYearInReviewReport.self, predicate: nil, fetchLimit: 1, in: store.viewContext)
        XCTAssertEqual(reports!.count, 1)

        try await dataController.deleteAllYearInReviewReports()

        reports = try store.fetch(entityType: CDYearInReviewReport.self, predicate: nil, fetchLimit: 1, in: store.viewContext)
        XCTAssertEqual(reports!.count, 0)
    }
    
    func testYearInReviewEntryPointFeatureDisabled() throws {
        
        // Create mock developer settings config
        let readCountSlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: true)
        let editCountSlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: true)
        let donateCountSlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: true)
        let mostReadDaySlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: true)
        let personalizedSlides = WMFFeatureConfigResponse.IOS.YearInReview.PersonalizedSlides(readCount: readCountSlideSettings, editCount: editCountSlideSettings, donateCount: donateCountSlideSettings, mostReadDay: mostReadDaySlideSettings)
        let yearInReview = WMFFeatureConfigResponse.IOS.YearInReview(yearID: "2024.2", isEnabled: false, countryCodes: ["FR", "IT"], primaryAppLanguageCodes: ["fr", "it"], dataPopulationStartDateString: "2024-01-01T00:00:00Z", dataPopulationEndDateString: "2024-11-01T00:00:00Z", personalizedSlides: personalizedSlides)
        let ios = WMFFeatureConfigResponse.IOS(version: 1, yir: [yearInReview])
        let config = WMFFeatureConfigResponse(ios: [ios])
        
        // Create mock developer settings data controller
        let developerSettingsDataController = WMFMockDeveloperSettingsDataController(featureConfig: config)
        
        // Create year in review data controller to test
        let yearInReviewDataController = try WMFYearInReviewDataController(coreDataStore: store, developerSettingsDataController: developerSettingsDataController)
        
        guard let frCountryCode else {
            XCTFail("Missing expected country codes")
            return
        }
        
        let shouldShowEntryPoint = yearInReviewDataController.shouldShowYearInReviewEntryPoint(countryCode: frCountryCode, primaryAppLanguageProject: frProject)
        
        XCTAssertFalse(shouldShowEntryPoint, "FR should not show entry point for mock config of with disabled YiR feature.")
    }
    
    func testYearInReviewEntryPointCountryCode() async throws {
        
        // Create mock developer settings config
        let readCountSlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: true)
        let editCountSlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: true)
        let donateCountSlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: true)
        let mostReadDaySlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: true)
        let personalizedSlides = WMFFeatureConfigResponse.IOS.YearInReview.PersonalizedSlides(readCount: readCountSlideSettings, editCount: editCountSlideSettings, donateCount: donateCountSlideSettings, mostReadDay: mostReadDaySlideSettings)
        let yearInReview = WMFFeatureConfigResponse.IOS.YearInReview(yearID: "2024.2", isEnabled: true, countryCodes: ["FR", "IT"], primaryAppLanguageCodes: ["fr", "it"], dataPopulationStartDateString: "2024-01-01T00:00:00Z", dataPopulationEndDateString: "2024-11-01T00:00:00Z", personalizedSlides: personalizedSlides)
        let ios = WMFFeatureConfigResponse.IOS(version: 1, yir: [yearInReview])
        let config = WMFFeatureConfigResponse(ios: [ios])
        
        // Create mock developer settings data controller
        let developerSettingsDataController = WMFMockDeveloperSettingsDataController(featureConfig: config)
        
        // Create year in review data controller to test
        let yearInReviewDataController = try WMFYearInReviewDataController(coreDataStore: store, developerSettingsDataController: developerSettingsDataController)
        
        // Persist a valid YiR report
        let slides = WMFYearInReviewSlide(year: 2024, id: .readCount, evaluated: true, display: true)
        try await yearInReviewDataController.createNewYearInReviewReport(year: 2024, slides: [slides])
        
        guard let usCountryCode, let frCountryCode else {
            XCTFail("Missing expected country codes")
            return
        }
        
        await MainActor.run {
            let shouldShowEntryPointUS = yearInReviewDataController.shouldShowYearInReviewEntryPoint(countryCode: usCountryCode, primaryAppLanguageProject: frProject)
            
            XCTAssertFalse(shouldShowEntryPointUS, "US should not show entry point for mock YiR config of [FR, IT] country codes.")

            let shouldShowEntryPointFR = yearInReviewDataController.shouldShowYearInReviewEntryPoint(countryCode: frCountryCode, primaryAppLanguageProject: frProject)
            
            XCTAssertTrue(shouldShowEntryPointFR, "FR should show entry point for mock YiR config of [FR, IT] country codes.")
        }
    }
    
    func testYearInReviewEntryPointPrimaryAppLanguageProject() async throws {
        
        // Create mock developer settings config
        let readCountSlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: true)
        let editCountSlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: true)
        let donateCountSlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: true)
        let mostReadDaySlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: true)
        let personalizedSlides = WMFFeatureConfigResponse.IOS.YearInReview.PersonalizedSlides(readCount: readCountSlideSettings, editCount: editCountSlideSettings, donateCount: donateCountSlideSettings, mostReadDay: mostReadDaySlideSettings)
        let yearInReview = WMFFeatureConfigResponse.IOS.YearInReview(yearID: "2024.2", isEnabled: true, countryCodes: ["FR", "IT"], primaryAppLanguageCodes: ["fr", "it"], dataPopulationStartDateString: "2024-01-01T00:00:00Z", dataPopulationEndDateString: "2024-11-01T00:00:00Z", personalizedSlides: personalizedSlides)
        let ios = WMFFeatureConfigResponse.IOS(version: 1, yir: [yearInReview])
        let config = WMFFeatureConfigResponse(ios: [ios])
        
        // Create mock developer settings data controller
        let developerSettingsDataController = WMFMockDeveloperSettingsDataController(featureConfig: config)
        
        // Create year in review data controller to test
        let yearInReviewDataController = try WMFYearInReviewDataController(coreDataStore: store, developerSettingsDataController: developerSettingsDataController)
        
        // Persist a valid YiR report
        let slides = WMFYearInReviewSlide(year: 2024, id: .readCount, evaluated: true, display: true)
        try await yearInReviewDataController.createNewYearInReviewReport(year: 2024, slides: [slides])
        
        guard let frCountryCode else {
            XCTFail("Missing expected country codes")
            return
        }
        
        await MainActor.run {
            let shouldShowEntryPointENProject = yearInReviewDataController.shouldShowYearInReviewEntryPoint(countryCode: frCountryCode, primaryAppLanguageProject: enProject)
            
            XCTAssertFalse(shouldShowEntryPointENProject, "Primary app language EN project should not show entry point for mock YiR config of [FR, IT] primary app language projects.")

            let shouldShowEntryPointFRProject = yearInReviewDataController.shouldShowYearInReviewEntryPoint(countryCode: frCountryCode, primaryAppLanguageProject: frProject)
            
            XCTAssertTrue(shouldShowEntryPointFRProject, "Primary app language FR project should show entry point for mock YiR config of [FR, IT] primary app language projects.")
        }
    }
    
    func testYearInReviewEntryPointDisabledPersonalizedSlides() async throws {

        // Create mock developer settings config
        let readCountSlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: false)
        let editCountSlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: false)
        let donateCountSlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: true)
        let mostReadDaySlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: true)
        let personalizedSlides = WMFFeatureConfigResponse.IOS.YearInReview.PersonalizedSlides(readCount: readCountSlideSettings, editCount: editCountSlideSettings, donateCount: donateCountSlideSettings, mostReadDay: mostReadDaySlideSettings)
        let yearInReview = WMFFeatureConfigResponse.IOS.YearInReview(yearID: "2024.2", isEnabled: true, countryCodes: ["FR", "IT"], primaryAppLanguageCodes: ["fr", "it"], dataPopulationStartDateString: "2024-01-01T00:00:00Z", dataPopulationEndDateString: "2024-11-01T00:00:00Z", personalizedSlides: personalizedSlides)
        let ios = WMFFeatureConfigResponse.IOS(version: 1, yir: [yearInReview])
        let config = WMFFeatureConfigResponse(ios: [ios])

        // Create mock developer settings data controller
        let developerSettingsDataController = WMFMockDeveloperSettingsDataController(featureConfig: config)

        // Create year in review data controller to test
        let yearInReviewDataController = try WMFYearInReviewDataController(coreDataStore: store, developerSettingsDataController: developerSettingsDataController)
        
        // Persist a valid YiR report
        let slides = WMFYearInReviewSlide(year: 2024, id: .readCount, evaluated: true, display: true)
        try await yearInReviewDataController.createNewYearInReviewReport(year: 2024, slides: [slides])

        guard let frCountryCode else {
            XCTFail("Missing expected country codes")
            return
        }

        await MainActor.run {
            let shouldShowEntryPoint = yearInReviewDataController.shouldShowYearInReviewEntryPoint(countryCode: frCountryCode, primaryAppLanguageProject: frProject)
            
            XCTAssertFalse(shouldShowEntryPoint, "Should not show entry point when both personalized slides are disabled.")
        }
    }

    func testYearInReviewEntryPointOneEnabledPersonalizedSlide() async throws {

        // Create mock developer settings config
        let readCountSlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: true)
        let editCountSlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: false)
        let donateCountSlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: true)
        let mostReadDaySlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: true)
        let personalizedSlides = WMFFeatureConfigResponse.IOS.YearInReview.PersonalizedSlides(readCount: readCountSlideSettings, editCount: editCountSlideSettings, donateCount: donateCountSlideSettings, mostReadDay: mostReadDaySlideSettings)
        let yearInReview = WMFFeatureConfigResponse.IOS.YearInReview(yearID: "2024.2", isEnabled: true, countryCodes: ["FR", "IT"], primaryAppLanguageCodes: ["fr", "it"], dataPopulationStartDateString: "2024-01-01T00:00:00Z", dataPopulationEndDateString: "2024-11-01T00:00:00Z", personalizedSlides: personalizedSlides)
        let ios = WMFFeatureConfigResponse.IOS(version: 1, yir: [yearInReview])
        let config = WMFFeatureConfigResponse(ios: [ios])

        // Create mock developer settings data controller
        let developerSettingsDataController = WMFMockDeveloperSettingsDataController(featureConfig: config)

        // Create year in review data controller to test
        let yearInReviewDataController = try WMFYearInReviewDataController(coreDataStore: store, developerSettingsDataController: developerSettingsDataController)
        
        // Persist a valid YiR report
        let slides = WMFYearInReviewSlide(year: 2024, id: .readCount, evaluated: true, display: true)
        try await yearInReviewDataController.createNewYearInReviewReport(year: 2024, slides: [slides])

        guard let frCountryCode else {
            XCTFail("Missing expected country codes")
            return
        }
        
        await MainActor.run {
            let shouldShowEntryPoint = yearInReviewDataController.shouldShowYearInReviewEntryPoint(countryCode: frCountryCode, primaryAppLanguageProject: frProject)

            XCTAssertTrue(shouldShowEntryPoint, "Should show entry point when one personalized slide is enabled.")
        }
    }
}
