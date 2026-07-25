import Foundation
import Testing
import WMFDataTestSupport
@testable import WMFComponents
@testable import WMFData
@testable import WMFDataMocks

@MainActor
final class WMFDonateViewModelTests {

    private let fixture = WMFDataTestFixture()
    private let merchantID = "merchant.id"

    @Test
    func viewModelInstantiatesWithCorrectDefaultsUSD() async throws {
        let viewModel = try await makeViewModel(countryCode: "US", currencyCode: "USD", languageCode: "EN", appInstallID: nil)

        #expect(viewModel.buttonViewModels.count == 7)
        
        let firstButtonVM = viewModel.buttonViewModels[0]
        #expect(firstButtonVM.currencyCode == "USD")
        #expect(firstButtonVM.isSelected == false)
        #expect(firstButtonVM.amount == 3)
        
        let secondButtonVM = viewModel.buttonViewModels[1]
        #expect(secondButtonVM.currencyCode == "USD")
        #expect(secondButtonVM.isSelected == false)
        #expect(secondButtonVM.amount == 10)
        
        let thirdButtonVM = viewModel.buttonViewModels[2]
        #expect(thirdButtonVM.currencyCode == "USD")
        #expect(thirdButtonVM.isSelected == false)
        #expect(thirdButtonVM.amount == 15)
        
        let fourthButtonVM = viewModel.buttonViewModels[3]
        #expect(fourthButtonVM.currencyCode == "USD")
        #expect(fourthButtonVM.isSelected == false)
        #expect(fourthButtonVM.amount == 25)
        
        let fifthButtonVM = viewModel.buttonViewModels[4]
        #expect(fifthButtonVM.currencyCode == "USD")
        #expect(fifthButtonVM.isSelected == false)
        #expect(fifthButtonVM.amount == 50)
        
        let sixthButtonVM = viewModel.buttonViewModels[5]
        #expect(sixthButtonVM.currencyCode == "USD")
        #expect(sixthButtonVM.isSelected == false)
        #expect(sixthButtonVM.amount == 75)
        
        let seventhButtonVM = viewModel.buttonViewModels[6]
        #expect(seventhButtonVM.currencyCode == "USD")
        #expect(seventhButtonVM.isSelected == false)
        #expect(seventhButtonVM.amount == 100)
        
        #expect(viewModel.textfieldViewModel.currencyCode == "USD")
        #expect(viewModel.textfieldViewModel.amount == 0)
        
        #expect(viewModel.transactionFeeOptInViewModel.isSelected == false)
        
        #expect(viewModel.emailOptInViewModel == nil)
        #expect(viewModel.errorViewModel == nil)
    }
    
    @Test
    func viewModelInstantiatesWithCorrectDefaultsUYU() async throws {
        let viewModel = try await makeViewModel(countryCode: "UY", currencyCode: "UYU", languageCode: "ES")

        #expect(viewModel.buttonViewModels.count == 7)
        
        let firstButtonVM = viewModel.buttonViewModels[0]
        #expect(firstButtonVM.currencyCode == "UYU")
        #expect(firstButtonVM.isSelected == false)
        #expect(firstButtonVM.amount == 100)
        
        let secondButtonVM = viewModel.buttonViewModels[1]
        #expect(secondButtonVM.currencyCode == "UYU")
        #expect(secondButtonVM.isSelected == false)
        #expect(secondButtonVM.amount == 200)
        
        let thirdButtonVM = viewModel.buttonViewModels[2]
        #expect(thirdButtonVM.currencyCode == "UYU")
        #expect(thirdButtonVM.isSelected == false)
        #expect(thirdButtonVM.amount == 300)
        
        let fourthButtonVM = viewModel.buttonViewModels[3]
        #expect(fourthButtonVM.currencyCode == "UYU")
        #expect(fourthButtonVM.isSelected == false)
        #expect(fourthButtonVM.amount == 500)
        
        let fifthButtonVM = viewModel.buttonViewModels[4]
        #expect(fifthButtonVM.currencyCode == "UYU")
        #expect(fifthButtonVM.isSelected == false)
        #expect(fifthButtonVM.amount == 1000)
        
        let sixthButtonVM = viewModel.buttonViewModels[5]
        #expect(sixthButtonVM.currencyCode == "UYU")
        #expect(sixthButtonVM.isSelected == false)
        #expect(sixthButtonVM.amount == 1500)
        
        let seventhButtonVM = viewModel.buttonViewModels[6]
        #expect(seventhButtonVM.currencyCode == "UYU")
        #expect(seventhButtonVM.isSelected == false)
        #expect(seventhButtonVM.amount == 2000)
        
        #expect(viewModel.textfieldViewModel.currencyCode == "UYU")
        #expect(viewModel.textfieldViewModel.amount == 0)
        
        #expect(viewModel.transactionFeeOptInViewModel.isSelected == false)
        
        #expect(viewModel.emailOptInViewModel != nil)
        #expect(viewModel.emailOptInViewModel?.isSelected == false)
        #expect(viewModel.errorViewModel == nil)
    }
    
    @Test
    func selectAmountButtonUpdatesTextfieldUSD() async throws {
        let viewModel = try await makeViewModel(countryCode: "US", currencyCode: "USD", languageCode: "EN")
        
        // Confirm initial values are correct
        viewModel.textfieldViewModel.hasFocus = false
        let firstButtonVM = viewModel.buttonViewModels[0]
        #expect(firstButtonVM.isSelected == false)
        #expect(viewModel.textfieldViewModel.amount == 0)
        
        viewModel.textfieldViewModel.hasFocus = false
        
        // Select amount button
        firstButtonVM.isSelected = true
        
        #expect(viewModel.textfieldViewModel.amount == firstButtonVM.amount)
    }
    
    @Test
    func updateTextfieldSelectsAmountButtonUSD() async throws {
        let viewModel = try await makeViewModel(countryCode: "US", currencyCode: "USD", languageCode: "EN")
        
        viewModel.textfieldViewModel.hasFocus = false
        
        
        // Confirm initial values are correct
        let firstButtonVM = viewModel.buttonViewModels[0]
        #expect(firstButtonVM.isSelected == false)
        #expect(viewModel.textfieldViewModel.amount == 0)
        
        // Update textfield
        viewModel.textfieldViewModel.amount = 3
        
        // Confirm first button is now selected
        let newFirstButton = viewModel.buttonViewModels[0]
        #expect(newFirstButton.isSelected)
    }
    
    @Test
    func selectTransactionFeeUpdatesTextfieldAndAmountButtonUSD() async throws {
        let viewModel = try await makeViewModel(countryCode: "US", currencyCode: "USD", languageCode: "EN")
        
        viewModel.textfieldViewModel.hasFocus = false
        
        // Confirm initial values are correct
        #expect(viewModel.textfieldViewModel.amount == 0)
        #expect(viewModel.transactionFeeOptInViewModel.isSelected == false)
        
        // Set amount to 3 initially
        viewModel.textfieldViewModel.amount = 3
        
        // Select transaction fee
        viewModel.transactionFeeOptInViewModel.isSelected = true
        
        // Confirm textfield has updated
        #expect(viewModel.textfieldViewModel.amount == 3.35)
    }
    
    @Test
    func smallAmountTriggersMinimumErrorUSD() async throws {
        let viewModel = try await makeViewModel(countryCode: "US", currencyCode: "USD", languageCode: "EN")
        
        // Confirm initial values are correct
        #expect(viewModel.textfieldViewModel.amount == 0)
        #expect(viewModel.errorViewModel == nil)
        
        // Set amount to something small
        viewModel.textfieldViewModel.amount = 0.25
        
        // Trigger validation
        viewModel.validateAmount()
        
        #expect(viewModel.errorViewModel != nil)
    }
    
    @Test
    func largeAmountTriggersMaximumErrorUSD() async throws {
        let viewModel = try await makeViewModel(countryCode: "US", currencyCode: "USD", languageCode: "EN")
        
        // Confirm initial values are correct
        #expect(viewModel.textfieldViewModel.amount == 0)
        #expect(viewModel.errorViewModel == nil)
        
        // Set amount to something large
        viewModel.textfieldViewModel.amount = 30000
        
        // Trigger validation
        viewModel.validateAmount()
        
        #expect(viewModel.errorViewModel != nil)
    }

    private func makeViewModel(countryCode: String, currencyCode: String, languageCode: String, appInstallID: String? = UUID().uuidString) async throws -> WMFDonateViewModel {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let donateData = try await loadDonateData()
            return try #require(WMFDonateViewModel(localizedStrings: .demoStringsForCurrencyCode(currencyCode), donateConfig: donateData.donateConfig, paymentMethods: donateData.paymentMethods, countryCode: countryCode, currencyCode: currencyCode, languageCode: languageCode, merchantID: merchantID, metricsID: "enNL_2023_11_iOS", appVersion: "7.4.3", appInstallID: appInstallID, coordinatorDelegate: nil, loggingDelegate: nil))
        }
    }

    private func configureEnvironment() async {
        WMFDataEnvironment.current.basicService = WMFMockBasicService()
        WMFDataEnvironment.current.serviceEnvironment = .staging
    }

    private func loadDonateData() async throws -> (donateConfig: WMFDonateConfig, paymentMethods: WMFPaymentMethods) {
        let controller = WMFDonateDataController(service: WMFMockBasicService(), sharedCacheStore: WMFMockKeyValueStore())
        try await controller.fetchConfigs(for: "US")

        let data = controller.loadConfigs()
        return (
            donateConfig: try #require(data.donateConfig),
            paymentMethods: try #require(data.paymentMethods)
        )
    }
}

private extension WMFDonateDataController {
    func fetchConfigs(for countryCode: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            fetchConfigs(for: countryCode) { result in
                continuation.resume(with: result)
            }
        }
    }
}

private extension WMFDonateViewModel.LocalizedStrings {
    static func demoStringsForCurrencyCode(_ currencyCode: String) -> WMFDonateViewModel.LocalizedStrings {

        let title = "Select an amount"
        let cancelTitle = "Cancel"

        let transactionFeeFormat = "I’ll generously add %1$@ to cover the transaction fees so you can keep 100 percent of my donation."
        
        var minimumString: String = ""
        var maximumString: String? = nil
        if currencyCode == "USD" {
            minimumString = usdMinimumString
            maximumString = usdMaximumString
        } else if currencyCode == "UYU" {
            minimumString = uyuMinimumString
            maximumString = nil
        }
        
        let genericError = "Something went wrong."
        
        let emailOptIn = "Yes, the Wikimedia Foundation can send me an occasional email."
        
        let helpProblemsDonating = "Problems donating?"
        let helpOtherWaysToGive = "Other ways to give"
        let helpFrequentlyAskedQuestions = "Frequently asked questions"
        let helpTaxDeductibilityInformation = "Tax deductibility information"
        
        let appleFinePrint = "Apple is not in charge of raising money for this purpose."
        let wikimediaFinePrint1 = "We do not sell or trade your information to anyone. By donating, you agree to share your personal information with the Wikimedia Foundation, the nonprofit organization that hosts Wikipedia and other Wikimedia projects, and its service providers pursuant to our donor policy. Wikimedia Foundation and its service providers are located in the United States and in other countries whose privacy laws may not be equivalent to your own. For more information please read our donor policy."
        let wikimediaFinePrint2 = "For recurring donors, fixed monthly payments will be debited by the Wikimedia Foundation on the monthly anniversary of the first donation, until such time as you notify us to discontinue them. Donations initiated on the 29, 30, or 31 of the month will recur on the last day of the month for shorter months, as close to the original date as possible. For questions, please contact donate@wikimedia.org."
        
        let accessibilityAmountButtonHint = "Double tap to select donation amount."
        let accessibilityTextfieldHint = "Enter custom amount to donate."
        let accessibilityTransactionFeeHint = "Double tap to add transaction fee to donation amount."
        let accessibilityEmailOptInHint = "Double tap to give the Wikimedia Foundation permission to email you."
        let accessibilityKeyboardDoneButtonHint = "Double tap to dismiss amount input keyboard view."
        let accessibilityDonateHintButtonFormat = "Double tap to donate %1$@ to the Wikimedia Foundation."
        
        let monthlyRecurring = "Make this a monthly recurring donation."
        let accessibilityMonthlyRecurringHint = "Double tap to enable automatic monthly donations of this amount."
        
        return WMFDonateViewModel.LocalizedStrings(title: title, cancelTitle: cancelTitle, transactionFeeOptInTextFormat: transactionFeeFormat, monthlyRecurringText: monthlyRecurring, emailOptInText: emailOptIn, maximumErrorText: maximumString, minimumErrorText: minimumString, genericErrorTextFormat: genericError, helpLinkProblemsDonating: helpProblemsDonating, helpLinkOtherWaysToGive: helpOtherWaysToGive, helpLinkFrequentlyAskedQuestions: helpFrequentlyAskedQuestions, helpLinkTaxDeductibilityInformation: helpTaxDeductibilityInformation, appleFinePrint: appleFinePrint, wikimediaFinePrint1: wikimediaFinePrint1, wikimediaFinePrint2: wikimediaFinePrint2, accessibilityAmountButtonHint: accessibilityAmountButtonHint, accessibilityTextfieldHint: accessibilityTextfieldHint, accessibilityTransactionFeeHint: accessibilityTransactionFeeHint, accessibilityMonthlyRecurringHint: accessibilityMonthlyRecurringHint, accessibilityEmailOptInHint: accessibilityEmailOptInHint, accessibilityKeyboardDoneButtonHint: accessibilityKeyboardDoneButtonHint, accessibilityDonateButtonHintFormat: accessibilityDonateHintButtonFormat)
    }
    
    static var usdMinimumString: String {
        let minimumFormat = "Please select an amount (minimum %1$@ %2$@)."
        return String.localizedStringWithFormat(minimumFormat, "$1.00", "USD")
    }
    
    static var usdMaximumString: String {
        let maximumFormat = "We cannot accept donations greater than %1$@ %2$@ through our website. Please contact our major gifts staff at benefactors@wikimedia.org."
        return String.localizedStringWithFormat(maximumFormat, "$25,000", "USD")
    }
    
    static var uyuMinimumString: String {
        let minimumFormat = "Please select an amount (minimum %1$@ %2$@)."
        return String.localizedStringWithFormat(minimumFormat, "$U 1.00", "UYU")
    }
}
