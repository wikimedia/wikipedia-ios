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
    
    private var usCountryCode: String? {
        return Locale(identifier: "en_US").region?.identifier
    }
    
    private var ruCountryCode: String? {
        return Locale(identifier: "ru_RU").region?.identifier
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
        
        let slide1 = WMFYearInReviewSlide(year: 2024, id: .editCount, data: nil)
        let slide2 = WMFYearInReviewSlide(year: 2023, id: .readCount, data: nil)

        try await dataController.createNewYearInReviewReport(year: 2023, slides: [slide1, slide2])

        try await store.viewContext.perform {
            let reports = try store.fetch(entityType: CDYearInReviewReport.self, predicate: nil, fetchLimit: 1, in: store.viewContext)
            XCTAssertEqual(reports!.count, 1)
            XCTAssertEqual(reports![0].year, 2023)
            XCTAssertEqual(reports![0].slides!.count, 2)
        }
    }

    func testSaveYearInReviewReport() async throws {
        
        guard let dataController else {
            throw TestError.missingDataController
        }
        
        guard let store else {
            throw TestError.missingStore
        }
        
        let slide = WMFYearInReviewSlide(year: 2024, id: .editCount, data: nil)
        let report = WMFYearInReviewReport(year: 2024, slides: [slide])

        try await dataController.saveYearInReviewReport(report)

        try await store.viewContext.perform {
            let reports = try store.fetch(entityType: CDYearInReviewReport.self, predicate: nil, fetchLimit: 1, in: store.viewContext)

            XCTAssertEqual(reports!.count, 1)
            XCTAssertEqual(reports![0].year, 2024)
            XCTAssertEqual(reports![0].slides!.count, 1)
        }
    }

    func testFetchYearInReviewReports() async throws {
        
        guard let dataController else {
            throw TestError.missingDataController
        }
        
        guard let store else {
            throw TestError.missingStore
        }
        
        let slide = WMFYearInReviewSlide(year: 2024, id: .editCount, data: nil)
        let slide2 = WMFYearInReviewSlide(year: 2024, id: .readCount, data: nil)
        let report = WMFYearInReviewReport(year: 2024, slides: [slide, slide2])

        try await dataController.saveYearInReviewReport(report)

        try await store.viewContext.perform {
            let reports = try store.fetch(entityType: CDYearInReviewReport.self, predicate: nil, fetchLimit: 1, in: store.viewContext)
            XCTAssertEqual(reports!.count, 1)
            XCTAssertEqual(reports![0].year, 2024)
            XCTAssertEqual(reports![0].slides!.count, 2)
        }
    }

    func testFetchYearInReviewReportForYear() async throws {
        
        guard let dataController else {
            throw TestError.missingDataController
        }
        
        let slide1 = WMFYearInReviewSlide(year: 2021, id: .editCount)
        let slide2 = WMFYearInReviewSlide(year: 2021, id: .readCount)

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
        
        let slide = WMFYearInReviewSlide(year: 2021, id: .readCount, data: nil)
        try await dataController.createNewYearInReviewReport(year: 2021, slides: [slide])

        var reports: [CDYearInReviewReport]?
        try store.viewContext.performAndWait {
            reports = try store.fetch(entityType: CDYearInReviewReport.self, predicate: nil, fetchLimit: 1, in: store.viewContext)
            XCTAssertEqual(reports!.count, 1)
        }

        try await dataController.deleteYearInReviewReport(year: 2021)

        try await store.viewContext.perform {
            reports = try store.fetch(entityType: CDYearInReviewReport.self, predicate: nil, fetchLimit: 1, in: store.viewContext)
            XCTAssertEqual(reports!.count, 0)
        }
    }

    func testDeleteAllYearInReviewReports() async throws {
        
        guard let dataController else {
            throw TestError.missingDataController
        }
        
        guard let store else {
            throw TestError.missingStore
        }
        
        let slide1 = WMFYearInReviewSlide(year: 2024, id: .editCount, data: nil)
        let slide2 = WMFYearInReviewSlide(year: 2023, id: .readCount, data: nil)

        try await dataController.createNewYearInReviewReport(year: 2024, slides: [slide1])
        try await dataController.createNewYearInReviewReport(year: 2023, slides: [slide2])

        var reports: [CDYearInReviewReport]?
        try store.viewContext.performAndWait {
            reports = try store.fetch(entityType: CDYearInReviewReport.self, predicate: nil, fetchLimit: 1, in: store.viewContext)
            XCTAssertEqual(reports!.count, 1)
        }


        try await dataController.deleteAllYearInReviewReports()

        try await store.viewContext.perform {
            reports = try store.fetch(entityType: CDYearInReviewReport.self, predicate: nil, fetchLimit: 1, in: store.viewContext)
            XCTAssertEqual(reports!.count, 0)
        }

    }
    
    var config: WMFFeatureConfigResponse {
        let common = WMFFeatureConfigResponse.Common(yir: [WMFFeatureConfigResponse.Common.YearInReview.testConfig])
        return WMFFeatureConfigResponse(common: common, ios: WMFFeatureConfigResponse.IOS(hCaptcha: nil))
    }
    
    var october17: Date {
        var components = DateComponents()
        components.year = 2025
        components.month = 10
        components.day = 17
        components.hour = 0
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components)!
    }
    
    var december15: Date {
        var components = DateComponents()
        components.year = 2025
        components.month = 12
        components.day = 15
        components.hour = 0
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components)!
    }
    
    func testYearInReviewEntryPointFeatureDisabled() throws {
        
        // Create mock developer settings data controller
        let developerSettingsDataController = WMFMockDeveloperSettingsDataController(featureConfig: config)
        
        // Create year in review data controller to test
        let yearInReviewDataController = try WMFYearInReviewDataController(coreDataStore: store, developerSettingsDataController: developerSettingsDataController)
        
        guard let usCountryCode else {
            XCTFail("Missing expected country codes")
            return
        }
        
        let shouldShowEntryPoint = yearInReviewDataController.shouldShowYearInReviewEntryPoint(countryCode: usCountryCode, currentDate: october17)
        
        XCTAssertFalse(shouldShowEntryPoint, "Should not show entry point for mock config outside of active dates.")
    }
    
    func testYearInReviewEntryPointCountryCode() async throws {

        // Create mock developer settings data controller
        let developerSettingsDataController = WMFMockDeveloperSettingsDataController(featureConfig: config)
        
        // Create year in review data controller to test
        let yearInReviewDataController = try WMFYearInReviewDataController(coreDataStore: store, developerSettingsDataController: developerSettingsDataController)
        
        // Persist a valid YiR report
        let slides = WMFYearInReviewSlide(year: 2025, id: .readCount)
        try await yearInReviewDataController.createNewYearInReviewReport(year: 2025, slides: [slides])
        
        guard let usCountryCode, let ruCountryCode else {
            XCTFail("Missing expected country codes")
            return
        }
        
        await MainActor.run {
            let shouldShowEntryPointUS = yearInReviewDataController.shouldShowYearInReviewEntryPoint(countryCode: usCountryCode, currentDate: december15)
            
            XCTAssertTrue(shouldShowEntryPointUS, "US should show entry point for mock YiR config.")

            let shouldShowEntryPointRU = yearInReviewDataController.shouldShowYearInReviewEntryPoint(countryCode: ruCountryCode, currentDate: december15)
            
            XCTAssertFalse(shouldShowEntryPointRU, "RU should not show entry point for mock YiR config.")
        }
    }
}

extension WMFFeatureConfigResponse.Common.YearInReview {
    
    static var testTopReadEN: [String] {
        [
            "Deaths in 2024",
            "Kamala Harris",
            "2024 United States presidential election",
            "Lyle and Erik Menendez",
            "Donald Trump"
        ]
    }
    
    static var testTopReadPercentages: [WMFFeatureConfigResponse.Common.YearInReview.TopReadPercentage] {
        [
            WMFFeatureConfigResponse.Common.YearInReview.TopReadPercentage(identifier: "0.01", min: 43740, max: nil),
            WMFFeatureConfigResponse.Common.YearInReview.TopReadPercentage(identifier: "1", min: 23456, max: 43739),
            WMFFeatureConfigResponse.Common.YearInReview.TopReadPercentage(identifier: "5", min: 12345, max: 23455),
            WMFFeatureConfigResponse.Common.YearInReview.TopReadPercentage(identifier: "10", min: 8901, max: 12344),
            WMFFeatureConfigResponse.Common.YearInReview.TopReadPercentage(identifier: "20", min: 4567, max: 8900),
            WMFFeatureConfigResponse.Common.YearInReview.TopReadPercentage(identifier: "30", min: 2456, max: 4566),
            WMFFeatureConfigResponse.Common.YearInReview.TopReadPercentage(identifier: "40", min: 1234, max: 2455),
            WMFFeatureConfigResponse.Common.YearInReview.TopReadPercentage(identifier: "50", min: 336, max: 1233)
        ]
    }
    
    static var testHideCountryCodes: [String] {
        [
                  "RU",
                  "IR",
                  "CN",
                  "HK",
                  "MO",
                  "SA",
                  "CU",
                  "MM",
                  "BY",
                  "EG",
                  "PS",
                  "GN",
                  "PK",
                  "KH",
                  "VN",
                  "SD",
                  "AE",
                  "BY",
                  "SY",
                  "JO",
                  "VE",
                  "AF"
                ]
    }
    
    static var testHideDonateCountryCodes: [String] {
        [ "AE",
          "AF",
          "AX",
          "BY",
          "CD",
          "CI",
          "CU",
          "FI",
          "ID",
          "IQ",
          "IR",
          "KP",
          "KR",
          "LB",
          "LY",
          "MM",
          "PY",
          "RU",
          "SA",
          "SD",
          "SO",
          "SS",
          "SY",
          "TM",
          "TR",
          "UA",
          "UZ",
          "XK",
          "YE",
          "ZW"]
    }
    
    static var testConfig: WMFFeatureConfigResponse.Common.YearInReview {
        
        // Dynamically set always active end date for test stability
        let dateFormatter = DateFormatter.mediaWikiAPIDateFormatter
        let oneDay = 60 * 60 * 24
        let activeEndDate = Date().addingTimeInterval(Double(oneDay))
        let activeEndDateString = dateFormatter.string(from: activeEndDate)
        
        return WMFFeatureConfigResponse.Common.YearInReview(year: 2025, activeStartDateString: "2025-12-01T00:00:00Z", activeEndDateString: activeEndDateString, dataStartDateString: "2025-01-01T00:00:00Z", dataEndDateString: "2025-12-01T00:00:00Z", languages: 300, articles: 10000000, savedArticlesApps: 37574993, viewsApps: 1000000000, editsApps: 124356, editsPerMinute: 342, averageArticlesReadPerYear: 335, edits: 81987181, editsEN: 31000000, hoursReadEN: 2423171000, yearsReadEN: 275000, topReadEN: testTopReadEN, topReadPercentages:testTopReadPercentages, bytesAddedEN: 1000000000, hideCountryCodes: testHideCountryCodes, hideDonateCountryCodes: testHideDonateCountryCodes)
    }
}
