import XCTest
@testable import WMFData
@testable import WMFDataMocks

final class WMFDeveloperSettingsDataControllerTests: XCTestCase {
    
    private var controller: WMFDeveloperSettingsDataController?
    
    override func setUp() async throws {
        WMFDataEnvironment.current.basicService = WMFMockBasicService()
        WMFDataEnvironment.current.sharedCacheStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.appData = WMFAppData(appLanguages: [WMFLanguage(languageCode: "en", languageVariantCode: nil)])
        self.controller = WMFDeveloperSettingsDataController()
    }
    
    func testFetchFeatureConfigAndLoad() {
        
        guard let controller else {
            XCTFail("Missing WMFDeveloperSettingsDataController")
            return
        }
        
        let expectation = XCTestExpectation(description: "Fetch Config")
        
        controller.fetchFeatureConfig { error in
            guard error == nil else {
                XCTFail("Failure fetching feature config")
                return
            }
            
            guard let config = controller.loadFeatureConfig(),
                  let yirConfig = config.common.yir(year: 2025) else {
                XCTFail("Failure loading feature config")
                return
            }
            
            XCTAssertEqual(yirConfig.year, 2025, "Unexpected feature config yir")
            XCTAssertEqual(yirConfig.activeStartDateString, "2025-12-01T00:00:00Z", "Unexpected feature config yir")
            XCTAssertEqual(yirConfig.activeEndDateString, "2026-02-01T00:00:00Z", "Unexpected feature config yir")
            XCTAssertEqual(yirConfig.dataStartDateString, "2025-01-01T00:00:00Z", "Unexpected feature config yir")
            XCTAssertEqual(yirConfig.dataEndDateString, "2025-12-01T00:00:00Z", "Unexpected feature config yir")
            XCTAssertEqual(yirConfig.languages, 300, "Unexpected feature config yir")
            XCTAssertEqual(yirConfig.articles, 10000000, "Unexpected feature config yir")
            XCTAssertEqual(yirConfig.savedArticlesApps, 37574993, "Unexpected feature config yir")
            XCTAssertEqual(yirConfig.viewsApps, 1000000000, "Unexpected feature config yir")
            XCTAssertEqual(yirConfig.editsApps, 124356, "Unexpected feature config yir")
            XCTAssertEqual(yirConfig.editsPerMinute, 342, "Unexpected feature config yir")
            XCTAssertEqual(yirConfig.averageArticlesReadPerYear, 335, "Unexpected feature config yir")
            XCTAssertEqual(yirConfig.edits, 81987181, "Unexpected feature config yir")
            XCTAssertEqual(yirConfig.editsEN, 31000000, "Unexpected feature config yir")
            XCTAssertEqual(yirConfig.bytesAddedEN, 1000000000, "Unexpected feature config yir")
            XCTAssertEqual(yirConfig.hoursReadEN, 2423171000, "Unexpected feature config yir")
            XCTAssertEqual(yirConfig.yearsReadEN, 275000, "Unexpected feature config yir")
            XCTAssertEqual(yirConfig.topReadEN.count, 5, "Unexpected feature config yir")
            XCTAssertEqual(yirConfig.topReadPercentages.count, 8, "Unexpected feature config yir")
            XCTAssertEqual(yirConfig.hideCountryCodes.count, 22, "Unexpected feature config yir")
            XCTAssertEqual(yirConfig.hideDonateCountryCodes.count, 30, "Unexpected feature config yir")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
}
