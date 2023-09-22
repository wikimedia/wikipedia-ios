import Foundation
import WKData

extension WMFAnnouncementsContentSource {
    @objc func fetchDonateConfigsForCountryCode(_ countryCode: String) {
        
        guard FeatureFlags.applePayEnabled else {
            return
        }
        
        let dataController = WKDonateDataController()
        dataController.fetchConfigs(for: countryCode) { result in
            
        }
    }
}
