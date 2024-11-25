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
            
            guard let config = controller.loadFeatureConfig(),
                  let iosConfig = config.ios.first,
            let yirConfig = config.ios.first?.yir(yearID: "2024.2") else {
                XCTFail("Failure loading feature config")
                return
            }
            
            XCTAssertEqual(iosConfig.version, 1, "Unexpected feature config version")
            XCTAssertEqual(yirConfig.isEnabled, true, "Unexpected feature config yir isEnabled")
            XCTAssertEqual(yirConfig.countryCodes.count, 2, "Unexpected feature config yir countryCodes count")
            XCTAssertEqual(yirConfig.primaryAppLanguageCodes.count, 3, "Unexpected feature config yir primaryAppLanguageCodes count")
            XCTAssertEqual(yirConfig.dataPopulationStartDateString, "2024-01-01T00:00:00Z", "Unexpected feature config yir dataPopulationStartDateString")
            XCTAssertEqual(yirConfig.dataPopulationEndDateString, "2024-12-31T23:59:59Z", "Unexpected feature config yir dataPopulationEndDateString")
            XCTAssertEqual(yirConfig.personalizedSlides.readCount.isEnabled, true, "Unexpected feature config yir personalizedSlides readCount isEnabled flag")
            XCTAssertEqual(yirConfig.personalizedSlides.editCount.isEnabled, true, "Unexpected feature config yir personalizedSlides editCount isEnabled flag")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
}
