
class EnableReadingListSyncPanelViewController : ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage(named: "reading-list-syncing")
        heading = WMFLocalizedString("reading-list-sync-enable-title", value:"Turn on reading list syncing?", comment:"Title describing reading list syncing.")
        subheading = WMFLocalizedString("reading-list-sync-enable-subtitle", value:"Your saved articles and reading lists can now be saved to your Wikipedia account and synced across Wikipedia apps.", comment:"Subtitle describing reading list syncing.")
        primaryButtonTitle = WMFLocalizedString("reading-list-sync-enable-button-title", value:"Enable syncing", comment:"Title for button enabling reading list syncing.")
    }
}

class AddSavedArticlesToReadingListPanelViewController : ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage(named: "reading-list-saved")
        heading = WMFLocalizedString("reading-list-add-saved-title", value:"Saved articles found", comment:"Title explaining saved articles were found.")
        subheading = WMFLocalizedString("reading-list-add-saved-subtitle", value:"There are articles saved to your Wikipedia app. Would you like to keep them and merge with reading lists synced to your account?", comment:"Subtitle explaining that saved articles can be added to reading lists.")
        primaryButtonTitle = WMFLocalizedString("reading-list-add-saved-button-title", value:"Yes, add them to my reading lists", comment:"Title for button to add saved articles to reading list.")
        secondaryButtonTitle = CommonStrings.readingListDoNotKeepSubtitle
    }
}

class LoginToSyncSavedArticlesToReadingListPanelViewController : ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage(named: "reading-list-login")
        heading = WMFLocalizedString("reading-list-login-title", value:"Sync your saved articles?", comment:"Title for syncing save articles.")
        subheading = CommonStrings.readingListLoginSubtitle
        primaryButtonTitle = CommonStrings.readingListLoginButtonTitle
    }
}

@objc enum KeepSavedArticlesTrigger: Int {
    case logout, syncDisabled
}

class KeepSavedArticlesOnDevicePanelViewController : ScrollableEducationPanelViewController {
    private let trigger: KeepSavedArticlesTrigger
    
    init(triggeredBy trigger: KeepSavedArticlesTrigger, showCloseButton: Bool, primaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, secondaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, dismissHandler: ScrollableEducationPanelDismissHandler?, discardDismissHandlerOnPrimaryButtonTap: Bool, theme: Theme) {
        self.trigger = trigger
        super.init(showCloseButton: showCloseButton, primaryButtonTapHandler: primaryButtonTapHandler, secondaryButtonTapHandler: secondaryButtonTapHandler, dismissHandler: dismissHandler, theme: theme)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage(named: "reading-list-saved")
        heading = WMFLocalizedString("reading-list-keep-title", value: "Keep saved articles on device?", comment: "Title for keeping save articles on device.")
        primaryButtonTitle = WMFLocalizedString("reading-list-keep-button-title", value: "Yes, keep articles on device", comment: "Title for button to keep synced articles on device.")
        if trigger == .logout {
            subheading = CommonStrings.keepSavedArticlesOnDeviceMessage
            secondaryButtonTitle = CommonStrings.readingListDoNotKeepSubtitle
        } else if trigger == .syncDisabled {
            subheading = CommonStrings.keepSavedArticlesOnDeviceMessage + "\n\n" + WMFLocalizedString("reading-list-keep-sync-disabled-additional-subtitle", value: "Turning sync off will remove these articles from your account. If you remove them from your device they will not be recoverable by turning sync on again in the future.", comment: "Additional subtitle informing user that turning sync off will remove saved articles from their account.")
            secondaryButtonTitle = WMFLocalizedString("reading-list-keep-sync-disabled-remove-article-button-title", value: "No, remove articles from device and my Wikipedia account", comment: "Title for button that removes save articles from device and Wikipedia account.")
        }
    }
}
class SyncEnabledPanelViewController: ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage(named: "reading-lists-sync-enabled-disabled")
        heading = WMFLocalizedString("reading-list-sync-enabled-panel-title", value: "Sync is enabled on this account", comment: "Title for panel informing user that sync was disabled on their Wikipedia account on another device")
        subheading = WMFLocalizedString("reading-list-sync-enabled-panel-message", value: "Reading list syncing is enabled for this account. To stop syncing, you can turn sync off for this account by updating your settings.", comment: "Message for panel informing user that sync is enabled for their account.")
        primaryButtonTitle = CommonStrings.gotItButtonTitle
    }
}

class SyncDisabledPanelViewController: ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage(named: "reading-lists-sync-enabled-disabled")
        heading = WMFLocalizedString("reading-list-sync-disabled-panel-title", value: "Sync disabled", comment: "Title for panel informing user that sync was disabled on their Wikipedia account on another device")
        subheading = WMFLocalizedString("reading-list-sync-disabled-panel-message", value: "Reading list syncing has been disabled for your Wikipedia account on another device. You can turn sync back on by updating your settings.", comment: "Message for panel informing user that sync was disabled on their Wikipedia account on another device.")
        primaryButtonTitle = CommonStrings.gotItButtonTitle
    }
}

class EnableLocationPanelViewController : ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage(named: "places-auth-arrow")
        heading = CommonStrings.localizedEnableLocationTitle
        primaryButtonTitle = CommonStrings.localizedEnableLocationButtonTitle
        footer = CommonStrings.localizedEnableLocationDescription
    }
}

class ReLoginFailedPanelViewController : ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage(named: "relogin-failed")
        heading = WMFLocalizedString("relogin-failed-title", value:"Unable to re-establish log in", comment:"Title for letting user know they are no longer logged in.")
        subheading = WMFLocalizedString("relogin-failed-subtitle", value:"Your session may have expired or previous log in credentials are no longer valid.", comment:"Subtitle for letting user know they are no longer logged in.")
        primaryButtonTitle = WMFLocalizedString("relogin-failed-retry-login-button-title", value:"Try to log in again", comment:"Title for button to let user attempt to log in again.")
        secondaryButtonTitle = WMFLocalizedString("relogin-failed-stay-logged-out-button-title", value:"Keep me logged out", comment:"Title for button for user to choose to remain logged out.")
    }
}

class LoginOrCreateAccountToSyncSavedArticlesToReadingListPanelViewController : ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage(named: "reading-list-user")
        heading = WMFLocalizedString("reading-list-login-or-create-account-title", value:"Log in to sync saved articles", comment:"Title for syncing saved articles.")
        subheading = CommonStrings.readingListLoginSubtitle
        primaryButtonTitle = WMFLocalizedString("reading-list-login-or-create-account-button-title", value:"Log in or create account", comment:"Title for button to login or create account to sync saved articles and reading lists.")
    }
}

class LimitHitForUnsortedArticlesPanelViewController: ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        heading = WMFLocalizedString("reading-list-limit-hit-for-unsorted-articles-title", value: "Limit hit for unsorted articles", comment: "Title for letting the user know that the limit for unsorted articles was reached.")
        subheading = WMFLocalizedString("reading-list-limit-hit-for-unsorted-articles-subtitle", value:  "There is a limit of 5000 unsorted articles. Please sort your existing articles into lists to continue the syncing of unsorted articles.", comment: "Subtitle letting the user know that there is a limit of 5000 unsorted articles.")
        primaryButtonTitle = WMFLocalizedString("reading-list-limit-hit-for-unsorted-articles-button-title", value: "Sort articles", comment: "Title for button to sort unsorted articles.")
    }
}

class DescriptionPublishedPanelViewController: ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage(named: "description-published")
        heading = WMFLocalizedString("description-published-title", value: "Description published!", comment: "Title for letting the user know their description change succeeded.")
        subheading = WMFLocalizedString("description-published-subtitle", value:  "You just made Wikipedia better for everyone", comment: "Subtitle encouraging user to continue editing")
        primaryButtonTitle = WMFLocalizedString("description-published-button-title", value: "Done", comment: "Title for description panel done button.")
        footer = WMFLocalizedString("description-published-footer", value: "You can also edit articles within this app. Try fixing typos and small sentences by clicking on the pencil icon next time", comment: "Title for footer explaining articles may be edited too - not just descriptions.")
    }
}

extension UIViewController {
    
    fileprivate func hasSavedArticles() -> Bool {
        let articleRequest = WMFArticle.fetchRequest()
        articleRequest.predicate = NSPredicate(format: "savedDate != NULL")
        articleRequest.fetchLimit = 1
        articleRequest.sortDescriptors = []
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: articleRequest, managedObjectContext: SessionSingleton.sharedInstance().dataStore.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        do {
            try fetchedResultsController.performFetch()
        } catch _ {
            return false
        }
        guard let fetchedObjects = fetchedResultsController.fetchedObjects else {
            return false
        }
        return fetchedObjects.count > 0
    }
        
    @objc func wmf_showEnableReadingListSyncPanel(theme: Theme, oncePerLogin: Bool = false, didNotPresentPanelCompletion: (() -> Void)? = nil, dismissHandler: ScrollableEducationPanelDismissHandler? = nil) {
        if oncePerLogin {
            guard !UserDefaults.wmf.wmf_didShowEnableReadingListSyncPanel() else {
                didNotPresentPanelCompletion?()
                return
            }
        }
        let presenter = self.presentedViewController ?? self
        guard !isAlreadyPresenting(presenter),
            WMFAuthenticationManager.sharedInstance.isLoggedIn,
            SessionSingleton.sharedInstance().dataStore.readingListsController.isSyncRemotelyEnabled,
            !SessionSingleton.sharedInstance().dataStore.readingListsController.isSyncEnabled else {
                didNotPresentPanelCompletion?()
                return
        }
        let enableSyncTapHandler: ScrollableEducationPanelButtonTapHandler = { _ in
            self.presentedViewController?.dismiss(animated: true, completion: {
                guard self.hasSavedArticles() else {
                    SessionSingleton.sharedInstance().dataStore.readingListsController.setSyncEnabled(true, shouldDeleteLocalLists: false, shouldDeleteRemoteLists: false)
                    SettingsFunnel.shared.logEnableSyncPopoverSyncEnabled()
                    return
                }
                self.wmf_showAddSavedArticlesToReadingListPanel(theme: theme)
            })
        }
        
        let panelVC = EnableReadingListSyncPanelViewController(showCloseButton: true, primaryButtonTapHandler: enableSyncTapHandler, secondaryButtonTapHandler: nil, dismissHandler: dismissHandler, theme: theme)
        
        presenter.present(panelVC, animated: true, completion: {
            UserDefaults.wmf.wmf_setDidShowEnableReadingListSyncPanel(true)
            // we don't want to present the "Sync disabled" panel if "Enable sync" was presented, wmf_didShowSyncDisabledPanel will be set to false when app is paused.
            UserDefaults.wmf.wmf_setDidShowSyncDisabledPanel(true)
            SettingsFunnel.shared.logEnableSyncPopoverImpression()
        })
    }
    
    @objc func wmf_showSyncDisabledPanel(theme: Theme, wasSyncEnabledOnDevice: Bool) {
        guard !UserDefaults.wmf.wmf_didShowSyncDisabledPanel(),
            wasSyncEnabledOnDevice else {
                return
        }
        let primaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler = { _ in
            self.presentedViewController?.dismiss(animated: true)
        }
        let panel = SyncDisabledPanelViewController(showCloseButton: true, primaryButtonTapHandler: primaryButtonTapHandler, secondaryButtonTapHandler: nil, dismissHandler: nil, theme: theme)
        let presenter = self.presentedViewController ?? self
        presenter.present(panel, animated: true) {
            UserDefaults.wmf.wmf_setDidShowSyncDisabledPanel(true)
        }
    }
    
    private func isAlreadyPresenting(_ presenter: UIViewController) -> Bool {
        let presenter = self.presentedViewController ?? self
        guard presenter is WMFThemeableNavigationController else {
            return false
        }
        return presenter.presentedViewController != nil
    }
    
    @objc func wmf_showSyncEnabledPanelOncePerLogin(theme: Theme, wasSyncEnabledOnDevice: Bool) {
        let presenter = self.presentedViewController ?? self
        guard !isAlreadyPresenting(presenter),
            !UserDefaults.wmf.wmf_didShowSyncEnabledPanel(),
            !wasSyncEnabledOnDevice else {
                return
        }
        let primaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler = { _ in
            self.presentedViewController?.dismiss(animated: true)
        }
        let panel = SyncEnabledPanelViewController(showCloseButton: true, primaryButtonTapHandler: primaryButtonTapHandler, secondaryButtonTapHandler: nil, dismissHandler: nil, theme: theme)
        presenter.present(panel, animated: true) {
            UserDefaults.wmf.wmf_setDidShowSyncEnabledPanel(true)
        }
    }
    
    fileprivate func wmf_showAddSavedArticlesToReadingListPanel(theme: Theme) {
        let addSavedArticlesToReadingListsTapHandler: ScrollableEducationPanelButtonTapHandler = { _ in
            SessionSingleton.sharedInstance().dataStore.readingListsController.setSyncEnabled(true, shouldDeleteLocalLists: false, shouldDeleteRemoteLists: false)
            SettingsFunnel.shared.logEnableSyncPopoverSyncEnabled()
            self.presentedViewController?.dismiss(animated: true, completion: nil)
        }
        let deleteSavedArticlesFromDeviceTapHandler: ScrollableEducationPanelButtonTapHandler = { _ in
            SessionSingleton.sharedInstance().dataStore.readingListsController.setSyncEnabled(true, shouldDeleteLocalLists: true, shouldDeleteRemoteLists: false)
            SettingsFunnel.shared.logEnableSyncPopoverSyncEnabled()
            self.presentedViewController?.dismiss(animated: true, completion: nil)
        }
        
        let panelVC = AddSavedArticlesToReadingListPanelViewController(showCloseButton: false, primaryButtonTapHandler: addSavedArticlesToReadingListsTapHandler, secondaryButtonTapHandler: deleteSavedArticlesFromDeviceTapHandler, dismissHandler: nil, theme: theme)
        
        present(panelVC, animated: true, completion: nil)
    }
    
    @objc func wmf_showLoginViewController(theme: Theme, loginSuccessCompletion: (() -> Void)? = nil, loginDismissedCompletion: (() -> Void)? = nil) {
        guard let loginVC = WMFLoginViewController.wmf_initialViewControllerFromClassStoryboard() else {
            assertionFailure("Expected view controller(s) not found")
            return
        }
        loginVC.loginSuccessCompletion = loginSuccessCompletion
        loginVC.loginDismissedCompletion = loginDismissedCompletion
        loginVC.apply(theme: theme)
        present(WMFThemeableNavigationController(rootViewController: loginVC, theme: theme), animated: true)
    }
    
    @objc func wmf_showReloginFailedPanelIfNecessary(theme: Theme) {
        guard WMFAuthenticationManager.sharedInstance.hasKeychainCredentials else {
            return
        }
        
        let tryLoginAgainTapHandler: ScrollableEducationPanelButtonTapHandler = { _ in
            self.presentedViewController?.dismiss(animated: true, completion: {
                self.wmf_showLoginViewController(theme: theme)
            })
        }
        let stayLoggedOutTapHandler: ScrollableEducationPanelButtonTapHandler = { _ in
            self.presentedViewController?.dismiss(animated: true, completion: {
                self.wmf_showKeepSavedArticlesOnDevicePanelIfNecessary(triggeredBy: .logout, theme: theme) {
                    WMFAuthenticationManager.sharedInstance.logout()
                }
            })
        }
        
        let panelVC = ReLoginFailedPanelViewController(showCloseButton: false, primaryButtonTapHandler: tryLoginAgainTapHandler, secondaryButtonTapHandler: stayLoggedOutTapHandler, dismissHandler: nil, theme: theme)

        present(panelVC, animated: true, completion: nil)
    }

    @objc func wmf_showLoginOrCreateAccountToSyncSavedArticlesToReadingListPanel(theme: Theme, dismissHandler: ScrollableEducationPanelDismissHandler? = nil, loginSuccessCompletion: (() -> Void)? = nil, loginDismissedCompletion: (() -> Void)? = nil) {
        LoginFunnel.shared.logLoginImpressionInSyncPopover()
        
        let loginToSyncSavedArticlesTapHandler: ScrollableEducationPanelButtonTapHandler = { _ in
            self.presentedViewController?.dismiss(animated: true, completion: {
                self.wmf_showLoginViewController(theme: theme, loginSuccessCompletion: loginSuccessCompletion, loginDismissedCompletion: loginDismissedCompletion)
                LoginFunnel.shared.logLoginStartInSyncPopover()
            })
        }
        
        let panelVC = LoginOrCreateAccountToSyncSavedArticlesToReadingListPanelViewController(showCloseButton: true, primaryButtonTapHandler: loginToSyncSavedArticlesTapHandler, secondaryButtonTapHandler: nil, dismissHandler: dismissHandler, discardDismissHandlerOnPrimaryButtonTap: true, theme: theme)
        
        present(panelVC, animated: true)
    }
    
    @objc func wmf_showLoginToSyncSavedArticlesToReadingListPanelOncePerDevice(theme: Theme) {
        guard
            !WMFAuthenticationManager.sharedInstance.isLoggedIn &&
            !UserDefaults.wmf.wmf_didShowLoginToSyncSavedArticlesToReadingListPanel() &&
            !SessionSingleton.sharedInstance().dataStore.readingListsController.isSyncEnabled
        else {
            return
        }
        
        LoginFunnel.shared.logLoginImpressionInSyncPopover()
        
        let loginToSyncSavedArticlesTapHandler: ScrollableEducationPanelButtonTapHandler = { _ in
            self.presentedViewController?.dismiss(animated: true, completion: {
                self.wmf_showLoginViewController(theme: theme)
                LoginFunnel.shared.logLoginStartInSyncPopover()
            })
        }
        
        let panelVC = LoginToSyncSavedArticlesToReadingListPanelViewController(showCloseButton: true, primaryButtonTapHandler: loginToSyncSavedArticlesTapHandler, secondaryButtonTapHandler: nil, dismissHandler: nil, theme: theme)
        
        present(panelVC, animated: true, completion: {
            UserDefaults.wmf.wmf_setDidShowLoginToSyncSavedArticlesToReadingListPanel(true)
        })
    }
    
    @objc func wmf_showKeepSavedArticlesOnDevicePanelIfNecessary(triggeredBy keepSavedArticlesTrigger: KeepSavedArticlesTrigger, theme: Theme, completion: @escaping (() -> Swift.Void) = {}) {
        guard self.hasSavedArticles() else {
            completion()
            return
        }
        
        let keepSavedArticlesOnDeviceTapHandler: ScrollableEducationPanelButtonTapHandler = { _ in
            SessionSingleton.sharedInstance().dataStore.readingListsController.setSyncEnabled(false, shouldDeleteLocalLists: false, shouldDeleteRemoteLists: false)
            self.presentedViewController?.dismiss(animated: true, completion: nil)
        }
        let deleteSavedArticlesFromDeviceTapHandler: ScrollableEducationPanelButtonTapHandler = { _ in
            SessionSingleton.sharedInstance().dataStore.readingListsController.setSyncEnabled(false, shouldDeleteLocalLists: true, shouldDeleteRemoteLists: false)
            self.presentedViewController?.dismiss(animated: true, completion: nil)
        }
        let dismissHandler: ScrollableEducationPanelDismissHandler = {
            completion()
        }
        
        let panelVC = KeepSavedArticlesOnDevicePanelViewController(triggeredBy: keepSavedArticlesTrigger, showCloseButton: false, primaryButtonTapHandler: keepSavedArticlesOnDeviceTapHandler, secondaryButtonTapHandler: deleteSavedArticlesFromDeviceTapHandler, dismissHandler: dismissHandler, discardDismissHandlerOnPrimaryButtonTap: false, theme: theme)
        
        present(panelVC, animated: true, completion: nil)
    }
    
    @objc func wmf_showLimitHitForUnsortedArticlesPanelViewController(theme: Theme, primaryButtonTapHandler: @escaping ScrollableEducationPanelButtonTapHandler, completion: @escaping () -> Void) {
        let panelVC = LimitHitForUnsortedArticlesPanelViewController(showCloseButton: true, primaryButtonTapHandler: primaryButtonTapHandler, secondaryButtonTapHandler: nil, dismissHandler: nil, theme: theme)
        present(panelVC, animated: true, completion: completion)
    }

    @objc func wmf_showDescriptionPublishedPanelViewController(theme: Theme) {
        let doneTapHandler: ScrollableEducationPanelButtonTapHandler = { sender in
            self.dismiss(animated: true, completion: nil)
        }
        let panelVC = DescriptionPublishedPanelViewController(showCloseButton: true, primaryButtonTapHandler: doneTapHandler, secondaryButtonTapHandler: nil, dismissHandler: nil, theme: theme)
        present(panelVC, animated: true, completion: nil)
    }
}
