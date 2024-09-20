import UIKit
import PassKit
import SwiftUI
import WMFComponents
import WMFData

@objc(WMFProfileCoordinator)
class ProfileCoordinator: NSObject, Coordinator, ProfileCoordinatorDelegate {

    // MARK: Coordinator Protocol Properties

    var navigationController: UINavigationController

    // MARK: Properties

    let theme: Theme
    let dataStore: MWKDataStore
    private let targetRects = WMFProfileViewTargetRects()
    private weak var viewModel: WMFProfileViewModel?
    private weak var donateDelegate: WMFDonateDelegate?

    // MARK: Lifecycle

    @objc init(navigationController: UINavigationController, theme: Theme, dataStore: MWKDataStore, donateDelegate: WMFDonateDelegate) {
        self.navigationController = navigationController
        self.theme = theme
        self.dataStore = dataStore
        self.donateDelegate = donateDelegate
    }

    // MARK: Coordinator Protocol Methods

    @objc func start() {
        let isLoggedIn = dataStore.authenticationManager.authStateIsPermanent

        let pageTitle = WMFLocalizedString("profile-page-title-logged-out", value: "Account", comment: "Page title for non-logged in users")
        let localizedStrings =
            WMFProfileViewModel.LocalizedStrings(
                pageTitle: (isLoggedIn ? MWKDataStore.shared().authenticationManager.authStatePermanentUsername : pageTitle) ?? pageTitle,
                doneButtonTitle: CommonStrings.doneTitle,
                notificationsTitle: WMFLocalizedString("profile-page-notification-title", value: "Notifications", comment: "Link to notifications page"),
                userPageTitle: WMFLocalizedString("profile-page-user-page-title", value: "User page", comment: "Link to user page"),
                talkPageTitle: WMFLocalizedString("profile-page-talk-page-title", value: "Talk page", comment: "Link to talk page"),
                watchlistTitle: WMFLocalizedString("profile-page-watchlist-title", value: "Watchlist", comment: "Link to watchlist"),
                logOutTitle: WMFLocalizedString("profile-page-logout", value: "Log out", comment: "Log out button"),
                donateTitle: WMFLocalizedString("profile-page-donate", value: "Donate", comment: "Link to donate"),
                settingsTitle: WMFLocalizedString("profile-page-settings", value: "Settings", comment: "Link to settings"),
                joinWikipediaTitle: WMFLocalizedString("profile-page-join-title", value: "Join Wikipedia / Log in", comment: "Link to sign up or sign in"),
                joinWikipediaSubtext: WMFLocalizedString("profile-page-join-subtext", value:"Sign up for a Wikipedia account to track your contributions, save articles offline, and sync across devices.", comment: "Information about signing in or up"),
                donateSubtext: WMFLocalizedString("profile-page-donate-subtext", value: "Or support Wikipedia with a donation to keep it free and accessible for everyone around the world.", comment: "Information about supporting Wikipedia through donations")
            )

        let inboxCount = try? dataStore.remoteNotificationsController.numberOfUnreadNotifications()

        let viewModel = WMFProfileViewModel(
            isLoggedIn: isLoggedIn,
            localizedStrings: localizedStrings,
            inboxCount: Int(truncating: inboxCount ?? 0),
            coordinatorDelegate: self
        )

        var profileView = WMFProfileView(viewModel: viewModel)
        profileView.donePressed = { [weak self] in
            self?.navigationController.dismiss(animated: true, completion: nil)
        }
        self.viewModel = viewModel
        let finalView = profileView.environmentObject(targetRects)
        let hostingController = UIHostingController(rootView: finalView)
        hostingController.modalPresentationStyle = .pageSheet

        if let sheetPresentationController = hostingController.sheetPresentationController {
            sheetPresentationController.detents = [.large()]
            sheetPresentationController.prefersGrabberVisible = true
        }

        navigationController.present(hostingController, animated: true, completion: nil)
    }

    // MARK: - ProfileCoordinatorDelegate Methods

    public func handleProfileAction(_ action: ProfileAction) {
        switch action {
        case .showNotifications:
            dismissProfile {
                self.showNotifications()
            }
        case .showSettings:
            dismissProfile {
                self.showSettings()
            }
        case .showDonate:
            self.showDonate()
        }
    }

    private func dismissProfile(completion: @escaping () -> Void) {
        navigationController.dismiss(animated: true) {
            completion()
        }
    }

    func showNotifications() {
        let notificationsCoordinator = NotificationsCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore)
        notificationsCoordinator.start()
    }

    func showSettings() {
        let settingsCoordinator = SettingsCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore)
        settingsCoordinator.start()
    }

    func showDonate() {
        
        guard let viewModel,
              let countryCode = Locale.current.region?.identifier else {
            return
        }
        
        viewModel.isLoadingDonateConfigs = true
        WMFDonateDataController.shared.fetchConfigsForCountryCode(countryCode) { [weak self] error in
            
            DispatchQueue.main.async {
                
                viewModel.isLoadingDonateConfigs = false
                
                guard let self else {
                    return
                }
                
                guard error == nil else {
                    return
                }
                
                guard let currencyCode = Locale.current.currency?.identifier else {
                    return
                }
                
                guard let languageCode = self.dataStore.languageLinkController.appLanguage?.languageCode else {
                    return
                }
                
                let appVersion = Bundle.main.wmf_debugVersion()
                
                // TODO: DonateLoggingDelegate
                guard let donateViewModel = self.nativeDonateFormViewModel(countryCode: countryCode, currencyCode: currencyCode, languageCode: languageCode, metricsID: nil, appVersion: appVersion, loggingDelegate: nil) else {
                    
                    self.navigationController.dismiss(animated: true, completion: { [weak self] in
                        self?.pushToOtherPaymentMethod()
                    })
                    
                    return
                }
                
                self.presentActionSheet(donateViewModel: donateViewModel)
            }
        }
    }
    
    private func pushToOtherPaymentMethod() {
        guard let donateURL else { return }
        
        let webVC = SinglePageWebViewController(url: donateURL, theme: theme)
        navigationController.pushViewController(webVC, animated: true)
    }
    
    func presentActionSheet(donateViewModel: WMFDonateViewModel) {
        let presentedViewController = self.navigationController.presentedViewController

        let title = WMFLocalizedString("donate-payment-method-prompt-title", value: "Donate with Apple Pay?", comment: "Title of prompt to user asking which payment method they want to donate with.")
        let message = WMFLocalizedString("donate-payment-method-prompt-message", value: "Donate with Apple Pay or choose other payment method.", comment: "Message of prompt to user asking which payment method they want to donate with.")
        
        let applePayButtonTitle = WMFLocalizedString("donate-payment-method-prompt-apple-pay-button-title", value: "Donate with Apple Pay", comment: "Title of Apple Pay button choice in donate payment method prompt.")
        let otherButtonTitle = WMFLocalizedString("donate-payment-method-prompt-other-button-title", value: "Other payment method", comment: "Title of Other payment method button choice in donate payment method prompt.")
        
        let cancelButtonTitle = CommonStrings.cancelActionTitle
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: cancelButtonTitle, style: .cancel, handler: { action in
            // TODO: Logging
        }))
        
        let applePayAction = UIAlertAction(title: applePayButtonTitle, style: .default, handler: { [weak self] action in
            // TODO: Logging
            
            self?.navigationController.dismiss(animated: true, completion: {
                self?.pushToNativeDonateForm(donateViewModel: donateViewModel)
            })
        })
        alert.addAction(applePayAction)
        
        alert.addAction(UIAlertAction(title: otherButtonTitle, style: .default, handler: { [weak self] action in
            // TODO: Logging
            self?.navigationController.dismiss(animated: true, completion: {
                self?.pushToOtherPaymentMethod()
            })
        }))
        
        alert.preferredAction = applePayAction

        alert.popoverPresentationController?.sourceView = navigationController.view
        alert.popoverPresentationController?.sourceRect = targetRects.donateButtonFrame
        
        presentedViewController?.present(alert, animated: true) {
          // The alert was presented
       }
    }
    
    private func nativeDonateFormViewModel(countryCode: String, currencyCode: String, languageCode: String, metricsID: String?, appVersion: String?, loggingDelegate: WMFDonateLoggingDelegate?) -> WMFDonateViewModel? {
        
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
        
        guard let donateDelegate else {
            return nil
        }
        
        guard let viewModel = WMFDonateViewModel(localizedStrings: localizedStrings, donateConfig: donateConfig, paymentMethods: paymentMethods, countryCode: countryCode, currencyCode: currencyCode, languageCode: languageCode, merchantID: merchantID, metricsID: metricsID, appVersion: appVersion, delegate: donateDelegate, loggingDelegate: loggingDelegate) else {
            return nil
        }
        
        return viewModel
    }
    
    var donateURL: URL? {
        
        var urlString = "https://donate.wikimedia.org/?utm_medium=WikipediaApp&utm_campaign=iOS&utm_source=appmenu&app_version=<app-version>&uselang=<langcode>"
        
        guard let languageCode = dataStore.languageLinkController.appLanguage?.languageCode else {
            return nil
        }
        
        guard let appVersion = Bundle.main.wmf_debugVersion().addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        
        urlString = urlString.replacingOccurrences(of: "<langcode>", with: languageCode)
        urlString = urlString.replacingOccurrences(of: "<app-version>", with: appVersion)
        
        return URL(string: urlString)
    }
    
    func pushToNativeDonateForm(donateViewModel: WMFDonateViewModel) {
        
        guard let donateDelegate else {
            return
        }
        
        // TODO: DonateLoggingDelegate
        let donateViewController = WMFDonateViewController(viewModel: donateViewModel, delegate: donateDelegate, loggingDelegate: nil)
        
        navigationController.pushViewController(donateViewController, animated: true)
    }

    private func dismissProfile() {
        navigationController.dismiss(animated: true, completion: nil)
    }

}

