import Foundation
import WKData
import Combine
import UIKit
import PassKit

public final class WKDonateViewModel: NSObject, ObservableObject {
    
    // MARK: - Nested Types
    
    enum Error: Swift.Error {
        case invalidToken
        case missingDonorInfo
    }
    
    public struct LocalizedStrings {
        public let title: String
        public let doneTitle: String
        public let transactionFeeOptInText: String
        public let emailOptInText: String
        public let maximumErrorText: String?
        public let minimumErrorText: String
        public let genericErrorTextFormat: String
        public let helpLinkProblemsDonating: String
        public let helpLinkOtherWaysToGive: String
        public let helpLinkFrequentlyAskedQuestions: String
        public let helpLinkTaxDeductibilityInformation: String
        public let accessibilityAmountButtonHint: String
        public let accessibilityTextfieldHint: String
        public let accessibilityTransactionFeeHint: String
        public let accessibilityEmailOptInHint: String
        public let accessibilityKeyboardDoneButtonHint: String
        public let accessibilityDonateButtonHintFormat: String
        
        public init(title: String, doneTitle: String, transactionFeeOptInText: String, emailOptInText: String, maximumErrorText: String?, minimumErrorText: String, genericErrorTextFormat: String, helpLinkProblemsDonating: String, helpLinkOtherWaysToGive: String, helpLinkFrequentlyAskedQuestions: String, helpLinkTaxDeductibilityInformation: String, accessibilityAmountButtonHint: String, accessibilityTextfieldHint: String, accessibilityTransactionFeeHint: String, accessibilityEmailOptInHint: String, accessibilityKeyboardDoneButtonHint: String, accessibilityDonateButtonHintFormat: String) {
            self.title = title
            self.doneTitle = doneTitle
            self.transactionFeeOptInText = transactionFeeOptInText
            self.emailOptInText = emailOptInText
            self.maximumErrorText = maximumErrorText
            self.minimumErrorText = minimumErrorText
            self.genericErrorTextFormat = genericErrorTextFormat
            self.helpLinkProblemsDonating = helpLinkProblemsDonating
            self.helpLinkOtherWaysToGive = helpLinkOtherWaysToGive
            self.helpLinkFrequentlyAskedQuestions = helpLinkFrequentlyAskedQuestions
            self.helpLinkTaxDeductibilityInformation = helpLinkTaxDeductibilityInformation
            self.accessibilityAmountButtonHint = accessibilityAmountButtonHint
            self.accessibilityTextfieldHint = accessibilityTextfieldHint
            self.accessibilityTransactionFeeHint = accessibilityTransactionFeeHint
            self.accessibilityEmailOptInHint = accessibilityEmailOptInHint
            self.accessibilityKeyboardDoneButtonHint = accessibilityKeyboardDoneButtonHint
            self.accessibilityDonateButtonHintFormat = accessibilityDonateButtonHintFormat
        }
    }
    
    public final class AmountButtonViewModel: ObservableObject, Equatable, Identifiable {
        public static func == (lhs: WKDonateViewModel.AmountButtonViewModel, rhs: WKDonateViewModel.AmountButtonViewModel) -> Bool {
            return lhs.amount == rhs.amount
        }
        
        @Published var amount: Decimal
        @Published var isSelected: Bool = false
        
        let currencyCode: String
        let accessibilityHint: String
        
        internal init(amount: Decimal, isSelected: Bool = false, currencyCode: String, accessibilityHint: String) {
            self.amount = amount
            self.isSelected = isSelected
            self.currencyCode = currencyCode
            self.accessibilityHint = accessibilityHint
        }
    }
    
    public final class AmountTextFieldViewModel: ObservableObject {
        
        public struct LocalizedStrings {
            let doneTitle: String
            let textfieldAccessibilityHint: String
            let doneAccessibilityHint: String
        }
        
        let localizedStrings: LocalizedStrings
        let currencyCode: String
        
        @Published var amount: Decimal
        @Published var hasFocus: Bool
        
        init(localizedStrings: LocalizedStrings, currencyCode: String, amount: Decimal, hasFocus: Bool) {
            self.localizedStrings = localizedStrings
            self.currencyCode = currencyCode
            self.amount = amount
            self.hasFocus = hasFocus
        }
    }
    
    public final class OptInViewModel: ObservableObject {
        
        public struct LocalizedStrings {
            let text: String
            let accessibilityHint: String
        }
        
        @Published var isSelected: Bool = false

        let localizedStrings: LocalizedStrings
        
        init(localizedStrings: LocalizedStrings) {
            self.localizedStrings = localizedStrings
        }
    }
    
    public final class ErrorViewModel: ObservableObject {
        public struct LocalizedStrings {
            let text: String
        }
        
        @Published var hasAccessibilityFocus: Bool = false
        
        let localizedStrings: LocalizedStrings
        
        init(localizedStrings: LocalizedStrings) {
            self.localizedStrings = localizedStrings
        }
    }
    
    // MARK: - Properties
    
    let localizedStrings: LocalizedStrings
    private let donateConfig: WKDonateConfig
    private let paymentMethods: WKPaymentMethods
    private let currencyCode: String
    private let countryCode: String
    
    private let merchantID: String
    private let paymentsAPIKey: String
    
    @Published var buttonViewModels: [AmountButtonViewModel]
    @Published var textfieldViewModel: AmountTextFieldViewModel
    @Published var transactionFeeOptInViewModel: OptInViewModel
    @Published var emailOptInViewModel: OptInViewModel?
    @Published var errorViewModel: ErrorViewModel?
    
    private let transactionFeeAmount: Decimal
    private(set) var finalAmount: Decimal
    
    private var textFieldSubscribers: Set<AnyCancellable> = []
    private var buttonSubscribers: Set<AnyCancellable> = []
    private var transactionFeeSubscribers: Set<AnyCancellable> = []
    
    private weak var delegate: WKDonateDelegate?
    
    // MARK: - Lifecycle
    
    public init?(localizedStrings: LocalizedStrings, donateConfig: WKDonateConfig, paymentMethods: WKPaymentMethods, currencyCode: String, countryCode: String, merchantID: String, paymentsAPIKey: String, delegate: WKDonateDelegate?) {
        self.localizedStrings = localizedStrings
        self.donateConfig = donateConfig
        self.paymentMethods = paymentMethods
        self.currencyCode = currencyCode
        self.countryCode = countryCode
        self.merchantID = merchantID
        self.paymentsAPIKey = paymentsAPIKey
        self.delegate = delegate
        
        guard let transactionFeeAmount = donateConfig.transactionFee(for: currencyCode) else {
            return nil
        }
        
        self.transactionFeeAmount = transactionFeeAmount
        
        guard let configAmounts = donateConfig.currencyAmounts7[currencyCode] else {
            return nil
        }
        
        var buttonViewModels: [AmountButtonViewModel] = []
        for amount in configAmounts {
            let viewModel = AmountButtonViewModel(amount: amount, currencyCode: currencyCode, accessibilityHint: localizedStrings.accessibilityAmountButtonHint)
            buttonViewModels.append(viewModel)
        }
        
        guard buttonViewModels.count == configAmounts.count else {
            return nil
        }
        
        self.buttonViewModels = buttonViewModels
        self.textfieldViewModel = AmountTextFieldViewModel(localizedStrings: AmountTextFieldViewModel.LocalizedStrings(doneTitle: localizedStrings.doneTitle, textfieldAccessibilityHint: localizedStrings.accessibilityTextfieldHint, doneAccessibilityHint: localizedStrings.accessibilityKeyboardDoneButtonHint), currencyCode: currencyCode, amount: 0, hasFocus: true)
        
        self.finalAmount = 0
        
        self.transactionFeeOptInViewModel = OptInViewModel(localizedStrings: OptInViewModel.LocalizedStrings(text: localizedStrings.transactionFeeOptInText, accessibilityHint: localizedStrings.accessibilityTransactionFeeHint))
        
        if donateConfig.countryCodeEmailOptInRequired.contains(countryCode) {
            self.emailOptInViewModel = OptInViewModel(localizedStrings: OptInViewModel.LocalizedStrings(text: localizedStrings.emailOptInText, accessibilityHint: localizedStrings.accessibilityEmailOptInHint))
        }
        
        super.init()
        
        addButtonSelectionListener()
        addTextfieldChangeListener()
        addTransactionFeeSelectionListener()
    }
    
    // MARK: - Internal
    
    var accessibilityDonateButtonHint: String? {
        let formatter = NumberFormatter.wkCurrencyFormatter
        formatter.currencyCode = currencyCode
        
        if let finalAmountString = formatter.string(from: finalAmount as NSNumber) {
            return String.localizedStringWithFormat(localizedStrings.accessibilityDonateButtonHintFormat, finalAmountString)
        }
        
        return nil
    }
    
    func validateAndSubmit() {
        validateAmount()
        submit()
    }
    
    func validateAmount() {
        guard let minimum = donateConfig.currencyMinimums[currencyCode] else {
            return
        }
        
        if finalAmount < minimum {
            self.errorViewModel = ErrorViewModel(localizedStrings: ErrorViewModel.LocalizedStrings(text: localizedStrings.minimumErrorText))
            return
        }
        
        if let maximum = donateConfig.currencyMaximums[currencyCode],
        finalAmount > maximum,
        let maximumErrorText = localizedStrings.maximumErrorText {
            self.errorViewModel = ErrorViewModel(localizedStrings: ErrorViewModel.LocalizedStrings(text: maximumErrorText))
            return
        }
        
        self.errorViewModel = nil
    }
    
    func submit() {
        guard errorViewModel == nil else {
            return
        }
        
        // Create a payment request.
        let paymentRequest = PKPaymentRequest()
        paymentRequest.paymentSummaryItems = [PKPaymentSummaryItem(label: "", amount: finalAmount as NSDecimalNumber, type: .final)]
        paymentRequest.merchantIdentifier =  merchantID
        paymentRequest.currencyCode = currencyCode
        paymentRequest.merchantCapabilities = .capability3DS
        paymentRequest.countryCode = countryCode
        paymentRequest.supportedNetworks = paymentMethods.applePayPaymentNetworks
        paymentRequest.requiredBillingContactFields = [.name, .postalAddress]
        paymentRequest.requiredShippingContactFields = [.emailAddress]
        
        // Display the payment request.
        let paymentController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
        paymentController.delegate = self
        paymentController.present(completion: { (presented: Bool) in
            if presented {
                debugPrint("Presented payment controller")
            } else {
                debugPrint("Failed to present payment controller")
            }
        })
    }
    
    // MARK: - Private
    
    private func didSelectAmountButton(buttonViewModel: AmountButtonViewModel) {

        // Deselect other buttons
        for loopButtonViewModel in buttonViewModels {
            if loopButtonViewModel != buttonViewModel {
                loopButtonViewModel.isSelected = false
            }
        }
        
        // Reset transaction fee checkbox.
        self.transactionFeeOptInViewModel = OptInViewModel(localizedStrings: transactionFeeOptInViewModel.localizedStrings)
        addTransactionFeeSelectionListener()
        
        // Update finalAmount for submission
        self.finalAmount = buttonViewModel.amount
        
        // Update textfield
        var updateDelay = 0.0
        if #unavailable(iOS 17) {
            if textfieldViewModel.hasFocus {
                textfieldViewModel.hasFocus = false
                updateDelay = 0.25
            }
        }

        
        DispatchQueue.main.asyncAfter(deadline: .now() + updateDelay) { [weak self] in
            
            guard let self else {
                return
            }
            
            self.textfieldViewModel.amount = self.finalAmount
        }
    }
    
    private func didChangeTextfield(newAmount: Decimal) {
        
        // Update finalAmount for submission
        self.finalAmount = newAmount
        
        // Determine if a button should be automatically selected, to reflect textfield
        
        // Propagate new button selection values by replacing view models (changing isSelected directly causes infinite update loop)
        let targetButtonAmount = finalAmount - (transactionFeeOptInViewModel.isSelected ? transactionFeeAmount : 0)
        let newButtonViewModels = buttonViewModels.map { AmountButtonViewModel(amount: $0.amount, isSelected: targetButtonAmount == $0.amount, currencyCode: currencyCode, accessibilityHint: localizedStrings.accessibilityAmountButtonHint) }
        self.buttonViewModels = newButtonViewModels
        
        // Apply isSelected listeners again
        addButtonSelectionListener()
    }
    
    private func didChangeTransactionFeeSelection(isSelected: Bool) {
        
        var updateDelay = 0.0
        if #unavailable(iOS 17) {
            if textfieldViewModel.hasFocus {
                textfieldViewModel.hasFocus = false
                updateDelay = 0.25
            }
        }

        
        DispatchQueue.main.asyncAfter(deadline: .now() + updateDelay) { [weak self] in
            
            guard let self else {
                return
            }
            
            self.finalAmount = isSelected ? self.finalAmount + self.transactionFeeAmount : max(0, self.finalAmount - self.transactionFeeAmount)
            textfieldViewModel.amount = self.finalAmount
        }
    }
    
    private func addButtonSelectionListener() {
        
        self.buttonSubscribers.removeAll()
        for buttonViewModel in buttonViewModels {
            buttonViewModel.$isSelected
                .dropFirst()
                .sink { [weak self] isSelected in

                guard let self else {
                    return
                }

                if isSelected {
                    self.didSelectAmountButton(buttonViewModel: buttonViewModel)
                }
            }.store(in: &buttonSubscribers)
        }
    }
    
    private func addTextfieldChangeListener() {
        
        textFieldSubscribers.removeAll()
        self.textfieldViewModel.$amount
            .dropFirst()
            .sink { [weak self] newAmount in

            guard let self else {
                return
            }

            self.didChangeTextfield(newAmount: newAmount)


        }.store(in: &textFieldSubscribers)
    }
    
    private func addTransactionFeeSelectionListener() {
        
        transactionFeeSubscribers.removeAll()
        self.transactionFeeOptInViewModel.$isSelected
            .dropFirst()
            .sink { [weak self] isSelected in

            guard let self else {
                return
            }

            self.didChangeTransactionFeeSelection(isSelected: isSelected)


        }.store(in: &textFieldSubscribers)
    }
}

// MARK: - PKPaymentAuthorizationControllerDelegate

extension WKDonateViewModel: PKPaymentAuthorizationControllerDelegate {

    public func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {

        guard !payment.token.paymentData.isEmpty,
              let paymentToken = String(data: payment.token.paymentData, encoding: .utf8) else {
            let error = Error.invalidToken
            let errorText = String.localizedStringWithFormat(localizedStrings.genericErrorTextFormat, error.localizedDescription)
            self.errorViewModel = ErrorViewModel(localizedStrings: ErrorViewModel.LocalizedStrings(text: errorText))
            completion(PKPaymentAuthorizationResult(status: .failure, errors: [error]))
            return
        }
        
        guard let donorName = payment.billingContact?.name?.formatted(),
              let donorEmail = payment.shippingContact?.emailAddress,
              let donorAddress = payment.billingContact?.postalAddress else {
            let error = Error.missingDonorInfo
            let errorText = String.localizedStringWithFormat(localizedStrings.genericErrorTextFormat, error.localizedDescription)
            self.errorViewModel = ErrorViewModel(localizedStrings: ErrorViewModel.LocalizedStrings(text: errorText))
            completion(PKPaymentAuthorizationResult(status: .failure, errors: [error]))
            return
        }
        
        let formatter = CNPostalAddressFormatter()
        formatter.style = .mailingAddress
        
        let donorFormattedAddress = formatter.string(from: donorAddress)
        let emailOptIn: Bool? = emailOptInViewModel?.isSelected
        
        let dataController = WKDonateDataController()
        dataController.submitPayment(amount: finalAmount, currencyCode: currencyCode, paymentToken: paymentToken, donorName: donorName, donorEmail: donorEmail, donorAddress: donorFormattedAddress, emailOptIn: emailOptIn, paymentsAPIKey: paymentsAPIKey) { [weak self] result in
            
            guard let self else {
                return
            }
            
            switch result {
            case .success:
                completion(PKPaymentAuthorizationResult(status: .success, errors: []))
                
                // Wait for payment sheet to dismiss
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.75, execute: { [weak self] in
                    self?.delegate?.donateDidSuccessfullySubmitPayment()
                })
            case .failure(let error):
                // TODO: Handle errors more?
                completion(PKPaymentAuthorizationResult(status: .failure, errors: [error]))
            }
        }
    }
    
    public func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController, didSelectPaymentMethod paymentMethod: PKPaymentMethod, handler completion: @escaping (PKPaymentRequestPaymentMethodUpdate) -> Void) {
        completion(.init(paymentSummaryItems: [PKPaymentSummaryItem(label: "", amount: finalAmount as NSDecimalNumber, type: .final)]))
    }
    
    public func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss {
            
        }
    }
}
