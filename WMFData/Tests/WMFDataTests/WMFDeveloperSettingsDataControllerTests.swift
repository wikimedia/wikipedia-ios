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
            XCTAssertEqual(config.ios.first?.yir.isEnabled, true, "Unexpected feature config yir isEnabled")
            XCTAssertEqual(config.ios.first?.yir.countryCodes.count, 2, "Unexpected feature config yir countryCodes count")
            XCTAssertEqual(config.ios.first?.yir.primaryAppLanguageCodes.count, 2, "Unexpected feature config yir primaryAppLanguageCodes count")
            XCTAssertEqual(config.ios.first?.yir.dataPopulationStartDateString, "2024-01-01T00:00:00Z", "Unexpected feature config yir dataPopulationStartDateString")
            XCTAssertEqual(config.ios.first?.yir.dataPopulationEndDateString, "2024-11-01T00:00:00Z", "Unexpected feature config yir dataPopulationEndDateString")
            XCTAssertEqual(config.ios.first?.yir.personalizedSlides.readCount.isEnabled, true, "Unexpected feature config yir personalizedSlides readCount isEnabled flag")
            XCTAssertEqual(config.ios.first?.yir.personalizedSlides.editCount.isEnabled, true, "Unexpected feature config yir personalizedSlides editCount isEnabled flag")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
}
