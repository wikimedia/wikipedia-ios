import Contacts
import Foundation
import Testing
@testable import WMFData
@testable import WMFDataMocks

@Suite(.serialized)
struct WMFDonateDataControllerTests {

    private let controller: WMFDonateDataController

    init() {
        controller = WMFDonateDataController(service: WMFDonateRequestMockService(), sharedCacheStore: WMFMockKeyValueStore())
    }

    @Test
    func fetchDonateConfig() async throws {
        try await controller.fetchConfigs(for: "US")

        let donateData = controller.loadConfigs()
        let paymentMethods = try #require(donateData.paymentMethods)
        let donateConfig = try #require(donateData.donateConfig)

        #expect(donateConfig.version == 1)
        #expect(donateConfig.currencyMinimumDonation["USD"] == 1)
        #expect(donateConfig.currencyMaximumDonation["USD"] == 25000)
        #expect(donateConfig.currencyAmountPresets["USD"]?.count == 7)
        #expect(donateConfig.currencyAmountPresets["USD"]?[0] == 3)
        #expect(donateConfig.currencyTransactionFees["default"] == 0.35)
        #expect(donateConfig.countryCodeEmailOptInRequired.contains("AR"))
        #expect(paymentMethods.applePayPaymentNetworks == [.amex, .discover, .maestro, .masterCard, .visa])
    }

    @Test
    func donateSubmitPayment() async throws {
        try await controller.submitPayment()
    }

    @Test
    func fetchDonateConfigWithNoCacheAndNoInternetConnection() async throws {
        controller.service = WMFMockServiceNoInternetConnection()

        let error = try #require(await #expect(throws: NSError.self) {
            try await controller.fetchConfigs(for: "US")
        })
        #expect(error.domain == NSURLErrorDomain)
        #expect(error.code == NSURLErrorNotConnectedToInternet)

        let donateData = controller.loadConfigs()

        #expect(donateData.paymentMethods == nil)
        #expect(donateData.donateConfig == nil)
    }

    @Test
    func fetchDonateConfigWithCacheAndNoInternetConnection() async throws {
        try await controller.fetchConfigs(for: "US")

        let connectedDonateData = controller.loadConfigs()
        let connectedPaymentMethods = try #require(connectedDonateData.paymentMethods)
        let connectedDonateConfig = try #require(connectedDonateData.donateConfig)

        controller.service = WMFMockServiceNoInternetConnection()

        let error = try #require(await #expect(throws: NSError.self) {
            try await controller.fetchConfigs(for: "US")
        })
        #expect(error.domain == NSURLErrorDomain)
        #expect(error.code == NSURLErrorNotConnectedToInternet)

        let notConnectedDonateData = controller.loadConfigs()
        let notConnectedPaymentMethods = try #require(notConnectedDonateData.paymentMethods)
        let notConnectedDonateConfig = try #require(notConnectedDonateData.donateConfig)

        #expect(connectedPaymentMethods.applePayPaymentNetworks == notConnectedPaymentMethods.applePayPaymentNetworks)
        #expect(connectedDonateConfig.version == notConnectedDonateConfig.version)
    }

    @Test
    func donateSubmitPaymentNoInternetConnection() async throws {
        controller.service = WMFMockServiceNoInternetConnection()

        let error = try #require(await #expect(throws: NSError.self) {
            try await controller.submitPayment()
        })
        #expect(error.domain == NSURLErrorDomain)
        #expect(error.code == NSURLErrorNotConnectedToInternet)
    }
}

private final class WMFDonateRequestMockService: WMFService {
    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<Data, Error>) -> Void) {
        completion(.failure(WMFServiceError.unexpectedResponse))
    }

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<[String: Any]?, Error>) -> Void) {
        completion(.failure(WMFServiceError.unexpectedResponse))
    }

    func performDecodableGET<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        if isPaymentMethodsRequest(request) {
            WMFMockBasicService(jsonResourceName: "donate-get-payment-methods").performDecodableGET(request: request, completion: completion)
        } else if isDonateConfigRequest(request) {
            WMFMockBasicService(jsonResourceName: "donate-get-config").performDecodableGET(request: request, completion: completion)
        } else {
            completion(.failure(WMFServiceError.unexpectedResponse))
        }
    }

    func performDecodablePOST<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        if isSubmitPaymentRequest(request) {
            WMFMockBasicService(jsonResourceName: "donate-post-submit-payment-success").performDecodablePOST(request: request, completion: completion)
        } else {
            completion(.failure(WMFServiceError.unexpectedResponse))
        }
    }

    func clearCachedData() {}

    private func isPaymentMethodsRequest(_ request: WMFServiceRequest) -> Bool {
        request.method == .GET &&
            request.url?.host == "payments.wikimedia.org" &&
            request.parameters?["action"] as? String == "getPaymentMethods" &&
            request.parameters?["country"] as? String == "US" &&
            request.parameters?["format"] as? String == "json"
    }

    private func isDonateConfigRequest(_ request: WMFServiceRequest) -> Bool {
        request.method == .GET &&
            request.url?.path == "/wiki/MediaWiki:AppsDonationConfig.json" &&
            ["donate.wikimedia.org", "test.wikipedia.org"].contains(request.url?.host) &&
            request.parameters?["action"] as? String == "raw"
    }

    private func isSubmitPaymentRequest(_ request: WMFServiceRequest) -> Bool {
        request.method == .POST &&
            request.url?.host == "payments.wikimedia.org" &&
            request.parameters?["action"] as? String == "submitPayment" &&
            request.parameters?["amount"] as? String == "3" &&
            request.parameters?["country"] as? String == "US" &&
            request.parameters?["currency"] as? String == "USD"
    }
}

private extension WMFDonateDataController {
    func fetchConfigs(for countryCode: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            fetchConfigs(for: countryCode) { result in
                continuation.resume(with: result)
            }
        }
    }

    func submitPayment() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let nameComponents = PersonNameComponents()
            let addressComponents = CNPostalAddress()

            submitPayment(
                amount: 3,
                countryCode: "US",
                currencyCode: "USD",
                languageCode: "EN",
                paymentToken: "fake-token",
                paymentNetwork: "Discover",
                donorNameComponents: nameComponents,
                recurring: true,
                donorEmail: "wikimediaTester1@gmail.com",
                donorAddressComponents: addressComponents,
                emailOptIn: nil,
                transactionFee: false,
                metricsID: "enUS_2024_09_iOS",
                appVersion: "7.4.3",
                appInstallID: UUID().uuidString
            ) { result in
                continuation.resume(with: result)
            }
        }
    }
}
