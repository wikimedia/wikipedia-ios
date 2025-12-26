import Foundation
import Contacts

// MARK: - Pure Swift Actor (Clean Implementation)

public actor WMFDonateDataController {
    
    public static let shared = WMFDonateDataController()
    
    private let service: WMFService?
    private let sharedCacheStore: WMFKeyValueStore?
    
    private var donateConfig: WMFDonateConfig?
    private var paymentMethods: WMFPaymentMethods?
    
    private let cacheDirectoryName = WMFSharedCacheDirectoryNames.donorExperience.rawValue
    private let cacheDonateConfigContainerFileName = "AppsDonationConfig"
    private let cachePaymentMethodsResponseFileName = "PaymentMethods"
    private let cacheLocalDonateHistoryFileName = "AppLocalDonationHistory"
    
    private let userDefaultsStore = WMFDataEnvironment.current.userDefaultsStore
    
    public var hasLocallySavedDonations: Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.hasLocallySavedDonations.rawValue)) ?? false
    }
    
    private func setHasLocallySavedDonations(_ value: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.hasLocallySavedDonations.rawValue, value: value)
    }
    
    public init(service: WMFService? = WMFDataEnvironment.current.basicService, sharedCacheStore: WMFKeyValueStore? = WMFDataEnvironment.current.sharedCacheStore) {
        self.service = service
        self.sharedCacheStore = sharedCacheStore
    }
    
    // MARK: - Public
    
    public func loadConfigs() -> (donateConfig: WMFDonateConfig?, paymentMethods: WMFPaymentMethods?) {
        
        // First pull from memory
        if let donateConfig, let paymentMethods {
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
    
    public func fetchConfigs(for countryCode: String) async throws {
        
        guard let service else {
            throw WMFDataControllerError.basicServiceUnavailable
        }
        
        guard let paymentMethodsURL = URL.paymentMethodsAPIURL(),
              let donateConfigURL = URL.donateConfigURL() else {
            throw WMFDataControllerError.failureCreatingRequestURL
        }
        
        let paymentMethodParameters: [String: Any] = [
            "action": "getPaymentMethods",
            "country": countryCode,
            "format": "json"
        ]
        
        let donateConfigParameters: [String: Any] = [
            "action": "raw"
        ]
        
        // DEBT: Make these calls concurrent, but to do so we must first make WMFService sendable.
        // 1️⃣ Fetch payment methods (first)
        let paymentMethods: WMFPaymentMethods = try await withCheckedThrowingContinuation { continuation in
            let request = WMFBasicServiceRequest(
                url: paymentMethodsURL,
                method: .GET,
                parameters: paymentMethodParameters,
                acceptType: .json
            )

            service.performDecodableGET(request: request) { (result: Result<WMFPaymentMethods, Error>) in
                continuation.resume(with: result)
            }
        }

        // 2️⃣ Fetch donate config (second)
        let donateConfigResponse: WMFDonateConfigResponse = try await withCheckedThrowingContinuation { continuation in
            let request = WMFBasicServiceRequest(
                url: donateConfigURL,
                method: .GET,
                parameters: donateConfigParameters,
                acceptType: .json
            )

            service.performDecodableGET(request: request) { (result: Result<WMFDonateConfigResponse, Error>) in
                continuation.resume(with: result)
            }
        }

        // 3️⃣ Update cached models
        var donateConfig = donateConfigResponse.config
        var mutPaymentMethods = paymentMethods
        
        donateConfig.cachedDate = Date()
        mutPaymentMethods.cachedDate = Date()
        
        self.donateConfig = donateConfig
        self.paymentMethods = mutPaymentMethods
        
        try? sharedCacheStore?.save(key: cacheDirectoryName, cacheDonateConfigContainerFileName, value: donateConfig)
        try? sharedCacheStore?.save(key: cacheDirectoryName, cachePaymentMethodsResponseFileName, value: mutPaymentMethods)
    }
    
    public func submitPayment(
        amount: Decimal,
        countryCode: String,
        currencyCode: String,
        languageCode: String,
        paymentToken: String,
        paymentNetwork: String?,
        donorNameComponents: PersonNameComponents,
        recurring: Bool,
        donorEmail: String,
        donorAddressComponents: CNPostalAddress,
        emailOptIn: Bool?,
        transactionFee: Bool,
        metricsID: String?,
        appVersion: String?,
        appInstallID: String?
    ) async throws {
        
        guard !WMFDeveloperSettingsDataController.shared.bypassDonation else {
            return
        }
        
        guard let donatePaymentSubmissionURL = URL.donatePaymentSubmissionURL() else {
            throw WMFDataControllerError.failureCreatingRequestURL
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
        
        if let appInstallID {
            parameters["app_install_id"] = appInstallID
        }
        
        let response: WMFPaymentSubmissionResponse = try await withCheckedThrowingContinuation { continuation in
            let request = WMFBasicServiceRequest(url: donatePaymentSubmissionURL, method: .POST, parameters: parameters, contentType: .form, acceptType: .json)
            service?.performDecodablePOST(request: request) { (result: Result<WMFPaymentSubmissionResponse, Error>) in
                continuation.resume(with: result)
            }
        }
        
        switch response.response.status.lowercased() {
        case "success":
            return
        case "error":
            throw WMFDonateDataControllerError.paymentsWikiResponseError(reason: response.response.errorMessage, orderID: response.response.orderID)
        default:
            throw WMFServiceError.unexpectedResponse
        }
    }
    
    @discardableResult
    public func saveLocalDonationHistory(type: WMFDonateLocalHistory.DonationType, amount: Decimal, currencyCode: String, isNative: Bool) -> [WMFDonateLocalHistory]? {
        
        let currentDate = Date()
        let timestamp = DateFormatter.mediaWikiAPIDateFormatter.string(from: currentDate)
        
        let donateHistory: [WMFDonateLocalHistory]? = loadLocalDonationHistory(startDate: nil, endDate: nil)
        let isFirstDonation = donateHistory?.count ?? 0 == 0
        
        let donationHistoryEntry = WMFDonateLocalHistory(
            donationTimestamp: timestamp,
            donationType: type,
            donationAmount: amount,
            currencyCode: currencyCode,
            isNative: true,
            isFirstDonation: isFirstDonation
        )
        
        if let donateHistory {
            var donationArray: [WMFDonateLocalHistory] = donateHistory
            donationArray.append(donationHistoryEntry)
            try? sharedCacheStore?.save(key: cacheDirectoryName, cacheLocalDonateHistoryFileName, value: donationArray)
        } else {
            try? sharedCacheStore?.save(key: cacheDirectoryName, cacheLocalDonateHistoryFileName, value: [donationHistoryEntry])
        }
        
        setHasLocallySavedDonations(true)
        return try? sharedCacheStore?.load(key: cacheDirectoryName, cacheLocalDonateHistoryFileName)
    }
    
    /// Returns persisted local donation entries, filtered by date params if needed. If either startDate or endDate is nil, no filter is applied.
    /// - Parameters:
    ///   - startDate: Supply to filter out donations timestamped older than startDate
    ///   - endDate: Supply to filter out donations timestamped older than endDate
    /// - Returns: Array of local donation entries
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
        setHasLocallySavedDonations(false)
        try? sharedCacheStore?.remove(key: cacheDirectoryName, cacheLocalDonateHistoryFileName)
    }
    
    // MARK: - Internal
    
    func reset() {
        donateConfig = nil
        paymentMethods = nil
    }
}

// MARK: - Objective-C Bridge

@objc final public class WMFDonateDataControllerObjCBridge: NSObject, @unchecked Sendable {
    
    @objc(sharedInstance)
    public static let shared = WMFDonateDataControllerObjCBridge(controller: .shared)
    
    private let controller: WMFDonateDataController
    
    public init(controller: WMFDonateDataController) {
        self.controller = controller
        super.init()
    }
    
    public func loadConfigs() -> (donateConfig: WMFDonateConfig?, paymentMethods: WMFPaymentMethods?) {
        
        // Synchronous bridge using semaphore
        var result: (WMFDonateConfig?, WMFPaymentMethods?) = (nil, nil)
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            result = await controller.loadConfigs()
            semaphore.signal()
        }
        
        semaphore.wait()
        return result
    }
    
    @objc public var hasLocallySavedDonations: Bool {
        // Synchronous bridge using semaphore
        var result = false
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            result = await controller.hasLocallySavedDonations
            semaphore.signal()
        }
        
        semaphore.wait()
        return result
    }
    
    @objc public func fetchConfigsForCountryCode(_ countryCode: String, completion: @escaping @Sendable (Error?) -> Void) {
        let controller = self.controller
        Task {
            do {
                try await controller.fetchConfigs(for: countryCode)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    public func loadLocalDonationHistory(
            startDate: Date?,
            endDate: Date?
        ) -> [WMFDonateLocalHistory]? {
            // Synchronous bridge
            var result: [WMFDonateLocalHistory]?
            let semaphore = DispatchSemaphore(value: 0)
            
            let localController = self.controller
            Task {
                result = await localController.loadLocalDonationHistory(startDate: startDate, endDate: endDate)
                semaphore.signal()
            }
            
            semaphore.wait()
            return result
        }
    
    @objc public func deleteLocalDonationHistory() {
        let controller = self.controller
        Task {
            await controller.deleteLocalDonationHistory()
        }
    }
}
