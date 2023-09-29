import Foundation
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
