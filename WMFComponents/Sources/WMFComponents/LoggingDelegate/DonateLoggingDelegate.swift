import Foundation
public protocol WMFDonateLoggingDelegate: AnyObject {
    func handleDonateLoggingAction(_ action: WMFDonateLoggingAction)
}

public enum WMFDonateLoggingAction {
    case nativeFormDidAppear
    case nativeFormDidTriggerError(error: Error)
    case nativeFormDidTapAmountPresetButton
    case nativeFormDidEnterAmountInTextfield
    case nativeFormDidTapApplePayButton(transactionFeeIsSelected: Bool, recurringMonthlyIsSelected: Bool, emailOptInIsSelected: NSNumber?)
    case nativeFormDidAuthorizeApplePayPaymentSheet(amount: Decimal, presetIsSelected: Bool, recurringMonthlyIsSelected: Bool, donorEmail: String?, metricsID: String?)
    case nativeFormDidTriggerPaymentSuccess
    case nativeFormDidTapProblemsDonating
    case nativeFormDidTapOtherWaysToGive
    case nativeFormDidTapFAQ
    case nativeFormDidTapTaxInfo
    case webViewFormDidAppear
    case webViewFormThankYouPageDidAppear
    case webViewFormThankYouDidTapReturn
    case webViewFormThankYouDidDisappear
}
