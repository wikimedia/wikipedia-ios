import XCTest
import Contacts
@testable import WMFData
@testable import WMFDataMocks

final class WMFDonateDataControllerTests: XCTestCase {
    
    private var controller: WMFDonateDataController?

    override func setUp() async throws {
        let service = WMFMockBasicService()
        WMFDataEnvironment.current.basicService = service
        WMFDataEnvironment.current.serviceEnvironment = .staging
        let store = WMFMockKeyValueStore()
        WMFDataEnvironment.current.sharedCacheStore = store
        self.controller = WMFDonateDataController.shared
        await controller?.setService(service)
        await controller?.setSharedCacheStore(store)
        await controller?.reset()
    }
    
    func testFetchDonateConfig() async throws {
        
        guard let controller else {
            throw WMFDataControllerError.unexpectedResponse
        }
        
        try await controller.fetchConfigs(for: "US")
        
        let donateData = await controller.loadConfigs()
        
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
    
    func testDonateSubmitPayment() async throws {
        
        guard let controller else {
            throw WMFDataControllerError.unexpectedResponse
        }
        
        let nameComponents = PersonNameComponents()
        let addressComponents = CNPostalAddress()
        
        try await controller.submitPayment(amount: 3, countryCode: "US", currencyCode: "USD", languageCode: "EN", paymentToken: "fake-token", paymentNetwork: "Discover", donorNameComponents: nameComponents, recurring: true, donorEmail: "wikimediaTester1@gmail.com", donorAddressComponents: addressComponents, emailOptIn: nil, transactionFee: false, metricsID: "enUS_2024_09_iOS", appVersion: "7.4.3", appInstallID: UUID().uuidString)
    }
    
    func testFetchDonateConfigWithNoCacheAndNoInternetConnection() async throws {
        
        guard let controller else {
            throw WMFDataControllerError.unexpectedResponse
        }
        
        let service = WMFMockServiceNoInternetConnection()
        WMFDataEnvironment.current.basicService = service
        await controller.setService(service)
        
        do {
            try await controller.fetchConfigs(for: "US")
        } catch {
            
        }
        
        let donateData = await controller.loadConfigs()
        
        let paymentMethods = donateData.paymentMethods
        let donateConfig = donateData.donateConfig
        
        XCTAssertNil(paymentMethods, "Expected Payment Methods")
        XCTAssertNil(donateConfig, "Expected Donate Config")
    }
    
    func testFetchDonateConfigWithCacheAndNoInternetConnection() async throws {
        
        guard let controller else {
            throw WMFDataControllerError.unexpectedResponse
        }

        var connectedPaymentMethods: WMFPaymentMethods?
        var connectedDonateConfig: WMFDonateConfig?
        var notConnectedPaymentMethods: WMFPaymentMethods?
        var notConnectedDonateConfig: WMFDonateConfig?
        
        // First fetch successfully to populate cache
        try await controller.fetchConfigs(for: "US")
        
        let donateData = await controller.loadConfigs()
        
        connectedPaymentMethods = donateData.paymentMethods
        connectedDonateConfig = donateData.donateConfig
        
        // Drop Internet Connection
        let noConnectionService = WMFMockServiceNoInternetConnection()
        WMFDataEnvironment.current.basicService = noConnectionService
        await controller.setService(noConnectionService)

        // Fetch again
        do {
            try await controller.fetchConfigs(for: "US")
        } catch {
            // Despite failure, we still expect to be able to load configs from cache
            let donateData = await controller.loadConfigs()
            notConnectedPaymentMethods = donateData.paymentMethods
            notConnectedDonateConfig = donateData.donateConfig
        }
        
        XCTAssertNotNil(connectedPaymentMethods, "Expected Payment Methods")
        XCTAssertNotNil(connectedDonateConfig, "Expected Donate Config")
        XCTAssertNotNil(notConnectedPaymentMethods, "Expected Payment Methods")
        XCTAssertNotNil(notConnectedDonateConfig, "Expected Donate Config")
    }
    
    func testDonateSubmitPaymentNoInternetConnection() async throws {
        
        guard let controller else {
            throw WMFDataControllerError.unexpectedResponse
        }
        
        // Drop Internet Connection
        let noConnectionService = WMFMockServiceNoInternetConnection()
        WMFDataEnvironment.current.basicService = noConnectionService
        await controller.setService(noConnectionService)
        
        let nameComponents = PersonNameComponents()
        let addressComponents = CNPostalAddress()
        
        do {
            try await controller.submitPayment(amount: 3, countryCode: "US", currencyCode: "USD", languageCode: "EN", paymentToken: "fake-token", paymentNetwork: "Discover", donorNameComponents: nameComponents, recurring: true, donorEmail: "wikimediaTester1@gmail.com", donorAddressComponents: addressComponents, emailOptIn: nil, transactionFee: false, metricsID: "enUS_2024_09_iOS", appVersion: "7.4.3", appInstallID: UUID().uuidString)
                XCTFail("Expected submitPayment to fail")
        } catch {
            
        }
    }

}
