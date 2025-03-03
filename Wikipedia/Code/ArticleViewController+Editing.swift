import CocoaLumberjackSwift
import WMFComponents
import WMFData
import UIKit
import SwiftUI

extension ArticleViewController {
    
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
    
    func showEditorForSectionOrTitleDescription(with id: Int, descriptionSource: ArticleDescriptionSource?) {
        /// If this is a first section with an existing description, show the dialog box. (This is reported as a `central` or `local` description source.) Otherwise, just show the editor for the section. (A first section without an article description has an `Add article description` button, and thus doesn't need the dialog box.)
        if let descriptionSource = descriptionSource, descriptionSource == .central || descriptionSource == .local {
            showEditSectionOrTitleDescriptionDialogForSection(with: id, descriptionSource: descriptionSource)
        } else {
            showEditorForSection(with: id)
        }
        
        if let project = WikimediaProject(siteURL: articleURL) {
            EditInteractionFunnel.shared.logArticleDidTapEditSectionButton(project: project)
        }
        
        EditAttemptFunnel.shared.logInit(pageURL: articleURL)
    }
    
    func showEditorForFullSource() {
        let editorViewController = EditorViewController(pageURL: articleURL, sectionID: nil, editFlow: .editorPreviewSave, source: .article, dataStore: dataStore, articleSelectedInfo: nil, editTag: .appFullSource, delegate: self, theme: theme)
        
        presentEditor(editorViewController: editorViewController)
        
        if let project = WikimediaProject(siteURL: articleURL) {
            EditInteractionFunnel.shared.logArticleDidTapEditSourceButton(project: project)
        }
        
        EditAttemptFunnel.shared.logInit(pageURL: articleURL)
    }
    
    func showEditorForSection(with id: Int, selectedTextEditInfo: SelectedTextEditInfo? = nil) {
        cancelWIconPopoverDisplay()
        
        let editTag: WMFEditTag = selectedTextEditInfo == nil ?  .appSectionSource : .appSelectSource

        let editorViewController = EditorViewController(pageURL: articleURL, sectionID: id, editFlow: .editorPreviewSave, source: .article, dataStore: dataStore, articleSelectedInfo: selectedTextEditInfo, editTag: editTag, delegate: self, theme: theme)
        
        presentEditor(editorViewController: editorViewController)
    }
    
    func showTitleDescriptionEditor(with descriptionSource: ArticleDescriptionSource) {

        let maybeDescriptionController: ArticleDescriptionControlling? = (articleURL.wmf_isEnglishWikipedia || articleURL.wmf_isTestWikipedia) ? ShortDescriptionController(article: article, articleLanguageCode: articleLanguageCode, articleURL: articleURL, descriptionSource: descriptionSource, delegate: self) : WikidataDescriptionController(article: article, articleLanguageCode: articleLanguageCode, descriptionSource: descriptionSource)

        guard let descriptionController = maybeDescriptionController else {
            showGenericError()
            return
        }
        
        let editVC = DescriptionEditViewController.with(dataStore: dataStore, theme: theme, articleDescriptionController: descriptionController)
        editVC.delegate = self
        let navigationController = WMFComponentNavigationController(rootViewController: editVC, modalPresentationStyle: .overFullScreen)
        navigationController.view.isOpaque = false
        navigationController.view.backgroundColor = .clear
       let needsIntro = !UserDefaults.standard.wmf_didShowTitleDescriptionEditingIntro()
       if needsIntro {
           navigationController.view.alpha = 0
       }
        let showIntro: (() -> Void)? = {
            let welcomeVC = DescriptionWelcomeInitialViewController.wmf_viewControllerFromDescriptionWelcomeStoryboard()
            welcomeVC.completionBlock = {
            }
            welcomeVC.apply(theme: self.theme)
            navigationController.present(welcomeVC, animated: true) {
                UserDefaults.standard.wmf_setDidShowTitleDescriptionEditingIntro(true)
                navigationController.view.alpha = 1
            }
        }
        present(navigationController, animated: !needsIntro) {
            if needsIntro {
                showIntro?()
            }
        }
    }
    
    private func presentEditor(editorViewController: UIViewController) {
        let presentEditorAction = { [weak self] in
              guard let self else { return }
            let navigationController = WMFComponentNavigationController(rootViewController: editorViewController, modalPresentationStyle: .overFullScreen)
            
            let needsIntro = !UserDefaults.standard.didShowEditingOnboarding
            if needsIntro {
                let editingWelcomeViewController = EditingWelcomeViewController(theme: self.theme) {
                    
                    self.present(navigationController, animated: true)
                }
                editingWelcomeViewController.apply(theme: self.theme)
                self.present(editingWelcomeViewController, animated: true) {
                    UserDefaults.standard.didShowEditingOnboarding = true
                }
                
            } else {
                self.present(navigationController, animated: true)
            }
        }
        
        if !authManager.authStateIsPermanent {
            if authManager.authStateIsTemporary {
                presentTempEditorSheet(presentEditorAction)
            } else {
                presentIPEditorSheet(presentEditorAction)
            }
        } else {
                presentEditorAction()
        }
    }
    
    private func presentTempEditorSheet(_ presentEditorAction: @escaping () -> Void) {
        var hostingController: UIHostingController<WMFTempAccountsSheetView>?
        if let tempUser = authManager.authStateTemporaryUsername {
            let vm = WMFTempAccountsSheetViewModel(
                image: "pageMessage",
                title: WMFLocalizedString("temp-account-edit-sheet-title", value: "You are using a temporary account", comment: "Temporary account sheet for editors"),
                subtitle: tempEditorSubtitleString(tempUsername: tempUser),
                ctaTopString: WMFLocalizedString("temp-account-edit-sheet-cta-top", value: "Log in or create an account", comment: "Temporary account sheet for editors, log in/sign up."),
                ctaBottomString: WMFLocalizedString("temp-account-got-it", value: "Got it", comment: "Got it button"),
                done: CommonStrings.doneTitle,
                handleURL: { url in
                    guard let presentedViewController = self.navigationController?.presentedViewController else {
                        DDLogError("Unexpected navigation controller state. Skipping Learn More presentation.")
                        return
                    }
                    
                    let webVC: SinglePageWebViewController
                    
                    let config = SinglePageWebViewController.StandardConfig(url: url, useSimpleNavigationBar: true)
                    webVC = SinglePageWebViewController(configType: .standard(config), theme: self.theme)
                    
                    let newNavigationVC = WMFComponentNavigationController(rootViewController: webVC, modalPresentationStyle: .formSheet)
                    presentedViewController.present(newNavigationVC, animated: true)
                },
                didTapDone: { [weak self] in
                    self?.dismiss(animated: true)
                    presentEditorAction()
                })
            let tempAccountsSheetView = WMFTempAccountsSheetView(viewModel: vm)
            hostingController = UIHostingController(rootView: tempAccountsSheetView)
            if let hostingController {
                hostingController.modalPresentationStyle = .pageSheet
                
                if let sheet = hostingController.sheetPresentationController {
                    sheet.detents = [.large()]
                }
                
                present(hostingController, animated: true, completion: nil)
            }
        }
    }
    
    func tempEditorSubtitleString(tempUsername: String) -> String {
        let openingLink = "<a href=\"\(ipURL)\">"
        let openingLinkLearnMore = "<a href=\"\(ipLearnMoreURL)\">"
        let closingLink = "</a>"
        let openingBold = "<b>"
        let closingBold = "</b>"
        let lineBreaks = "<br/><br/>"
        let format = WMFLocalizedString("temp-account-edit-sheet-subtitle", value: "Your edit will be attributed to %2$@%1$@%3$@. Your %4$@IP address%5$@ will be visible to administrators. %7$@Learn more.%5$@%6$@ If you log in or create an account, your edits will be attributed to a name you choose, among other benefits.",
          comment: "Information on temporary accounts, $1 is the temporary username, $2 and $3 are opening and closing bold, $4 is the URL opening tag, and $5 is the closing. $6 is the linebreaks. $7 is the opening for the learn more link.")
        return String.localizedStringWithFormat(format, tempUsername, openingBold, closingBold, openingLink, closingLink, lineBreaks, openingLinkLearnMore)
    }
    
    private func presentIPEditorSheet(_ presentEditorAction: @escaping () -> Void) {
        var hostingController: UIHostingController<WMFTempAccountsSheetView>?
        let vm = WMFTempAccountsSheetViewModel(
            image: "lockedEdit",
            title: WMFLocalizedString("ip-account-edit-sheet", value: "You are not logged in", comment: "IP account sheet for editors"),
            subtitle: ipEditorSubtitleString(),
            ctaTopString: WMFLocalizedString("ip-account-cta-top", value: "Log in or create an account", comment: "Log in or create an account button title"),
            ctaBottomString: WMFLocalizedString("ip-account-cta-bottom", value: "Continue without logging in", comment: "Continue without logging in button title"),
            done: CommonStrings.doneTitle,
            handleURL: { url in
                guard let presentedViewController = self.navigationController?.presentedViewController else {
                    DDLogError("Unexpected navigation controller state. Skipping Learn More presentation.")
                    return
                }

                let webVC: SinglePageWebViewController

                let config = SinglePageWebViewController.StandardConfig(url: url, useSimpleNavigationBar: true)
                webVC = SinglePageWebViewController(configType: .standard(config), theme: self.theme)

                let newNavigationVC = WMFComponentNavigationController(rootViewController: webVC, modalPresentationStyle: .formSheet)
                presentedViewController.present(newNavigationVC, animated: true)
            },
            didTapDone: { [weak self] in
                self?.dismiss(animated: true)
                presentEditorAction()
            })
        let tempAccountsSheetView = WMFTempAccountsSheetView(viewModel: vm)
        hostingController = UIHostingController(rootView: tempAccountsSheetView)
        if let hostingController {
            hostingController.modalPresentationStyle = .pageSheet
            
            if let sheet = hostingController.sheetPresentationController {
                sheet.detents = [.large()]
            }
            
            present(hostingController, animated: true, completion: nil)
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
    
    func showEditSectionOrTitleDescriptionDialogForSection(with id: Int, descriptionSource: ArticleDescriptionSource, selectedTextEditInfo: SelectedTextEditInfo? = nil) {

        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        
        let editTitleDescriptionTitle = WMFLocalizedString("description-edit-pencil-title", value: "Edit article description", comment: "Title for button used to show article description editor")
        let editTitleDescriptionAction = UIAlertAction(title: editTitleDescriptionTitle, style: .default) { (action) in
            self.showTitleDescriptionEditor(with: descriptionSource)
            
            if let project = WikimediaProject(siteURL: self.articleURL) {
                EditInteractionFunnel.shared.logArticleConfirmDidTapEditArticleDescription(project: project)
            }
        }
        sheet.addAction(editTitleDescriptionAction)
        
        let editLeadSectionTitle = WMFLocalizedString("description-edit-pencil-introduction", value: "Edit introduction", comment: "Title for button used to show article lead section editor")
        let editLeadSectionAction = UIAlertAction(title: editLeadSectionTitle, style: .default) { (action) in
            self.showEditorForSection(with: id, selectedTextEditInfo: selectedTextEditInfo)
            
            if let project = WikimediaProject(siteURL: self.articleURL) {
                EditInteractionFunnel.shared.logArticleConfirmDidTapEditIntroduction(project: project)
            }
        }
        sheet.addAction(editLeadSectionAction)
        
        sheet.addAction(UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel) { _ in

            if let project = WikimediaProject(siteURL: self.articleURL) {
                EditInteractionFunnel.shared.logArticleConfirmDidTapCancel(project: project)
            }

            EditAttemptFunnel.shared.logAbort(pageURL: self.articleURL)

        })
        present(sheet, animated: true)
    }

}

extension ArticleViewController: ShortDescriptionControllerDelegate {

    /// Pulls title description from article content.
    /// Looks for the innerText of the "pcs-edit-section-title-description" ID element
    /// - Parameter completion: Completion when bridge call completes. Passes back title description or nil if pcs-edit-section-title-description could not be extracted.
    func currentDescription(completion: @escaping (String?) -> Void) {

        let javascript = """
            function extractTitleDescription() {
                var editTitleDescriptionElement = document.getElementById('pcs-edit-section-title-description');
                if (editTitleDescriptionElement) {
                    return editTitleDescriptionElement.innerText;
                }
                return null;
            }
            extractTitleDescription();
        """

        webView.evaluateJavaScript(javascript) { (result, error) in
            DispatchQueue.main.async {
                if let error = error {
                    DDLogWarn("Failure in articleHtmlTitleDescription: \(error)")
                    completion(nil)
                    return
                }

                guard let stringResult = result as? String else {
                    completion(nil)
                    return
                }

                completion(stringResult)
            }
        }
    }
    
    enum ArticleEditingDescriptionError: Error {
        case failureInjectingNewDescription
    }
    
    func injectNewDescriptionIntoArticleContent(_ newDescription: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let javascript = """
            function injectTitleDescription(description) {

                //first attempt to swap out add description callout
                var addTitleDescriptionElement = document.getElementById("pcs-edit-section-add-title-description");
                if (addTitleDescriptionElement) {
                    addTitleDescriptionElement.insertAdjacentHTML("beforebegin",`<p id='pcs-edit-section-title-description'>${description}</p>`);
                    addTitleDescriptionElement.parentElement.removeChild(addTitleDescriptionElement);
                    return true;
                }
                
                //else replace existing description
                var editTitleDescriptionElement = document.getElementById('pcs-edit-section-title-description');
                if (editTitleDescriptionElement) {
                    editTitleDescriptionElement.innerHTML = description;
                    return true;
                }
                return false;
            }
           injectTitleDescription(`\(newDescription.sanitizedForJavaScriptTemplateLiterals)`);
        """

        webView.evaluateJavaScript(javascript) { (result, error) in
            DispatchQueue.main.async {
                if let error = error {
                    DDLogWarn("Failure in injectNewDescriptionIntoArticleContent: \(error)")
                    completion(.failure(error))
                    return
                }

                guard let boolResult = result as? Bool,
                      boolResult == true else {
                    completion(.failure(ArticleEditingDescriptionError.failureInjectingNewDescription))
                    return
                }

                completion(.success(()))
            }
        }
    }
}

extension ArticleViewController: EditorViewControllerDelegate {
    func editorDidCancelEditing(_ editor: EditorViewController, navigateToURL url: URL?) {
        dismiss(animated: true) {
            self.navigate(to: url)
        }
    }
    
    func editorDidFinishEditing(_ editor: EditorViewController, result: Result<EditorChanges, Error>) {
        switch result {
        case .failure(let error):
            showError(error)
        case .success(let changes):
            dismiss(animated: true) {
                
                let title = CommonStrings.editPublishedToastTitle
                let image = UIImage(systemName: "checkmark.circle.fill")
                
                if UIAccessibility.isVoiceOverRunning {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: title)
                    }
                } else {
                    WMFAlertManager.sharedInstance.showBottomAlertWithMessage(title, subtitle: nil, image: image, type: .custom, customTypeName: "edit-published", dismissPreviousAlerts: true)
                }
                
            }
            
            waitForNewContentAndRefresh(changes.newRevisionID)
        }
    }
}

extension ArticleViewController: DescriptionEditViewControllerDelegate {
    func descriptionEditViewControllerEditSucceeded(_ descriptionEditViewController: DescriptionEditViewController, result: ArticleDescriptionPublishResult) {
        injectNewDescriptionIntoArticleContent(result.newDescription) { [weak self] injectResult in
            
            guard let self = self else {
                return
            }

            switch injectResult {
            case .failure(let error):
                DDLogWarn("Failure injecting new description into article content, refreshing instead: \(error)")
                self.waitForNewContentAndRefresh(result.newRevisionID)
            case .success:
                break
            }
        }
    }
}

// Save these strings in case we need them - right now I don't think mobile-html even sends the event if they can't edit
// WMFLocalizedStringWithDefaultValue(@"page-protected-can-not-edit-title", nil, nil, @"This page is protected", @"Title of alert dialog shown when trying to edit a page that is protected beyond what the user can edit.")
// WMFLocalizedStringWithDefaultValue(@"page-protected-can-not-edit", nil, nil, @"You do not have the rights to edit this page", @"Text of alert dialog shown when trying to edit a page that is protected beyond what the user can edit.")
