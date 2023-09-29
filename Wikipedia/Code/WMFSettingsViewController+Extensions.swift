import Foundation
import Components
import WKData

@objc extension WMFSettingsViewController {
    func pushToDonateView() {
        guard let donateConfig = WKDonateDataController.donateConfig,
              let paymentMethods = WKDonateDataController.paymentMethods else {
            // TODO: Web path only
            return
        }
        
        let formatter = NumberFormatter.wkCurrencyFormatter
        
        // TODO: Try announcement currency code first
        guard let currencyCode = NSLocale.current.currencyCode else {
            // TODO: Web path only
            return
        }
        
        // TODO: Pass in announcement country code
        guard let countryCode = NSLocale.current.regionCode else {
            // TODO: Web path only
            return
        }
        
        formatter.currencyCode = currencyCode
        
        guard let transactionFee = donateConfig.transactionFee(for: currencyCode),
              let transactionFeeString = formatter.string(from: transactionFee as NSNumber),
            let minimumValue = donateConfig.currencyMinimumDonation[currencyCode],
              let minimumString = formatter.string(from: minimumValue as NSNumber) else {
            // TODO: Web path only
            return
        }
        
        var maximumString: String?
        if let maximumValue = donateConfig.currencyMaximumDonation[currencyCode] {
            maximumString = formatter.string(from: maximumValue as NSNumber)
        }
        
        let donate = WMFLocalizedString("donate-title", value: "Select an amount", comment: "Title for donate form.")
        let done = CommonStrings.doneTitle
        
        let transactionFeeFormat = WMFLocalizedString("donate-transaction-fee-opt-in-text", value: "I’ll generously add %1$@ to cover the transaction fees so you can keep 100 percent of my donation.", comment: "Text for search result letting user know if a result is a redirect from another article. Parameters: * %1$@ - article title the current search result redirected from")
        let transactionFeeOptIn = String.localizedStringWithFormat(transactionFeeFormat, transactionFeeString)
        
        let minimumFormat = WMFLocalizedString("donate-minimum-error-text", value: "Please select an amount (minimum %1$@ %2$@).", comment: "Error text displayed when user enters donation amount below the allowed minimum. Parameters: * %1$@ - the minimum amount allowed, %2$@ - the currency code. (For example, '$1 USD')")
        let minimum = String.localizedStringWithFormat(minimumFormat, minimumString, currencyCode)
        
        var maximum: String?
        if let maximumString {
            let maximumFormat = WMFLocalizedString("donate-maximum-error-text", value: "We cannot accept donations greater than %1$@ %2$@ through our website. Please contact our major gifts staff at benefactors@wikimedia.org.", comment: "Error text displayed when user enters donation amount above the maximum. Parameters: * %1$@ - the currency code, %2$@ - the maximum donation amount allowed. (For example, 'USD $25,000')")
            maximum = String.localizedStringWithFormat(maximumFormat, maximumString, currencyCode)
        }
        
        let genericErrorFormat = "\(CommonStrings.genericErrorDescription)\n\n%1$@"
        
        let emailOptIn = WMFLocalizedString("donate-email-opt-in-text", value: "Yes, the Wikimedia Foundation can send me an occasional email.", comment: "Text next to email opt-in checkbox on donate form.")
        
        let helpProblemsDonating = WMFLocalizedString("donate-help-problems-donating", value: "Problems donating?", comment: "Help link at the bottom of the donate form, that takes user to a web view link with more info.")
        let helpOtherWaysToGive = WMFLocalizedString("donate-help-other-ways-to-give", value: "Other ways to give", comment: "Help link at the bottom of the donate form, that takes user to a web view link with more info.")
        let helpFrequentlyAskedQuestions = WMFLocalizedString("donate-help-frequently-asked-questions", value: "Frequently asked questions", comment: "Help link at the bottom of the donate form, that takes user to a web view link with more info.")
        let helpTaxDeductibilityInformation = WMFLocalizedString("donate-help-tax-deductibility-information", value: "Tax deductibility information", comment: "Help link at the bottom of the donate form, that takes user to a web view link with more info.")
        
        let accessibilityAmountButtonHint = WMFLocalizedString("donate-accessibility-amount-button-hint", value: "Double tap to select donation amount.", comment: "Accessibility hint on donate form amount option button for screen readers.")
        
        let accessibilityTextfieldHint = WMFLocalizedString("donate-accessibility-textfield-hint", value: "Enter custom amount to donate.", comment: "Accessibility hint on donate form custom amount textfield for screen readers.")
        
        let accessibilityTransactionFeeHint = WMFLocalizedString("donate-accessibility-transaction-fee-hint", value: "Double tap to add transaction fee to donation amount.", comment: "Accessibility hint on donate form transaction fee checkbox for screen readers.")
        
        let accessibilityEmailOptInHint = WMFLocalizedString("donate-accessibility-email-opt-in-hint", value: "Double tap to give the Wikimedia Foundation permission to email you.", comment: "Accessibility hint on donate form email opt in checkbox for screen readers.")
        
        let accessibilityKeyboardDoneButtonHint = WMFLocalizedString("donate-accessibility-keyboard-done-hint", value: "Double tap to dismiss amount input keyboard view.", comment: "Accessibility hint on donate form keyboard done button for screen readers.")
        
        let accessibilityDonateHintButtonFormat = WMFLocalizedString("donate-accessibility-donate-hint-format", value: "Double tap to donate %1$@ to the Wikimedia Foundation.", comment: "Accessibility hint on donate form Apple Pay button for screen readers. Parameters: * %1$@ - the donation amount entered by the user.")
        
        let localizedStrings = WKDonateViewModel.LocalizedStrings(title: donate, doneTitle: done, transactionFeeOptInText: transactionFeeOptIn, emailOptInText: emailOptIn, maximumErrorText: maximum, minimumErrorText: minimum, genericErrorTextFormat: genericErrorFormat, helpLinkProblemsDonating: helpProblemsDonating, helpLinkOtherWaysToGive: helpOtherWaysToGive, helpLinkFrequentlyAskedQuestions: helpFrequentlyAskedQuestions, helpLinkTaxDeductibilityInformation: helpTaxDeductibilityInformation, accessibilityAmountButtonHint: accessibilityAmountButtonHint, accessibilityTextfieldHint: accessibilityTextfieldHint, accessibilityTransactionFeeHint: accessibilityTransactionFeeHint, accessibilityEmailOptInHint: accessibilityEmailOptInHint, accessibilityKeyboardDoneButtonHint: accessibilityKeyboardDoneButtonHint, accessibilityDonateButtonHintFormat: accessibilityDonateHintButtonFormat)
        
        
        guard let viewModel = WKDonateViewModel(localizedStrings: localizedStrings, donateConfig: donateConfig, paymentMethods: paymentMethods, currencyCode: currencyCode, countryCode: countryCode) else {
            
            // TODO: Web path only
            return
        }
        let donateViewController = WKDonateViewController(viewModel: viewModel, delegate: self)
        navigationController?.pushViewController(donateViewController, animated: true)
    }
    
    @objc var donorExperienceImprovementsEnabled: Bool {
        return FeatureFlags.donorExperienceImprovementsEnabled
    }
}

extension WMFSettingsViewController: WKDonateDelegate {
    public func donateDidTapProblemsDonatingLink() {
        
        guard let countryCode = Locale.current.regionCode,
        let languageCode = Locale.current.languageCode else {
            return
        }
        
        guard let url = URL(string: "https://donate.wikimedia.org/wiki/Special:LandingCheck?basic=true&landing_page=Problems_donating&country=\(countryCode)&language=\(languageCode)&uselang=\(languageCode)&utm_medium=sitenotice&utm_campaign=test&utm_source=B2324_0705_en6C_dsk_p1_lg_template") else {
            return
        }
        
        navigate(to: url, useSafari: true)
    }
    
    public func donateDidTapOtherWaysToGive() {
        
        guard let countryCode = Locale.current.regionCode,
        let languageCode = Locale.current.languageCode else {
            return
        }
        
        guard let url = URL(string: "https://donate.wikimedia.org/wiki/Special:LandingCheck?basic=true&landing_page=Ways_to_Give&country=\(countryCode)&language=\(languageCode)&uselang=\(languageCode)&utm_medium=sitenotice&utm_campaign=test&utm_source=B2324_0705_en6C_dsk_p1_lg_template") else {
            return
        }
        
        navigate(to: url, useSafari: true)
    }
    
    public func donateDidTapFrequentlyAskedQuestions() {
        
        guard let countryCode = Locale.current.regionCode,
        let languageCode = Locale.current.languageCode else {
            return
        }
        
        guard let url = URL(string: "https://donate.wikimedia.org/wiki/Special:LandingCheck?basic=true&landing_page=FAQ&country=\(countryCode)&language=\(languageCode)&uselang=\(languageCode)&utm_medium=sitenotice&utm_campaign=test&utm_source=B2324_0705_en6C_dsk_p1_lg_template") else {
            return
        }
        
        navigate(to: url, useSafari: true)
    }
    
    public func donateDidTapTaxDeductibilityInformation() {

        guard let url = URL(string: "https://donate.wikimedia.org/wiki/Tax_deductibility") else {
            return
        }
        
        navigate(to: url, useSafari: true)
    }
    
    
}
