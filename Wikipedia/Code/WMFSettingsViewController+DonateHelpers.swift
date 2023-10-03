import Foundation
import WKData
import Components

extension WMFSettingsViewController: WKDonateDelegate {
    
    public func donateDidTapProblemsDonatingLink() {
        sharedDonateDidTapProblemsDonatingLink()
    }
    
    public func donateDidTapOtherWaysToGive() {
        sharedDonateDidTapOtherWaysToGive()
    }
    
    public func donateDidTapFrequentlyAskedQuestions() {
        sharedDonateDidTapFrequentlyAskedQuestions()
    }
    
    public func donateDidTapTaxDeductibilityInformation() {
        sharedDonateDidTapTaxDeductibilityInformation()
    }
    
    public func donateDidSuccessfullySubmitPayment() {
        sharedDonateDidSuccessfullSubmitPayment()
    }
}

extension WMFSettingsViewController {
    @objc static func validTargetIDCampaignIsRunning() -> Bool {
        
        guard let countryCode = NSLocale.current.regionCode else {
            return false
        }
        
        let fundraisingCampaignDataController = WKFundraisingCampaignDataController()
        let currentDate = Date.now

        return fundraisingCampaignDataController.hasActivelyRunningCampaigns(countryCode: "NL", currentDate: currentDate)
    }
}
