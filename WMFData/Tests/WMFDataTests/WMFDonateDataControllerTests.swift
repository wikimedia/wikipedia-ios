import XCTest
import Contacts
@testable import WMFData
@testable import WMFDataMocks

final class WMFDonateDataControllerTests: XCTestCase {
    
    private let controller: WMFDonateDataController = WMFDonateDataController.shared

    override func setUp() async throws {
        WMFDataEnvironment.current.basicService = WMFMockBasicService()
        WMFDataEnvironment.current.serviceEnvironment = .staging
        WMFDataEnvironment.current.sharedCacheStore = WMFMockKeyValueStore()
        self.controller.reset()
        self.controller.service = WMFDataEnvironment.current.basicService
        self.controller.sharedCacheStore = WMFDataEnvironment.current.sharedCacheStore
    }
    
    func testFetchDonateConfig() {
        
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
        
        let donateData = controller.loadConfigs()
        
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
        
        let expectation = XCTestExpectation(description: "Submit Payment")
        
        let nameComponents = PersonNameComponents()
        let addressComponents = CNPostalAddress()
        
        controller.submitPayment(amount: 3, countryCode: "US", currencyCode: "USD", languageCode: "EN", paymentToken: "fake-token", paymentNetwork: "Discover", donorNameComponents: nameComponents, recurring: true, donorEmail: "wikimediaTester1@gmail.com", donorAddressComponents: addressComponents, emailOptIn: nil, transactionFee: false, metricsID: "enUS_2024_09_iOS", appVersion: "7.4.3") { result in
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
        WMFDataEnvironment.current.basicService = WMFMockServiceNoInternetConnection()
        controller.service = WMFDataEnvironment.current.basicService
        
        let expectation = XCTestExpectation(description: "Fetch Donate Configs")
        
        controller.fetchConfigs(for: "US") { result in
            switch result {
            case .success:
                
                XCTFail("Unexpected success")
                
            case .failure:
                break
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        let donateData = controller.loadConfigs()
        
        let paymentMethods = donateData.paymentMethods
        let donateConfig = donateData.donateConfig
        
        XCTAssertNil(paymentMethods, "Expected Payment Methods")
        XCTAssertNil(donateConfig, "Expected Donate Config")
    }
    
    func testFetchDonateConfigWithCacheAndNoInternetConnection() {

        let expectation1 = XCTestExpectation(description: "Fetch Donate Configs with Internet Connection")
        let expectation2 = XCTestExpectation(description: "Fetch Donate Configs without Internet Connection")

        var connectedPaymentMethods: WMFPaymentMethods?
        var connectedDonateConfig: WMFDonateConfig?
        var notConnectedPaymentMethods: WMFPaymentMethods?
        var notConnectedDonateConfig: WMFDonateConfig?
        
        // First fetch successfully to populate cache
        controller.fetchConfigs(for: "US") { result in
            switch result {
            case .success:
                
                let donateData = self.controller.loadConfigs()
                
                connectedPaymentMethods = donateData.paymentMethods
                connectedDonateConfig = donateData.donateConfig
                
                // Drop Internet Connection
                WMFDataEnvironment.current.basicService = WMFMockServiceNoInternetConnection()
                self.controller.service = WMFDataEnvironment.current.basicService

                // Fetch again
                self.controller.fetchConfigs(for: "US") { result in
                    switch result {
                    case .success:
                        
                        XCTFail("Unexpected disconnected success")
                        
                    case .failure:
                        
                        // Despite failure, we still expect to be able to load configs from cache
                        let donateData = self.controller.loadConfigs()
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
        WMFDataEnvironment.current.basicService = WMFMockServiceNoInternetConnection()
        controller.service = WMFDataEnvironment.current.basicService
        
        let expectation = XCTestExpectation(description: "Submit Payment")
        
        let nameComponents = PersonNameComponents()
        let addressComponents = CNPostalAddress()
        
        controller.submitPayment(amount: 3, countryCode: "US", currencyCode: "USD", languageCode: "EN", paymentToken: "fake-token", paymentNetwork: "Discover", donorNameComponents: nameComponents, recurring: true, donorEmail: "wikimediaTester1@gmail.com", donorAddressComponents: addressComponents, emailOptIn: nil, transactionFee: false, metricsID: "enUS_2024_09_iOS", appVersion: "7.4.3") { result in
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
