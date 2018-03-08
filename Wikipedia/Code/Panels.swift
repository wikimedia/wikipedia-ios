
class EnableReadingListSyncPanelViewController : ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage.init(named: "reading-list-syncing")
        heading = WMFLocalizedString("reading-list-sync-enable-title", value:"Turn on reading list syncing?", comment:"Title describing reading list syncing.")
        subheading = WMFLocalizedString("reading-list-sync-enable-subtitle", value:"Your saved articles and reading lists can now be saved to your Wikipedia account and synced across devices.", comment:"Subtitle describing reading list syncing.")
        primaryButtonTitle = WMFLocalizedString("reading-list-sync-enable-button-title", value:"Enable syncing", comment:"Title for button enabling reading list syncing.")
    }
}

class AddSavedArticlesToReadingListPanelViewController : ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage.init(named: "reading-list-saved")
        heading = WMFLocalizedString("reading-list-add-saved-title", value:"Saved articles found", comment:"Title explaining saved articles were found.")
        subheading = WMFLocalizedString("reading-list-add-saved-subtitle", value:"There are articles saved to your Wikipedia app. Would you like to keep them and merge with reading lists synced to your account?", comment:"Subtitle explaining that saved articles can be added to reading lists.")
        primaryButtonTitle = WMFLocalizedString("reading-list-add-saved-button-title", value:"Yes, add them to my reading lists", comment:"Title for button to add saved articles to reading list.")
        secondaryButtonTitle = CommonStrings.readingListDoNotKeepSubtitle
    }
}

class LoginToSyncSavedArticlesToReadingListPanelViewController : ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage.init(named: "reading-list-login")
        heading = WMFLocalizedString("reading-list-login-title", value:"Sync your saved articles?", comment:"Title for syncing save articles.")
        subheading = CommonStrings.readingListLoginSubtitle
        primaryButtonTitle = CommonStrings.readingListLoginButtonTitle
    }
}

class KeepSavedArticlesOnDevicePanelViewController : ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage.init(named: "reading-list-saved")
        heading = WMFLocalizedString("reading-list-keep-title", value:"Keep saved articles on device?", comment:"Title for keeping save articles on device.")
        subheading = WMFLocalizedString("reading-list-keep-subtitle", value:"There are articles synced to your Wikipedia account. Would you like to keep them on this device after you log out?", comment:"Subtitle asking if synced articles should be kept on device after logout.")
        primaryButtonTitle = WMFLocalizedString("reading-list-keep-button-title", value:"Yes, keep articles on device", comment:"Title for button to keep synced articles on device.")
        secondaryButtonTitle = CommonStrings.readingListDoNotKeepSubtitle
    }
}

class EnableLocationPanelViewController : ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage.init(named: "places-auth-arrow")
        heading = CommonStrings.localizedEnableLocationTitle
        primaryButtonTitle = CommonStrings.localizedEnableLocationButtonTitle
        footer = CommonStrings.localizedEnableLocationDescription
    }
}

class ReLoginFailedPanelViewController : ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage.init(named: "relogin-failed")
        heading = WMFLocalizedString("relogin-failed-title", value:"Unable to re-establish log in", comment:"Title for letting user know they are no longer logged in.")
        subheading = WMFLocalizedString("relogin-failed-subtitle", value:"Your session may have expired or previous log in credentials are no longer valid.", comment:"Subtitle for letting user know they are no longer logged in.")
        primaryButtonTitle = WMFLocalizedString("relogin-failed-retry-login-button-title", value:"Try to log in again", comment:"Title for button to let user attempt to log in again.")
        secondaryButtonTitle = WMFLocalizedString("relogin-failed-stay-logged-out-button-title", value:"Keep me logged out", comment:"Title for button for user to choose to remain logged out.")
    }
}

class LoginOrCreateAccountToSyncSavedArticlesToReadingListPanelViewController : ScrollableEducationPanelViewController {
    private var tappedPrimaryButton: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage.init(named: "reading-list-user")
        heading = WMFLocalizedString("reading-list-login-or-create-account-title", value:"Log in to sync saved articles", comment:"Title for syncing save articles.")
        subheading = CommonStrings.readingListLoginSubtitle
        primaryButtonTitle = WMFLocalizedString("reading-list-login-or-create-account-button-title", value:"Log in or create account", comment:"Title for button to login or create account to sync saved articles and reading lists.")
    }
    
    override func primaryButtonTapped(_ sender: Any) {
        tappedPrimaryButton = true
        super.primaryButtonTapped(sender)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        guard !tappedPrimaryButton else {
            return
        }
        super.viewWillDisappear(animated)
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
    
    fileprivate func present<T: UIViewController & Themeable>(_ viewControllerToPresent: T, with theme: Theme, animated flag: Bool, completion: (() -> Swift.Void)? = nil) {
        viewControllerToPresent.apply(theme: theme)
        present(viewControllerToPresent, animated: flag, completion: completion)
    }
    
    @objc func wmf_showEnableReadingListSyncPanelOncePerLogin(theme: Theme) {
        guard !UserDefaults.wmf_userDefaults().wmf_didShowEnableReadingListSyncPanel(),
            SessionSingleton.sharedInstance().dataStore.readingListsController.isSyncRemotelyEnabled,
            !SessionSingleton.sharedInstance().dataStore.readingListsController.isSyncEnabled else {
            return
        }
        
        let enableSyncTapHandler: ScrollableEducationPanelButtonTapHandler = { _ in
            self.presentedViewController?.dismiss(animated: true, completion: {
                guard self.hasSavedArticles() else {
                    SessionSingleton.sharedInstance().dataStore.readingListsController.setSyncEnabled(true, shouldDeleteLocalLists: false, shouldDeleteRemoteLists: false)
                    return
                }
                self.wmf_showAddSavedArticlesToReadingListPanel(theme: theme)
            })
        }
        
        let panelVC = EnableReadingListSyncPanelViewController(showCloseButton: true, primaryButtonTapHandler: enableSyncTapHandler, secondaryButtonTapHandler: nil, dismissHandler: nil)
        
        present(panelVC, with: theme, animated: true, completion: {
            UserDefaults.wmf_userDefaults().wmf_setDidShowEnableReadingListSyncPanel(true)
        })
    }
    
    fileprivate func wmf_showAddSavedArticlesToReadingListPanel(theme: Theme) {
        let addSavedArticlesToReadingListsTapHandler: ScrollableEducationPanelButtonTapHandler = { _ in
            SessionSingleton.sharedInstance().dataStore.readingListsController.setSyncEnabled(true, shouldDeleteLocalLists: false, shouldDeleteRemoteLists: false)
            self.presentedViewController?.dismiss(animated: true, completion: nil)
        }
        let deleteSavedArticlesFromDeviceTapHandler: ScrollableEducationPanelButtonTapHandler = { _ in
            SessionSingleton.sharedInstance().dataStore.readingListsController.setSyncEnabled(true, shouldDeleteLocalLists: true, shouldDeleteRemoteLists: false)
            self.presentedViewController?.dismiss(animated: true, completion: nil)
        }
        
        let panelVC = AddSavedArticlesToReadingListPanelViewController(showCloseButton: false, primaryButtonTapHandler: addSavedArticlesToReadingListsTapHandler, secondaryButtonTapHandler: deleteSavedArticlesFromDeviceTapHandler, dismissHandler: nil)
        
        present(panelVC, with: theme, animated: true, completion: nil)
    }
    
    @objc func wmf_showLoginViewController(theme: Theme, enableSync: Bool = false) {
        guard let loginVC = WMFLoginViewController.wmf_initialViewControllerFromClassStoryboard() else {
            assertionFailure("Expected view controller(s) not found")
            return
        }
        if enableSync {
            loginVC.enableSyncOnLogin = enableSync
        }
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
                self.wmf_showKeepSavedArticlesOnDevicePanelIfNecessary(theme: theme, completion: {
                    WMFAuthenticationManager.sharedInstance.logout()
                })
            })
        }
        
        let panelVC = ReLoginFailedPanelViewController(showCloseButton: false, primaryButtonTapHandler: tryLoginAgainTapHandler, secondaryButtonTapHandler: stayLoggedOutTapHandler, dismissHandler: nil)

        present(panelVC, with: theme, animated: true, completion: nil)
    }

    @objc func wmf_showLoginOrCreateAccountToSyncSavedArticlesToReadingListPanel(theme: Theme) {
        let loginToSyncSavedArticlesTapHandler: ScrollableEducationPanelButtonTapHandler = { _ in
            self.presentedViewController?.dismiss(animated: true, completion: {
                self.wmf_showLoginViewController(theme: theme)
            })
        }
        
        let panelVC = LoginOrCreateAccountToSyncSavedArticlesToReadingListPanelViewController(showCloseButton: true, primaryButtonTapHandler: loginToSyncSavedArticlesTapHandler, secondaryButtonTapHandler: nil, dismissHandler: nil)
        
        present(panelVC, with: theme, animated: true, completion: nil)
    }
    
    @objc func wmf_showLoginToSyncSavedArticlesToReadingListPanelOncePerDevice(theme: Theme) {
        guard
            WMFAuthenticationManager.sharedInstance.loggedInUsername == nil &&
            !UserDefaults.wmf_userDefaults().wmf_didShowLoginToSyncSavedArticlesToReadingListPanel() &&
            !SessionSingleton.sharedInstance().dataStore.readingListsController.isSyncEnabled
        else {
            return
        }
        
        let loginToSyncSavedArticlesTapHandler: ScrollableEducationPanelButtonTapHandler = { _ in
            self.presentedViewController?.dismiss(animated: true, completion: {
                self.wmf_showLoginViewController(theme: theme)
            })
        }
        
        let panelVC = LoginToSyncSavedArticlesToReadingListPanelViewController(showCloseButton: true, primaryButtonTapHandler: loginToSyncSavedArticlesTapHandler, secondaryButtonTapHandler: nil, dismissHandler: nil)
        
        present(panelVC, with: theme, animated: true, completion: {
            UserDefaults.wmf_userDefaults().wmf_setDidShowLoginToSyncSavedArticlesToReadingListPanel(true)
        })
    }
    
    @objc func wmf_showKeepSavedArticlesOnDevicePanelIfNecessary(theme: Theme, completion: @escaping (() -> Swift.Void) = {}) {
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
        
        let panelVC = KeepSavedArticlesOnDevicePanelViewController(showCloseButton: false, primaryButtonTapHandler: keepSavedArticlesOnDeviceTapHandler, secondaryButtonTapHandler: deleteSavedArticlesFromDeviceTapHandler, dismissHandler: dismissHandler)
        
        present(panelVC, with: theme, animated: true, completion: nil)
    }
}
