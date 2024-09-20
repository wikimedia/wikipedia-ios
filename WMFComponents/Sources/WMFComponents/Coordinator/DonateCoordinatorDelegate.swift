import Foundation

public protocol DonateCoordinatorDelegate: AnyObject {
    func handleDonateAction(_ action: DonateCoordinatorAction)
}

public enum DonateCoordinatorAction {
    case nativeFormDidTapProblemsDonating
    case nativeFormDidTapOtherWaysToGive
    case nativeFormDidTapFAQ
    case nativeFormDidTapTaxInfo
    case nativeFormDidTriggerPaymentSuccess
    case webViewFormThankYouDidTapReturn
    case webViewFormThankYouDidDisappear
}
