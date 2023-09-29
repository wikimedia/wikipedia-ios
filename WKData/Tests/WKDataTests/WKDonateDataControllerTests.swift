import XCTest
import Contacts
@testable import WKData
@testable import WKDataMocks

final class WKDonateDataControllerTests: XCTestCase {
    
    let paymentsAPIKey = "ABCDPaymentAPIKeyEFGH"
    

    override func setUp() async throws {
        WKDataEnvironment.current.basicService = WKMockBasicService()
        WKDataEnvironment.current.serviceEnvironment = .staging
        WKDataEnvironment.current.sharedCacheStore = WKMockKeyValueStore()
    }
    
    func testFetchDonateConfig() {
        let controller = WKDonateDataController()
        
        let expectation = XCTestExpectation(description: "Fetch Donate Configs")
        
        controller.fetchConfigs(for: "US", paymentsAPIKey: paymentsAPIKey) { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                XCTFail("Failure fetching configs: \(error)")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        let donateData = WKDonateDataController().loadConfigs()
        
        let paymentMethods = donateData.paymentMethods
        let donateConfig = donateData.donateConfig
        
        XCTAssertNotNil(paymentMethods, "Expected Payment Methods")
        XCTAssertNotNil(donateConfig, "Expected Donate Config")
        
        guard let paymentMethods,
              let donateConfig else {
            return
        }
        
        XCTAssertEqual(donateConfig.version, 1, "Unexpected version")
        XCTAssertEqual(donateConfig.currencyMinimumDonation["USD"], 1, "Unexpected USD minimum")
        XCTAssertEqual(donateConfig.currencyMaximumDonation["USD"], 25000, "Unexpected USD maximum")
        XCTAssertEqual(donateConfig.currencyAmountPresets["USD"]?.count, 7, "Unexpected USD default options count")
        XCTAssertEqual(donateConfig.currencyAmountPresets["USD"]?[0], 3, "Unexpected USD default option first value")
        XCTAssertEqual(donateConfig.currencyTransactionFees["default"], 0.35, "Unexpected default transaction fee")
        XCTAssertTrue(donateConfig.countryCodeEmailOptInRequired.contains("AR"), "Missing AR from email opt in required list")
        XCTAssertEqual(paymentMethods.applePayPaymentNetworks, [.amex, .discover, .maestro, .masterCard, .visa], "Unexpected Apple Pay payment networks")
    }
    
    func testDonateSubmitPayment() {
        let controller = WKDonateDataController()
        
        let expectation = XCTestExpectation(description: "Submit Payment")
        
        let nameComponents = PersonNameComponents()
        let addressComponents = CNPostalAddress()
        
        controller.submitPayment(amount: 3, currencyCode: "USD", paymentToken: "fake-token", donorNameComponents: nameComponents, recurring: true, donorEmail: "wikimediaTester1@gmail.com", donorAddressComponents: addressComponents, emailOptIn: nil, transactionFee: false, paymentsAPIKey: "fake-api-key") { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                XCTFail("Failure submitting payment: \(error)")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testFetchDonateConfigWithNoCacheAndNoInternetConnection() {
        WKDataEnvironment.current.basicService = WKMockServiceNoInternetConnection()
        let controller = WKDonateDataController()
        
        let expectation = XCTestExpectation(description: "Fetch Donate Configs")
        
        controller.fetchConfigs(for: "US", paymentsAPIKey: paymentsAPIKey) { result in
            switch result {
            case .success:
                
                XCTFail("Unexpected success")
                
            case .failure:
                break
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        let donateData = WKDonateDataController().loadConfigs()
        
        let paymentMethods = donateData.paymentMethods
        let donateConfig = donateData.donateConfig
        
        XCTAssertNil(paymentMethods, "Expected Payment Methods")
        XCTAssertNil(donateConfig, "Expected Donate Config")
    }
    
    func testFetchDonateConfigWithCacheAndNoInternetConnection() {

        let expectation1 = XCTestExpectation(description: "Fetch Donate Configs with Internet Connection")
        let expectation2 = XCTestExpectation(description: "Fetch Donate Configs without Internet Connection")

        var connectedPaymentMethods: WKPaymentMethods?
        var connectedDonateConfig: WKDonateConfig?
        var notConnectedPaymentMethods: WKPaymentMethods?
        var notConnectedDonateConfig: WKDonateConfig?
        
        // First fetch successfully to populate cache
        let connectedController = WKDonateDataController()
        connectedController.fetchConfigs(for: "US", paymentsAPIKey: paymentsAPIKey) { result in
            switch result {
            case .success:
                
                let donateData = WKDonateDataController().loadConfigs()
                
                connectedPaymentMethods = donateData.paymentMethods
                connectedDonateConfig = donateData.donateConfig
                
                // Drop Internet Connection
                WKDataEnvironment.current.basicService = WKMockServiceNoInternetConnection()
                let disconnectedController = WKDonateDataController()

                // Fetch again
                disconnectedController.fetchConfigs(for: "US", paymentsAPIKey: self.paymentsAPIKey) { result in
                    switch result {
                    case .success:
                        
                        XCTFail("Unexpected disconnected success")
                        
                    case .failure:
                        
                        // Despite failure, we still expect to be able to load configs from cache
                        let donateData = disconnectedController.loadConfigs()
                        notConnectedPaymentMethods = donateData.paymentMethods
                        notConnectedDonateConfig = donateData.donateConfig
                        
                    }
                    
                    expectation2.fulfill()
                }
            case .failure:
                XCTFail("Unexpected connected failure")
            }
            
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: 10.0)
        wait(for: [expectation2], timeout: 10.0)
        
        XCTAssertNotNil(connectedPaymentMethods, "Expected Payment Methods")
        XCTAssertNotNil(connectedDonateConfig, "Expected Donate Config")
        XCTAssertNotNil(notConnectedPaymentMethods, "Expected Payment Methods")
        XCTAssertNotNil(notConnectedDonateConfig, "Expected Donate Config")
    }
    
    func testDonateSubmitPaymentNoInternetConnection() {
        WKDataEnvironment.current.basicService = WKMockServiceNoInternetConnection()
        let controller = WKDonateDataController()
        
        let expectation = XCTestExpectation(description: "Submit Payment")
        
        let nameComponents = PersonNameComponents()
        let addressComponents = CNPostalAddress()
        
        controller.submitPayment(amount: 3, currencyCode: "USD", paymentToken: "fake-token", donorNameComponents: nameComponents, recurring: true, donorEmail: "wikimediaTester1@gmail.com", donorAddressComponents: addressComponents, emailOptIn: nil, transactionFee: false, paymentsAPIKey: "fake-api-key") { result in
            switch result {
            case .success:
                XCTFail("Expected submitPayment to fail")
            case .failure:
                break
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }

}
