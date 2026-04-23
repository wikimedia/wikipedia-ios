import UIKit
import WMFData
import WMFComponents
import WMFTestKitchen
import WMFNativeLocalizations

// MARK: - KeepSavedArticlesTrigger

@objc enum KeepSavedArticlesTrigger: Int {
    case logout, syncDisabled
}

// MARK: - UIViewController Reusable alerts

extension UIViewController {

    fileprivate func hasSavedArticles() -> Bool {
        let articleRequest = WMFArticle.fetchRequest()
        articleRequest.predicate = NSPredicate(format: "savedDate != NULL")
        articleRequest.fetchLimit = 1
        articleRequest.sortDescriptors = []
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: articleRequest, managedObjectContext: MWKDataStore.shared().viewContext, sectionNameKeyPath: nil, cacheName: nil)
        do {
            try fetchedResultsController.performFetch()
        } catch _ {
            return false
        }
        guard let fetchedObjects = fetchedResultsController.fetchedObjects else {
            return false
        }
        return !fetchedObjects.isEmpty
    }

    /// Displays a blocked alert message using UIAlertController.
    func wmf_showBlockedPanel(messageHtml: String, linkBaseURL: URL, currentTitle: String, theme: Theme, image: UIImage? = nil, linkLoggingAction: (() -> Void)? = nil) {
        let message = messageHtml.wmf_stringByRemovingHTML()
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: CommonStrings.okTitle, style: .default) { _ in
            alert.dismiss(animated: true)
        })
        present(alert, animated: true)
    }

    /// Displays a alert message when abuse filter disallow error code is triggered.
    func wmf_showAbuseFilterDisallowPanel(messageHtml: String, linkBaseURL: URL, currentTitle: String, theme: Theme, goBackIsOnlyDismiss: Bool) {
        let message = messageHtml.wmf_stringByRemovingHTML()
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: CommonStrings.goBackTitle, style: .default) { [weak self] _ in
            if goBackIsOnlyDismiss {
                self?.dismiss(animated: true)
            } else {
                self?.dismiss(animated: true) {
                    guard let viewControllers = self?.navigationController?.viewControllers,
                          viewControllers.count > 2 else { return }
                    let remaining = viewControllers.prefix(viewControllers.count - 2)
                    self?.navigationController?.setViewControllers(Array(remaining), animated: true)
                }
            }
        })
        present(alert, animated: true)
    }

    /// Displays a alert message when abuse filter warning error code is triggered.
    func wmf_showAbuseFilterWarningPanel(messageHtml: String, linkBaseURL: URL, currentTitle: String, theme: Theme, goBackIsOnlyDismiss: Bool, publishAnywayTapHandler: @escaping () -> Void) {
        let message = messageHtml.wmf_stringByRemovingHTML()
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: CommonStrings.goBackTitle, style: .cancel) { [weak self] _ in
            self?.dismiss(animated: true) {
                guard let viewControllers = self?.navigationController?.viewControllers,
                      viewControllers.count > 2 else { return }
                let remaining = viewControllers.prefix(viewControllers.count - 2)
                self?.navigationController?.setViewControllers(Array(remaining), animated: true)
            }
        })
        alert.addAction(UIAlertAction(title: CommonStrings.publishAnywayTitle, style: .default) { _ in
            publishAnywayTapHandler()
        })
        present(alert, animated: true)
    }

    @objc func wmf_showEnableReadingListSyncPanel(theme: Theme, oncePerLogin: Bool = false, didNotPresentPanelCompletion: (() -> Void)? = nil, dismissHandler: (() -> Void)? = nil) {
        if oncePerLogin {
            guard !UserDefaults.standard.wmf_didShowEnableReadingListSyncPanel() else {
                didNotPresentPanelCompletion?()
                return
            }
        }
        let dataStore = MWKDataStore.shared()
        let presenter = self.presentedViewController ?? self
        guard !isAlreadyPresenting(presenter),
              dataStore.authenticationManager.authStateIsPermanent,
              dataStore.readingListsController.isSyncRemotelyEnabled,
              !dataStore.readingListsController.isSyncEnabled else {
            didNotPresentPanelCompletion?()
            return
        }

        let alert = UIAlertController(
            title: WMFLocalizedString("reading-list-sync-enable-title", value: "Turn on reading list syncing?", comment: "Title describing reading list syncing."),
            message: WMFLocalizedString("reading-list-sync-enable-subtitle", value: "Your saved articles and reading lists can now be saved to your Wikipedia account and synced across Wikipedia apps.", comment: "Subtitle describing reading list syncing."),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: WMFLocalizedString("reading-list-sync-enable-button-title", value: "Enable syncing", comment: "Title for button enabling reading list syncing."), style: .default) { [weak self] _ in
            guard let self else { return }
            if self.hasSavedArticles() {
                self.wmf_showAddSavedArticlesToReadingListAlert()
            } else {
                dataStore.readingListsController.setSyncEnabled(true, shouldDeleteLocalLists: false, shouldDeleteRemoteLists: false)
                SettingsFunnel.shared.logEnableSyncPopoverSyncEnabled()
            }
            dismissHandler?()
        })
        alert.addAction(UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel) { _ in
            dismissHandler?()
        })

        presenter.present(alert, animated: true, completion: {
            UserDefaults.standard.wmf_setDidShowEnableReadingListSyncPanel(true)
            UserDefaults.standard.wmf_setDidShowSyncDisabledPanel(true)
            SettingsFunnel.shared.logEnableSyncPopoverImpression()
        })
    }

    private func isAlreadyPresenting(_ presenter: UIViewController) -> Bool {
        let presenter = self.presentedViewController ?? self
        guard presenter is WMFComponentNavigationController else {
            return false
        }
        return presenter.presentedViewController != nil
    }

    fileprivate func wmf_showAddSavedArticlesToReadingListAlert() {
        let dataStore = MWKDataStore.shared()
        let alert = UIAlertController(
            title: WMFLocalizedString("reading-list-add-saved-title", value: "Saved articles found", comment: "Title explaining saved articles were found."),
            message: WMFLocalizedString("reading-list-add-saved-subtitle", value: "There are articles saved to your Wikipedia app. Would you like to keep them and merge with reading lists synced to your account?", comment: "Subtitle explaining that saved articles can be added to reading lists."),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: WMFLocalizedString("reading-list-add-saved-button-title", value: "Yes, add them to my reading lists", comment: "Title for button to add saved articles to reading list."), style: .default) { _ in
            dataStore.readingListsController.setSyncEnabled(true, shouldDeleteLocalLists: false, shouldDeleteRemoteLists: false)
            SettingsFunnel.shared.logEnableSyncPopoverSyncEnabled()
        })
        alert.addAction(UIAlertAction(title: CommonStrings.readingListDoNotKeepSubtitle, style: .destructive) { _ in
            dataStore.readingListsController.setSyncEnabled(true, shouldDeleteLocalLists: true, shouldDeleteRemoteLists: false)
            SettingsFunnel.shared.logEnableSyncPopoverSyncEnabled()
        })
        present(alert, animated: true)
    }

    func wmf_showLoginViewController(category: EventCategoryMEP? = nil, theme: Theme, loginSuccessCompletion: (() -> Void)? = nil, loginDismissedCompletion: (() -> Void)? = nil) {
        guard let loginVC = WMFLoginViewController.wmf_initialViewControllerFromClassStoryboard() else {
            assertionFailure("Expected view controller(s) not found")
            return
        }
        loginVC.loginSuccessCompletion = loginSuccessCompletion
        loginVC.loginDismissedCompletion = loginDismissedCompletion
        loginVC.category = category
        loginVC.apply(theme: theme)
        present(WMFComponentNavigationController(rootViewController: loginVC, modalPresentationStyle: .overFullScreen), animated: true)
    }


    @objc func wmf_showNotLoggedInUponPublishPanel(buttonTapHandler: ((Int) -> Void)?, theme: Theme) {
        let alert = UIAlertController(
            title: WMFLocalizedString("panel-not-logged-in-title", value: "You are not logged in", comment: "Title for education panel letting user know they are not logged in."),
            message: WMFLocalizedString("panel-not-logged-in-subtitle-plain", value: "Your IP address will be publicly visible if you make any edits. Log in or create an account to have your edits attributed to your username.", comment: "Subtitle for letting user know that they are not logged in."),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: CommonStrings.loginOrCreateAccountTitle, style: .default) { [weak self] _ in
            self?.wmf_showLoginViewController(theme: theme, loginSuccessCompletion: nil, loginDismissedCompletion: nil)
            buttonTapHandler?(0)
        })
        alert.addAction(UIAlertAction(title: WMFLocalizedString("panel-not-logged-in-continue-edit-action-title", value: "Edit without logging in", comment: "Title for button that continues publishing the edit anonymously."), style: .cancel) { _ in
            buttonTapHandler?(1)
        })
        present(alert, animated: true)
    }

    @objc func wmf_showLoginOrCreateAccountToSyncSavedArticlesToReadingListPanel(theme: Theme, dismissHandler: (() -> Void)? = nil, loginSuccessCompletion: (() -> Void)? = nil, loginDismissedCompletion: (() -> Void)? = nil) {
        LoginFunnel.shared.logLoginImpressionInSyncPopover()
        let alert = UIAlertController(
            title: WMFLocalizedString("reading-list-login-or-create-account-title", value: "Log in to sync saved articles", comment: "Title for syncing saved articles."),
            message: CommonStrings.readingListLoginSubtitle,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: CommonStrings.loginOrCreateAccountTitle, style: .default) { [weak self] _ in
            self?.wmf_showLoginViewController(category: .loginToSyncPopover, theme: theme, loginSuccessCompletion: loginSuccessCompletion, loginDismissedCompletion: loginDismissedCompletion)
            LoginFunnel.shared.logLoginStartInSyncPopover()
            dismissHandler?()
        })
        alert.addAction(UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel) { _ in
            dismissHandler?()
        })
        present(alert, animated: true)
    }


    func wmf_showThankRevisionAuthorEducationPanel(theme: Theme, sendThanksHandler: @escaping () -> Void, cancelHandler: @escaping () -> Void) {
        let alert = UIAlertController(
            title: WMFLocalizedString("diff-thanks-send-title", value: "Publicly send 'Thanks'", comment: "Title for sending thanks panel."),
            message: WMFLocalizedString("diff-thanks-send-subtitle", value: "'Thanks' are an easy way to show appreciation for an editor's work on Wikipedia. 'Thanks' cannot be undone and are publicly viewable.", comment: "Subtitle for sending thanks panel."),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: WMFLocalizedString("diff-thanks-send-button-title", value: "Send 'Thanks'", comment: "Title for sending thanks button."), style: .default) { _ in
            sendThanksHandler()
        })
        alert.addAction(UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel) { _ in
            cancelHandler()
        })
        present(alert, animated: true)
    }
    
    @objc func wmf_objcShowKeepSavedArticlesOnDevicePanelIfNeeded(triggeredBy keepSavedArticlesTrigger: KeepSavedArticlesTrigger, theme: Theme, completion: (() -> Swift.Void)? = nil) {
        wmf_showKeepSavedArticlesOnDevicePanelIfNeeded(triggeredBy: keepSavedArticlesTrigger, theme: theme, authInstrument: nil, completion: completion)
    }

    func wmf_showKeepSavedArticlesOnDevicePanelIfNeeded(triggeredBy keepSavedArticlesTrigger: KeepSavedArticlesTrigger, theme: Theme, authInstrument: InstrumentImpl?, completion: (() -> Swift.Void)? = nil) {
        guard hasSavedArticles() else {
            completion?()
            return
        }

        let keepTitle = WMFLocalizedString("reading-list-keep-button-title", value: "Yes, keep articles on device", comment: "Title for button to keep synced articles on device.")
        let removeTitle: String
        let message: String

        if keepSavedArticlesTrigger == .logout {
            message = CommonStrings.keepSavedArticlesOnDeviceMessage
            removeTitle = CommonStrings.readingListDoNotKeepSubtitle
        } else {
            message = CommonStrings.keepSavedArticlesOnDeviceMessage + "\n\n" + WMFLocalizedString("reading-list-keep-sync-disabled-additional-subtitle", value: "Turning sync off will remove these articles from your account. If you remove them from your device they will not be recoverable by turning sync on again in the future.", comment: "Additional subtitle informing user that turning sync off will remove saved articles from their account.")
            removeTitle = WMFLocalizedString("reading-list-keep-sync-disabled-remove-article-button-title", value: "No, remove articles from device and my Wikipedia account", comment: "Title for button that removes save articles from device and Wikipedia account.")
        }

        let alert = UIAlertController(
            title: WMFLocalizedString("reading-list-keep-title", value: "Keep saved articles on device?", comment: "Title for keeping save articles on device."),
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: keepTitle, style: .default) { _ in
            authInstrument?.submitInteraction(action: "click", actionSource: "save_articles_prompt", elementId: "save")
            MWKDataStore.shared().readingListsController.setSyncEnabled(false, shouldDeleteLocalLists: false, shouldDeleteRemoteLists: false)
            completion?()
        })
        alert.addAction(UIAlertAction(title: removeTitle, style: .destructive) { _ in
            authInstrument?.submitInteraction(action: "click", actionSource: "save_articles_prompt", elementId: "delete")
            MWKDataStore.shared().readingListsController.setSyncEnabled(false, shouldDeleteLocalLists: true, shouldDeleteRemoteLists: false)
            completion?()
        })
        
        present(alert, animated: true) {
            authInstrument?.submitInteraction(action: "impression", actionSource: "save_articles_prompt")
        }
    }

}
