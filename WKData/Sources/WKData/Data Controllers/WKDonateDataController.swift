import Foundation

final public class WKDonateDataController {
    
    // MARK: - Properties
    
    private let service = WKDataEnvironment.current.basicService
    
    public static private(set) var donateConfig: WKDonateConfig?
    public static private(set) var paymentMethods: WKPaymentMethods?
    
    // MARK: - Lifecycle
    
    public init() {
        
    }
    
    // MARK: - Public
    
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
            "format": "json"
        ]
        
        let donateConfigParameters: [String: Any] = [
            "action": "raw"
        ]
        
        // TODO: Also fetch AppsCampaignConfig https://donate.wikimedia.org/wiki/MediaWiki:AppsCampaignConfig.json?action=raw here
        
        // TODO: Send in API key
        
        var errors: [Error] = []
        
        group.enter()
        let paymentMethodsRequest = WKBasicServiceRequest(url: paymentMethodsURL, method: .GET, parameters: paymentMethodParameters)
        service.performDecodableGET(request: paymentMethodsRequest) { (result: Result<WKPaymentMethods, Error>) in
            defer {
                group.leave()
            }
            
            switch result {
            case .success(let paymentMethods):
                Self.paymentMethods = paymentMethods
            case .failure(let error):
                errors.append(error)
            }
        }
        
        group.enter()
        let donateConfigRequest = WKBasicServiceRequest(url: donateConfigURL, method: .GET, parameters: donateConfigParameters)
        service.performDecodableGET(request: donateConfigRequest) { (result: Result<WKDonateConfigResponse, Error>) in
            defer {
                group.leave()
            }
            
            switch result {
            case .success(let response):
                Self.donateConfig = response.config
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
    
    public func submitPayment(amount: Decimal, currencyCode: String, paymentToken: String, donorName: String, donorEmail: String, donorAddress: String, emailOptIn: Bool?, paymentsAPIKey: String, completion: @escaping (Result<Void, Error>) -> Void) {
        
        guard let donatePaymentSubmissionURL = URL.donatePaymentSubmissionURL() else {
            completion(.failure(WKDataControllerError.failureCreatingRequestURL))
            return
        }
        
        let donorInfo: [String: Any] = [
            "name": donorName,
            "email": donorEmail,
            "address": donorAddress
        ]
        
        var parameters: [String: Any] = [
            "action": "submitPayment",
            "amount": amount,
            "currency": currencyCode,
            "payment_token": paymentToken,
            "donor_info": donorInfo
        ]
        
        if let emailOptIn {
            parameters["opt_in"] = emailOptIn
        }
        
        // TODO: Send in API key
            
        let request = WKBasicServiceRequest(url: donatePaymentSubmissionURL, method: .POST, parameters: parameters, bodyContentType: .json)
        service?.performDecodablePOST(request: request, completion: { (result: Result<WKPaymentSubmissionResponse, Error>) in
            switch result {
            case .success(let response):
                guard response.response.status == "Success" else {
                    return
                }
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            
            }
        })
    }
}
