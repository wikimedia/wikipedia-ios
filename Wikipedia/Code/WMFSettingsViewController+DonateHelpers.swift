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
    
    public func logDonateFormUserDidAuthorizeApplePayPaymentSheet(amount: Decimal, presetIsSelected: Bool, recurringMonthlyIsSelected: Bool, donorEmail: String?, metricsID: String?) {
        sharedLogDonateFormUserDidAuthorizeApplePayPaymentSheet(amount: amount, presetIsSelected: presetIsSelected, recurringMonthlyIsSelected: recurringMonthlyIsSelected, donorEmail: donorEmail, metricsID: metricsID)
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
