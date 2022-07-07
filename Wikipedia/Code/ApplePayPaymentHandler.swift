import UIKit
import PassKit
import WMF

typealias PaymentCompletionHandler = (Bool) -> Void

@objc(WMFApplePayPaymentHandler)
class ApplePayPaymentHandler: NSObject {
    
    /// Describes the error that can occur during Apple Pay payment.
    enum Error: Swift.Error, LocalizedError {

        /// Indicates that the grand total summary item is a negative value.
        case invalidAmount

        /// Indicates that the token was generated incorrectly.
        case invalidToken

        public var errorDescription: String? {
            switch self {
            case .invalidAmount:
                return WMFLocalizedString("apple-pay-error-invalid-amount", value: "The donation amount entered is invalid.", comment: "Error that presents when the user enters an invalid donation amount.")
            case .invalidToken:
                return "The Apple Pay token is invalid. Make sure you are using physical device, not a Simulator."
            }
        }
    }

    private var paymentStatus = PKPaymentAuthorizationStatus.failure
    private var completionHandler: PaymentCompletionHandler!
    
    @objc static var isSupported: Bool {
        return PKPaymentAuthorizationController.canMakePayments()
    }
    
    static var needsSetup: Bool {
        return isSupported && !PKPaymentAuthorizationController.canMakePayments(usingNetworks: supportedNetworks)
    }
    
    private static let supportedNetworks: [PKPaymentNetwork] = [
        .amex,
        .discover,
        .masterCard,
        .visa
    ]
    
    deinit {
        print("deinit called")
    }
    
    func startPayment(amount: Decimal, completion: @escaping PaymentCompletionHandler) {
        
        print(amount)
        completionHandler = completion
        
        guard (amount as NSDecimalNumber) != NSDecimalNumber.notANumber,
              amount > 0 else {
            paymentStatus = .failure
            let error = Error.invalidAmount
            self.completionHandler(false)
            // todo: pass back error?
            return
        }

        // Create a payment request.
        let paymentRequest = PKPaymentRequest()
        paymentRequest.paymentSummaryItems = [PKPaymentSummaryItem(label: WMFLocalizedString("apple-pay-item-description", value: "Wikipedia Gift", comment: "Apple Pay item description. Appears in the Apple Pay payment sheet."), amount: amount as NSDecimalNumber, type: .final)] // todo: tax? total?
        paymentRequest.merchantIdentifier = "{redacted}" // todo: make this dynamic and hidden
        paymentRequest.currencyCode = Locale.current.currencyCode ?? "USD" // todo: confirm default
        paymentRequest.merchantCapabilities = .capability3DS // todo: confirm
        paymentRequest.countryCode = Locale.current.regionCode ?? "US" // todo: confirm, may need to just be US
        paymentRequest.supportedNetworks = Self.supportedNetworks // todo: confirm static list, may need to come from Adyen /paymentMethods
        paymentRequest.supportedCountries = []
        paymentRequest.requiredShippingContactFields = [.name, .emailAddress]
        paymentRequest.requiredBillingContactFields = [.name, .postalAddress]
        
        // Display the payment request.
        let paymentController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
        paymentController.delegate = self
        paymentController.present(completion: { (presented: Bool) in
            if presented {
                debugPrint("Presented payment controller")
            } else {
                debugPrint("Failed to present payment controller")
                self.completionHandler(false)
            }
        })
    }
}

// Set up PKPaymentAuthorizationControllerDelegate conformance.

extension ApplePayPaymentHandler: PKPaymentAuthorizationControllerDelegate {

    func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        
        // TODO: Validate
        guard !payment.token.paymentData.isEmpty,
        let token = String(data: payment.token.paymentData, encoding: .utf8) else {
            paymentStatus = .failure
            let error = Error.invalidToken
            completion(PKPaymentAuthorizationResult(status: paymentStatus, errors: [error]))
            return
        }
        
        let emailAddressForCiviCRM = payment.shippingContact?.emailAddress
        let nameForCiciCRM = payment.shippingContact?.name
        
        print(emailAddressForCiviCRM)
        print(nameForCiciCRM)
        
        // TODO: Post payment & metadata, handle errors
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.0, execute: {
            self.paymentStatus = .success
            completion(PKPaymentAuthorizationResult(status: self.paymentStatus, errors: []))
            return
        })
        
    }
    
    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        // todo: also consider updating button state here (change "setup" to "donate" bc they may have added a card in wallet)
        controller.dismiss {
            // The payment sheet doesn't automatically dismiss once it has finished. Dismiss the payment sheet.
            DispatchQueue.main.async {
                if self.paymentStatus == .success {
                    self.completionHandler?(true)
                } else {
                    self.completionHandler?(false)
                }
            }
        }
    }
    
//    func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController, didSelectPaymentMethod paymentMethod: PKPaymentMethod, handler completion: @escaping (PKPaymentRequestPaymentMethodUpdate) -> Void) {
//        print("did update")
//        // todo: also consider updating button state here (change "setup" to "donate" bc they may have added a card in wallet)
//    }
}
