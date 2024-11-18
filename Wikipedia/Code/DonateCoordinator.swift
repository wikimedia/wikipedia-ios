import WMF
import PassKit
import WMFComponents
import WMFData
import CocoaLumberjackSwift

// Helper class to access donate coordinator logic from Obj-c
@objc class WMFDonateCoordinatorWrapper: NSObject {
    @objc static func metricsIDForSettingsProfileDonateSource(languageCode: String?) -> String? {
        return DonateCoordinator.metricsID(for: .settingsProfile, languageCode: languageCode)
    }
}

class DonateCoordinator: Coordinator {
    
    // MARK: Nested Types
    
    typealias ArticleURL = URL
    typealias DonateURL = URL
    typealias MetricsID = String
    
    enum Source {
        case articleCampaignModal(ArticleURL, MetricsID, DonateURL)
        case settingsProfile
        case exploreProfile
        case articleProfile(ArticleURL)
        case yearInReview // TODO: Do it properly T376062
    }
    
    enum NavigationStyle {
        case dismissThenPush
        case push
        case present
    }
    
    // MARK: Properties
    
    var navigationController: UINavigationController
    private let donateButtonGlobalRect: CGRect
    private let source: Source
    private let navigationStyle: NavigationStyle
    
    // Code to run when we are fetching donate configs. Typically this changes some donate button into a spinner.
    private let setLoadingBlock: (Bool) -> Void
    
    private let dataStore: MWKDataStore
    private let theme: Theme
    
    private lazy var wikimediaProject: WikimediaProject? = {
        switch source {
        case .articleCampaignModal(let articleURL, _, _):
            guard let wikimediaProject = WikimediaProject(siteURL: articleURL) else {
                return nil
            }
            
            return wikimediaProject
        case .articleProfile(let articleURL):
            guard let wikimediaProject = WikimediaProject(siteURL: articleURL) else {
                return nil
            }
            
            return wikimediaProject
        case .exploreProfile, .settingsProfile, .yearInReview:
            return nil
        }
    }()
    
    private lazy var languageCode: String? = {
        guard let languageCode = dataStore.languageLinkController.appLanguage?.languageCode else {
            return nil
        }
        return languageCode
    }()
    
    private(set) lazy var metricsID: String? = {
        return Self.metricsID(for: source, languageCode: languageCode)
    }()
    
    private var webViewURL: URL? {
        
        guard let metricsID,
              let languageCode else {
            return nil
        }
        
        var urlString: String
        if case .articleCampaignModal(_, _, let articleCampaignDonateURL) = source {
            urlString = articleCampaignDonateURL.absoluteString
        } else {
            urlString = "https://donate.wikimedia.org/?wmf_medium=WikipediaApp&wmf_campaign=iOS&wmf_source=\(metricsID)&uselang=<langcode>"
            urlString = urlString.replacingOccurrences(of: "<langcode>", with: languageCode)
        }
        
        let appVersion = Bundle.main.wmf_debugVersion()
        return URL(string: urlString)?.appendingAppVersion(appVersion: appVersion)
    }
    
    // MARK: Lifecycle
    
    init(navigationController: UINavigationController, donateButtonGlobalRect: CGRect, source: Source, dataStore: MWKDataStore, theme: Theme, navigationStyle: NavigationStyle, setLoadingBlock: @escaping (Bool) -> Void) {
        self.navigationController = navigationController
        self.donateButtonGlobalRect = donateButtonGlobalRect
        self.source = source
        self.dataStore = dataStore
        self.theme = theme
        self.navigationStyle = navigationStyle
        self.setLoadingBlock = setLoadingBlock
    }
    
    static func metricsID(for donateSource: Source, languageCode: String?) -> String? {
        switch donateSource {
        case .articleCampaignModal(_, let metricsID, _):
            return metricsID
        case .articleProfile, .exploreProfile, .settingsProfile:
            guard let languageCode,
                  let countryCode = Locale.current.region?.identifier else {
                return nil
            }
            
            return "\(languageCode)\(countryCode)_appmenu_iOS"
        case .yearInReview:
            guard let languageCode,
                  let countryCode = Locale.current.region?.identifier else {
                return nil
            }
            return "\(languageCode)\(countryCode)_appmenu_yir_iOS"
        }
    }
    
    func start() {
        
        guard let countryCode = Locale.current.region?.identifier else {
            return
        }
        
        setLoadingBlock(true)
        WMFDonateDataController.shared.fetchConfigsForCountryCode(countryCode) { [weak self] error in
            
            DispatchQueue.main.async {
                
                guard let self else {
                    return
                }
                
                self.setLoadingBlock(false)
                
                guard let donateViewModel = self.nativeDonateFormViewModel(countryCode: countryCode) else {
                    
                    self.navigateToOtherPaymentMethod()
                    
                    return
                }
                
                self.presentActionSheet(donateViewModel: donateViewModel)
            }
        }
    }
    
    // MARK: Private
    
    private func presentActionSheet(donateViewModel: WMFDonateViewModel) {
        
        guard let metricsID else {
            return
        }
        
        let viewControllerToPresentActionSheet: UIViewController?
        switch navigationStyle {
        case .dismissThenPush:
            viewControllerToPresentActionSheet = navigationController.presentedViewController
        case .push:
            viewControllerToPresentActionSheet = navigationController.topViewController
        case .present:
            viewControllerToPresentActionSheet = navigationController.presentedViewController
        }

        let title = WMFLocalizedString("donate-payment-method-prompt-title", value: "Donate with Apple Pay?", comment: "Title of prompt to user asking which payment method they want to donate with.")
        let message = WMFLocalizedString("donate-payment-method-prompt-message", value: "Donate with Apple Pay or choose other payment method.", comment: "Message of prompt to user asking which payment method they want to donate with.")
        
        let applePayButtonTitle = WMFLocalizedString("donate-payment-method-prompt-apple-pay-button-title", value: "Donate with Apple Pay", comment: "Title of Apple Pay button choice in donate payment method prompt.")
        let otherButtonTitle = WMFLocalizedString("donate-payment-method-prompt-other-button-title", value: "Other payment method", comment: "Title of Other payment method button choice in donate payment method prompt.")
        
        let cancelButtonTitle = CommonStrings.cancelActionTitle
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: cancelButtonTitle, style: .cancel, handler: { action in
            switch self.source {
            case .exploreProfile:
                DonateFunnel.shared.logExploreProfileDonateCancel(metricsID: metricsID)
            case .articleProfile:
                guard let project = self.wikimediaProject else {
                    return
                }
                DonateFunnel.shared.logArticleProfileDonateCancel(project: project, metricsID: metricsID)
            case .settingsProfile:
                DonateFunnel.shared.logExploreOptOutProfileDonateCancel(metricsID: metricsID)
            case .articleCampaignModal:
               guard let project = self.wikimediaProject else {
                   return
               }
                
                DonateFunnel.shared.logArticleDidTapCancel(project: project, metricsID: metricsID)
            case .yearInReview:
                DonateFunnel.shared.logYearInReviewDidTapDonateCancel(metricsID: metricsID)
            }
        }))
        
        let applePayAction = UIAlertAction(title: applePayButtonTitle, style: .default, handler: { [weak self] action in
            guard let self else {
                return
            }
            switch source {
            case .exploreProfile:
                DonateFunnel.shared.logExploreProfileDonateApplePay(metricsID: metricsID)
            case .articleProfile:
                guard let project = self.wikimediaProject else {
                    return
                }
                DonateFunnel.shared.logArticleProfileDonateApplePay(project: project, metricsID: metricsID)
            case .settingsProfile:
                DonateFunnel.shared.logExploreOptOutProfileDonateApplePay(metricsID: metricsID)
            case .articleCampaignModal:
                guard let project = wikimediaProject else {
                   return
               }
                DonateFunnel.shared.logArticleDidTapDonateWithApplePay(project: project, metricsID: metricsID)
            case .yearInReview:
                DonateFunnel.shared.logYearInReviewDidTapDonateApplePay(metricsID: metricsID)
            }
            self.navigateToNativeDonateForm(donateViewModel: donateViewModel)
        })
        alert.addAction(applePayAction)
        
        alert.addAction(UIAlertAction(title: otherButtonTitle, style: .default, handler: { [weak self] action in
            guard let self else {
                return
            }
            switch source {
            case .exploreProfile:
                DonateFunnel.shared.logExploreProfileDonateWebPay(metricsID: metricsID)
            case .articleProfile:
                guard let project = self.wikimediaProject else {
                    return
                }
                DonateFunnel.shared.logArticleProfileDonateWebPay(project: project, metricsID: metricsID)
            case .settingsProfile:
                DonateFunnel.shared.logExploreOptOutProfileDonateWebPay(metricsID: metricsID)
            case .articleCampaignModal:
                guard let project = wikimediaProject else {
                    return
                }
                DonateFunnel.shared.logArticleDidTapOtherPaymentMethod(project: project, metricsID: metricsID)
            case .yearInReview:
                DonateFunnel.shared.logYearInReviewDidTapDonateOtherPaymentMethod(metricsID: metricsID)
            }
            navigateToOtherPaymentMethod()
        }))
        
        alert.preferredAction = applePayAction
        alert.overrideUserInterfaceStyle = theme.isDark ? .dark : .light

        alert.popoverPresentationController?.sourceView = navigationController.view
        alert.popoverPresentationController?.sourceRect = donateButtonGlobalRect
        
        viewControllerToPresentActionSheet?.present(alert, animated: true)
    }
    
    private func nativeDonateFormViewModel(countryCode: String) -> WMFDonateViewModel? {
        
        guard let currencyCode = Locale.current.currency?.identifier else {
            return nil
        }
        
        guard let languageCode = dataStore.languageLinkController.appLanguage?.languageCode else {
            return nil
        }
        
        let appVersion = Bundle.main.wmf_debugVersion()
        
        let donateDataController = WMFDonateDataController.shared
        let donateData = donateDataController.loadConfigs()
        
        guard let donateConfig = donateData.donateConfig,
              donateConfig.countryCodeApplePayEnabled.contains(countryCode),
              let paymentMethods = donateData.paymentMethods else {
            return nil
        }
        
        guard PKPaymentAuthorizationController.canMakePayments(),
              PKPaymentAuthorizationController.canMakePayments(usingNetworks: paymentMethods.applePayPaymentNetworks, capabilities: .capability3DS) else {
            return nil
        }
        
        let formatter = NumberFormatter.wmfCurrencyFormatter
        formatter.currencyCode = currencyCode
        
        guard let merchantID = Bundle.main.wmf_merchantID() else {
            return nil
        }
        
        guard let minimumValue = donateConfig.currencyMinimumDonation[currencyCode],
              let minimumString = formatter.string(from: minimumValue as NSNumber) else {
            return nil
        }

        let maximumValue = donateConfig.getMaxAmount(for: currencyCode)
        let maximumString = formatter.string(from: maximumValue as NSNumber)

        let donate = WMFLocalizedString("donate-title", value: "Select an amount", comment: "Title for donate form.")
        let done = CommonStrings.doneTitle
        
        let transactionFeeFormat = WMFLocalizedString("donate-transaction-fee-opt-in-text", value: "I’ll generously add %1$@ to cover the transaction fees so you can keep 100%% of my donation.", comment: "Transaction fee checkbox on donate form. Checking it adds transaction fee to donation amount. Parameters: * %1$@ - transaction fee amount. Please leave %% unchanged for proper formatting.")
        
        let minimumFormat = WMFLocalizedString("donate-minimum-error-text", value: "Please select an amount (minimum %1$@ %2$@).", comment: "Error text displayed when user enters donation amount below the allowed minimum. Parameters: * %1$@ - the minimum amount allowed, %2$@ - the currency code. (For example, '$1 USD')")
        let minimum = String.localizedStringWithFormat(minimumFormat, minimumString, currencyCode)
        
        var maximum: String?
        if let maximumString {
            let maximumFormat = WMFLocalizedString("donate-maximum-error-text", value: "We cannot accept donations greater than %1$@ %2$@ through our website. Please contact our major gifts staff at benefactors@wikimedia.org.", comment: "Error text displayed when user enters donation amount above the maximum. Parameters: * %1$@ - the currency code, %2$@ - the maximum donation amount allowed. (For example, 'USD $25,000')")
            maximum = String.localizedStringWithFormat(maximumFormat, maximumString, currencyCode)
        }
        
        let genericErrorFormat = "\(CommonStrings.genericErrorDescription)\n\n%1$@"
        
        let monthlyRecurring = WMFLocalizedString("donate-monthly-recurring-text", value: "Make this a monthly recurring donation.", comment: "Text next to monthly recurring checkbox on donate form.")
        
        let emailOptIn = WMFLocalizedString("donate-email-opt-in-text", value: "Yes, the Wikimedia Foundation can send me an occasional email.", comment: "Text next to email opt-in checkbox on donate form.")
        
        let helpProblemsDonating = WMFLocalizedString("donate-help-problems-donating", value: "Problems donating?", comment: "Help link at the bottom of the donate form, that takes user to a web view link with more info.")
        let helpOtherWaysToGive = WMFLocalizedString("donate-help-other-ways-to-give", value: "Other ways to give", comment: "Help link at the bottom of the donate form, that takes user to a web view link with more info.")
        let helpFrequentlyAskedQuestions = WMFLocalizedString("donate-help-frequently-asked-questions", value: "Frequently asked questions", comment: "Help link at the bottom of the donate form, that takes user to a web view link with more info.")
        let helpTaxDeductibilityInformation = WMFLocalizedString("donate-help-tax-deductibility-information", value: "Tax deductibility information", comment: "Help link at the bottom of the donate form, that takes user to a web view link with more info.")
        
        let appleFinePrint = WMFLocalizedString("donate-apple-fine-print", value: "Apple is not in charge of raising money for this purpose.", comment: "Apple fine print displayed on donation form for Apple Pay, indicating that Apple is not in charge of raising money.")
        
        let wikimediaFinePrint1Format = WMFLocalizedString("donate-wikimedia-fine-print-1", value: "We do not sell or trade your information to anyone. By donating, you agree to share your personal information with the Wikimedia Foundation, the nonprofit organization that hosts Wikipedia and other Wikimedia projects, and its service providers pursuant to our [donor policy](%1$@). Wikimedia Foundation and its service providers are located in the United States and in other countries whose privacy laws may not be equivalent to your own. For more information please read our [donor policy](%1$@).", comment: "Wikimedia data policy fine print displayed on donation form for Apple Pay. Do not translate donor policy url. %1$@ is replaced by the localized donor policy link.")
        let wikimediaFinePrint1 = String.localizedStringWithFormat(wikimediaFinePrint1Format, "https://foundation.wikimedia.org/wiki/Special:LandingCheck?landing_page=Donor_privacy_policy&basic=true&language=\(languageCode)")
        
        let wikimediaFinePrint2 = WMFLocalizedString("donate-wikimedia-fine-print-2", value: "For recurring donors, fixed monthly payments will be debited by the Wikimedia Foundation on the monthly anniversary of the first donation, until such time as you notify us to discontinue them. Donations initiated on the 29, 30, or 31 of the month will recur on the last day of the month for shorter months, as close to the original date as possible. For questions, please contact donate@wikimedia.org.", comment: "Recurring donor fine print displayed on donation form for Apple Pay. Do not translate email.")
        
        let accessibilityAmountButtonHint = WMFLocalizedString("donate-accessibility-amount-button-hint", value: "Double tap to select donation amount.", comment: "Accessibility hint on donate form amount option button for screen readers.")
        
        let accessibilityTextfieldHint = WMFLocalizedString("donate-accessibility-textfield-hint", value: "Enter custom amount to donate.", comment: "Accessibility hint on donate form custom amount textfield for screen readers.")
        
        let accessibilityTransactionFeeHint = WMFLocalizedString("donate-accessibility-transaction-fee-hint", value: "Double tap to add transaction fee to donation amount.", comment: "Accessibility hint on donate form transaction fee checkbox for screen readers.")
        
        let accessibilityMonthlyRecurringHint = WMFLocalizedString("donate-accessibility-monthly-recurring-hint", value: "Double tap to enable automatic monthly donations of this amount.", comment: "Accessibility hint on donate form monthly recurring checkbox for screen readers.")
        
        let accessibilityEmailOptInHint = WMFLocalizedString("donate-accessibility-email-opt-in-hint", value: "Double tap to give the Wikimedia Foundation permission to email you.", comment: "Accessibility hint on donate form email opt in checkbox for screen readers.")
        
        let accessibilityKeyboardDoneButtonHint = WMFLocalizedString("donate-accessibility-keyboard-done-hint", value: "Double tap to dismiss amount input keyboard view.", comment: "Accessibility hint on donate form keyboard done button for screen readers.")
        
        let accessibilityDonateHintButtonFormat = WMFLocalizedString("donate-accessibility-donate-hint-format", value: "Double tap to donate %1$@ to the Wikimedia Foundation.", comment: "Accessibility hint on donate form Apple Pay button for screen readers. Parameters: * %1$@ - the donation amount entered by the user.")

        let localizedStrings = WMFDonateViewModel.LocalizedStrings(title: donate, doneTitle: done, transactionFeeOptInTextFormat: transactionFeeFormat, monthlyRecurringText: monthlyRecurring, emailOptInText: emailOptIn, maximumErrorText: maximum, minimumErrorText: minimum, genericErrorTextFormat: genericErrorFormat, helpLinkProblemsDonating: helpProblemsDonating, helpLinkOtherWaysToGive: helpOtherWaysToGive, helpLinkFrequentlyAskedQuestions: helpFrequentlyAskedQuestions, helpLinkTaxDeductibilityInformation: helpTaxDeductibilityInformation, appleFinePrint: appleFinePrint, wikimediaFinePrint1: wikimediaFinePrint1, wikimediaFinePrint2: wikimediaFinePrint2, accessibilityAmountButtonHint: accessibilityAmountButtonHint, accessibilityTextfieldHint: accessibilityTextfieldHint, accessibilityTransactionFeeHint: accessibilityTransactionFeeHint, accessibilityMonthlyRecurringHint: accessibilityMonthlyRecurringHint, accessibilityEmailOptInHint: accessibilityEmailOptInHint, accessibilityKeyboardDoneButtonHint: accessibilityKeyboardDoneButtonHint, accessibilityDonateButtonHintFormat: accessibilityDonateHintButtonFormat)

        guard let viewModel = WMFDonateViewModel(localizedStrings: localizedStrings, donateConfig: donateConfig, paymentMethods: paymentMethods, countryCode: countryCode, currencyCode: currencyCode, languageCode: languageCode, merchantID: merchantID, metricsID: metricsID, appVersion: appVersion, coordinatorDelegate: self, loggingDelegate: self) else {
            return nil
        }
        
        return viewModel
    }
    
    private func navigateToNativeDonateForm(donateViewModel: WMFDonateViewModel) {
        let donateViewController = WMFDonateViewController(viewModel: donateViewModel)
        
        switch navigationStyle {
        case .push:
            navigationController.pushViewController(donateViewController, animated: true)
        case .dismissThenPush:
            navigationController.dismiss(animated: true) {
                self.navigationController.pushViewController(donateViewController, animated: true)
            }
        case .present:
            
            guard let presentedViewController = navigationController.presentedViewController else {
                DDLogError("Unexpected navigation controller state. Skipping donate form presentation.")
                return
            }
            
            let newNavigationController = WMFThemeableNavigationController(rootViewController: donateViewController, theme: theme)
            newNavigationController.modalPresentationStyle = .pageSheet
            presentedViewController.present(newNavigationController, animated: true)
        }
        
    }
    
    private func navigateToOtherPaymentMethod() {
        guard let webViewURL else { return }
        
        let completeButtonTitle: String
        switch source {
        case .articleCampaignModal, .articleProfile:
            completeButtonTitle = CommonStrings.returnToArticle
        case .exploreProfile, .settingsProfile, .yearInReview:
            completeButtonTitle = CommonStrings.returnButtonTitle
        }
        let donateConfig = SinglePageWebViewController.DonateConfig(url: webViewURL, dataController: WMFDonateDataController.shared, coordinatorDelegate: self, loggingDelegate: self, completeButtonTitle: completeButtonTitle)
        let webVC = SinglePageWebViewController(configType: .donate(donateConfig), theme: theme)
        
        switch navigationStyle {
        case .push:
            navigationController.pushViewController(webVC, animated: true)
        case .dismissThenPush:
            navigationController.dismiss(animated: true, completion: {
                self.navigationController.pushViewController(webVC, animated: true)
            })
        case .present:
            
            guard let presentedViewController = navigationController.presentedViewController else {
                DDLogError("Unexpected navigation controller state. Skipping donate form presentation.")
                return
            }
            
            let newNavigationController = WMFThemeableNavigationController(rootViewController: webVC, theme: theme)
            newNavigationController.modalPresentationStyle = .formSheet
            presentedViewController.present(newNavigationController, animated: true)
        }
    }
}

// MARK: DonateCoordinatorDelegate

extension DonateCoordinator: DonateCoordinatorDelegate {
    func handleDonateAction(_ action: WMFComponents.DonateCoordinatorAction) {
        switch action {
        case .nativeFormDidTapProblemsDonating:
            showProblemsDonating()
        case .nativeFormDidTapOtherWaysToGive:
            showOtherWaysToGive()
        case .nativeFormDidTapFAQ:
            showFrequentlyAskedQuestions()
        case .nativeFormDidTapTaxInfo:
            showTaxDeductibilityInformation()
        case .nativeFormDidTriggerPaymentSuccess:
            popAndShowSuccessToastFromNativeForm()
        case .webViewFormThankYouDidTapReturn:
            popFromWebFormThankYouPage()
        case .webViewFormThankYouDidDisappear:
            displayThankYouToastAfterDelay()
        }
    }
    
    private func showProblemsDonating() {
        
        guard let countryCode = Locale.current.region?.identifier,
              let languageCode = Locale.current.language.languageCode?.identifier else {
            return
        }
        
        guard let url = URL(string: "https://donate.wikimedia.org/wiki/Special:LandingCheck?basic=true&landing_page=Problems_donating&country=\(countryCode)&language=\(languageCode)&uselang=\(languageCode)&utm_medium=sitenotice&utm_campaign=test&utm_source=B2324_0705_en6C_dsk_p1_lg_template") else {
            return
        }
        
        UIApplication.shared.open(url)
    }
    
    private func showOtherWaysToGive() {
        
        guard let countryCode = Locale.current.region?.identifier,
              let languageCode = Locale.current.language.languageCode?.identifier else {
            return
        }
        
        guard let url = URL(string: "https://donate.wikimedia.org/wiki/Special:LandingCheck?basic=true&landing_page=Ways_to_Give&country=\(countryCode)&language=\(languageCode)&uselang=\(languageCode)&utm_medium=sitenotice&utm_campaign=test&utm_source=B2324_0705_en6C_dsk_p1_lg_template") else {
            return
        }
        
        UIApplication.shared.open(url)
    }
    
    private func showFrequentlyAskedQuestions() {
        guard let countryCode = Locale.current.region?.identifier,
              let languageCode = Locale.current.language.languageCode?.identifier else {
            return
        }
        
        guard let url = URL(string: "https://donate.wikimedia.org/wiki/Special:LandingCheck?basic=true&landing_page=FAQ&country=\(countryCode)&language=\(languageCode)&uselang=\(languageCode)&utm_medium=sitenotice&utm_campaign=test&utm_source=B2324_0705_en6C_dsk_p1_lg_template") else {
            return
        }
        
        UIApplication.shared.open(url)
    }
    
    public func showTaxDeductibilityInformation() {
        guard let url = URL(string: "https://donate.wikimedia.org/wiki/Tax_deductibility") else {
            return
        }
        
        UIApplication.shared.open(url)
    }
    
    private func popAndShowSuccessToastFromNativeForm() {
        
        let showToastBlock: () -> Void = {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                
                WMFAlertManager.sharedInstance.showBottomAlertWithMessage(CommonStrings.donateThankTitle, subtitle: CommonStrings.donateThankSubtitle, image: UIImage.init(systemName: "heart.fill"), type: .custom, customTypeName: "donate-success", duration: -1, dismissPreviousAlerts: true)
            }
        }
        
        switch navigationStyle {
        case .push:
            self.navigationController.popViewController(animated: true)
            showToastBlock()
        case .dismissThenPush:
            self.navigationController.popViewController(animated: true)
            showToastBlock()
        case .present:
            guard let presentedVC = navigationController.presentedViewController else {
                DDLogError("Unexpected navigation controller state. Skipping auto-dismissal.")
                return
            }
            
            presentedVC.dismiss(animated: true) {
                showToastBlock()
            }
        }
        
        
    }
    
    private func popFromWebFormThankYouPage() {
        
        switch navigationStyle {
        case .push:
            self.navigationController.popViewController(animated: true)
        case .dismissThenPush:
            navigationController.popViewController(animated: true)
        case .present:
            guard let presentedVC = navigationController.presentedViewController else {
                DDLogError("Unexpected navigation controller state. Skipping auto-dismissal.")
                return
            }
            
            presentedVC.dismiss(animated: true)
        }
    }
    
    private func displayThankYouToastAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            WMFAlertManager.sharedInstance.showBottomAlertWithMessage(CommonStrings.donateThankTitle, subtitle: CommonStrings.donateThankSubtitle, image: UIImage.init(systemName: "heart.fill"), type: .custom, customTypeName: "donate-success", duration: -1, dismissPreviousAlerts: true)
        }
    }
}

// MARK: WMFDonateLoggingDelegate

extension DonateCoordinator: WMFDonateLoggingDelegate {
    func handleDonateLoggingAction(_ action: WMFComponents.WMFDonateLoggingAction) {
        switch action {
        case .nativeFormDidAppear:
            logNativeFormDidAppear()
        case .nativeFormDidTriggerError(let error):
            logNativeFormDidTriggerError(error: error)
        case .nativeFormDidTapAmountPresetButton:
            logNativeFormDidTapAmountPresetButton()
        case .nativeFormDidEnterAmountInTextfield:
            logNativeFormDidEnterAmountInTextfield()
        case .nativeFormDidTapApplePayButton(let transactionFeeIsSelected, let recurringMonthlyIsSelected, let emailOptInIsSelected):
            logNativeFormDidTapApplePayButton(transactionFeeIsSelected: transactionFeeIsSelected, recurringMonthlyIsSelected: recurringMonthlyIsSelected, emailOptInIsSelected: emailOptInIsSelected)
        case .nativeFormDidAuthorizeApplePayPaymentSheet(let amount, let presetIsSelected, let recurringMonthlyIsSelected, let donorEmail, let metricsID):
            logNativeFormDidAuthorizeApplePayPaymentSheet(amount: amount, presetIsSelected: presetIsSelected, recurringMonthlyIsSelected: recurringMonthlyIsSelected, donorEmail: donorEmail, metricsID: metricsID)
        case .nativeFormDidTriggerPaymentSuccess:
            logNativeFormDidTriggerPaymentSuccess()
        case .nativeFormDidTapProblemsDonating:
            logNativeFormDidTapProblemsDonating()
        case .nativeFormDidTapOtherWaysToGive:
            logNativeFormDidTapOtherWaysToGive()
        case .nativeFormDidTapFAQ:
            logNativeFormDidTapFAQ()
        case .nativeFormDidTapTaxInfo:
            logNativeFormDidTapTaxInfo()
        case .webViewFormDidAppear:
            logWebViewFormDidAppear()
        case .webViewFormThankYouPageDidAppear:
            logWebViewFormThankYouPageDidAppear()
        case .webViewFormThankYouDidTapReturn:
            logWebViewFormThankYouDidTapReturn()
        case .webViewFormThankYouDidDisappear:
            logWebViewFormThankYouDidDisappear()
        }
    }
    

    private func logNativeFormDidAppear() {
        
        guard let metricsID else {
            return
        }
        
        DonateFunnel.shared.logDonateFormNativeApplePayImpression(project: wikimediaProject, metricsID: metricsID)
    }
    
    private func logNativeFormDidTriggerError(error: any Error) {
        
        guard let metricsID else {
            return
        }
        
        let errorReason = (error as NSError).description
        let errorCode = String((error as NSError).code)
        
        if let viewModelError = error as? WMFDonateViewModel.Error {
            switch viewModelError {
            case .invalidToken:
                DonateFunnel.shared.logDonateFormNativeApplePaySubmissionError(errorReason: errorReason, errorCode: errorCode, orderID: nil, project: wikimediaProject, metricsID: metricsID)
            case .missingDonorInfo:
                DonateFunnel.shared.logDonateFormNativeApplePaySubmissionError(errorReason: errorReason, errorCode: errorCode, orderID: nil, project: wikimediaProject, metricsID: metricsID)
            case .validationAmountMinimum:
                DonateFunnel.shared.logDonateFormNativeApplePayEntryError(project: wikimediaProject, metricsID: metricsID)
            case .validationAmountMaximum:
                DonateFunnel.shared.logDonateFormNativeApplePayEntryError(project: wikimediaProject, metricsID: metricsID)
            }
            return
        }
        
        if let donateDataControllerError = error as? WMFDonateDataControllerError {
            switch donateDataControllerError {
            case .paymentsWikiResponseError(let reason, let orderID):
                DonateFunnel.shared.logDonateFormNativeApplePaySubmissionError(errorReason: reason, errorCode: errorCode, orderID: orderID, project: wikimediaProject, metricsID: metricsID)
            }
            return
        }
        
        DonateFunnel.shared.logDonateFormNativeApplePaySubmissionError(errorReason: errorReason, errorCode: errorCode, orderID: nil, project: wikimediaProject, metricsID: metricsID)
    }
    
    private func logNativeFormDidTapAmountPresetButton() {
        guard let metricsID else {
            return
        }
        
        DonateFunnel.shared.logDonateFormNativeApplePayDidTapAmountPresetButton(project: wikimediaProject, metricsID: metricsID)
    }
    
    private func logNativeFormDidEnterAmountInTextfield() {
        guard let metricsID else {
            return
        }
        
        DonateFunnel.shared.logDonateFormNativeApplePayDidEnterAmountInTextfield(project: wikimediaProject, metricsID: metricsID)
    }
    
    private func logNativeFormDidTapApplePayButton(transactionFeeIsSelected: Bool, recurringMonthlyIsSelected: Bool, emailOptInIsSelected: NSNumber?) {
        guard let metricsID else {
            return
        }
        
        DonateFunnel.shared.logDonateFormNativeApplePayDidTapApplePayButton(transactionFeeIsSelected: transactionFeeIsSelected, recurringMonthlyIsSelected: recurringMonthlyIsSelected, emailOptInIsSelected: emailOptInIsSelected?.boolValue, project: wikimediaProject, metricsID: metricsID)
    }
    
    private func logNativeFormDidAuthorizeApplePayPaymentSheet(amount: Decimal, presetIsSelected: Bool, recurringMonthlyIsSelected: Bool, donorEmail: String?, metricsID: String?) {
        guard let metricsID else {
            return
        }
        
        DonateFunnel.shared.logDonateFormNativeApplePayDidAuthorizeApplePay(amount: amount, presetIsSelected: presetIsSelected, recurringMonthlyIsSelected: recurringMonthlyIsSelected, metricsID: metricsID, donorEmail: donorEmail, project: wikimediaProject)
    }
    
    private func logNativeFormDidTriggerPaymentSuccess() {
        guard let metricsID else {
            return
        }
        
        switch source {
        case .exploreProfile:
            DonateFunnel.shared.logExploreProfileDidSeeApplePayDonateSuccessToast(metricsID: metricsID)
        case .articleProfile:
            if let wikimediaProject = self.wikimediaProject {
                DonateFunnel.shared.logArticleProfileDidSeeApplePayDonateSuccessToast(project: wikimediaProject, metricsID: metricsID)
            }
        case .settingsProfile:
            DonateFunnel.shared.logExploreOptOutProfileDidSeeApplePayDonateSuccessToast(metricsID: metricsID)
        case .articleCampaignModal:
            if let wikimediaProject = self.wikimediaProject {
                DonateFunnel.shared.logArticleCampaignDidSeeApplePayDonateSuccessToast(project: wikimediaProject, metricsID: metricsID)
            }
        case .yearInReview:
            DonateFunnel.shared.logYearInReviewDidSeeApplePayDonateSuccessToast(metricsID: metricsID)
        }
    }
    
    private func logNativeFormDidTapProblemsDonating() {
        guard let metricsID else {
            return
        }
        
        DonateFunnel.shared.logDonateFormNativeApplePayDidTapProblemsDonatingLink(project: wikimediaProject, metricsID: metricsID)
    }
    
    private func logNativeFormDidTapOtherWaysToGive() {
        guard let metricsID else {
            return
        }
        
        DonateFunnel.shared.logDonateFormNativeApplePayDidTapOtherWaysToGiveLink(project: wikimediaProject, metricsID: metricsID)
    }
    
    private func logNativeFormDidTapFAQ() {
        guard let metricsID else {
            return
        }
        
        DonateFunnel.shared.logDonateFormNativeApplePayDidTapFAQLink(project: wikimediaProject, metricsID: metricsID)
    }
    
    private func logNativeFormDidTapTaxInfo() {
        guard let metricsID else {
            return
        }
        
        DonateFunnel.shared.logDonateFormNativeApplePayDidTapTaxInfoLink(project: wikimediaProject, metricsID: metricsID)
    }
    
    private func logWebViewFormDidAppear() {
        guard let metricsID else {
            return
        }
        
        DonateFunnel.shared.logDonateFormInAppWebViewImpression(project: wikimediaProject, metricsID: metricsID)
    }
    
    private func logWebViewFormThankYouPageDidAppear() {
        guard let metricsID else {
            return
        }
        
        DonateFunnel.shared.logDonateFormInAppWebViewThankYouImpression(project: wikimediaProject, metricsID: metricsID)
    }
    
    private func logWebViewFormThankYouDidTapReturn() {
        
        guard let metricsID else {
            return
        }
        
        switch source {
        case .articleCampaignModal:
            
            guard let wikimediaProject else {
                return
            }
            
            DonateFunnel.shared.logDonateFormInAppWebViewDidTapArticleReturnButton(project: wikimediaProject, metricsID: metricsID)
        case .articleProfile:
            guard let wikimediaProject else {
                return
            }
            
            DonateFunnel.shared.logDonateFormInAppWebViewDidTapArticleReturnButton(project: wikimediaProject, metricsID: metricsID)
        case .exploreProfile, .settingsProfile, .yearInReview:
            DonateFunnel.shared.logDonateFormInAppWebViewDidTapReturnButton(metricsID: metricsID)
        }
    }
    
    private func logWebViewFormThankYouDidDisappear() {
        
        guard let metricsID else {
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            
            guard let self else {
                return
            }
            
            switch self.source {
            case .articleCampaignModal:
                guard let wikimediaProject else {
                    return
                }
                
                DonateFunnel.shared.logArticleCampaignDidSeeApplePayDonateSuccessToast(project: wikimediaProject, metricsID: metricsID)
            case .articleProfile:
                guard let wikimediaProject else {
                    return
                }
                
                DonateFunnel.shared.logArticleProfileDidSeeApplePayDonateSuccessToast(project: wikimediaProject, metricsID: metricsID)
            case .exploreProfile:
                DonateFunnel.shared.logExploreProfileDidSeeApplePayDonateSuccessToast(metricsID: metricsID)
            case .settingsProfile:
                DonateFunnel.shared.logExploreOptOutProfileDidSeeApplePayDonateSuccessToast(metricsID: metricsID)
            case .yearInReview:
                DonateFunnel.shared.logYearInReviewDidSeeApplePayDonateSuccessToast(metricsID: metricsID)
            }
        }
    }
}

// MARK: URL Extensions

fileprivate extension URL {
    func appendingAppVersion(appVersion: String?) -> URL {
        
        guard let appVersion,
              var components = URLComponents(url: self, resolvingAgainstBaseURL: false),
        var queryItems = components.queryItems else {
            return self
        }
        
        
        queryItems.append(URLQueryItem(name: "app_version", value: appVersion))
        components.queryItems = queryItems
        
        guard let url = components.url else {
            return self
        }
        
        return url
    }
}
