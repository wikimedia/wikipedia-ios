import Foundation
import Contacts

@objc final public class WKDonateDataController: NSObject {
    
    // MARK: - Properties
    
    private let service = WKDataEnvironment.current.basicService
    private let sharedCacheStore = WKDataEnvironment.current.sharedCacheStore
    
    private(set) var donateConfig: WKDonateConfig?
    private(set) var paymentMethods: WKPaymentMethods?
    
    private let cacheDirectoryName = WKSharedCacheDirectoryNames.donorExperience.rawValue
    private let cacheDonateConfigFileName = "AppsDonationConfig"
    private let cachePaymentMethodsFileName = "PaymentMethods"
    
    // MARK: - Lifecycle
    
    public override init() {
        
    }
    
    // MARK: - Public
    
    public func loadConfigs() -> (donateConfig: WKDonateConfig?, paymentMethods: WKPaymentMethods?) {
        
        guard donateConfig == nil,
              paymentMethods == nil else {
            return (donateConfig, paymentMethods)
        }
        
        let donateConfigResponse: WKDonateConfigResponse? = try? sharedCacheStore?.load(key: cacheDirectoryName, cacheDonateConfigFileName)
        let paymentMethodsResponse: WKPaymentMethods? = try? sharedCacheStore?.load(key: cacheDirectoryName, cachePaymentMethodsFileName)
        
        donateConfig = donateConfigResponse?.config
        paymentMethods = paymentMethodsResponse
        
        return (donateConfig, paymentMethods)
    }
    
    @objc public func fetchConfigs(countryCode: String, paymentsAPIKey: String) {
        fetchConfigs(for: countryCode, paymentsAPIKey: paymentsAPIKey) { result in
            
        }
    }
    
    public func fetchConfigs(for countryCode: String, paymentsAPIKey: String, completion: @escaping (Result<Void, Error>) -> Void) {
        
        guard let service else {
            completion(.failure(WKDataControllerError.basicServiceUnavailable))
            return
        }
        
        let group = DispatchGroup()
        
        guard let paymentMethodsURL = URL.paymentMethodsAPIURL(),
              let donateConfigURL = URL.donateConfigURL() else {
            completion(.failure(WKDataControllerError.failureCreatingRequestURL))
            return
        }
        
        let paymentMethodParameters: [String: Any] = [
            "action": "getPaymentMethods",
            "country": countryCode,
            "api_key": paymentsAPIKey,
            "format": "json"
        ]
        
        let donateConfigParameters: [String: Any] = [
            "action": "raw"
        ]
        
        var errors: [Error] = []
        
        group.enter()
        let paymentMethodsRequest = WKBasicServiceRequest(url: paymentMethodsURL, method: .GET, parameters: paymentMethodParameters)
        service.performDecodableGET(request: paymentMethodsRequest) { [weak self] (result: Result<WKPaymentMethods, Error>) in
            defer {
                group.leave()
            }
            
            guard let self else {
                return
            }
            
            switch result {
            case .success(let paymentMethods):
                self.paymentMethods = paymentMethods
                try? self.sharedCacheStore?.save(key: cacheDirectoryName, cachePaymentMethodsFileName, value: paymentMethods)
            case .failure(let error):
                errors.append(error)
            }
        }
        
        group.enter()
        let donateConfigRequest = WKBasicServiceRequest(url: donateConfigURL, method: .GET, parameters: donateConfigParameters)
        service.performDecodableGET(request: donateConfigRequest) { [weak self] (result: Result<WKDonateConfigResponse, Error>) in
            
            defer {
                group.leave()
            }
            
            guard let self else {
                return
            }
            
            switch result {
            case .success(let response):
                self.donateConfig = response.config
                try? self.sharedCacheStore?.save(key: cacheDirectoryName, cacheDonateConfigFileName, value: response)
            case .failure(let error):
                errors.append(error)
            }
        }
        
        group.notify(queue: .main) {
            if let firstError = errors.first {
                completion(.failure(firstError))
                return
            }
            
            completion(.success(()))
        }
    }
    
    public func submitPayment(amount: Decimal, countryCode: String, currencyCode: String, languageCode: String, paymentToken: String, donorNameComponents: PersonNameComponents, recurring: Bool, donorEmail: String, donorAddressComponents: CNPostalAddress, emailOptIn: Bool?, transactionFee: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        
        guard let donatePaymentSubmissionURL = URL.donatePaymentSubmissionURL() else {
            completion(.failure(WKDataControllerError.failureCreatingRequestURL))
            return
        }
        
        var parameters: [String: String] = [
            "action": "submitPayment",
            "amount": (amount as NSNumber).stringValue,
            "currency": currencyCode,
            "recurring": recurring ? "1" : "0",
            "country": countryCode,
            "language": languageCode,
            "payment_token": paymentToken,
            "pay_the_fee": transactionFee ? "1" : "0",
            "full_name": donorNameComponents.formatted(.name(style: .long)),
            "email": donorEmail,
            "street_address": donorAddressComponents.street,
            "city": donorAddressComponents.city,
            "state_province": donorAddressComponents.state,
            "donor_country": donorAddressComponents.country,
            "postal_code": donorAddressComponents.postalCode
        ]
        
        if let emailOptIn,
           let firstName = donorNameComponents.givenName,
           let lastName = donorNameComponents.familyName {
            parameters["opt_in"] = emailOptIn ? "1" : "0"
            parameters["first_name"] = firstName
            parameters["last_name"] = lastName
        }
            
        let request = WKBasicServiceRequest(url: donatePaymentSubmissionURL, method: .POST, parameters: parameters, bodyContentType: .form)
        service?.performDecodablePOST(request: request, completion: { (result: Result<WKPaymentSubmissionResponse, Error>) in
            switch result {
            case .success(let response):
                switch response.response.status.lowercased() {
                case "success":
                    completion(.success(()))
                case "error":
                    completion(.failure(WKDonateDataControllerError.paymentsWikiResponseError(response.response.errorMessage)))
                default:
                    completion(.failure(WKServiceError.unexpectedResponse))
                }
                return
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }
}
