import UIKit
import SwiftUI
import WMFComponents
import WMFData
import CocoaLumberjackSwift

final class TempAccountSheetCoordinator: Coordinator {
    var navigationController: UINavigationController
    var theme: Theme
    let dataStore: MWKDataStore
    let didTapDone: () -> Void
    let didTapContinue: () -> Void
    let isTempAccount: Bool
    
    func start() -> Bool {
        if isTempAccount {
            presentTempEditorSheet()
        } else {
            presentIPEditorSheet()
        }
        return true
    }
    
    public init(navigationController: UINavigationController, theme: Theme, dataStore: MWKDataStore, didTapDone: @escaping () -> Void, didTapContinue: @escaping () -> Void, isTempAccount: Bool) {
        self.navigationController = navigationController
        self.theme = theme
        self.dataStore = dataStore
        self.didTapDone = didTapDone
        self.isTempAccount = isTempAccount
        self.didTapContinue = didTapContinue
    }
    
    internal var authManager: WMFAuthenticationManager {
       return dataStore.authenticationManager
   }
    
    var learnMoreURL: String {
        var languageCodeSuffix = ""
        if let primaryAppLanguageCode = dataStore.languageLinkController.appLanguage?.languageCode {
            languageCodeSuffix = "\(primaryAppLanguageCode)"
        }
        return "https://www.mediawiki.org/wiki/Special:MyLanguage/Help:Temporary_accounts?uselang=\(languageCodeSuffix)"
    }
    var ipURL: String {
        var languageCodeSuffix = ""
        if let primaryAppLanguageCode = dataStore.languageLinkController.appLanguage?.languageCode {
            languageCodeSuffix = "\(primaryAppLanguageCode)"
        }
        return "https://en.wikipedia.org/wiki/Special:MyLanguage/IP_address?uselang=\(languageCodeSuffix)"
    }
    
    var ipLearnMoreURL: String {
        var languageCodeSuffix = ""
        if let primaryAppLanguageCode = dataStore.languageLinkController.appLanguage?.languageCode {
            languageCodeSuffix = "\(primaryAppLanguageCode)"
        }
        return "https://www.mediawiki.org/wiki/Special:MyLanguage/Help:Temporary_accounts?uselang=\(languageCodeSuffix)#Who_can_see_IP_address_data_associated_with_temporary_accounts?"
    }
    
    private var hostingController: UIHostingController<WMFTempAccountsSheetView>?
    
    private func presentTempEditorSheet() {
        var hostingController: UIHostingController<WMFTempAccountsSheetView>?
        if let tempUser = authManager.authStateTemporaryUsername {
            let vm = WMFTempAccountsSheetViewModel(
                image: "page-message",
                title: CommonStrings.tempWarningTitle,
                subtitle: tempEditorSubtitleString(tempUsername: tempUser),
                ctaTopString: WMFLocalizedString("temp-account-edit-sheet-cta-top", value: "Log in or create an account", comment: "Temporary account sheet for editors, log in/sign up."),
                ctaBottomString: CommonStrings.gotItButtonTitle,
                done: CommonStrings.doneTitle,
                handleURL: { url in
                    guard let presentedViewController = self.navigationController.presentedViewController else {
                        DDLogError("Unexpected navigation controller state. Skipping Learn More presentation.")
                        return
                    }
                    
                    let webVC: SinglePageWebViewController
                    
                    let config = SinglePageWebViewController.StandardConfig(url: url, useSimpleNavigationBar: true)
                    webVC = SinglePageWebViewController(configType: .standard(config), theme: self.theme)
                    
                    let newNavigationVC = WMFComponentNavigationController(rootViewController: webVC, modalPresentationStyle: .formSheet)
                    presentedViewController.present(newNavigationVC, animated: true)
                },
                didTapDone: didTapDone,
                ctaTopButtonAction: {
                  let loginCoordinator = LoginCoordinator(navigationController: self.navigationController, theme: self.theme)
                  loginCoordinator.loginSuccessCompletion = {
                            self.didTapContinue()
                        }

                        loginCoordinator.createAccountSuccessCustomDismissBlock = {
                            self.didTapContinue()
                        }

                        loginCoordinator.start()
                    },
                    ctaBottomButtonAction: {
                        self.didTapContinue()
                })
            let tempAccountsSheetView = WMFTempAccountsSheetView(viewModel: vm)
            hostingController = UIHostingController(rootView: tempAccountsSheetView)
            if let hostingController {
                hostingController.modalPresentationStyle = .pageSheet
                
                if let sheet = hostingController.sheetPresentationController {
                    sheet.detents = [.large()]
                }
                
                // In some cases (talk page new topic), navigation controller is already presenting. In this case, present on top of naviagation controller's presented VC.
                
                if let presentedViewController = self.navigationController.presentedViewController {
                    presentedViewController.present(hostingController, animated: true, completion: nil)
                } else {
                    navigationController.present(hostingController, animated: true, completion: nil)
                }
            }
        }
    }
    
    func tempEditorSubtitleString(tempUsername: String) -> String {
        let openingBold = "<b>"
        let closingBold = "</b>"
        let format = WMFLocalizedString("temp-account-edit-sheet-subtitle", value: "%2$@You are currently using a temporary account.%3$@ Edits made with the temporary account %1$@ will not be carried over to your permanent account when you log in. Log in or create an account to get credit to your username, among other benefits.",
          comment: "Information on temporary accounts, $1 is the temporary username, $2 and $3 are opening and closing bold")
        return String.localizedStringWithFormat(format, tempUsername, openingBold, closingBold)
    }
    
    private func presentIPEditorSheet() {
        var hostingController: UIHostingController<WMFTempAccountsSheetView>?
        let vm = WMFTempAccountsSheetViewModel(
            image: "locked-edit",
            title: CommonStrings.ipWarningTitle,
            subtitle: ipEditorSubtitleString(),
            ctaTopString: WMFLocalizedString("ip-account-cta-top", value: "Log in or create an account", comment: "Log in or create an account button title"),
            ctaBottomString: CommonStrings.continueWithoutLoggingIn,
            done: CommonStrings.doneTitle,
            handleURL: { url in
                guard let presentedViewController = self.navigationController.presentedViewController else {
                    DDLogError("Unexpected navigation controller state. Skipping Learn More presentation.")
                    return
                }

                let webVC: SinglePageWebViewController

                let config = SinglePageWebViewController.StandardConfig(url: url, useSimpleNavigationBar: true)
                webVC = SinglePageWebViewController(configType: .standard(config), theme: self.theme)

                let newNavigationVC = WMFComponentNavigationController(rootViewController: webVC, modalPresentationStyle: .formSheet)
                presentedViewController.present(newNavigationVC, animated: true)
            },
            didTapDone: didTapDone,
            ctaTopButtonAction: {

               let loginCoordinator = LoginCoordinator(navigationController: self.navigationController, theme: self.theme) 

                loginCoordinator.loginSuccessCompletion = {
                    self.didTapContinue()
                }

                loginCoordinator.createAccountSuccessCustomDismissBlock = {
                    self.didTapContinue()
                }

                loginCoordinator.start()
            },
            ctaBottomButtonAction:  {
                self.didTapContinue()
            })
        let tempAccountsSheetView = WMFTempAccountsSheetView(viewModel: vm)
        hostingController = UIHostingController(rootView: tempAccountsSheetView)
        if let hostingController {
            hostingController.modalPresentationStyle = .pageSheet
            
            if let sheet = hostingController.sheetPresentationController {
                sheet.detents = [.large()]
            }
            
            // In some cases (talk page new topic), navigation controller is already presenting. In this case, present on top of naviagation controller's presented VC.
            if let presentedViewController = self.navigationController.presentedViewController {
                presentedViewController.present(hostingController, animated: true, completion: nil)
            } else {
                navigationController.present(hostingController, animated: true, completion: nil)
            }
        }
    }
    
    func ipEditorSubtitleString() -> String {
        let openingLink = "<a href=\"\(learnMoreURL)\">"
        let closingLink = "</a>"
        let openingBold = "<b>"
        let closingBold = "</b>"
        let lineBreaks = "<br/><br/>"
        let format = WMFLocalizedString("ip-account-edit-sheet-subtitle", value:
          "Once you make an edit, a %1$@temporary account%2$@ will be created for you to protect your privacy. %3$@Learn more.%4$@%5$@Log in or create an account to get credit for future edits and to access other features.",
          comment: "Information on temporary accounts, $1 is the opening bold bracket, $2 is the closing, $3 is the opening HTML link, $4 is the closing link, $5 is the line breaks.")
        return String.localizedStringWithFormat(format, openingBold, closingBold, openingLink, closingLink, lineBreaks)
    }
    
    private func dismissTempAccountsSheet(completion: (() -> Void)? = nil) {
        guard let hostingController = hostingController else {
            completion?()
            return
        }

        hostingController.dismiss(animated: true) {
            self.hostingController = nil
            completion?()
        }
    }
}
