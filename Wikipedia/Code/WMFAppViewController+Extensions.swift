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
        
        let linkCoordinator = LinkCoordinator(navigationController: navigationController, url: linkURL, dataStore: dataStore, theme: theme, articleSource: .undefined)
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
    
    @objc func assignAndLogArticleSearchBarExperiment() {
        guard let dataController = WMFNavigationExperimentsDataController.shared,
        let primaryLanguage = dataStore.languageLinkController.appLanguage,
        let project = WikimediaProject(siteURL: primaryLanguage.siteURL)?.wmfProject else {
            return
        }
        
        do {
            let assignment = try dataController.assignArticleSearchBarExperiment(project: project)
            SearchFunnel.shared.logDidAssignArticleSearchExperiment(assignment: assignment)
        } catch {
            DDLogWarn("Error assigning article search experiment: \(error)")
        }
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
            diffURL = siteURL.wmf_URL(withPath: "/wiki/Special:MobileDiff/\(oldRevisionID)", isMobile: true)
        } else if oldRevisionID == 0 {
            diffURL = siteURL.wmf_URL(withPath: "/wiki/Special:MobileDiff/\(revisionID)", isMobile: true)
        } else {
            diffURL = siteURL.wmf_URL(withPath: "/wiki/Special:MobileDiff/\(oldRevisionID)...\(revisionID)", isMobile: true)
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
        
        Task {
            do {
                WMFDataEnvironment.current.coreDataStore = try await WMFCoreDataStore()
            } catch let error {
                DDLogError("Error setting up WMFCoreDataStore: \(error)")
            }
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


    @objc func populateYearInReviewReport(for year: Int) {
        guard let language  = dataStore.languageLinkController.appLanguage?.languageCode,
              let countryCode = Locale.current.region?.identifier
        else { return }
        let wmfLanguage = WMFLanguage(languageCode: language, languageVariantCode: nil)
        let project = WMFProject.wikipedia(wmfLanguage)
        var userId: Int?

        if let siteURL = dataStore.languageLinkController.appLanguage?.siteURL,
           let userID = dataStore.authenticationManager.permanentUser(siteURL: siteURL)?.userID {
            userId = userID
        }
        
        let userIdString: String? = userId.map { String($0) }

        Task {
            do {
                let yirDataController = try WMFYearInReviewDataController()
                try await yirDataController.populateYearInReviewReportData(
                    for: year,
                    countryCode: countryCode,
                    primaryAppLanguageProject: project,
                    username: dataStore.authenticationManager.authStatePermanentUsername,
                    userID: userIdString,
                    savedSlideDataDelegate: dataStore.savedPageList,
                    legacyPageViewsDataDelegate: dataStore)
            } catch {
                DDLogError("Failure populating year in review report: \(error)")
            }
        }
    }
    
    @objc func deleteYearInReviewPersonalizedEditingData() {
        Task {
            do {
                let yirDataController = try WMFYearInReviewDataController()
                try await yirDataController.deleteAllPersonalizedEditingData()
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
        return WMFAppEnvironment.current.traitCollection != traitCollection
    }

    @objc func generateActivityTab(exploreViewController: ExploreViewController) -> WMFActivityTabViewController {

        let openHistoryClosure = { [weak self] in
            guard let self = self else { return }

            guard let navigationController = self.currentTabNavigationController else {
                return
            }

            let historyVC = HistoryViewController()
            historyVC.dataStore = self.dataStore
            historyVC.apply(theme: self.theme)
            historyVC.title = CommonStrings.historyTabTitle
            navigationController.pushViewController(historyVC, animated: true)
        }
        
        let openSavedArticlesClosure = { [weak self] in
            guard let self = self else { return }
            
            self.dismissPresentedViewControllers()
            withAnimation {
                self.selectedIndex = AppTab.saved.rawValue
            }
        }
        
        let openSuggestedEditsClosure = { [weak self] in
            guard let self = self, let navigationController = self.currentTabNavigationController else {
                return
            }
            
            guard let vc = WMFImageRecommendationsViewController.imageRecommendationsViewController(
                dataStore: dataStore,
                imageRecDelegate: self,
                imageRecLoggingDelegate: self) else {
                return
            }
            
            navigationController.pushViewController(vc, animated: true)
        }
        
        let isLoggedIn = dataStore.authenticationManager.authStateIsPermanent
        let localizedStrings = WMFActivityViewModel.LocalizedStrings(
            activityTabViewReadingHistory: CommonStrings.activityTabViewReadingHistoryTitle,
            activityTabViewSavedArticles: CommonStrings.activityTabViewSavedArticlesTitle, localizedTabTitle: CommonStrings.activityTitle
        )
        let viewModel = WMFActivityViewModel(
            localizedStrings: localizedStrings,
            shouldShowAddAnImage: false,
            shouldShowStartEditing: false,
            hasNoEdits: false,
            openHistory: openHistoryClosure,
            openSavedArticles: openSavedArticlesClosure,
            openSuggestedEdits: openSuggestedEditsClosure,
            loginAction: nil,
            isLoggedIn: isLoggedIn)
        
        viewModel.savedSlideDataDelegate = dataStore.savedPageList
        viewModel.legacyPageViewsDataDelegate = dataStore

        let activityTabViewController = WMFActivityTabViewController(viewModel: viewModel)
        
        let loginAction = { [weak self] in
            guard let self = self else { return }

            guard let navigationController = self.currentTabNavigationController else {
                print("navigationController is nil")
                return
            }
            
            let loginCoordinator = LoginCoordinator(navigationController: navigationController, theme: theme)
            loginCoordinator.createAccountSuccessCustomDismissBlock = { [weak self] in
                
                guard let self else { return }
                
                self.updateActivityTabLoginState(activityTabViewController: activityTabViewController)
            }
            
            loginCoordinator.loginSuccessCompletion = { [weak self] in
                
                guard let self else { return }
                
                self.updateActivityTabLoginState(activityTabViewController: activityTabViewController)
            }

            loginCoordinator.start()
        }
        
        if let siteURL = dataStore.languageLinkController.appLanguage?.siteURL,
           let wikimediaProject = WikimediaProject(siteURL: siteURL),
           let wmfProject = wikimediaProject.wmfProject {
            viewModel.project = wmfProject
        }
        
        viewModel.loginAction = loginAction
        
        return activityTabViewController
    }
    
    @objc func updateActivityTabProject(activityTabViewController: WMFActivityTabViewController) {
        if let siteURL = dataStore.languageLinkController.appLanguage?.siteURL,
           let wikimediaProject = WikimediaProject(siteURL: siteURL),
           let wmfProject = wikimediaProject.wmfProject {
            activityTabViewController.viewModel.project = wmfProject
        }
    }
    
    @objc func updateActivityTabLoginState(activityTabViewController: WMFActivityTabViewController) {
        let isLoggedIn = dataStore.authenticationManager.authStateIsPermanent
        activityTabViewController.viewModel.isLoggedIn = isLoggedIn
    }
}

extension WMFAppViewController: WMFImageRecommendationsDelegate, InsertMediaSettingsViewControllerDelegate, InsertMediaSettingsViewControllerLoggingDelegate {
    func insertMediaSettingsViewControllerDidTapProgress(imageWikitext: String, caption: String?, altText: String?, localizedFileTitle: String) {
        
        guard let viewModel = self.imageRecommendationsViewModelWrapper.viewModel,
        let currentRecommendation = viewModel.currentRecommendation,
                    let siteURL = viewModel.project.siteURL,
              let articleURL = siteURL.wmf_URL(withTitle: currentRecommendation.title),
        let articleWikitext = currentRecommendation.imageData.wikitext else {
            return
        }
        
        currentRecommendation.caption = caption
        currentRecommendation.altText = altText
        currentRecommendation.imageWikitext = imageWikitext
        currentRecommendation.localizedFileTitle = localizedFileTitle
        
        do {
            let wikitextWithImage = try WMFWikitextUtils.insertImageWikitextIntoArticleWikitextAfterTemplates(imageWikitext: imageWikitext, into: articleWikitext)
            
            currentRecommendation.fullArticleWikitextWithImage = wikitextWithImage
            
            let editPreviewViewController = EditPreviewViewController(pageURL: articleURL)
            editPreviewViewController.theme = theme
            editPreviewViewController.sectionID = 0
            editPreviewViewController.languageCode = articleURL.wmf_languageCode
            editPreviewViewController.wikitext = wikitextWithImage
            editPreviewViewController.delegate = self
            editPreviewViewController.loggingDelegate = self

            navigationController?.pushViewController(editPreviewViewController, animated: true)
        } catch {
            showGenericError()
        }
    }
    
    func logInsertMediaSettingsViewControllerDidAppear() {
        ImageRecommendationsFunnel.shared.logAddImageDetailsDidAppear()
    }
    
    func logInsertMediaSettingsViewControllerDidTapFileName() {
        ImageRecommendationsFunnel.shared.logAddImageDetailsDidTapFileName()
    }
    
    func logInsertMediaSettingsViewControllerDidTapCaptionLearnMore() {
        ImageRecommendationsFunnel.shared.logAddImageDetailsDidTapCaptionLearnMore()
    }
    
    func logInsertMediaSettingsViewControllerDidTapAltTextLearnMore() {
        ImageRecommendationsFunnel.shared.logAddImageDetailsDidTapAltTextLearnMore()
    }
    
    func logInsertMediaSettingsViewControllerDidTapAdvancedSettings() {
        ImageRecommendationsFunnel.shared.logAddImageDetailsDidTapAdvancedSettings()
    }
    
    public func imageRecommendationsUserDidTapLearnMore(url: URL?) {
        navigate(to: url, useSafari: false)
    }
    
    public func imageRecommendationsUserDidTapReportIssue() {
        let emailAddress = "ios-support@wikimedia.org"
        let emailSubject = WMFLocalizedString("image-recommendations-email-title", value: "Issue Report - Add an Image Feature", comment: "Title text for Image recommendations pre-filled issue report email")
        let emailBodyLine1 = WMFLocalizedString("image-recommendations-email-first-line", value: "I’ve encountered a problem with the Add an Image Suggested Edits Feature:", comment: "Text for Image recommendations pre-filled issue report email")
        let emailBodyLine2 = WMFLocalizedString("image-recommendations-email-second-line", value: "- [Describe specific problem]", comment: "Text for Image recommendations pre-filled issue report email. This text is intended to be replaced by the user with a description of the problem they are encountering")
        let emailBodyLine3 = WMFLocalizedString("image-recommendations-email-third-line", value: "The behavior I would like to see is:", comment: "Text for Image recommendations pre-filled issue report email")
        let emailBodyLine4 = WMFLocalizedString("image-recommendations-email-fourth-line", value: "- [Describe proposed solution]", comment: "Text for Image recommendations pre-filled issue report email. This text is intended to be replaced by the user with a description of a user suggested solution")
        let emailBodyLine5 = WMFLocalizedString("image-recommendations-email-fifth-line", value: "[Screenshots or Links]", comment: "Text for Image recommendations pre-filled issue report email. This text is intended to be replaced by the user with a screenshot or link.")
        let emailBody = "\(emailBodyLine1)\n\n\(emailBodyLine2)\n\n\(emailBodyLine3)\n\n\(emailBodyLine4)\n\n\(emailBodyLine5)"
        let mailto = "mailto:\(emailAddress)?subject=\(emailSubject)&body=\(emailBody)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)

        guard let encodedMailto = mailto, let mailtoURL = URL(string: encodedMailto), UIApplication.shared.canOpenURL(mailtoURL) else {
            WMFAlertManager.sharedInstance.showErrorAlertWithMessage(CommonStrings.noEmailClient, sticky: false, dismissPreviousAlerts: false)
            return
        }
        UIApplication.shared.open(mailtoURL)
    }
    
    public func imageRecommendationsUserDidTapImage(project: WMFProject, data: WMFImageRecommendationsViewModel.WMFImageRecommendationData, presentingVC: UIViewController) {

        guard let siteURL = project.siteURL,
              let articleURL = siteURL.wmf_URL(withTitle: data.pageTitle) else {
            return
        }

        let item = MediaListItem(title: "File:\(data.filename)", sectionID: 0, type: .image, showInGallery: true, isLeadImage: false, sources: nil)
        let mediaList = MediaList(items: [item])

        let gallery = MediaListGalleryViewController(articleURL: articleURL, mediaList: mediaList, dataStore: dataStore, initialItem: item, theme: theme, dismissDelegate: nil)
        presentingVC.present(gallery, animated: true)
    }

    public func imageRecommendationsUserDidTapViewArticle(project: WMFData.WMFProject, title: String) {
        
        guard let navigationController = currentTabNavigationController,
              let siteURL = project.siteURL,
              let articleURL = siteURL.wmf_URL(withTitle: title) else {
            return
        }
        
        let coordinator = ArticleCoordinator(navigationController: navigationController, articleURL: articleURL, dataStore: dataStore, theme: theme, source: .undefined)
        coordinator.start()
    }
    
    public func imageRecommendationsUserDidTapImageLink(commonsURL: URL) {
        navigate(to: commonsURL, useSafari: false)
        ImageRecommendationsFunnel.shared.logCommonsWebViewDidAppear()
    }

    public func imageRecommendationsUserDidTapInsertImage(viewModel: WMFImageRecommendationsViewModel, title: String, with imageData: WMFImageRecommendationsViewModel.WMFImageRecommendationData) {
        guard let currentTabNavigationController else { return }

        guard let image = imageData.uiImage,
        let siteURL = viewModel.project.siteURL else {
            return
        }
        
        if let imageURL = URL(string: imageData.descriptionURL),
           let thumbURL = URL(string: imageData.thumbUrl) {

            let fileName = imageData.filename.normalizedPageTitle ?? imageData.filename
            let imageDescription = imageData.description?.removingHTML
            let searchResult = InsertMediaSearchResult(fileTitle: "File:\(imageData.filename)", displayTitle: fileName, thumbnailURL: thumbURL, imageDescription: imageDescription,  filePageURL: imageURL)
            
            let insertMediaViewController = InsertMediaSettingsViewController(
                image: image,
                searchResult: searchResult,
                fromImageRecommendations: true,
                delegate: self,
                imageRecLoggingDelegate: self,
                theme: theme,
                siteURL: siteURL)
            self.imageRecommendationsViewModel = viewModel
            currentTabNavigationController.pushViewController(insertMediaViewController, animated: true)
        }
    }
    
    public func imageRecommendationsDidTriggerError(_ error: any Error) {
        WMFAlertManager.sharedInstance.showErrorAlert(error, sticky: false, dismissPreviousAlerts: true)
    }

    public func imageRecommendationsDidTriggerTimeWarning() {
        let warningmessage = WMFLocalizedString("image-recs-time-warning-message", value: "Please review the article to understand its topic and inspect the image", comment: "Message displayed in a warning when a user taps yes to an image recommendation within 5 seconds or less")
        WMFAlertManager.sharedInstance.showBottomAlertWithMessage(warningmessage, subtitle: nil, image: nil, type: .normal, customTypeName: nil, dismissPreviousAlerts: true)
    }
}


extension WMFAppViewController: WMFImageRecommendationsLoggingDelegate {

    public func logOnboardingDidTapPrimaryButton() {
        ImageRecommendationsFunnel.shared.logOnboardingDidTapContinue()
    }
    
    public func logOnboardingDidTapSecondaryButton() {
        ImageRecommendationsFunnel.shared.logOnboardingDidTapLearnMore()
    }
    
    public func logTooltipsDidTapFirstNext() {
        ImageRecommendationsFunnel.shared.logTooltipDidTapFirstNext()
    }
    
    public func logTooltipsDidTapSecondNext() {
        ImageRecommendationsFunnel.shared.logTooltipDidTapSecondNext()
    }
    
    public func logTooltipsDidTapThirdOK() {
        ImageRecommendationsFunnel.shared.logTooltipDidTapThirdOk()
    }
    
    public func logBottomSheetDidAppear() {
        ImageRecommendationsFunnel.shared.logBottomSheetDidAppear()
    }

    public func logDialogWarningMessageDidDisplay(fileName: String, recommendationSource: String) {
        ImageRecommendationsFunnel.shared.logDialogWarningMessageDidDisplay(fileName: fileName, recommendationSource: recommendationSource)
    }

    public func logBottomSheetDidTapYes() {
        
        // TODO: Grey
//        if let viewModel = self.imageRecommendationsViewModel,
//              let currentRecommendation = viewModel.currentRecommendation,
//           let siteURL = viewModel.project.siteURL,
//           let pageURL = siteURL.wmf_URL(withTitle: currentRecommendation.title) {
//            currentRecommendation.suggestionAcceptDate = Date()
//            EditAttemptFunnel.shared.logInit(pageURL: pageURL)
//        }
        
        ImageRecommendationsFunnel.shared.logBottomSheetDidTapYes()
    }
    
    public func logBottomSheetDidTapNo() {
        ImageRecommendationsFunnel.shared.logBottomSheetDidTapNo()
    }
    
    public func logBottomSheetDidTapNotSure() {
        ImageRecommendationsFunnel.shared.logBottomSheetDidTapNotSure()
    }
    
    public func logOverflowDidTapLearnMore() {
        ImageRecommendationsFunnel.shared.logOverflowDidTapLearnMore()
    }
    
    public func logOverflowDidTapTutorial() {
        ImageRecommendationsFunnel.shared.logOverflowDidTapTutorial()
    }
    
    public func logOverflowDidTapProblem() {
        ImageRecommendationsFunnel.shared.logOverflowDidTapProblem()
    }
    
    public func logBottomSheetDidTapFileName() {
        ImageRecommendationsFunnel.shared.logBottomSheetDidTapFileName()
    }
    
    public func logRejectSurveyDidAppear() {
        ImageRecommendationsFunnel.shared.logRejectSurveyDidAppear()
    }
    
    public func logRejectSurveyDidTapCancel() {
        ImageRecommendationsFunnel.shared.logRejectSurveyDidTapCancel()
    }
    
    public func logRejectSurveyDidTapSubmit(rejectionReasons: [String], otherReason: String?, fileName: String, recommendationSource: String) {
        
        ImageRecommendationsFunnel.shared.logRejectSurveyDidTapSubmit(rejectionReasons: rejectionReasons, otherReason: otherReason, fileName: fileName, recommendationSource: recommendationSource)
    }
    
    public func logEmptyStateDidAppear() {
        ImageRecommendationsFunnel.shared.logEmptyStateDidAppear()
    }
    
    public func logEmptyStateDidTapBack() {
        ImageRecommendationsFunnel.shared.logEmptyStateDidTapBack()
    }
}
