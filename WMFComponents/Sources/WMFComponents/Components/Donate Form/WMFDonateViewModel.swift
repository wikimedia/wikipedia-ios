import Foundation
import WMFData
import Combine
import UIKit
import PassKit

public final class WMFDonateViewModel: NSObject, ObservableObject {
    
    // MARK: - Nested Types
    
    public enum Error: Swift.Error {
        case invalidToken
        case missingDonorInfo
        case validationAmountMinimum
        case validationAmountMaximum
    }
    
    public struct LocalizedStrings {
        public let title: String
        public let doneTitle: String
        public let transactionFeeOptInTextFormat: String
        public let monthlyRecurringText: String
        public let emailOptInText: String
        public let maximumErrorText: String?
        public let minimumErrorText: String
        public let genericErrorTextFormat: String
        public let helpLinkProblemsDonating: String
        public let helpLinkOtherWaysToGive: String
        public let helpLinkFrequentlyAskedQuestions: String
        public let helpLinkTaxDeductibilityInformation: String
        public let appleFinePrint: String
        public let wikimediaFinePrint1: String
        public let wikimediaFinePrint2: String
        public let accessibilityAmountButtonHint: String
        public let accessibilityTextfieldHint: String
        public let accessibilityTransactionFeeHint: String
        public let accessibilityMonthlyRecurringHint: String
        public let accessibilityEmailOptInHint: String
        public let accessibilityKeyboardDoneButtonHint: String
        public let accessibilityDonateButtonHintFormat: String
        
        public init(title: String, doneTitle: String, transactionFeeOptInTextFormat: String, monthlyRecurringText: String, emailOptInText: String, maximumErrorText: String?, minimumErrorText: String, genericErrorTextFormat: String, helpLinkProblemsDonating: String, helpLinkOtherWaysToGive: String, helpLinkFrequentlyAskedQuestions: String, helpLinkTaxDeductibilityInformation: String, appleFinePrint: String, wikimediaFinePrint1: String, wikimediaFinePrint2: String, accessibilityAmountButtonHint: String, accessibilityTextfieldHint: String, accessibilityTransactionFeeHint: String, accessibilityMonthlyRecurringHint: String, accessibilityEmailOptInHint: String, accessibilityKeyboardDoneButtonHint: String, accessibilityDonateButtonHintFormat: String) {
            self.title = title
            self.doneTitle = doneTitle
            self.transactionFeeOptInTextFormat = transactionFeeOptInTextFormat
            self.monthlyRecurringText = monthlyRecurringText
            self.emailOptInText = emailOptInText
            self.maximumErrorText = maximumErrorText
            self.minimumErrorText = minimumErrorText
            self.genericErrorTextFormat = genericErrorTextFormat
            self.helpLinkProblemsDonating = helpLinkProblemsDonating
            self.helpLinkOtherWaysToGive = helpLinkOtherWaysToGive
            self.helpLinkFrequentlyAskedQuestions = helpLinkFrequentlyAskedQuestions
            self.helpLinkTaxDeductibilityInformation = helpLinkTaxDeductibilityInformation
            self.appleFinePrint = appleFinePrint
            self.wikimediaFinePrint1 = wikimediaFinePrint1
            self.wikimediaFinePrint2 = wikimediaFinePrint2
            self.accessibilityAmountButtonHint = accessibilityAmountButtonHint
            self.accessibilityTextfieldHint = accessibilityTextfieldHint
            self.accessibilityTransactionFeeHint = accessibilityTransactionFeeHint
            self.accessibilityMonthlyRecurringHint = accessibilityMonthlyRecurringHint
            self.accessibilityEmailOptInHint = accessibilityEmailOptInHint
            self.accessibilityKeyboardDoneButtonHint = accessibilityKeyboardDoneButtonHint
            self.accessibilityDonateButtonHintFormat = accessibilityDonateButtonHintFormat
        }
    }
    
    public final class AmountButtonViewModel: ObservableObject, Identifiable {
        
        @Published var amount: Decimal
        @Published var isSelected: Bool = false
        
        let currencyCode: String
        let accessibilityHint: String
        weak var loggingDelegate: WMFDonateLoggingDelegate?
        weak var coordinatorDelegate: DonateCoordinatorDelegate?
        
        internal init(amount: Decimal, isSelected: Bool = false, currencyCode: String, accessibilityHint: String, coordinatorDelegate: DonateCoordinatorDelegate?, loggingDelegate: WMFDonateLoggingDelegate?) {
            self.amount = amount
            self.isSelected = isSelected
            self.currencyCode = currencyCode
            self.accessibilityHint = accessibilityHint
            self.coordinatorDelegate = coordinatorDelegate
            self.loggingDelegate = loggingDelegate
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
        
        init(localizedStrings: LocalizedStrings, isSelected: Bool = false) {
            self.localizedStrings = localizedStrings
            self.isSelected = isSelected
        }
    }
    
    public final class ErrorViewModel: ObservableObject {
        @Published var hasAccessibilityFocus: Bool = false
        
        struct LocalizedStrings {
            let genericErrorFormat: String
            let minimumErrorText: String
            let maximumErrorText: String?
        }
        
        let localizedStrings: LocalizedStrings
        let error: Swift.Error
        let orderID: String?
        
        var displayText: String {
            if let viewModelError = error as? WMFDonateViewModel.Error {
                if viewModelError == WMFDonateViewModel.Error.validationAmountMinimum {
                    return localizedStrings.minimumErrorText
                } else if viewModelError == WMFDonateViewModel.Error.validationAmountMaximum,
                          let maximumErrorText = localizedStrings.maximumErrorText {
                    return maximumErrorText
                }
            } else if let donateError = error as? WMFDonateDataControllerError {
                return donateError.localizedDescription
            }
            
            return String.localizedStringWithFormat(localizedStrings.genericErrorFormat, (error as NSError).description)
        }
        
        init(localizedStrings: LocalizedStrings, error: Swift.Error, orderID: String?) {
            self.localizedStrings = localizedStrings
            self.error = error
            self.orderID = orderID
        }
    }
    
    // MARK: - Properties
    
    let localizedStrings: LocalizedStrings
    private let donateConfig: WMFDonateConfig
    private let paymentMethods: WMFPaymentMethods
    private let countryCode: String
    private let currencyCode: String
    private let languageCode: String
    
    private let merchantID: String
    private let metricsID: String?
    private let appVersion: String?
    
    @Published var buttonViewModels: [AmountButtonViewModel]
    @Published var textfieldViewModel: AmountTextFieldViewModel
    @Published var transactionFeeOptInViewModel: OptInViewModel
    @Published var monthlyRecurringViewModel: OptInViewModel
    @Published var emailOptInViewModel: OptInViewModel?
    @Published var errorViewModel: ErrorViewModel?
    
    private var transactionFeeAmount: Decimal
    private(set) var finalAmount: Decimal {
        didSet {
            recalculateTransactionFee()
        }
    }
    
    private var textFieldSubscribers: Set<AnyCancellable> = []
    private var buttonSubscribers: Set<AnyCancellable> = []
    private var transactionFeeSubscribers: Set<AnyCancellable> = []
    
    private(set) weak var coordinatorDelegate: DonateCoordinatorDelegate?
    private(set) weak var loggingDelegate: WMFDonateLoggingDelegate?

    // MARK: - Lifecycle

    public init?(localizedStrings: LocalizedStrings, donateConfig: WMFDonateConfig, paymentMethods: WMFPaymentMethods, countryCode: String, currencyCode: String, languageCode: String, merchantID: String, metricsID: String?, appVersion: String?, coordinatorDelegate: DonateCoordinatorDelegate?, loggingDelegate: WMFDonateLoggingDelegate?) {
        self.localizedStrings = localizedStrings
        self.donateConfig = donateConfig
        self.paymentMethods = paymentMethods
        self.countryCode = countryCode
        self.currencyCode = currencyCode
        self.languageCode = languageCode
        self.merchantID = merchantID
        self.metricsID = metricsID
        self.appVersion = appVersion
        self.coordinatorDelegate = coordinatorDelegate
        self.loggingDelegate = loggingDelegate

        guard let transactionFeeAmount = Self.transactionFee(donateConfig: donateConfig, currencyCode: currencyCode) else {
            return nil
        }
        
        self.transactionFeeAmount = transactionFeeAmount
        
        guard let configAmounts = donateConfig.currencyAmountPresets[currencyCode] else {
            return nil
        }
        
        var buttonViewModels: [AmountButtonViewModel] = []
        for amount in configAmounts {
            let viewModel = AmountButtonViewModel(amount: amount, currencyCode: currencyCode, accessibilityHint: localizedStrings.accessibilityAmountButtonHint, coordinatorDelegate: coordinatorDelegate, loggingDelegate: loggingDelegate)
            buttonViewModels.append(viewModel)
        }
        
        guard buttonViewModels.count == configAmounts.count else {
            return nil
        }
        
        self.buttonViewModels = buttonViewModels
        self.textfieldViewModel = AmountTextFieldViewModel(localizedStrings: AmountTextFieldViewModel.LocalizedStrings(doneTitle: localizedStrings.doneTitle, textfieldAccessibilityHint: localizedStrings.accessibilityTextfieldHint, doneAccessibilityHint: localizedStrings.accessibilityKeyboardDoneButtonHint), currencyCode: currencyCode, amount: 0, hasFocus: true)
        
        self.finalAmount = 0
        
        let formatter = NumberFormatter.wmfCurrencyFormatter
        formatter.currencyCode = currencyCode
        let transactionFeeString = formatter.string(from: transactionFeeAmount as NSNumber) ?? ""
        let text = String.localizedStringWithFormat(localizedStrings.transactionFeeOptInTextFormat, transactionFeeString)
        self.transactionFeeOptInViewModel = OptInViewModel(localizedStrings: OptInViewModel.LocalizedStrings(text: text, accessibilityHint: localizedStrings.accessibilityTransactionFeeHint))
        
        self.monthlyRecurringViewModel = OptInViewModel(localizedStrings: OptInViewModel.LocalizedStrings(text: localizedStrings.monthlyRecurringText, accessibilityHint: localizedStrings.accessibilityMonthlyRecurringHint))
        
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
        let formatter = NumberFormatter.wmfCurrencyFormatter
        formatter.currencyCode = currencyCode
        
        if let finalAmountString = formatter.string(from: finalAmount as NSNumber) {
            return String.localizedStringWithFormat(localizedStrings.accessibilityDonateButtonHintFormat, finalAmountString)
        }
        
        return nil
    }

    func logTappedApplePayButton() {
        
        var emailOptInNSNumber: NSNumber? = nil
        if let emailOptIn = emailOptInViewModel?.isSelected {
            emailOptInNSNumber = NSNumber(booleanLiteral: emailOptIn)
        }
        
        loggingDelegate?.handleDonateLoggingAction(.nativeFormDidTapApplePayButton(transactionFeeIsSelected: transactionFeeOptInViewModel.isSelected, recurringMonthlyIsSelected: monthlyRecurringViewModel.isSelected, emailOptInIsSelected: emailOptInNSNumber))
    }
    
    func validateAndSubmit() {
        validateAmount()
        submit()
    }
    
    private var errorLocalizedStrings: ErrorViewModel.LocalizedStrings {
        return ErrorViewModel.LocalizedStrings(genericErrorFormat: localizedStrings.genericErrorTextFormat, minimumErrorText: localizedStrings.minimumErrorText, maximumErrorText: localizedStrings.maximumErrorText)
    }
    
    func validateAmount() {

        guard let minimum = donateConfig.currencyMinimumDonation[currencyCode] else {
            return
        }

        if finalAmount < minimum {
            let errorViewModel = ErrorViewModel(localizedStrings: errorLocalizedStrings, error: WMFDonateViewModel.Error.validationAmountMinimum, orderID: nil)
            self.errorViewModel = errorViewModel
            loggingDelegate?.handleDonateLoggingAction(.nativeFormDidTriggerError(error: errorViewModel.error))
            return
        }

        if finalAmount > donateConfig.getMaxAmount(for: currencyCode) {
            let errorViewModel = ErrorViewModel(localizedStrings: errorLocalizedStrings, error: WMFDonateViewModel.Error.validationAmountMaximum, orderID: nil)
            self.errorViewModel = errorViewModel
            loggingDelegate?.handleDonateLoggingAction(.nativeFormDidTriggerError(error: errorViewModel.error))
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
            if loopButtonViewModel.amount != buttonViewModel.amount {
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
        let newButtonViewModels = buttonViewModels.map { AmountButtonViewModel(amount: $0.amount, isSelected: targetButtonAmount == $0.amount, currencyCode: currencyCode, accessibilityHint: localizedStrings.accessibilityAmountButtonHint, coordinatorDelegate: coordinatorDelegate, loggingDelegate: loggingDelegate) }
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
    
    private static func transactionFee(donateConfig: WMFDonateConfig, currencyCode: String, amount: Decimal = 0.0) -> Decimal? {
        let percent = Decimal(0.04)
        let percentageTransactionFee = amount * percent
        
        var finalTransactionFee: Decimal?
        
        if let minimumTransactionFee = donateConfig.currencyTransactionFees[currencyCode] {
            finalTransactionFee = percentageTransactionFee > minimumTransactionFee ? percentageTransactionFee : minimumTransactionFee
        } else if let defaultTransactionFee = donateConfig.currencyTransactionFees["default"] {
            finalTransactionFee = percentageTransactionFee > defaultTransactionFee ? percentageTransactionFee : defaultTransactionFee
        }
        
        return finalTransactionFee
    }
    
    private func recalculateTransactionFee() {
        
        let originalAmount = transactionFeeOptInViewModel.isSelected ? finalAmount - transactionFeeAmount : finalAmount

        guard let transactionFee = Self.transactionFee(donateConfig: donateConfig, currencyCode: currencyCode, amount: originalAmount) else {
            return
        }
        
        let formatter = NumberFormatter.wmfCurrencyFormatter
        formatter.currencyCode = currencyCode
        
        guard let transactionFeeString = formatter.string(from: transactionFeeAmount as NSNumber) else {
            return
        }
        
        self.transactionFeeAmount = transactionFee
        
        // Assign transactionFeeOptInViewModel again so that SwiftUI form updates
        let text = String.localizedStringWithFormat(localizedStrings.transactionFeeOptInTextFormat, transactionFeeString)
        let isOldModelSelected = transactionFeeOptInViewModel.isSelected
        transactionFeeOptInViewModel = OptInViewModel(localizedStrings: OptInViewModel.LocalizedStrings(text: text, accessibilityHint: localizedStrings.accessibilityTransactionFeeHint), isSelected: isOldModelSelected)
        addTransactionFeeSelectionListener()
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

extension WMFDonateViewModel: PKPaymentAuthorizationControllerDelegate {

    public func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        
        let presetIsSelected = buttonViewModels.first(where: {$0.isSelected}) != nil
        
        loggingDelegate?.handleDonateLoggingAction(.nativeFormDidAuthorizeApplePayPaymentSheet(amount: finalAmount, presetIsSelected: presetIsSelected, recurringMonthlyIsSelected: monthlyRecurringViewModel.isSelected, donorEmail: payment.shippingContact?.emailAddress, metricsID: metricsID))

        let paymentToken: String
        if !WMFDeveloperSettingsDataController.shared.bypassDonation {
            guard !payment.token.paymentData.isEmpty,
                  let token = String(data: payment.token.paymentData, encoding: .utf8) else {
                let error = Error.invalidToken
                self.errorViewModel = ErrorViewModel(localizedStrings: errorLocalizedStrings, error: error, orderID: nil)
                loggingDelegate?.handleDonateLoggingAction(.nativeFormDidTriggerError(error: error))
                completion(PKPaymentAuthorizationResult(status: .failure, errors: [error]))
                return
            }
            paymentToken = token
        } else {
            paymentToken = ""
        }
        
        guard let donorNameComponents = payment.billingContact?.name,
              let donorEmail = payment.shippingContact?.emailAddress,
              let donorAddressComponents = payment.billingContact?.postalAddress else {
            let error = Error.missingDonorInfo
            self.errorViewModel = ErrorViewModel(localizedStrings: errorLocalizedStrings, error: error, orderID: nil)
            loggingDelegate?.handleDonateLoggingAction(.nativeFormDidTriggerError(error: error))
            completion(PKPaymentAuthorizationResult(status: .failure, errors: [error]))
            return
        }
        let recurring: Bool = monthlyRecurringViewModel.isSelected
        let emailOptIn: Bool? = emailOptInViewModel?.isSelected
        
        let paymentNetwork = payment.token.paymentMethod.network?.rawValue
        
        let dataController = WMFDonateDataController.shared
        dataController.submitPayment(amount: finalAmount, countryCode: countryCode, currencyCode: currencyCode, languageCode: languageCode, paymentToken: paymentToken, paymentNetwork: paymentNetwork, donorNameComponents: donorNameComponents, recurring: recurring, donorEmail: donorEmail, donorAddressComponents: donorAddressComponents, emailOptIn: emailOptIn, transactionFee: transactionFeeOptInViewModel.isSelected, metricsID: metricsID, appVersion: appVersion) { [weak self] result in
            
            guard let self else {
                return
            }
            
            switch result {
            case .success:
                completion(PKPaymentAuthorizationResult(status: .success, errors: []))
                // Wait for payment sheet to dismiss
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.75, execute: { [weak self] in

                    guard let self else { return }

                    self.saveDonationToLocalHistory(with: dataController, recurring: recurring, currencyCode: self.currencyCode)
                    self.coordinatorDelegate?.handleDonateAction(.nativeFormDidTriggerPaymentSuccess)
                    self.loggingDelegate?.handleDonateLoggingAction(.nativeFormDidTriggerPaymentSuccess)
                })
            case .failure(let error):
                if let dataControllerError = error as? WMFDonateDataControllerError {
                    switch dataControllerError {
                    case .paymentsWikiResponseError(_, let orderID):
                        DispatchQueue.main.async {
                            self.errorViewModel = ErrorViewModel(localizedStrings: self.errorLocalizedStrings, error: error, orderID: orderID)
                        }
                        loggingDelegate?.handleDonateLoggingAction(.nativeFormDidTriggerError(error: error))
                    }
                } else {
                    DispatchQueue.main.async {
                        self.errorViewModel = ErrorViewModel(localizedStrings: self.errorLocalizedStrings, error: error, orderID: nil)
                    }
                    loggingDelegate?.handleDonateLoggingAction(.nativeFormDidTriggerError(error: error))
                }
                
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

    private func saveDonationToLocalHistory(with dataController: WMFDonateDataController, recurring: Bool, currencyCode: String) {
        let donationType: WMFDonateLocalHistory.DonationType = recurring ? .recurring : .oneTime
        
        dataController.saveLocalDonationHistory(type: donationType, amount: finalAmount, currencyCode: currencyCode, isNative: true)
    }

}
