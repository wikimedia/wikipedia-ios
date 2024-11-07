import Foundation
import Contacts

@objc final public class WMFDonateDataController: NSObject {
    
    // MARK: - Properties
    
    var service: WMFService?
    var sharedCacheStore: WMFKeyValueStore?
    
    private var donateConfig: WMFDonateConfig?
    private var paymentMethods: WMFPaymentMethods?
    
    private let cacheDirectoryName = WMFSharedCacheDirectoryNames.donorExperience.rawValue
    private let cacheDonateConfigContainerFileName = "AppsDonationConfig"
    private let cachePaymentMethodsResponseFileName = "PaymentMethods"
    private let cacheLocalDonateHistoryFileName = "AppLocalDonationHistory"

    private let userDefaultsStore = WMFDataEnvironment.current.userDefaultsStore

    public var hasLocallySavedDonations: Bool {
        get {
            return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.hasLocallySavedDonations.rawValue)) ?? false
        } set {
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.hasLocallySavedDonations.rawValue, value: newValue)
        }
    }

    // MARK: - Lifecycle
    
    @objc(sharedInstance)
    public static let shared = WMFDonateDataController()
    
    public init(service: WMFService? = WMFDataEnvironment.current.basicService, sharedCacheStore: WMFKeyValueStore? = WMFDataEnvironment.current.sharedCacheStore) {
       self.service = service
        self.sharedCacheStore = sharedCacheStore
   }
    
    // MARK: - Public
    
    public func loadConfigs() -> (donateConfig: WMFDonateConfig?, paymentMethods: WMFPaymentMethods?) {
        
        // First pull from memory
        guard donateConfig == nil,
              paymentMethods == nil else {
            return (donateConfig, paymentMethods)
        }
        
        // Fall back to persisted objects if within seven days
        let donateConfig: WMFDonateConfig? = try? sharedCacheStore?.load(key: cacheDirectoryName, cacheDonateConfigContainerFileName)
        let paymentMethods: WMFPaymentMethods? = try? sharedCacheStore?.load(key: cacheDirectoryName, cachePaymentMethodsResponseFileName)
        
        guard let donateConfigCachedDate = donateConfig?.cachedDate,
              let paymentMethodsCachedDate = paymentMethods?.cachedDate else {
            return (nil, nil)
        }
        
        let sevenDays = TimeInterval(60 * 60 * 24 * 7)
        guard (-donateConfigCachedDate.timeIntervalSinceNow) < sevenDays,
              (-paymentMethodsCachedDate.timeIntervalSinceNow) < sevenDays else {
            return (nil, nil)
        }
        
        self.donateConfig = donateConfig
        self.paymentMethods = paymentMethods
        
        return (self.donateConfig, self.paymentMethods)
    }
    
    @objc public func fetchConfigsForCountryCode(_ countryCode: String, completion: @escaping (Error?) -> Void) {
        fetchConfigs(for: countryCode) { result in
            switch result {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }
    
    public func fetchConfigs(for countryCode: String, completion: @escaping (Result<Void, Error>) -> Void) {
        
        guard let service else {
            completion(.failure(WMFDataControllerError.basicServiceUnavailable))
            return
        }
        
        let group = DispatchGroup()
        
        guard let paymentMethodsURL = URL.paymentMethodsAPIURL(),
              let donateConfigURL = URL.donateConfigURL() else {
            completion(.failure(WMFDataControllerError.failureCreatingRequestURL))
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
        
        var errors: [Error] = []
        
        var donateConfig: WMFDonateConfig?
        var paymentMethods: WMFPaymentMethods?
        
        group.enter()
        let paymentMethodsRequest = WMFBasicServiceRequest(url: paymentMethodsURL, method: .GET, parameters: paymentMethodParameters, acceptType: .json)
        service.performDecodableGET(request: paymentMethodsRequest) { (result: Result<WMFPaymentMethods, Error>) in
            defer {
                group.leave()
            }
            
            switch result {
            case .success(let response):
                paymentMethods = response
            case .failure(let error):
                errors.append(error)
            }
        }
        
        group.enter()
        let donateConfigRequest = WMFBasicServiceRequest(url: donateConfigURL, method: .GET, parameters: donateConfigParameters, acceptType: .json)
        service.performDecodableGET(request: donateConfigRequest) { (result: Result<WMFDonateConfigResponse, Error>) in
            
            defer {
                group.leave()
            }
            
            switch result {
            case .success(let response):
                donateConfig = response.config
            case .failure(let error):
                errors.append(error)
            }
        }
        
        group.notify(queue: .main) {

            if let firstError = errors.first {
                self.donateConfig = nil
                self.paymentMethods = nil
                completion(.failure(firstError))
                return
            }
            
            guard var donateConfig,
                var paymentMethods else {
                self.donateConfig = nil
                self.paymentMethods = nil
                completion(.failure(WMFServiceError.unexpectedResponse))
                return
            }
            
            donateConfig.cachedDate = Date()
            paymentMethods.cachedDate = Date()
            
            self.donateConfig = donateConfig
            self.paymentMethods = paymentMethods
            
            try? self.sharedCacheStore?.save(key: self.cacheDirectoryName, self.cacheDonateConfigContainerFileName, value: donateConfig)
            try? self.sharedCacheStore?.save(key: self.cacheDirectoryName, self.cachePaymentMethodsResponseFileName, value: paymentMethods)
            
            completion(.success(()))
        }
    }
    
    public func submitPayment(amount: Decimal, countryCode: String, currencyCode: String, languageCode: String, paymentToken: String, paymentNetwork: String?, donorNameComponents: PersonNameComponents, recurring: Bool, donorEmail: String, donorAddressComponents: CNPostalAddress, emailOptIn: Bool?, transactionFee: Bool, metricsID: String?, appVersion: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        
        guard !WMFDeveloperSettingsDataController.shared.bypassDonation else {
            completion(.success(()))
            return
        }
        
        guard let donatePaymentSubmissionURL = URL.donatePaymentSubmissionURL() else {
            completion(.failure(WMFDataControllerError.failureCreatingRequestURL))
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
            "donor_country": donorAddressComponents.isoCountryCode,
            "postal_code": donorAddressComponents.postalCode,
            "payment_method": "applepay",
            "format": "json"
        ]
        
        if let emailOptIn {
            parameters["opt_in"] = emailOptIn ? "1" : "0"
        }
        
        if let firstName = donorNameComponents.givenName {
            parameters["first_name"] = firstName
        }
        
        if let lastName = donorNameComponents.familyName {
            parameters["last_name"] = lastName
        }
        
        if let paymentNetwork {
            parameters["payment_network"] = paymentNetwork
        }
        
        if let metricsID {
            parameters["banner"] = metricsID
        }
        
        if let appVersion {
            parameters["app_version"] = appVersion
        }
            
        let request = WMFBasicServiceRequest(url: donatePaymentSubmissionURL, method: .POST, parameters: parameters, contentType: .form, acceptType: .json)
        service?.performDecodablePOST(request: request, completion: { (result: Result<WMFPaymentSubmissionResponse, Error>) in
            switch result {
            case .success(let response):
                switch response.response.status.lowercased() {
                case "success":
                    completion(.success(()))
                case "error":
                    completion(.failure(WMFDonateDataControllerError.paymentsWikiResponseError(reason: response.response.errorMessage, orderID: response.response.orderID)))
                default:
                    completion(.failure(WMFServiceError.unexpectedResponse))
                }
                return
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }

    @discardableResult
    public func saveLocalDonationHistory(type: WMFDonateLocalHistory.DonationType, amount: Decimal, currencyCode: String, isNative: Bool) -> [WMFDonateLocalHistory]? {
        
        let currentDate = Date()
        let timestamp = DateFormatter.mediaWikiAPIDateFormatter.string(from: currentDate)
        
        let donateHistory: [WMFDonateLocalHistory]? = loadLocalDonationHistory(startDate: nil, endDate: nil)
        let isFirstDonation = donateHistory?.count ?? 0 == 0
        
        let donationHistoryEntry = WMFDonateLocalHistory(donationTimestamp: timestamp,
                                                         donationType: type,
                                                         donationAmount: amount,
                                                         currencyCode: currencyCode,
                                                         isNative: true,
                                                         isFirstDonation: isFirstDonation)

        if let donateHistory {
            var donationArray: [WMFDonateLocalHistory] = donateHistory
            donationArray.append(donationHistoryEntry)
            try? self.sharedCacheStore?.save(key: self.cacheDirectoryName, self.cacheLocalDonateHistoryFileName, value: donationArray)
        } else {
            try? self.sharedCacheStore?.save(key: self.cacheDirectoryName, self.cacheLocalDonateHistoryFileName, value: [donationHistoryEntry])
        }

        hasLocallySavedDonations = true
        return try? sharedCacheStore?.load(key: cacheDirectoryName, cacheLocalDonateHistoryFileName)

    }

    // Pass in startDate and endDate to return filtered donations.
    // If either are nil, all local donations are returned.
    
    /// Returns persisted local donation entries, filtered by date params if needed. If either startDate or endDate is nil, no filter is applied.
    /// - Parameters:
    ///   - startDate: Supply to filter out donations timestamped older than startDate
    ///   - endDate: Supply to filter out donations timestamped older than endDate
    /// - Returns:Array of local donation entries
    public func loadLocalDonationHistory(startDate: Date?, endDate: Date?) -> [WMFDonateLocalHistory]? {
        
        guard let donations: [WMFDonateLocalHistory] = try? sharedCacheStore?.load(key: cacheDirectoryName, cacheLocalDonateHistoryFileName) else {
            return nil
        }
        
        guard let startDate, let endDate else {
            return donations
        }
        
        
        let filteredDonationsByDate = donations.filter { donation in
            
            guard let timestamp = DateFormatter.mediaWikiAPIDateFormatter.date(from: donation.donationTimestamp) else {
                return false
            }
            
            if timestamp >= startDate && timestamp <= endDate {
                return true
            }
            return false
        }
        
        return filteredDonationsByDate
    }

    public func deleteLocalDonationHistory() {
        hasLocallySavedDonations = false
        try? self.sharedCacheStore?.remove(key: cacheDirectoryName, cacheLocalDonateHistoryFileName)
    }

    // MARK: - Internal
    
    func reset() {
        donateConfig = nil
        paymentMethods = nil
    }
}
