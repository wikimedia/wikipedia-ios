import XCTest
@testable import WMFData
@testable import WMFDataMocks

final class WMFDeveloperSettingsDataControllerTests: XCTestCase {
    
    private var controller: WMFDeveloperSettingsDataController?
    
    override func setUp() async throws {
        WMFDataEnvironment.current.basicService = WMFMockBasicService()
        WMFDataEnvironment.current.serviceEnvironment = .staging
        WMFDataEnvironment.current.sharedCacheStore = WMFMockKeyValueStore()
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
            
            guard let config = controller.loadFeatureConfig() else {
                XCTFail("Failure loading feature config")
                return
            }
            
            XCTAssertEqual(config.ios.first?.version, 1, "Unexpected feature config version")
            XCTAssertEqual(config.ios.first?.yirIsEnabled, true, "Unexpected feature config yirIsEnabled")
            XCTAssertEqual(config.ios.first?.yirCountryCodes.count, 2, "Unexpected feature config yirCountryCodes count")
            XCTAssertEqual(config.ios.first?.yirPrimaryAppLanguageCodes.count, 2, "Unexpected feature config yirPrimaryAppLanguageCodes count")
            XCTAssertEqual(config.ios.first?.yirDataPopulationStartDateString, "2024-01-01T00:00:00Z", "Unexpected feature config yirDataPopulationStartDateString")
            XCTAssertEqual(config.ios.first?.yirDataPopulationEndDateString, "2024-11-01T00:00:00Z", "Unexpected feature config yirDataPopulationStartDateString")
            XCTAssertEqual(config.ios.first?.yirDataPopulationFetchMaxPagesPerSession, 3, "Unexpected feature config yirDataPopulationFetchMaxPagesPerSession")
            XCTAssertEqual(config.ios.first?.yirPersonalizedSlides.count, 8, "Unexpected feature config yirPersonalizedSlides count")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
}
