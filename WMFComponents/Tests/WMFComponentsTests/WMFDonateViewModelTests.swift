import XCTest
@testable import WMFComponents
@testable import WMFData
@testable import WMFDataMocks

final class WMFDonateViewModelTests: XCTestCase {
    
    private var paymentMethods: WMFPaymentMethods?
    private var donateConfig: WMFDonateConfig?
    
    private let merchantID = "merchant.id"
    
    override func setUp(completion: @escaping (Error?) -> Void) {
        WMFDataEnvironment.current.basicService = WMFMockBasicService()
        WMFDataEnvironment.current.serviceEnvironment = .staging
        
        let controller = WMFDonateDataController.shared
        
        controller.fetchConfigs(for: "US") { result in
            switch result {
            case .success:
                let data = controller.loadConfigs()
                self.paymentMethods = data.paymentMethods
                self.donateConfig = data.donateConfig
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }
    
    func testViewModelInstantiatesWithCorrectDefaultsUSD() {
        
        guard let donateConfig,
              let paymentMethods else {
            XCTFail("Failure mocking donate config and payment methods")
            return
        }
        
        guard let viewModel = WMFDonateViewModel(localizedStrings: .demoStringsForCurrencyCode("USD"), donateConfig: donateConfig, paymentMethods: paymentMethods, countryCode: "US", currencyCode: "USD",  languageCode: "EN", merchantID: merchantID, metricsID: "enNL_2023_11_iOS", appVersion: "7.4.3", coordinatorDelegate: nil, loggingDelegate: nil) else {
            XCTFail("View model failed to instantiate")
            return
        }
        XCTAssertEqual(viewModel.buttonViewModels.count, 7)
        
        let firstButtonVM = viewModel.buttonViewModels[0]
        XCTAssertEqual(firstButtonVM.currencyCode, "USD")
        XCTAssertFalse(firstButtonVM.isSelected)
        XCTAssertEqual(firstButtonVM.amount, 3)
        
        let secondButtonVM = viewModel.buttonViewModels[1]
        XCTAssertEqual(secondButtonVM.currencyCode, "USD")
        XCTAssertFalse(secondButtonVM.isSelected)
        XCTAssertEqual(secondButtonVM.amount, 10)
        
        let thirdButtonVM = viewModel.buttonViewModels[2]
        XCTAssertEqual(thirdButtonVM.currencyCode, "USD")
        XCTAssertFalse(thirdButtonVM.isSelected)
        XCTAssertEqual(thirdButtonVM.amount, 15)
        
        let fourthButtonVM = viewModel.buttonViewModels[3]
        XCTAssertEqual(fourthButtonVM.currencyCode, "USD")
        XCTAssertFalse(fourthButtonVM.isSelected)
        XCTAssertEqual(fourthButtonVM.amount, 25)
        
        let fifthButtonVM = viewModel.buttonViewModels[4]
        XCTAssertEqual(fifthButtonVM.currencyCode, "USD")
        XCTAssertFalse(fifthButtonVM.isSelected)
        XCTAssertEqual(fifthButtonVM.amount, 50)
        
        let sixthButtonVM = viewModel.buttonViewModels[5]
        XCTAssertEqual(sixthButtonVM.currencyCode, "USD")
        XCTAssertFalse(sixthButtonVM.isSelected)
        XCTAssertEqual(sixthButtonVM.amount, 75)
        
        let seventhButtonVM = viewModel.buttonViewModels[6]
        XCTAssertEqual(seventhButtonVM.currencyCode, "USD")
        XCTAssertFalse(seventhButtonVM.isSelected)
        XCTAssertEqual(seventhButtonVM.amount, 100)
        
        XCTAssertEqual(viewModel.textfieldViewModel.currencyCode, "USD")
        XCTAssertEqual(viewModel.textfieldViewModel.amount, 0)
        
        XCTAssertFalse(viewModel.transactionFeeOptInViewModel.isSelected)
        
        XCTAssertNil(viewModel.emailOptInViewModel)
        XCTAssertNil(viewModel.errorViewModel)
    }
    
    func testViewModelInstantiatesWithCorrectDefaultsUYU() {
        
        guard let donateConfig,
              let paymentMethods else {
            XCTFail("Failure mocking donate config and payment methods")
            return
        }
        
        guard let viewModel = WMFDonateViewModel(localizedStrings: .demoStringsForCurrencyCode("UYU"), donateConfig: donateConfig, paymentMethods: paymentMethods, countryCode: "UY", currencyCode: "UYU", languageCode: "ES", merchantID: merchantID, metricsID: "enNL_2023_11_iOS", appVersion: "7.4.3", coordinatorDelegate: nil, loggingDelegate: nil) else {
            XCTFail("View model failed to instantiate")
            return
        }
        XCTAssertEqual(viewModel.buttonViewModels.count, 7)
        
        let firstButtonVM = viewModel.buttonViewModels[0]
        XCTAssertEqual(firstButtonVM.currencyCode, "UYU")
        XCTAssertFalse(firstButtonVM.isSelected)
        XCTAssertEqual(firstButtonVM.amount, 100)
        
        let secondButtonVM = viewModel.buttonViewModels[1]
        XCTAssertEqual(secondButtonVM.currencyCode, "UYU")
        XCTAssertFalse(secondButtonVM.isSelected)
        XCTAssertEqual(secondButtonVM.amount, 200)
        
        let thirdButtonVM = viewModel.buttonViewModels[2]
        XCTAssertEqual(thirdButtonVM.currencyCode, "UYU")
        XCTAssertFalse(thirdButtonVM.isSelected)
        XCTAssertEqual(thirdButtonVM.amount, 300)
        
        let fourthButtonVM = viewModel.buttonViewModels[3]
        XCTAssertEqual(fourthButtonVM.currencyCode, "UYU")
        XCTAssertFalse(fourthButtonVM.isSelected)
        XCTAssertEqual(fourthButtonVM.amount, 500)
        
        let fifthButtonVM = viewModel.buttonViewModels[4]
        XCTAssertEqual(fifthButtonVM.currencyCode, "UYU")
        XCTAssertFalse(fifthButtonVM.isSelected)
        XCTAssertEqual(fifthButtonVM.amount, 1000)
        
        let sixthButtonVM = viewModel.buttonViewModels[5]
        XCTAssertEqual(sixthButtonVM.currencyCode, "UYU")
        XCTAssertFalse(sixthButtonVM.isSelected)
        XCTAssertEqual(sixthButtonVM.amount, 1500)
        
        let seventhButtonVM = viewModel.buttonViewModels[6]
        XCTAssertEqual(seventhButtonVM.currencyCode, "UYU")
        XCTAssertFalse(seventhButtonVM.isSelected)
        XCTAssertEqual(seventhButtonVM.amount, 2000)
        
        XCTAssertEqual(viewModel.textfieldViewModel.currencyCode, "UYU")
        XCTAssertEqual(viewModel.textfieldViewModel.amount, 0)
        
        XCTAssertFalse(viewModel.transactionFeeOptInViewModel.isSelected)
        
        XCTAssertNotNil(viewModel.emailOptInViewModel)
        XCTAssertEqual(viewModel.emailOptInViewModel?.isSelected, false)
        XCTAssertNil(viewModel.errorViewModel)
    }
    
    func testSelectAmountButtonUpdatesTextfieldUSD() {
        guard let donateConfig,
              let paymentMethods else {
            XCTFail("Failure mocking donate config and payment methods")
            return
        }
        
        guard let viewModel = WMFDonateViewModel(localizedStrings: .demoStringsForCurrencyCode("USD"), donateConfig: donateConfig, paymentMethods: paymentMethods, countryCode: "US", currencyCode: "USD", languageCode: "EN", merchantID: merchantID, metricsID: "enNL_2023_11_iOS", appVersion: "7.4.3", coordinatorDelegate: nil, loggingDelegate: nil) else {
            XCTFail("View model failed to instantiate")
            return
        }
        
        // Confirm initial values are correct
        viewModel.textfieldViewModel.hasFocus = false
        let firstButtonVM = viewModel.buttonViewModels[0]
        XCTAssertFalse(firstButtonVM.isSelected)
        XCTAssertEqual(viewModel.textfieldViewModel.amount, 0)
        
        viewModel.textfieldViewModel.hasFocus = false
        
        // Select amount button
        firstButtonVM.isSelected = true
        
        let expectation = XCTestExpectation(description: "Waiting for textfield amount to update")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertEqual(viewModel.textfieldViewModel.amount, firstButtonVM.amount)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testUpdateTextfieldSelectsAmountButtonUSD() {
        guard let donateConfig,
              let paymentMethods else {
            XCTFail("Failure mocking donate config and payment methods")
            return
        }
        
        guard let viewModel = WMFDonateViewModel(localizedStrings: .demoStringsForCurrencyCode("USD"), donateConfig: donateConfig, paymentMethods: paymentMethods, countryCode: "US", currencyCode: "USD", languageCode: "EN", merchantID: merchantID, metricsID: "enNL_2023_11_iOS", appVersion: "7.4.3", coordinatorDelegate: nil, loggingDelegate: nil) else {
            XCTFail("View model failed to instantiate")
            return
        }
        
        viewModel.textfieldViewModel.hasFocus = false
        
        
        // Confirm initial values are correct
        let firstButtonVM = viewModel.buttonViewModels[0]
        XCTAssertFalse(firstButtonVM.isSelected)
        XCTAssertEqual(viewModel.textfieldViewModel.amount, 0)
        
        // Update textfield
        viewModel.textfieldViewModel.amount = 3
        
        let expectation = XCTestExpectation(description: "Waiting for button selections to update")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Confirm first button is now selected
            let newFirstButton = viewModel.buttonViewModels[0]
            XCTAssertTrue(newFirstButton.isSelected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testSelectTransactionFeeUpdatesTextfieldAndAmountButtonUSD() {
        guard let donateConfig,
              let paymentMethods else {
            XCTFail("Failure mocking donate config and payment methods")
            return
        }
        
        guard let viewModel = WMFDonateViewModel(localizedStrings: .demoStringsForCurrencyCode("USD"), donateConfig: donateConfig, paymentMethods: paymentMethods, countryCode: "US", currencyCode: "USD", languageCode: "EN", merchantID: merchantID, metricsID: "enNL_2023_11_iOS", appVersion: "7.4.3", coordinatorDelegate: nil, loggingDelegate: nil) else {
            XCTFail("View model failed to instantiate")
            return
        }
        
        viewModel.textfieldViewModel.hasFocus = false
        
        // Confirm initial values are correct
        XCTAssertEqual(viewModel.textfieldViewModel.amount, 0)
        XCTAssertFalse(viewModel.transactionFeeOptInViewModel.isSelected)
        
        // Set amount to 3 initially
        viewModel.textfieldViewModel.amount = 3
        
        // Select transaction fee
        viewModel.transactionFeeOptInViewModel.isSelected = true
        
        let expectation = XCTestExpectation(description: "Waiting for textfield amount to update")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            
            // Confirm textfield has updated
            XCTAssertEqual(viewModel.textfieldViewModel.amount, 3.35)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testSmallAmountTriggersMinimumErrorUSD() {
        guard let donateConfig,
              let paymentMethods else {
            XCTFail("Failure mocking donate config and payment methods")
            return
        }
        
        guard let viewModel = WMFDonateViewModel(localizedStrings: .demoStringsForCurrencyCode("USD"), donateConfig: donateConfig, paymentMethods: paymentMethods, countryCode: "US", currencyCode: "USD", languageCode: "EN", merchantID: merchantID, metricsID: "enNL_2023_11_iOS", appVersion: "7.4.3", coordinatorDelegate: nil, loggingDelegate: nil) else {
            XCTFail("View model failed to instantiate")
            return
        }
        
        // Confirm initial values are correct
        XCTAssertEqual(viewModel.textfieldViewModel.amount, 0)
        XCTAssertNil(viewModel.errorViewModel)
        
        // Set amount to something small
        viewModel.textfieldViewModel.amount = 0.25
        
        // Trigger validation
        viewModel.validateAmount()
        
        XCTAssertNotNil(viewModel.errorViewModel)
    }
    
    func testLargeAmountTriggersMaximumErrorUSD() {
        guard let donateConfig,
              let paymentMethods else {
            XCTFail("Failure mocking donate config and payment methods")
            return
        }
        
        guard let viewModel = WMFDonateViewModel(localizedStrings: .demoStringsForCurrencyCode("USD"), donateConfig: donateConfig, paymentMethods: paymentMethods, countryCode: "US", currencyCode: "USD", languageCode: "EN", merchantID: merchantID, metricsID: "enNL_2023_11_iOS", appVersion: "7.4.3", coordinatorDelegate: nil, loggingDelegate: nil) else {
            XCTFail("View model failed to instantiate")
            return
        }
        
        // Confirm initial values are correct
        XCTAssertEqual(viewModel.textfieldViewModel.amount, 0)
        XCTAssertNil(viewModel.errorViewModel)
        
        // Set amount to something large
        viewModel.textfieldViewModel.amount = 30000
        
        // Trigger validation
        viewModel.validateAmount()
        
        XCTAssertNotNil(viewModel.errorViewModel)
    }
}

private extension WMFDonateViewModel.LocalizedStrings {
    static func demoStringsForCurrencyCode(_ currencyCode: String) -> WMFDonateViewModel.LocalizedStrings {

        let title = "Select an amount"
        let doneTitle = "Done"
        
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
        
        return WMFDonateViewModel.LocalizedStrings(title: title, doneTitle: doneTitle, transactionFeeOptInTextFormat: transactionFeeFormat, monthlyRecurringText: monthlyRecurring, emailOptInText: emailOptIn, maximumErrorText: maximumString, minimumErrorText: minimumString, genericErrorTextFormat: genericError, helpLinkProblemsDonating: helpProblemsDonating, helpLinkOtherWaysToGive: helpOtherWaysToGive, helpLinkFrequentlyAskedQuestions: helpFrequentlyAskedQuestions, helpLinkTaxDeductibilityInformation: helpTaxDeductibilityInformation, appleFinePrint: appleFinePrint, wikimediaFinePrint1: wikimediaFinePrint1, wikimediaFinePrint2: wikimediaFinePrint2, accessibilityAmountButtonHint: accessibilityAmountButtonHint, accessibilityTextfieldHint: accessibilityTextfieldHint, accessibilityTransactionFeeHint: accessibilityTransactionFeeHint, accessibilityMonthlyRecurringHint: accessibilityMonthlyRecurringHint, accessibilityEmailOptInHint: accessibilityEmailOptInHint, accessibilityKeyboardDoneButtonHint: accessibilityKeyboardDoneButtonHint, accessibilityDonateButtonHintFormat: accessibilityDonateHintButtonFormat)
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
