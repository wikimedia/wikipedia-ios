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
        sharedDonateDidSuccessfullSubmitPayment(source:.settings, articleURL: nil)
    }
}

extension WMFSettingsViewController: WKDonateLoggingDelegate {
    public func logDonateFormDidAppear() {
        sharedLogDonateFormDidAppear()
    }
    
    public func logDonateFormUserDidTriggerError(error: Error) {
        sharedLogDonateFormUserDidTriggerError(error: error)
    }
    
    public func logDonateFormUserDidTapAmountPresetButton() {
        sharedLogDonateFormUserDidTapAmountPresetButton()
    }
    
    public func logDonateFormUserDidEnterAmountInTextfield() {
        sharedLogDonateFormUserDidEnterAmountInTextfield()
    }
    
    public func logDonateFormUserDidTapApplePayButton(transactionFeeIsSelected: Bool, recurringMonthlyIsSelected: Bool, emailOptInIsSelected: NSNumber?) {
        sharedLogDonateFormUserDidTapApplePayButton(transactionFeeIsSelected: transactionFeeIsSelected, recurringMonthlyIsSelected: recurringMonthlyIsSelected, emailOptInIsSelected: emailOptInIsSelected?.boolValue)
    }
    
    public func logDonateFormUserDidAuthorizeApplePayPaymentSheet(amount: Decimal, recurringMonthlyIsSelected: Bool, donorEmail: String?) {
        sharedLogDonateFormUserDidAuthorizeApplePayPaymentSheet(amount: amount, recurringMonthlyIsSelected: recurringMonthlyIsSelected, donorEmail: donorEmail)
    }
    
    public func logDonateFormUserDidTapProblemsDonatingLink() {
        sharedLogDonateFormUserDidTapProblemsDonatingLink()
    }
    
    public func logDonateFormUserDidTapOtherWaysToGiveLink() {
        sharedLogDonateFormUserDidTapOtherWaysToGiveLink()
    }
    
    public func logDonateFormUserDidTapFAQLink() {
        sharedLogDonateFormUserDidTapFAQLink()
    }
    
    public func logDonateFormUserDidTapTaxInfoLink() {
        sharedLogDonateFormUserDidTapTaxInfoLink()
    }
}

extension WMFSettingsViewController {
    @objc static func validTargetIDCampaignIsRunning() -> Bool {
        
        guard let countryCode = NSLocale.current.regionCode else {
            return false
        }
        
        let fundraisingCampaignDataController = WKFundraisingCampaignDataController()
        let currentDate = Date.now

        return fundraisingCampaignDataController.hasActivelyRunningCampaigns(countryCode: countryCode, currentDate: currentDate)
    }
}
