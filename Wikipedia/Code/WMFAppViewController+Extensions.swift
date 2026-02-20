import UIKit
import WMF
import SwiftUI
import WMFComponents
import WMFData
import CocoaLumberjackSwift

extension Notification.Name {
    static let showErrorBanner = Notification.Name("WMFShowErrorBanner")
    static let showErrorBannerNSErrorKey = "nserror"
}

@objc extension NSNotification {
    public static let showErrorBanner = Notification.Name.showErrorBanner
    static let showErrorBannerNSErrorKey = Notification.Name.showErrorBannerNSErrorKey
}

@objc public enum AppTab: Int {
    case main = 0
    case places = 1
    case saved = 2
    case activity = 3
    case search = 4
}

extension WMFAppViewController {
    
    @objc internal func processLinkUserActivity(_ userActivity: NSUserActivity) -> Bool {
        
        guard let linkURL = userActivity.wmf_linkURL() else {
            return false
        }
        
        guard let navigationController = self.currentNavigationController else {
            return false
        }
        
        let linkCoordinator = LinkCoordinator(navigationController: navigationController, url: linkURL, dataStore: dataStore, theme: theme, articleSource: .external_link, tabConfig: .appendArticleAndAssignNewTabAndSetToCurrent)
        return linkCoordinator.start()
    }

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
              let navigationController = currentTabNavigationController,
              navigationController.viewControllers.count == 1 else {
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
        let navVC = WMFComponentNavigationController(rootViewController: languagesVC, modalPresentationStyle: .overFullScreen)
        present(navVC, animated: true, completion: nil)
    }
}

// MARK: - Notifications

extension WMFAppViewController: NotificationsCenterPresentationDelegate {

    /// Perform conditional presentation logic depending on origin `UIViewController`
    public func userDidTapNotificationsCenter(from viewController: UIViewController? = nil) {
        let viewModel = NotificationsCenterViewModel(notificationsController: dataStore.notificationsController, remoteNotificationsController: dataStore.remoteNotificationsController, languageLinkController: self.dataStore.languageLinkController)
        let notificationsCenterViewController = NotificationsCenterViewController(theme: theme, viewModel: viewModel)
        
        currentTabNavigationController?.pushViewController(notificationsCenterViewController, animated: true)
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
            self?.currentTabNavigationController?.pushViewController(notificationsCenterViewController, animated: true)
        }

        guard let editingFlowViewController = editingFlowViewControllerInHierarchy,
            editingFlowViewController.shouldDisplayExitConfirmationAlert else {
            dismissAndPushBlock()
            return
        }
        
        presentEditorAlert(on: topMostViewController, confirmationBlock: dismissAndPushBlock)
    }
    
    var editingFlowViewControllerInHierarchy: EditingFlowViewController? {
        var currentController: UIViewController? = currentTabNavigationController

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
    
    @objc var currentTabNavigationController: WMFComponentNavigationController? {
        if let componentNavVC = selectedViewController as? WMFComponentNavigationController {
            return componentNavVC
        }
        
        return nil
    }
    
    private var topMostViewController: UIViewController? {
            
        var topViewController: UIViewController = currentTabNavigationController ?? self

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
    
    @objc func showRandomArticleFromShortcut(siteURL: URL?, animated: Bool) {
        guard let navVC = currentTabNavigationController else { return }
        let coordinator = RandomArticleCoordinator(navigationController: navVC, articleURL: nil, siteURL: siteURL, dataStore: dataStore, theme: theme, source: .undefined, animated: animated)
        coordinator.start()
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

// MARK: - Watchlist

extension WMFAppViewController: WMFWatchlistDelegate {

    public func emptyViewDidTapSearch() {
        NSUserActivity.wmf_navigate(to: NSUserActivity.wmf_searchView())
    }

    public func watchlistUserDidTapDiff(project: WMFProject, title: String, revisionID: UInt, oldRevisionID: UInt) {
        let wikimediaProject = WikimediaProject(wmfProject: project)
        guard let siteURL = wikimediaProject.mediaWikiAPIURL(configuration: .current), !(revisionID == 0 && oldRevisionID == 0) else {
            return
        }

        let diffURL: URL?

        if revisionID == 0 {
            diffURL = siteURL.wmf_URL(withPath: "/wiki/Special:MobileDiff/\(oldRevisionID)")
        } else if oldRevisionID == 0 {
            diffURL = siteURL.wmf_URL(withPath: "/wiki/Special:MobileDiff/\(revisionID)")
        } else {
            diffURL = siteURL.wmf_URL(withPath: "/wiki/Special:MobileDiff/\(oldRevisionID)...\(revisionID)")
        }
        
        let userInfo: [AnyHashable : Any] = [RoutingUserInfoKeys.source: RoutingUserInfoSourceValue.watchlist.rawValue]

        navigate(to: diffURL, userInfo: userInfo)
    }

    public func watchlistUserDidTapUser(project: WMFProject, title: String, revisionID: UInt, oldRevisionID: UInt, username: String, action: WMFWatchlistUserButtonAction) {
        let wikimediaProject = WikimediaProject(wmfProject: project)
        guard let siteURL = wikimediaProject.mediaWikiAPIURL(configuration: .current) else {
            return
        }

        switch action {
        case .userPage:
            navigate(to: siteURL.wmf_URL(withPath: "/wiki/User:\(username)"))
        case .userTalkPage:
            navigate(to: siteURL.wmf_URL(withPath: "/wiki/User_talk:\(username)"))
        case .userContributions:
            navigate(to: siteURL.wmf_URL(withPath: "/wiki/Special:Contributions/\(username)"))
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

    public func watchlistUserDidTapAddLanguage(from viewController: UIViewController, viewModel: WMFWatchlistFilterViewModel) {
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
            var localizedProjectNames = appLanguages.reduce(into: [WMFProject: String]()) { result, language in
                guard let wikimediaProject = WikimediaProject(siteURL: language.siteURL, languageLinkController: dataStore.languageLinkController), let wmfProject = wikimediaProject.wmfProject else {
                    return
                }

                result[wmfProject] = wikimediaProject.projectName(shouldReturnCodedFormat: false)
            }
            localizedProjectNames[.wikidata] = WikimediaProject.wikidata.projectName(shouldReturnCodedFormat: false)
            localizedProjectNames[.commons] = WikimediaProject.commons.projectName(shouldReturnCodedFormat: false)

            viewModel?.reloadWikipedias(localizedProjectNames: localizedProjectNames)
        }

        let navigationController = WMFComponentNavigationController(rootViewController: languagesController, modalPresentationStyle: .overFullScreen)
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

extension WMFAppViewController: WMFWatchlistLoggingDelegate {
    public func logWatchlistDidLoad(itemCount: Int) {
        WatchlistFunnel.shared.logWatchlistLoaded(itemCount: itemCount)
    }
    
    public func logWatchlistUserDidTapNavBarFilterButton() {
        WatchlistFunnel.shared.logOpenFilterSettings()
    }
    
    public func logWatchlistUserDidSaveFilterSettings(filterSettings: WMFWatchlistFilterSettings, onProjects: [WMFProject]) {
        
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
        let wikipediaProjects = onProjects.map { WikimediaProject(wmfProject: $0) }.filter {
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
        for changeType in WMFWatchlistFilterSettings.ChangeType.allCases {
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
    
    public func logWatchlistEmptyViewDidShow(type: WMFEmptyViewStateType) {
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
    
    public func logWatchlistUserDidTapUserButton(project: WMFData.WMFProject) {
        
        let wikimediaProject = WikimediaProject(wmfProject: project)
        WatchlistFunnel.shared.logTapUserMenu(project: wikimediaProject)
    }
    
    public func logWatchlistUserDidTapUserButtonAction(project: WMFData.WMFProject, action: WMFComponents.WMFWatchlistUserButtonAction) {
        
        let wikimediaProject = WikimediaProject(wmfProject: project)

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
    
    @objc func setWMFAppEnvironmentTheme(theme: Theme, traitCollection: UITraitCollection) {
        let wmfTheme: WMFTheme
        switch theme.name {
        case "light":
            wmfTheme = WMFTheme.light
        case "sepia":
            wmfTheme = WMFTheme.sepia
        case "dark":
            wmfTheme = WMFTheme.dark
        case "black":
            wmfTheme = WMFTheme.black
        default:
            wmfTheme = WMFTheme.light
        }
        WMFAppEnvironment.current.set(theme: wmfTheme, traitCollection: traitCollection)
    }
}

// MARK: WMFData setup

extension WMFAppViewController {
    
    @objc func setupWMFDataCoreDataStore() {
        WMFDataEnvironment.current.appContainerURL = FileManager.default.wmf_containerURL()
        
        Task(priority: .userInitiated) {
            do {
                WMFDataEnvironment.current.coreDataStore = try await WMFCoreDataStore()
                await self.migrateSavedArticleInfoWithBackgroundTask()
            } catch let error {
                DDLogError("Error setting up WMFCoreDataStore: \(error)")
            }
        }
    }

    private func migrateSavedArticleInfoWithBackgroundTask() async {

        var bgTask: UIBackgroundTaskIdentifier = .invalid
        bgTask = UIApplication.shared.beginBackgroundTask(withName: "WMFDataMigration") {
            if bgTask != .invalid {
                UIApplication.shared.endBackgroundTask(bgTask)
                bgTask = .invalid
            }
        }

        await WMFArticleSavedStateMigrationManager.shared.migrateAllIfNeeded()

        if bgTask != .invalid {
            UIApplication.shared.endBackgroundTask(bgTask)
            bgTask = .invalid
        }
    }

    @objc func setupWMFDataEnvironment() {
        WMFDataEnvironment.current.mediaWikiService = MediaWikiFetcher(session: dataStore.session, configuration: dataStore.configuration)
        
        switch Configuration.current.environment {
        case .staging:
            WMFDataEnvironment.current.serviceEnvironment = .staging
        default:
            WMFDataEnvironment.current.serviceEnvironment = .production
        }
        
        WMFDataEnvironment.current.userAgentUtility = {
            return WikipediaAppUtils.versionedUserAgent()
        }
        
        WMFDataEnvironment.current.appInstallIDUtility = {
            return UserDefaults.standard.wmf_appInstallId
        }
        
        WMFDataEnvironment.current.acceptLanguageUtility = {
            return Locale.acceptLanguageHeaderForPreferredLanguages
        }
        
        WMFDataEnvironment.current.sharedCacheStore = SharedContainerCacheStore()
        
        let languages = dataStore.languageLinkController.preferredLanguages.map { WMFLanguage(languageCode: $0.languageCode, languageVariantCode: $0.languageVariantCode) }
        WMFDataEnvironment.current.appData = WMFAppData(appLanguages: languages)
    }
    
    @objc func updateWMFDataEnvironmentFromLanguagesDidChange() {
        let languages = dataStore.languageLinkController.preferredLanguages.map { WMFLanguage(languageCode: $0.languageCode, languageVariantCode: $0.languageVariantCode) }
        WMFDataEnvironment.current.appData = WMFAppData(appLanguages: languages)
    }
    
    @objc func performWMFDataHousekeeping() {
        let coreDataStore = WMFDataEnvironment.current.coreDataStore
        Task {
            do {
                try await coreDataStore?.performDatabaseHousekeeping()
            } catch {
                DDLogError("Error pruning WMFData database: \(error)")
            }
        }
    }
    
    @objc func deleteYearInReviewPersonalizedNetworkData() {
        Task {
            do {
                let yirDataController = try WMFYearInReviewDataController()
                try await yirDataController.deleteAllPersonalizedNetworkData()
            } catch {
                DDLogError("Failure deleting personalized editing data from year in review: \(error)")
            }
        }
    }
}

// MARK: WMFComponents App Environment Helpers
extension WMFAppViewController {

    @objc func updateAppEnvironment(theme: Theme, traitCollection: UITraitCollection) {
        let wmfTheme = Theme.wmfTheme(from: theme)
        WMFAppEnvironment.current.set(theme: wmfTheme, traitCollection: traitCollection)
    }
    
    @objc func appEnvironmentTraitCollectionIsDifferentThanTraitCollection(_ traitCollection: UITraitCollection) -> Bool {
        return WMFAppEnvironment.current.traitCollection.hasDifferentColorAppearance(comparedTo: traitCollection)
    }

}

// MARK: - Tabs

 extension WMFAppViewController {
     
     @objc func assignMoreDynamicTabsV2ExperimentIfNeeded() {
         ArticleTabsFunnel.shared.logGroupAssignment(group: "dynamic_c")
     }
     
     @objc func observeArticleTabsNSNotifications() {
              NotificationCenter.default.addObserver(self, selector: #selector(articleTabDeleted(_:)), name: WMFNSNotification.articleTabDeleted, object: nil)
         NotificationCenter.default.addObserver(self, selector: #selector(articleTabItemDeleted(_:)), name: WMFNSNotification.articleTabItemDeleted, object: nil)
          }
          
      @objc func articleTabDeleted(_ note: Notification) {
          guard
             let tabIdentifier = note.userInfo?[WMFNSNotification.UserInfoKey.articleTabIdentifier] as? UUID
          else {
              return
          }
          
          DispatchQueue.main.async {
              self.removeArticlesForDeletedTabParts(tabIdentifier: tabIdentifier)
          }
      }
     
     @objc func articleTabItemDeleted(_ note: Notification) {
         guard
            let tabItemIdentifier = note.userInfo?[WMFNSNotification.UserInfoKey.articleTabItemIdentifier] as? UUID
         else {
             return
         }
         
         DispatchQueue.main.async {
             self.removeArticlesForDeletedTabParts(tabItemIdentifier: tabItemIdentifier)
         }
     }
     
     func removeArticlesForDeletedTabParts(tabIdentifier: UUID? = nil, tabItemIdentifier: UUID? = nil) {
         if let tabIdentifier {
             tabIdentifiersToDelete.add(tabIdentifier)
         }
         
         if let tabItemIdentifier {
             tabItemIdentifiersToDelete.add(tabItemIdentifier)
         }
         
         NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(debounceRemoveArticlesForDeletedTabParts), object: nil)
         perform(#selector(debounceRemoveArticlesForDeletedTabParts), with: nil, afterDelay: 0.5)
     }
      
      /// Removes any articles from the navigation stack that belong to the deleted tab or a deleted article
     @objc func debounceRemoveArticlesForDeletedTabParts() {
          
          guard let viewControllers else {
              return
          }
          
          // Loop through all view controllers
          for viewController in viewControllers {
              // Check if it's a navigation controller
              guard let navigationController = viewController as? UINavigationController else {
                  continue
              }
              
              // Get all view controllers in the navigation stack
              let viewControllers = navigationController.viewControllers
              
              // Filter out any ArticleViewControllers that belong to the deleted tab
              let remainingViewControllers = viewControllers.filter { viewController in
                  if let articleViewController = viewController as? ArticleViewController,
                        let coordinator = articleViewController.coordinator,
                        let tabIdentifier = coordinator.tabIdentifier,
                        let tabItemIdentifier = coordinator.tabItemIdentifier,
                        tabIdentifiersToDelete.contains(tabIdentifier) || tabItemIdentifiersToDelete.contains(tabItemIdentifier) {
                      return false // Remove this view controller
                  }
                  
                  return true // Keep this view controller
              }
              
              // Update the navigation stack if we removed any view controllers
              if remainingViewControllers.count < viewControllers.count {
                  navigationController.setViewControllers(remainingViewControllers, animated: false)
              }
          }
         
         tabIdentifiersToDelete.removeAllObjects()
         tabItemIdentifiersToDelete.removeAllObjects()
      }
 }

// MARK: - Activity Tab

extension WMFAppViewController {
    @objc func incrementActivityTabVisitCount() {
        Task {
            await WMFActivityTabDataController.shared.incrementActivityTabVisitCount()
        }
    }
    
    @objc func generateActivityTab() -> WMFActivityTabViewController {
        let onWikipediaiOS = WMFLocalizedString(
            "activity-tab-hours-on-wikipedia-ios",
            value: "ON WIKIPEDIA iOS",
            comment: "Activity tab header for on Wikipedia iOS, entirely capitalized except for iOS, which maintains its proper capitalization"
        )
        
        let timeSpentReading = WMFLocalizedString(
            "activity-tab-time-spent-reading",
            value: "Time spent reading this week",
            comment: "Subtitle to describe the amount of time read this week which will be displayed above with hours and minutes"
        )
        
        let activityTabDataController = WMFActivityTabDataController()
        
        func usernamesReading(username: String) -> String {
            let format = WMFLocalizedString(
                "activity-tab-usernames-reading-title",
                value: "%1$@'s reading",
                comment: "Activity tab header, includes username and their reading, like User's reading where $1 is replaced with the username."
            )
            return String.localizedStringWithFormat(format, username)
        }
        
        let noUsernameReading = WMFLocalizedString("activity-tab-no-username-reading-title", value: "Your reading", comment: "Activity tab header, for when there is no username.")
        
        func hoursMinutesRead(hours: Int, minutes: Int) -> String {
            let hoursString = hours.description
            let minutesString = minutes.description
            let format = WMFLocalizedString(
                "activity-tab-hours-minutes-read",
                value: "%1$@h %2$@m",
                comment: "Activity tab header, $1 is the amount of hours they spent reading, h is for the first letter of Hours, $2 is the amount of minutes they spent reading, m is for the first letter of Minutes."
            )
            return String.localizedStringWithFormat(format, hoursString, minutesString)
        }
        
        let articlesRead = WMFLocalizedString("activity-tab-articles-read", value: "Articles read this month", comment: "Title for module about articles read this month, displayed below the time spent reading this week")
        
        let articlesReadGraph = WMFLocalizedString("activity-tab-articles-read-graph-label", value: "Articles", comment: "Activity tab articles read graph axis label")
        let weekGraph = WMFLocalizedString("activity-tab-week-graph-label", value: "Week", comment: "Activity tab week graph axis label")
        
        let topCategories = WMFLocalizedString("activity-tab-top-categories", value: "Top categories this month", comment: "Title for module about top categories this month")
        let saved = WMFLocalizedString("activity-tab-saved", value: "Articles saved this month", comment: "Title for module about saved articles")
        
        func remaining(amount: Int) -> String {
            let format = WMFLocalizedString(
                "activity-tab-remaining-articles",
                value: "+%1$@",
                comment: "Activity tab saved articles amount, where $1 is replaced with the amount of excess articles saved above 3."
            )
            return String.localizedStringWithFormat(format, String(amount))
        }
        
        let loggedOutTitle = WMFLocalizedString("activity-tab-logged-out-title", value: "See more reading and editing insights", comment: "Title for logged out users")
        let loggedOutSubtitle = WMFLocalizedString("activity-tab-logged-out-subtitle", value: "Log in or create an account to view your activity on the Wikipedia app.", comment: "Subtitle for logged out users")
        let openArticle = WMFLocalizedString("open-article", value: "Open article", comment: "Open article title")
        let totalEditsAcrossProjects = WMFLocalizedString("activity-tab-total-edits", value: "Total edits across projects", comment: "Text for activity tab module about global edits")
        
        let edited = WMFLocalizedString("edited-article", value: "Edited", comment: "Label for edited articles")
        let emptyTitleLoggedIn = WMFLocalizedString("activity-tab-empty-title", value: "Nothing to show", comment: "Title on activity tab timeline empty state.")
        let emptySubtitleLoggedIn = WMFLocalizedString("activity-tab-empty-subtitle", value: "Start reading and editing to build your history", comment: "Subtitle on activity tab timeline empty state.")
        let emptyTitleLoggedOut = CommonStrings.emptyNoHistoryTitle
        let emptySubtitleLoggedOut = CommonStrings.emptyNoHistorySubtitle
        let yourImpact = WMFLocalizedString("activity-tab-your-impact", value: "Your impact", comment: "Title for editing section in activity tab.")
        
        // Customize Screen
        let customizeTimeSpentReading = WMFLocalizedString("activity-tab-customize-time-spent-reading", value: "Time spent reading", comment: "Title for time spent reading")
        let customizeReadingInsights = WMFLocalizedString("activity-tab-customize-reading-insights", value: "Reading insights", comment: "Title for reading insights")
        let customizeEditingInsights = WMFLocalizedString("activity-tab-customize-editing-insights", value: "Editing insights", comment: "Title for editing insights")
        let customizeAllTimeImpact = WMFLocalizedString("activity-tab-customize-all-time-impact", value: "All time impact", comment: "Title for all time impact")
        let customizeLastInAppDonation = WMFLocalizedString("activity-tab-customize-last-in-app-donation", value: "Last in app donation", comment: "Title for last in-app donation")
        let customizeTimelineOfBehavior = WMFLocalizedString("activity-tab-customize-timeline-of-behavior", value: "Timeline of behavior", comment: "Title for timeline of behavior")
        let customizeFooter = WMFLocalizedString("activity-tab-customize-footer", value: "Reading insights are based on your app languages in settings, and editing insights are limited to your primary app language.  Insights leverage local data, with the exception of edits which are public.", comment: "Footer for customize activity tab page.")
        
        // Impact module
        let allTimeImpactTitle = WMFLocalizedString("activity-tab-impact-all-time-title", value: "All time impact", comment: "Title for activity tab module about all time editing impact")
        let totalEditsLabel = WMFLocalizedString("activity-tab-impact-total-edits-label", value: "total edits", comment: "Label in impact module for total edits count")
        
        
        let bestStreakValue: (Int) -> String = { count in
            let bestStreakFormat = WMFLocalizedString("activity-tab-impact-best-streak-format", value: "{{PLURAL:%1$d|%1$d day|%1$d days}}", comment: "Count in impact module for best editing streak in number of days. %1$d is replaced with number of days.")
            
            return String.localizedStringWithFormat(bestStreakFormat, count)
        }
        
        let bestStreakLabel = WMFLocalizedString("activity-tab-impact-best-streak-label", value: "best streak", comment: "Label in impact module for best streak day count")
        
        let thanksLabel = WMFLocalizedString("activity-tab-impact-thanks-label", value: "thanks", comment: "Label in impact module for thanks count")
        let lastEditedLabel = WMFLocalizedString("activity-tab-impact-last-edited-label", value: "last edited", comment: "Label in impact module for last edited date")
        
        
        let yourRecentActivityTitle = WMFLocalizedString("activity-tab-impact-recent-activity-title", value: "Your recent activity (last 30 days)", comment: "Title for activity tab module about your recent editing activity")
        let editsLabel = WMFLocalizedString("activity-tab-impact-edits-label", value: "edits", comment: "Label in impact module for recent activity edit count")
        
        let startEndDatesAccessibilityLabel: (String, String) -> String = { startDate, endDate in
            let startEndDatesAccessibilityFormat = WMFLocalizedString("activity-tab-impact-recent-startend-accessibility", value: "From %1$@ to %2$@", comment: "Accessibility label in impact module for start / end date recent activity. %1$@ is replaced with start date, %2$@ is replaced with end date.")
            
            return String.localizedStringWithFormat(startEndDatesAccessibilityFormat, startDate, endDate)
        }
        
        let viewsOnArticlesYouveEditedTitle = WMFLocalizedString("activity-tab-impact-views-title", value: "Views on articles you’ve edited", comment: "Title for activity tab module about views on articles user edited")
        
        let lineGraphDay = WMFLocalizedString("activity-tab-impact-views-day", value: "Day", comment: "Accessibility label for activity tab views line graph, y-axis.")
        
        let lineGraphViews = WMFLocalizedString("activity-tab-impact-views-views", value: "Views", comment: "Accessibility label for activity tab views line graph, x-axis.")

        
        func customizeEmptyState() -> String {
            // Fake link because it's needed
            let openingLink = "<a href=\"www.wikipedia.org\">"
            let closingLink = "</a>"
            let format = WMFLocalizedString("activity-tab-customize-empty-state", value: "Activity modules are turned off. %1$@Switch them on%2$@ to see updates in this tab.", comment: "Empty state for customization on activity tab, $1 is the opening link, $2 is the closing.")
            return String.localizedStringWithFormat(format, openingLink, closingLink)
        }
        
        var authdValue: LoginState = .loggedOut
        if dataStore.authenticationManager.authStateIsPermanent {
            authdValue = .loggedIn
        } else if dataStore.authenticationManager.authStateIsTemporary {
            authdValue = .temp
        } else {
            authdValue = .loggedOut
        }
        
        let viewModel = WMFActivityTabViewModel(
            localizedStrings:
                WMFActivityTabViewModel.LocalizedStrings(
                    userNamesReading: usernamesReading(username:),
                    noUsernameReading: noUsernameReading,
                    totalHoursMinutesRead: hoursMinutesRead(hours:minutes:),
                    onWikipediaiOS: onWikipediaiOS,
                    timeSpentReading: timeSpentReading,
                    totalArticlesRead: articlesRead,
                    week: weekGraph,
                    articlesRead: articlesReadGraph,
                    topCategories: topCategories,
                    articlesSavedTitle: saved,
                    remaining: remaining(amount:),
                    loggedOutTitle: loggedOutTitle,
                    loggedOutSubtitle: loggedOutSubtitle,
                    loggedOutPrimaryCTA: CommonStrings.joinLoginTitle,
                    yourImpact: yourImpact,
                    todayTitle: CommonStrings.todayTitle,
                    yesterdayTitle: CommonStrings.yesterdayTitle,
                    openArticle: openArticle,
                    deleteAccessibilityLabel: CommonStrings.deleteActionTitle,
                    totalEditsAcrossProjects: totalEditsAcrossProjects,
                    read: CommonStrings.readString,
                    edited: edited,
                    saved: CommonStrings.shortSavedTitle,
                    emptyViewTitleLoggedIn: emptyTitleLoggedIn,
                    emptyViewSubtitleLoggedIn: emptySubtitleLoggedIn,
                    emptyViewTitleLoggedOut: emptyTitleLoggedOut,
                    emptyViewSubtitleLoggedOut: emptySubtitleLoggedOut,
                    customizeTimeSpentReading: customizeTimeSpentReading,
                    customizeReadingInsights: customizeReadingInsights,
                    customizeEditingInsights: customizeEditingInsights,
                    customizeAllTimeImpact: customizeAllTimeImpact,
                    customizeLastInAppDonation: customizeLastInAppDonation,
                    customizeTimelineOfBehavior: customizeTimelineOfBehavior,
                    customizeFooter: customizeFooter,
                    customizeEmptyState: customizeEmptyState(),
                    viewChanges: WMFLocalizedString("view-changes", value: "View changes", comment: "View changes button title"),
                    contributionsThisMonth: WMFLocalizedString("contributions-this-month", value: "Contributions this month", comment: "Title for section of contributions this month"),
                    thisMonth: WMFLocalizedString("edits-this-month", value: "edits this month", comment: "Title for edits this month section"),
                    lastMonth: WMFLocalizedString("edits-last-month", value: "edits last month", comment: "Title for edits last month section"),
                    lookingForSomethingNew: WMFLocalizedString("looking-for-something-new", value: "Looking for something new to read?", comment: "Title prompting user to explore Wikipedia"),
                    exploreWikipedia: WMFLocalizedString("explore-wikipedia", value: "Explore Wikipedia", comment: "Button title to explore Wikipedia"),
                    zeroEditsToArticles: WMFLocalizedString("zero-edits-to-articles", value: "0 edits to articles recently", comment: "Message showing zero recent edits"),
                    looksLikeYouHaventMadeAnEdit: WMFLocalizedString("looks-like-you-havent-made-an-edit", value: "Looks like you haven't made an edit this month. Extend free knowledge by editing topics that matter most to you.", comment: "Message encouraging user to make their first edit"),
                    makeAnEdit: WMFLocalizedString("learn-about-editing", value: "Learn about editing", comment: "Button title to learn about editing"),
                    viewsString: viewsString(views:),
                    mostViewed: WMFLocalizedString("activity-tab-most-viewed", value: "Most viewed since your edit", comment: "Title for section for most viewed articles since an edit"),
                    allTimeImpactTitle: allTimeImpactTitle,
                    totalEditsLabel: totalEditsLabel,
                    bestStreakValue: bestStreakValue,
                    bestStreakLabel: bestStreakLabel,
                    thanksLabel: thanksLabel,
                    lastEditedLabel: lastEditedLabel,
                    yourRecentActivityTitle: yourRecentActivityTitle,
                    editsLabel: editsLabel,
                    startEndDatesAccessibilityLabel: startEndDatesAccessibilityLabel,
                    viewsOnArticlesYouveEditedTitle: viewsOnArticlesYouveEditedTitle,
                    lineGraphDay: lineGraphDay,
                    lineGraphViews: lineGraphViews
                ),
                dataController: activityTabDataController,
                authenticationState: authdValue)
        
        viewModel.isExploreFeedOn = UserDefaults.standard.integer(forKey: "WMFDefaultTabTypeKey") == 0

        let controller = WMFActivityTabViewController(
            dataStore: dataStore,
            theme: theme,
            viewModel: viewModel,
            dataController: activityTabDataController
        )
        
        func viewsString(views: Int) -> String {
            let format = WMFLocalizedString("activity-tab-amount-article-views", value: "{{PLURAL:%1$d|%1$d view|%1$d views}}", comment: "$1 is the amount of views that an article has had since a user has edited it.")
            return String.localizedStringWithFormat(format, views)
        }

        return controller
    }
    
    private var isLoggedIn: Int {
        // 0 logged out
        // 1 temp
        // 2 logged in
        if dataStore.authenticationManager.authStateIsTemporary {
            return 1
        } else if dataStore.authenticationManager.authStateIsPermanent {
            return 2
        }
        return 0
    }
    
    @objc func logTabBarSelectionsForActivityTab(currentTabSelection: UIViewController, newTabSelection: UIViewController) {
        guard let currentNavVC = currentTabSelection as? UINavigationController,
              currentNavVC.viewControllers.count > 0,
              let newTabNavVC = newTabSelection as? UINavigationController,
              newTabNavVC.viewControllers.count > 0 else {
            return
        }
        
        guard let currentVC = currentNavVC.viewControllers.last else {
            return
        }
        
        let newVC = newTabNavVC.viewControllers[0]
        
        var action: ActivityTabFunnel.Action? = nil
        if newVC is WMFActivityTabViewController {
            action = .activityNavClick
        }

        guard let action else { return }
        
        if currentVC is ExploreViewController {
            ActivityTabFunnel.shared.logTabBarSelected(from: .feed, action: action)
        } else if currentVC is PlacesViewController {
            ActivityTabFunnel.shared.logTabBarSelected(from: .places, action: action)
        } else if currentVC is SavedViewController {
            ActivityTabFunnel.shared.logTabBarSelected(from: .saved, action: action)
        } else if currentVC is WMFActivityTabViewController {
            ActivityTabFunnel.shared.logTabBarSelected(from: .activityTab, action: action)
        } else if currentVC is SearchViewController {
            ActivityTabFunnel.shared.logTabBarSelected(from: .search, action: action)
        } else if currentVC is WMFSettingsViewController {
            ActivityTabFunnel.shared.logTabBarSelected(from: .settings, action: action)
        } else if let article = currentVC as? ArticleViewController {
            guard let title = article.articleURL.wmf_title?.denormalizedPageTitle else {
                return
            }
            
            if title == "Main_Page" {
                ActivityTabFunnel.shared.logTabBarSelected(from: .mainPage, action: action)
            } else {
                ActivityTabFunnel.shared.logTabBarSelected(from: .article, action: action)
            }
        }
    }
}
