import XCTest
@testable import WKData
@testable import WKDataMocks

final class WKDonateDataControllerTests: XCTestCase {

    override func setUp() async throws {
        WKDataEnvironment.current.basicService = WKMockDonateBasicService()
        WKDataEnvironment.current.serviceEnvironment = .staging
    }
    
    func testFetchDonateConfig() {
        let controller = WKDonateDataController()
        
        let expectation = XCTestExpectation(description: "Fetch Donate Configs")
        
        controller.fetchConfigs(for: "US") { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                XCTFail("Failure fetching configs: \(error)")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        let paymentMethods = WKDonateDataController.paymentMethods
        let donateConfig = WKDonateDataController.donateConfig
        
        XCTAssertNotNil(paymentMethods, "Expected Payment Methods")
        XCTAssertNotNil(donateConfig, "Expected Donate Config")
        
        guard let paymentMethods,
              let donateConfig else {
            return
        }
        
        XCTAssertEqual(donateConfig.version, 1, "Unexpected version")
        XCTAssertEqual(donateConfig.currencyMinimums["USD"], 1, "Unexpected USD minimum")
        XCTAssertEqual(donateConfig.currencyMaximums["USD"], 25000, "Unexpected USD maximum")
        XCTAssertEqual(donateConfig.currencyAmounts7["USD"]?.count, 7, "Unexpected USD default options count")
        XCTAssertEqual(donateConfig.currencyAmounts7["USD"]?[0], 3, "Unexpected USD default option first value")
        XCTAssertEqual(donateConfig.currencyTransactionFees["default"], 0.35, "Unexpected default transaction fee")
        XCTAssertTrue(donateConfig.countryCodeEmailOptInRequired.contains("AR"), "Missing AR from email opt in required list")
        XCTAssertEqual(paymentMethods.applePayPaymentNetworks, [.amex, .discover, .maestro, .masterCard, .visa], "Unexpected Apple Pay payment networks")
    }
    
    func testDonateSubmitPayment() {
        let controller = WKDonateDataController()
        
        let expectation = XCTestExpectation(description: "Fetch Donate Configs")
        
        controller.submitPayment(amount: 3, currencyCode: "USD", paymentToken: "fake-token", donorName: "iOS Tester", donorEmail: "wikimediaTester1@gmail.com", donorAddress: "123 Fake Street\nFaketown AA 12345\nUnited States", emailOptIn: nil) { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                XCTFail("Failure fetching configs: \(error)")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }

}
