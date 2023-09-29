import Foundation
import WKData

extension WMFAnnouncementsContentSource {

    @objc func fetchDonorExperienceDataForCountryCode(_ countryCode: String) {
        
        let fundraisingCampaignDataController = WKFundraisingCampaignDataController()
        let currentDate = Date.now
        fundraisingCampaignDataController.fetchConfig(countryCode: countryCode, currentDate: currentDate) { result in

        }
        
        guard let paymentsAPIKey = Bundle.main.wmf_paymentsAPIKey() else {
            return
        }
        
        let donateDataController = WKDonateDataController()
        donateDataController.fetchConfigs(for: countryCode, paymentsAPIKey: paymentsAPIKey) { result in

        }
    }
}
