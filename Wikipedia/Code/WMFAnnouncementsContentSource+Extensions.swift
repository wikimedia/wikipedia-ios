import Foundation
import WKData

extension WMFAnnouncementsContentSource {
    @objc func fetchDonateConfigsForCountryCode(_ countryCode: String) {
        
        guard FeatureFlags.applePayEnabled,
        let paymentsAPIKey = Bundle.main.wmf_paymentsAPIKey() else {
            return
        }
        
        let dataController = WKDonateDataController()
        dataController.fetchConfigs(for: countryCode, paymentsAPIKey: paymentsAPIKey) { result in
            print(WKDonateDataController.donateConfig)
            print(WKDonateDataController.paymentMethods)
        }
    }
}
