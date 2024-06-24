import UIKit
import WMF
import SwiftUI
import Components
import WKData

extension Notification.Name {
    static let showErrorBanner = Notification.Name("WMFShowErrorBanner")
    static let showErrorBannerNSErrorKey = "nserror"
}

@objc extension NSNotification {
    public static let showErrorBanner = Notification.Name.showErrorBanner
    static let showErrorBannerNSErrorKey = Notification.Name.showErrorBannerNSErrorKey
}

extension WMFAppViewController {

    // MARK: - Language Variant Migration Alerts
    
    @objc internal func presentLanguageVariantAlerts(completion: @escaping () -> Void) {
        
        guard shouldPresentLanguageVariantAlerts else {
            completion()
            return
        }
        
        let savedLibraryVersion = UserDefaults.standard.integer(forKey: WMFLanguageVariantAlertsLibraryVersion)
        guard savedLibraryVersion < MWKDataStore.currentLibraryVersion else {
            completion()
            return
        }
        
        let languageCodesNeedingAlerts = self.dataStore.languageCodesNeedingVariantAlerts(since: savedLibraryVersion)
        guard let firstCode = languageCodesNeedingAlerts.first else {
            completion()
            return
        }
        
        self.presentVariantAlert(for: firstCode, remainingCodes: Array(languageCodesNeedingAlerts.dropFirst()), completion: completion)
            
        UserDefaults.standard.set(MWKDataStore.currentLibraryVersion, forKey: WMFLanguageVariantAlertsLibraryVersion)
    }
    
    private func presentVariantAlert(for languageCode: String, remainingCodes: [String], completion: @escaping () -> Void) {
        
        let primaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler
        let secondaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?
                
        // If there are remaining codes
        if let nextCode = remainingCodes.first {
            
            // If more to show, primary button shows next variant alert
            primaryButtonTapHandler = { _, _ in
                self.dismiss(animated: true) {
                    self.presentVariantAlert(for: nextCode, remainingCodes: Array(remainingCodes.dropFirst()), completion: completion)
                }
            }
            // And no secondary button
            secondaryButtonTapHandler = nil
            
        } else {
            // If no more to show, primary button navigates to languge settings
            primaryButtonTapHandler = { _, _ in
                self.displayPreferredLanguageSettings(completion: completion)
            }

            // And secondary button dismisses
            secondaryButtonTapHandler = { _, _ in
                self.dismiss(animated: true, completion: completion)
            }
        }
                
        let alert = LanguageVariantEducationalPanelViewController(primaryButtonTapHandler: primaryButtonTapHandler, secondaryButtonTapHandler: secondaryButtonTapHandler, dismissHandler: nil, theme: self.theme, languageCode: languageCode)
        self.present(alert, animated: true, completion: nil)
    }
    
    // Don't present over modals or navigation stacks
    // The user is deep linking in these states and we don't want to interrupt them
    private var shouldPresentLanguageVariantAlerts: Bool {
        guard presentedViewController == nil,
              let navigationController = navigationController,
              navigationController.viewControllers.count == 1 &&
                navigationController.viewControllers[0] is WMFAppViewController else {
            return false
        }
        return true
    }

    private func displayPreferredLanguageSettings(completion: @escaping () -> Void) {
        self.dismissPresentedViewControllers()
        let languagesVC = WMFPreferredLanguagesViewController.preferredLanguagesViewController()
        languagesVC.showExploreFeedCustomizationSettings = true
        languagesVC.userDismissalCompletionBlock = completion
        languagesVC.apply(self.theme)
        let navVC = WMFThemeableNavigationController(rootViewController: languagesVC, theme: theme)
        present(navVC, animated: true, completion: nil)
    }

}

// MARK: Notifications

extension WMFAppViewController: SettingsPresentationDelegate {

    public func userDidTapSettings(from viewController: UIViewController?) {
        if viewController is ExploreViewController {
            NavigationEventsFunnel.shared.logTappedSettingsFromExplore()
        }
        showSettings(animated: true)
    }

}

extension WMFAppViewController: NotificationsCenterPresentationDelegate {

    /// Perform conditional presentation logic depending on origin `UIViewController`
    public func userDidTapNotificationsCenter(from viewController: UIViewController? = nil) {
        let viewModel = NotificationsCenterViewModel(notificationsController: dataStore.notificationsController, remoteNotificationsController: dataStore.remoteNotificationsController, languageLinkController: self.dataStore.languageLinkController)
        let notificationsCenterViewController = NotificationsCenterViewController(theme: theme, viewModel: viewModel)
        navigationController?.pushViewController(notificationsCenterViewController, animated: true)
    }
}

extension WMFAppViewController {
    @objc func userDidTapPushNotification() {
        guard let topMostViewController = self.topMostViewController else {
            return
        }
        
        // If already displaying Notifications Center (or some part of it), exit early
        if let notificationsCenterFlowViewController = topMostViewController.notificationsCenterFlowViewController {
            notificationsCenterFlowViewController.tappedPushNotification()
            return
        }

        let viewModel = NotificationsCenterViewModel(notificationsController: dataStore.notificationsController, remoteNotificationsController: dataStore.remoteNotificationsController, languageLinkController: dataStore.languageLinkController)

        let notificationsCenterViewController = NotificationsCenterViewController(theme: theme, viewModel: viewModel)
        
        let dismissAndPushBlock = { [weak self] in
            self?.dismissPresentedViewControllers()
            self?.navigationController?.pushViewController(notificationsCenterViewController, animated: true)
        }

        guard let editingFlowViewController = editingFlowViewControllerInHierarchy,
            editingFlowViewController.shouldDisplayExitConfirmationAlert else {
            dismissAndPushBlock()
            return
        }
        
        presentEditorAlert(on: topMostViewController, confirmationBlock: dismissAndPushBlock)
    }
    
    var editingFlowViewControllerInHierarchy: EditingFlowViewController? {
        var currentController: UIViewController? = navigationController

        while let presentedViewController = currentController?.presentedViewController {
            if let presentedNavigationController = (presentedViewController as? UINavigationController) {
                for viewController in presentedNavigationController.viewControllers {
                    if let editingFlowViewController = viewController as? EditingFlowViewController {
                        return editingFlowViewController
                    }
                }
            } else if let editingFlowViewController = presentedViewController as? EditingFlowViewController {
                return editingFlowViewController
            }
            
            currentController = presentedViewController
        }

        return nil
    }
    
    private var topMostViewController: UIViewController? {
            
        var topViewController: UIViewController = navigationController ?? self

        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }

        return topViewController
    }
    
    private func presentEditorAlert(on viewController: UIViewController, confirmationBlock: @escaping () -> Void) {
        
        let title = CommonStrings.editorExitConfirmationTitle
        let message = CommonStrings.editorExitConfirmationBody
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let discardAction = UIAlertAction(title: CommonStrings.discardEditsActionTitle, style: .destructive) { _ in
            confirmationBlock()
        }
        let cancelAction = UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel)
        
        alertController.addAction(discardAction)
        alertController.addAction(cancelAction)
        
        viewController.present(alertController, animated: true, completion: nil)
        
    }
}

// MARK: - Watchlist

extension WMFAppViewController: WKWatchlistDelegate {

    public func emptyViewDidTapSearch() {
        NSUserActivity.wmf_navigate(to: NSUserActivity.wmf_searchView())
    }

    public func watchlistUserDidTapDiff(project: WKProject, title: String, revisionID: UInt, oldRevisionID: UInt) {
        let wikimediaProject = WikimediaProject(wkProject: project)
        guard let siteURL = wikimediaProject.mediaWikiAPIURL(configuration: .current), !(revisionID == 0 && oldRevisionID == 0) else {
            return
        }

        let diffURL: URL?

        if revisionID == 0 {
            diffURL = siteURL.wmf_URL(withPath: "/wiki/Special:MobileDiff/\(oldRevisionID)", isMobile: true)
        } else if oldRevisionID == 0 {
            diffURL = siteURL.wmf_URL(withPath: "/wiki/Special:MobileDiff/\(revisionID)", isMobile: true)
        } else {
            diffURL = siteURL.wmf_URL(withPath: "/wiki/Special:MobileDiff/\(oldRevisionID)...\(revisionID)", isMobile: true)
        }
        
        let userInfo: [AnyHashable : Any] = [RoutingUserInfoKeys.source: RoutingUserInfoSourceValue.watchlist.rawValue]

        navigate(to: diffURL, userInfo: userInfo)
    }

    public func watchlistUserDidTapUser(project: WKProject, title: String, revisionID: UInt, oldRevisionID: UInt, username: String, action: WKWatchlistUserButtonAction) {
        let wikimediaProject = WikimediaProject(wkProject: project)
        guard let siteURL = wikimediaProject.mediaWikiAPIURL(configuration: .current) else {
            return
        }

        switch action {
        case .userPage:
            navigate(to: siteURL.wmf_URL(withPath: "/wiki/User:\(username)", isMobile: true))
        case .userTalkPage:
            navigate(to: siteURL.wmf_URL(withPath: "/wiki/User_talk:\(username)", isMobile: true))
        case .userContributions:
            navigate(to: siteURL.wmf_URL(withPath: "/wiki/Special:Contributions/\(username)", isMobile: true))
        case .thank(let revisionID):
            let performThanks = {
                let diffThanker = DiffThanker()
                diffThanker.thank(siteURL: siteURL, rev: Int(revisionID), completion: { result in
                    switch result {
                    case .success:
                        let successfulThanks = WMFLocalizedString("watchlist-thanks-success", value: "Your ‘Thanks’ was sent to %@", comment: "Message displayed in a toast on successful thanking of user in Watchlist view. %@ is replaced with the user being thanked.")
                        let successMessage = String.localizedStringWithFormat(successfulThanks, username)
                        WMFAlertManager.sharedInstance.showBottomAlertWithMessage(successMessage, subtitle: nil, image: UIImage(named: "watchlist-thanks-checkmark"), type: .normal, customTypeName: nil, dismissPreviousAlerts: true)
                    case .failure(let failure):
                        WMFAlertManager.sharedInstance.showBottomAlertWithMessage(failure.localizedDescription, subtitle: nil, image: nil, type: .error, customTypeName: nil, dismissPreviousAlerts: true)
                    }
                })
            }

            if !UserDefaults.standard.wmf_didShowThankRevisionAuthorEducationPanel() {
                topMostViewController?.wmf_showThankRevisionAuthorEducationPanel(theme: theme, sendThanksHandler: { [weak self] _, _ in
                    WatchlistFunnel.shared.logThanksTapSend(project: wikimediaProject)
                    UserDefaults.standard.wmf_setDidShowThankRevisionAuthorEducationPanel(true)
                    self?.topMostViewController?.dismiss(animated: true, completion: {
                        performThanks()
                    })
                }, cancelHandler: { [weak self] _, _ in
                    WatchlistFunnel.shared.logThanksTapCancel(project: wikimediaProject)
                    self?.topMostViewController?.dismiss(animated: true)
                })
            } else {
                performThanks()
            }
        case .diff(let revId, let oldRevId):
            watchlistUserDidTapDiff(project: project, title: title, revisionID: revId, oldRevisionID: oldRevId)
        }
    }
    
    public func watchlistEmptyViewUserDidTapSearch() {
        NSUserActivity.wmf_navigate(to: NSUserActivity.wmf_searchView())
    }

    public func watchlistUserDidTapAddLanguage(from viewController: UIViewController, viewModel: WKWatchlistFilterViewModel) {
        let languagesController = WMFLanguagesViewController(nibName: "WMFLanguagesViewController", bundle: nil)
        languagesController.title = CommonStrings.wikipediaLanguages
        languagesController.apply(theme)
        languagesController.delegate = self
        languagesController.showAllLanguages = true
        languagesController.showPreferredLanguages = false
        languagesController.showNonPreferredLanguages = false

        languagesController.userLanguageSelectionBlock = { [weak self, weak viewModel] in
            guard let self = self else { return }

            // From `ViewControllerRouter`
            let dataStore = self.dataStore
            let appLanguages = dataStore.languageLinkController.preferredLanguages
            var localizedProjectNames = appLanguages.reduce(into: [WKProject: String]()) { result, language in
                guard let wikimediaProject = WikimediaProject(siteURL: language.siteURL, languageLinkController: dataStore.languageLinkController), let wkProject = wikimediaProject.wkProject else {
                    return
                }

                result[wkProject] = wikimediaProject.projectName(shouldReturnCodedFormat: false)
            }
            localizedProjectNames[.wikidata] = WikimediaProject.wikidata.projectName(shouldReturnCodedFormat: false)
            localizedProjectNames[.commons] = WikimediaProject.commons.projectName(shouldReturnCodedFormat: false)

            viewModel?.reloadWikipedias(localizedProjectNames: localizedProjectNames)
        }

        let navigationController = WMFThemeableNavigationController(rootViewController: languagesController, theme: theme)
        viewController.present(navigationController, animated: true)
    }

}

extension WMFAppViewController: WMFLanguagesViewControllerDelegate {

    public func languagesController(_ controller: WMFLanguagesViewController, didSelectLanguage language: MWKLanguageLink) {
        dataStore.languageLinkController.appendPreferredLanguage(language)
        controller.userLanguageSelectionBlock?()
        controller.dismiss(animated: true)
    }

}

extension WMFAppViewController: WKWatchlistLoggingDelegate {
    public func logWatchlistDidLoad(itemCount: Int) {
        WatchlistFunnel.shared.logWatchlistLoaded(itemCount: itemCount)
    }
    
    public func logWatchlistUserDidTapNavBarFilterButton() {
        WatchlistFunnel.shared.logOpenFilterSettings()
    }
    
    public func logWatchlistUserDidSaveFilterSettings(filterSettings: WKWatchlistFilterSettings, onProjects: [WKProject]) {
        
        // Projects
        let commonsAndWikidataProjects: WatchlistFunnel.FilterEnabledList.Projects?
        
        if onProjects.contains(.commons) && onProjects.contains(.wikidata) {
            commonsAndWikidataProjects = .both
        } else if onProjects.contains(.commons) && onProjects.contains(.commons) {
            commonsAndWikidataProjects = .commons
        } else if onProjects.contains(.wikidata) {
            commonsAndWikidataProjects = .wikidata
        } else {
            commonsAndWikidataProjects = nil
        }
        
        // Wikis
        let wikipediaProjects = onProjects.map { WikimediaProject(wkProject: $0) }.filter {
            switch $0 {
            case .wikipedia: return true
            default: return false
            }
        }
        
        let wikiIdentifiers = wikipediaProjects.map { $0.notificationsApiWikiIdentifier }
        
        // Latest
        let latest: WatchlistFunnel.FilterEnabledList.Latest
        switch filterSettings.latestRevisions {
        case .notTheLatestRevision:
            latest = .notLatest
        case .latestRevision:
            latest = .latest
        }
        
        // Activity
        let activity: WatchlistFunnel.FilterEnabledList.Activity
        switch filterSettings.activity {
        case .all:
            activity = .all
        case .seenChanges:
            activity = .seen
        case .unseenChanges:
            activity = .unseen
        }
        
        // Automated
        let automated: WatchlistFunnel.FilterEnabledList.Automated
        switch filterSettings.automatedContributions {
        case .all:
            automated = .all
        case .bot:
            automated = .bot
        case .human:
            automated = .nonBot
        }
        
        // Significance
        let significance: WatchlistFunnel.FilterEnabledList.Significance
        switch filterSettings.significance {
        case .all:
            significance = .all
        case .minorEdits:
            significance = .minor
        case .nonMinorEdits:
            significance = .nonMinor
        }
        
        // User Registration
        let userRegistration: WatchlistFunnel.FilterEnabledList.UserRegistration
        switch filterSettings.userRegistration {
        case .all:
            userRegistration = .all
        case .registered:
            userRegistration = .registered
        case .unregistered:
            userRegistration = .unregistered
        }
        
        // Type Change
        var onTypeChanges: [WatchlistFunnel.FilterEnabledList.TypeChange] = []
        for changeType in WKWatchlistFilterSettings.ChangeType.allCases {
            if !filterSettings.offTypes.contains(changeType) {
                switch changeType {
                case .categoryChanges: onTypeChanges.append(.categoryChanges)
                case .loggedActions: onTypeChanges.append(.logActions)
                case .pageCreations: onTypeChanges.append(.pageCreations)
                case .pageEdits: onTypeChanges.append(.pageEdits)
                case .wikidataEdits: onTypeChanges.append(.wikidataEdits)
                }
            }
        }
        
        let filterEnabledList = WatchlistFunnel.FilterEnabledList(projects: commonsAndWikidataProjects, wikis: wikiIdentifiers, latest: latest, activity: activity, automated: automated, significance: significance, userRegistration: userRegistration, typeChange: onTypeChanges)
        
        WatchlistFunnel.shared.logSaveFilterSettings(filterEnabledList: filterEnabledList)
    }
    
    public func logWatchlistEmptyViewDidShow(type: WKEmptyViewStateType) {
        switch type {
        case .noItems: WatchlistFunnel.shared.logWatchlistSawEmptyStateNoFilters()
        case .filter: WatchlistFunnel.shared.logWatchlistSawEmptyStateWithFilters()
        }
    }
    
    public func logWatchlistEmptyViewUserDidTapSearch() {
        WatchlistFunnel.shared.logWatchlistEmptyStateTapSearch()
    }
    
    public func logWatchlistEmptyViewUserDidTapModifyFilters() {
        WatchlistFunnel.shared.logWatchlistEmptyStateTapModifyFilters()
    }
    
    public func logWatchlistUserDidTapUserButton(project: WKData.WKProject) {
        
        let wikimediaProject = WikimediaProject(wkProject: project)
        WatchlistFunnel.shared.logTapUserMenu(project: wikimediaProject)
    }
    
    public func logWatchlistUserDidTapUserButtonAction(project: WKData.WKProject, action: Components.WKWatchlistUserButtonAction) {
        
        let wikimediaProject = WikimediaProject(wkProject: project)

        switch action {
        case .userPage:
            WatchlistFunnel.shared.logTapUserPage(project: wikimediaProject)
        case .userTalkPage:
            WatchlistFunnel.shared.logTapUserTalk(project: wikimediaProject)
        case .userContributions:
            WatchlistFunnel.shared.logTapUserContributions(project: wikimediaProject)
        case .thank:
            WatchlistFunnel.shared.logTapUserThank(project: wikimediaProject)
        case .diff:
            break
        }
    }
    
    
}

fileprivate extension UIViewController {
    
    /// Returns self or embedded view controller (if self is a UINavigationController) if conforming to NotificationsCenterFlowViewController
    /// Does not consider presenting view controllers
    var notificationsCenterFlowViewController: NotificationsCenterFlowViewController? {
        
        if let viewController = self as? NotificationsCenterFlowViewController {
            return viewController
        }
        
        if let navigationController = self as? UINavigationController,
           let viewController = navigationController.viewControllers.last as? NotificationsCenterFlowViewController {
            return viewController
        }

        return nil
    }
}


/// View Controllers that have an editing element (Editor flow, User talk pages, Article description editor)
protocol EditingFlowViewController where Self: UIViewController {
    var shouldDisplayExitConfirmationAlert: Bool { get }
}

extension EditingFlowViewController {
    var shouldDisplayExitConfirmationAlert: Bool {
        return true
    }
}

/// View Controllers that are a part of the Notifications Center flow
protocol NotificationsCenterFlowViewController where Self: UIViewController {
    
    // hook called after the user taps a push notification while in the foregound.
    // use if needed to tweak the view hierarchy to display the Notifications Center
    func tappedPushNotification()
}

// MARK: Importing Reading Lists - CreateReadingListDelegate

extension WMFAppViewController: CreateReadingListDelegate {
    func createReadingListViewController(_ createReadingListViewController: CreateReadingListViewController, didCreateReadingListWith name: String, description: String?, articles: [WMFArticle]) {
        
        guard !articles.isEmpty else {
            WMFAlertManager.sharedInstance.showErrorAlert(ImportReadingListError.missingArticles, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            return
        }

        do {
            createReadingListViewController.createReadingListButton.isEnabled = false
            let readingList = try dataStore.readingListsController.createReadingList(named: name, description: description, with: articles)
            ReadingListsFunnel.shared.logCompletedImport(articlesCount: articles.count)
            showImportedReadingList(readingList)

        } catch let error {
            switch error {
            case let readingListError as ReadingListError where readingListError == .listExistsWithTheSameName:
                createReadingListViewController.handleReadingListNameError(readingListError)
            default:
                WMFAlertManager.sharedInstance.showErrorAlert(error, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
                createReadingListViewController.createReadingListButton.isEnabled = true
            }
        }
    }
    
    @objc func setWKAppEnvironmentTheme(theme: Theme, traitCollection: UITraitCollection) {
        let wkTheme: WKTheme
        switch theme.name {
        case "light":
            wkTheme = WKTheme.light
        case "sepia":
            wkTheme = WKTheme.sepia
        case "dark":
            wkTheme = WKTheme.dark
        case "black":
            wkTheme = WKTheme.black
        default:
            wkTheme = WKTheme.light
        }
        WKAppEnvironment.current.set(theme: wkTheme, traitCollection: traitCollection)
    }
}

// MARK: WKData setup

extension WMFAppViewController {
    @objc func setupWKDataEnvironment() {
        WKDataEnvironment.current.mediaWikiService = MediaWikiFetcher(session: dataStore.session, configuration: dataStore.configuration)
        
        switch Configuration.current.environment {
        case .staging:
            WKDataEnvironment.current.serviceEnvironment = .staging
        default:
            WKDataEnvironment.current.serviceEnvironment = .production
        }
        
        WKDataEnvironment.current.userAgentUtility = {
            return WikipediaAppUtils.versionedUserAgent()
        }
        
        WKDataEnvironment.current.appInstallIDUtility = {
            return UserDefaults.standard.wmf_appInstallId
        }
        
        WKDataEnvironment.current.acceptLanguageUtility = {
            return Locale.acceptLanguageHeaderForPreferredLanguages
        }
        
        WKDataEnvironment.current.sharedCacheStore = SharedContainerCacheStore()
        
        let languages = dataStore.languageLinkController.preferredLanguages.map { WKLanguage(languageCode: $0.languageCode, languageVariantCode: $0.languageVariantCode) }
        WKDataEnvironment.current.appData = WKAppData(appLanguages: languages)
    }
    
    @objc func updateWKDataEnvironmentFromLanguagesDidChange() {
        let languages = dataStore.languageLinkController.preferredLanguages.map { WKLanguage(languageCode: $0.languageCode, languageVariantCode: $0.languageVariantCode) }
        WKDataEnvironment.current.appData = WKAppData(appLanguages: languages)
    }
}

// MARK: Components App Environment
extension WMFAppViewController {

    @objc func appEnvironmentDidChange(theme: Theme, traitCollection: UITraitCollection) {
        let wkTheme = Theme.wkTheme(from: theme)
        WKAppEnvironment.current.set(theme: wkTheme, traitCollection: traitCollection)
    }

}
