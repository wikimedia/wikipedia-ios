class AnnouncementPanelViewController : ScrollableEducationPanelViewController {
    
    enum Style {
        case standard
        case minimal
    }
    
    private let announcement: WMFAnnouncement
    private let style: Style

    init(announcement: WMFAnnouncement, style: Style = .standard, primaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, secondaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, footerLinkAction: ((URL) -> Void)?, traceableDismissHandler: ScrollableEducationPanelTraceableDismissHandler?, theme: Theme) {
        self.announcement = announcement
        self.style = style
        super.init(showCloseButton: false, primaryButtonTapHandler: primaryButtonTapHandler, secondaryButtonTapHandler: secondaryButtonTapHandler, traceableDismissHandler: traceableDismissHandler, theme: theme)
        isUrgent = announcement.announcementType == .fundraising
        self.footerLinkAction = footerLinkAction
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        subheadingHTML = announcement.text
        subheadingTextAlignment = style == .minimal ? .center : .natural
        primaryButtonTitle = announcement.actionTitle
        secondaryButtonTitle = announcement.negativeText
        footerHTML = announcement.captionHTML
        secondaryButtonTextStyle = .mediumFootnote
        spacing = 20
        buttonCornerRadius = 8
        buttonTopSpacing = 10
        primaryButtonTitleEdgeInsets = UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
        primaryButtonBorderWidth = 0
        dismissWhenTappedOutside = true
        contentHorizontalPadding = 20
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        evaluateConstraintsOnNewSize(view.frame.size)
    }

    private func evaluateConstraintsOnNewSize(_ size: CGSize) {
        let panelWidth = size.width * 0.9
        if style == .minimal && traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular {
            width = min(320, panelWidth)
        } else {
            width = panelWidth
        }
        
        if style == .minimal {
            //avoid scrolling on SE landscape, otherwise add a bit of padding
            let subheadingExtraTopBottomSpacing = size.height <= 320 ? 0 : CGFloat(10)
            subheadingTopConstraint.constant = originalSubheadingTopConstraint + CGFloat(subheadingExtraTopBottomSpacing)
            subheadingBottomConstraint.constant = originalSubheadingTopConstraint + CGFloat(subheadingExtraTopBottomSpacing)
        }
    }
    
    override var footerParagraphStyle: NSParagraphStyle? {
        
        guard let paragraphStyle = super.footerParagraphStyle else {
            return nil
        }
        
        return modifiedParagraphStyleFromOriginalStyle(paragraphStyle)
    }
    
    override var subheadingParagraphStyle: NSParagraphStyle? {
        
        guard let paragraphStyle = super.subheadingParagraphStyle else {
            return nil
        }
        
        return modifiedParagraphStyleFromOriginalStyle(paragraphStyle)
    }
    
    private func modifiedParagraphStyleFromOriginalStyle(_ originalStyle: NSParagraphStyle) -> NSParagraphStyle? {
        
        if let mutParagraphStyle = originalStyle.mutableCopy() as? NSMutableParagraphStyle {
            mutParagraphStyle.alignment = style == .minimal ? .center : .natural
            return mutParagraphStyle.copy() as? NSParagraphStyle
        }
        
        return originalStyle
    }
}

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
        primaryButtonTitle = WMFLocalizedString("reading-list-add-saved-button-title", value:"Yes, add them to my reading lists", comment:"Title for button to add saved articles to reading list. The question being asked is: There are articles saved to your Wikipedia app. Would you like to keep them and merge with reading lists synced to your account?")
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
        heading = WMFLocalizedString("reading-list-sync-enabled-panel-title", value: "Sync is enabled on this account", comment: "Title for panel informing user that sync was enabled on their Wikipedia account on another device")
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

class LoggedOutPanelViewController: ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage(named: "logged-out-warning")
        heading = WMFLocalizedString("logged-out-title", value: "You have been logged out", comment: "Title for education panel letting user know they have been logged out.")
        subheading = WMFLocalizedString("logged-out-subtitle", value: "There was a problem authenticating your account. In order to sync your reading lists and edit under your user name please log back in.", comment: "Subtitle for letting user know there was a problem authenticating their account.")
        primaryButtonTitle = WMFLocalizedString("logged-out-log-back-in-button-title", value: "Log back in to your account", comment: "Title for button allowing user to log back in to their account")
        secondaryButtonTitle = WMFLocalizedString("logged-out-continue-without-logging-in-button-title", value: "Continue without logging in", comment: "Title for button allowing user to continue without logging back in to their account")
    }
}

class LoginOrCreateAccountToSyncSavedArticlesToReadingListPanelViewController : ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage(named: "reading-list-user")
        heading = WMFLocalizedString("reading-list-login-or-create-account-title", value:"Log in to sync saved articles", comment:"Title for syncing saved articles.")
        subheading = CommonStrings.readingListLoginSubtitle
        primaryButtonTitle = CommonStrings.loginOrCreateAccountTitle
    }
}

class LoginOrCreateAccountToToThankRevisionAuthorPanelViewController : ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage(named: "diff-smile-heart")
        heading = WMFLocalizedString("diff-thanks-login-title", value:"Log in to send 'Thanks'", comment:"Title for thanks login panel.")
        subheading = WMFLocalizedString("diff-thanks-login-subtitle", value:"'Thanks' are an easy way to show appreciation for an editor's work on Wikipedia. You must be logged in to send 'Thanks'.", comment:"Subtitle for thanks login panel.")
        primaryButtonTitle = CommonStrings.loginOrCreateAccountTitle
        secondaryButtonTitle = CommonStrings.cancelActionTitle
    }
}

class ThankRevisionAuthorEducationPanelViewController : ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage(named: "diff-smile-heart")
        heading = WMFLocalizedString("diff-thanks-send-title", value:"Publicly send 'Thanks'", comment:"Title for sending thanks panel.")
        subheading = WMFLocalizedString("diff-thanks-send-subtitle", value:"'Thanks' are an easy way to show appreciation for an editor's work on Wikipedia. 'Thanks' cannot be undone and are publicly viewable.", comment:"Subtitle for sending thanks panel.")
        primaryButtonTitle = WMFLocalizedString("diff-thanks-send-button-title", value:"Send 'Thanks'", comment:"Title for sending thanks button.")
        secondaryButtonTitle = CommonStrings.cancelActionTitle
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
        primaryButtonTitle = CommonStrings.doneTitle
        footer = WMFLocalizedString("description-published-footer", value: "You can also edit articles within this app. Try fixing typos and small sentences by clicking on the pencil icon next time", comment: "Title for footer explaining articles may be edited too - not just descriptions.")
    }
}

class EditPublishedPanelViewController: ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage(named: "description-published")
        heading = WMFLocalizedString("edit-published", value: "Edit published", comment: "Title edit published panel letting user know their edit was saved.")
        subheading = WMFLocalizedString("edit-published-subtitle", value: "You just made Wikipedia better for everyone", comment: "Subtitle for letting users know their edit improved Wikipedia.")
        primaryButtonTitle = CommonStrings.doneTitle
    }
}

class NoInternetConnectionPanelViewController: ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage(named: "no-internet-article")
        heading = CommonStrings.noInternetConnection
        subheading = WMFLocalizedString("no-internet-connection-article-reload", value: "A newer version of this article might be available, but cannot be loaded without a connection to the internet", comment: "Subtitle for letting users know article cannot be reloaded without internet connection.")
        primaryButtonTitle = WMFLocalizedString("no-internet-connection-article-reload-button", value: "Return to last saved version", comment: "Title for button to return to last saved version of article.")
    }
}

class DiffEducationalPanelViewController: ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage(named: "panel-compare-revisions")
        heading = WMFLocalizedString("panel-compare-revisions-title", value: "Comparing revisions", comment: "Title for educational panel about comparing revisions")
        subheading = WMFLocalizedString("panel-compare-revisions-text", value: "Comparing revisions helps to show how an article has changed over time. Comparing two revisions of an article will show the difference between those revisions by highlighting any content that was changed.", comment: "Text for educational panel about comparing revisions")
        primaryButtonTitle = CommonStrings.gotItButtonTitle
    }
}

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

    func wmf_showAnnouncementPanel(announcement: WMFAnnouncement, style: AnnouncementPanelViewController.Style = .standard, primaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, secondaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, footerLinkAction: ((URL) -> Void)?, traceableDismissHandler: ScrollableEducationPanelTraceableDismissHandler?, theme: Theme) {
        let panel = AnnouncementPanelViewController(announcement: announcement, style: style, primaryButtonTapHandler: { (sender: Any) in
            primaryButtonTapHandler?(sender)
            self.dismiss(animated: true)
            // dismissHandler is called on viewDidDisappear
        }, secondaryButtonTapHandler: { (sender: Any) in
            secondaryButtonTapHandler?(sender)
            self.dismiss(animated: true)
            // dismissHandler is called on viewDidDisappear
        }, footerLinkAction: footerLinkAction
        , traceableDismissHandler: { lastAction in
            traceableDismissHandler?(lastAction)
        }, theme: theme)
        present(panel, animated: true)
    }
        
    @objc func wmf_showEnableReadingListSyncPanel(theme: Theme, oncePerLogin: Bool = false, didNotPresentPanelCompletion: (() -> Void)? = nil, dismissHandler: ScrollableEducationPanelDismissHandler? = nil) {
        if oncePerLogin {
            guard !UserDefaults.standard.wmf_didShowEnableReadingListSyncPanel() else {
                didNotPresentPanelCompletion?()
                return
            }
        }
        // SINGLETONTODO
        let dataStore = MWKDataStore.shared()
        let presenter = self.presentedViewController ?? self
        guard !isAlreadyPresenting(presenter),
              dataStore.authenticationManager.isLoggedIn,
              dataStore.readingListsController.isSyncRemotelyEnabled,
              !dataStore.readingListsController.isSyncEnabled else {
            didNotPresentPanelCompletion?()
            return
        }
        let enableSyncTapHandler: ScrollableEducationPanelButtonTapHandler = { _ in
            self.presentedViewController?.dismiss(animated: true, completion: {
                guard self.hasSavedArticles() else {
                    dataStore.readingListsController.setSyncEnabled(true, shouldDeleteLocalLists: false, shouldDeleteRemoteLists: false)
                    SettingsFunnel.shared.logEnableSyncPopoverSyncEnabled()
                    return
                }
                self.wmf_showAddSavedArticlesToReadingListPanel(theme: theme)
            })
        }
        
        let panelVC = EnableReadingListSyncPanelViewController(showCloseButton: true, primaryButtonTapHandler: enableSyncTapHandler, secondaryButtonTapHandler: nil, dismissHandler: dismissHandler, theme: theme)
        
        presenter.present(panelVC, animated: true, completion: {
            UserDefaults.standard.wmf_setDidShowEnableReadingListSyncPanel(true)
            // we don't want to present the "Sync disabled" panel if "Enable sync" was presented, wmf_didShowSyncDisabledPanel will be set to false when app is paused.
            UserDefaults.standard.wmf_setDidShowSyncDisabledPanel(true)
            SettingsFunnel.shared.logEnableSyncPopoverImpression()
        })
    }
    
    @objc func wmf_showSyncDisabledPanel(theme: Theme, wasSyncEnabledOnDevice: Bool) {
        guard !UserDefaults.standard.wmf_didShowSyncDisabledPanel(),
            wasSyncEnabledOnDevice else {
                return
        }
        let primaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler = { _ in
            self.presentedViewController?.dismiss(animated: true)
        }
        let panel = SyncDisabledPanelViewController(showCloseButton: true, primaryButtonTapHandler: primaryButtonTapHandler, secondaryButtonTapHandler: nil, dismissHandler: nil, theme: theme)
        let presenter = self.presentedViewController ?? self
        presenter.present(panel, animated: true) {
            UserDefaults.standard.wmf_setDidShowSyncDisabledPanel(true)
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
            !UserDefaults.standard.wmf_didShowSyncEnabledPanel(),
            !wasSyncEnabledOnDevice else {
                return
        }
        let primaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler = { _ in
            self.presentedViewController?.dismiss(animated: true)
        }
        let panel = SyncEnabledPanelViewController(showCloseButton: true, primaryButtonTapHandler: primaryButtonTapHandler, secondaryButtonTapHandler: nil, dismissHandler: nil, theme: theme)
        presenter.present(panel, animated: true) {
            UserDefaults.standard.wmf_setDidShowSyncEnabledPanel(true)
        }
    }
    
    fileprivate func wmf_showAddSavedArticlesToReadingListPanel(theme: Theme) {
        // SINGLETONTODO
        let dataStore = MWKDataStore.shared()
        let addSavedArticlesToReadingListsTapHandler: ScrollableEducationPanelButtonTapHandler = { _ in
            dataStore.readingListsController.setSyncEnabled(true, shouldDeleteLocalLists: false, shouldDeleteRemoteLists: false)
            SettingsFunnel.shared.logEnableSyncPopoverSyncEnabled()
            self.presentedViewController?.dismiss(animated: true, completion: nil)
        }
        let deleteSavedArticlesFromDeviceTapHandler: ScrollableEducationPanelButtonTapHandler = { _ in
            dataStore.readingListsController.setSyncEnabled(true, shouldDeleteLocalLists: true, shouldDeleteRemoteLists: false)
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

    @objc func wmf_showLoggedOutPanel(theme: Theme, dismissHandler: @escaping ScrollableEducationPanelDismissHandler) {
        let primaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler = { _ in
            self.presentedViewController?.dismiss(animated: true) {
                self.presenter?.wmf_showLoginViewController(theme: theme, loginDismissedCompletion: {
                    self.presenter?.wmf_showKeepSavedArticlesOnDevicePanelIfNeeded(triggeredBy: .logout, theme: theme)
                })
            }
        }
        let secondaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler = { _ in
            self.presentedViewController?.dismiss(animated: true) {
                self.presenter?.wmf_showKeepSavedArticlesOnDevicePanelIfNeeded(triggeredBy: .logout, theme: theme)
            }
        }
        let panelVC = LoggedOutPanelViewController(showCloseButton: false, primaryButtonTapHandler: primaryButtonTapHandler, secondaryButtonTapHandler: secondaryButtonTapHandler, dismissHandler: dismissHandler, theme: theme)

        presenter?.present(panelVC, animated: true)
    }

    private var presenter: UIViewController? {
        guard view.window == nil else {
            return self
        }
        if presentedViewController is UINavigationController {
            return presentedViewController
        }
        return nil
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

    @objc func wmf_showLoginOrCreateAccountToThankRevisionAuthorPanel(theme: Theme, dismissHandler: ScrollableEducationPanelDismissHandler? = nil, loginSuccessCompletion: (() -> Void)? = nil, loginDismissedCompletion: (() -> Void)? = nil) {

        let loginToThankTapHandler: ScrollableEducationPanelButtonTapHandler = { _ in
            self.presentedViewController?.dismiss(animated: true, completion: {
                self.wmf_showLoginViewController(theme: theme, loginSuccessCompletion: loginSuccessCompletion, loginDismissedCompletion: loginDismissedCompletion)
            })
        }
        
        let secondaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler = { _ in
            self.presentedViewController?.dismiss(animated: true)
        }
        
        let panelVC = LoginOrCreateAccountToToThankRevisionAuthorPanelViewController(showCloseButton: false, primaryButtonTapHandler: loginToThankTapHandler, secondaryButtonTapHandler: secondaryButtonTapHandler, dismissHandler: dismissHandler, discardDismissHandlerOnPrimaryButtonTap: true, theme: theme)
        
        present(panelVC, animated: true)
    }

    func wmf_showThankRevisionAuthorEducationPanel(theme: Theme, sendThanksHandler: @escaping ScrollableEducationPanelButtonTapHandler) {
        let secondaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler = { _ in
            self.presentedViewController?.dismiss(animated: true)
        }
        let panelVC = ThankRevisionAuthorEducationPanelViewController(showCloseButton: false, primaryButtonTapHandler: sendThanksHandler, secondaryButtonTapHandler: secondaryButtonTapHandler, dismissHandler: nil, discardDismissHandlerOnPrimaryButtonTap: true, theme: theme)
        present(panelVC, animated: true)
    }
    
    @objc func wmf_showLoginToSyncSavedArticlesToReadingListPanelOncePerDevice(theme: Theme) {
        // SINGLETONTODO
        let dataStore = MWKDataStore.shared()
        guard
            !dataStore.authenticationManager.isLoggedIn &&
            !UserDefaults.standard.wmf_didShowLoginToSyncSavedArticlesToReadingListPanel() &&
            !dataStore.readingListsController.isSyncEnabled
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
            UserDefaults.standard.wmf_setDidShowLoginToSyncSavedArticlesToReadingListPanel(true)
        })
    }

    @objc(wmf_showKeepSavedArticlesOnDevicePanelIfNeededTriggeredBy:theme:completion:)
    func wmf_showKeepSavedArticlesOnDevicePanelIfNeeded(triggeredBy keepSavedArticlesTrigger: KeepSavedArticlesTrigger, theme: Theme, completion: (() -> Swift.Void)? = nil) {
        guard self.hasSavedArticles() else {
            completion?()
            return
        }
        
        let keepSavedArticlesOnDeviceTapHandler: ScrollableEducationPanelButtonTapHandler = { _ in
            MWKDataStore.shared().readingListsController.setSyncEnabled(false, shouldDeleteLocalLists: false, shouldDeleteRemoteLists: false)
            self.presentedViewController?.dismiss(animated: true, completion: nil)
        }
        let deleteSavedArticlesFromDeviceTapHandler: ScrollableEducationPanelButtonTapHandler = { _ in
            MWKDataStore.shared().readingListsController.setSyncEnabled(false, shouldDeleteLocalLists: true, shouldDeleteRemoteLists: false)
            self.presentedViewController?.dismiss(animated: true, completion: nil)
        }
        let dismissHandler: ScrollableEducationPanelDismissHandler = {
            completion?()
        }
        
        let panelVC = KeepSavedArticlesOnDevicePanelViewController(triggeredBy: keepSavedArticlesTrigger, showCloseButton: false, primaryButtonTapHandler: keepSavedArticlesOnDeviceTapHandler, secondaryButtonTapHandler: deleteSavedArticlesFromDeviceTapHandler, dismissHandler: dismissHandler, discardDismissHandlerOnPrimaryButtonTap: false, theme: theme)
        
        present(panelVC, animated: true, completion: nil)
    }
    
    @objc func wmf_showLimitHitForUnsortedArticlesPanelViewController(theme: Theme, primaryButtonTapHandler: @escaping ScrollableEducationPanelButtonTapHandler, completion: @escaping () -> Void) {
        let panelVC = LimitHitForUnsortedArticlesPanelViewController(showCloseButton: true, primaryButtonTapHandler: primaryButtonTapHandler, secondaryButtonTapHandler: nil, dismissHandler: nil, theme: theme)
        present(panelVC, animated: true, completion: completion)
    }

    @objc func wmf_showDescriptionPublishedPanelViewController(theme: Theme) {
        guard !UserDefaults.standard.didShowDescriptionPublishedPanel else {
            return
        }
        let doneTapHandler: ScrollableEducationPanelButtonTapHandler = { sender in
            self.dismiss(animated: true, completion: nil)
        }
        let panelVC = DescriptionPublishedPanelViewController(showCloseButton: true, primaryButtonTapHandler: doneTapHandler, secondaryButtonTapHandler: nil, dismissHandler: nil, theme: theme)
        present(panelVC, animated: true) {
            UserDefaults.standard.didShowDescriptionPublishedPanel = true
        }
    }

    @objc func wmf_showEditPublishedPanelViewController(theme: Theme) {
        guard !UserDefaults.standard.wmf_didShowFirstEditPublishedPanel() else {
            return
        }

        let doneTapHandler: ScrollableEducationPanelButtonTapHandler = { sender in
            self.dismiss(animated: true, completion: nil)
        }
        let panelVC = EditPublishedPanelViewController(showCloseButton: false, primaryButtonTapHandler: doneTapHandler, secondaryButtonTapHandler: nil, dismissHandler: nil, theme: theme)
        present(panelVC, animated: true, completion: {
            UserDefaults.standard.wmf_setDidShowFirstEditPublishedPanel(true)
        })
    }

    @objc func wmf_showNoInternetConnectionPanelViewController(theme: Theme, primaryButtonTapHandler: @escaping ScrollableEducationPanelButtonTapHandler, completion: @escaping () -> Void) {
        let panelVC = NoInternetConnectionPanelViewController(showCloseButton: false, primaryButtonTapHandler: primaryButtonTapHandler, secondaryButtonTapHandler: nil, dismissHandler: nil, theme: theme)
        present(panelVC, animated: true, completion: completion)
    }
}
