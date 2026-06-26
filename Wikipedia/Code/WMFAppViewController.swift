import UIKit
import WMF
import WMFData
import WMFComponents
import SystemConfiguration
import UserNotifications
import CocoaLumberjackSwift
import SwiftUI
import WMFNativeLocalizations

// MARK: - Tab enum

@objc enum WMFAppTabType: Int {
    case main = 0
    case places = 1
    case saved = 2
    case recent = 3 // Activity tab
    case search = 4
}

// MARK: - Constants

private let wmfTimeBeforeShowingExploreScreenOnLaunch: TimeInterval = 24 * 60 * 60
private let wmfRemoteAppConfigCheckInterval: CFTimeInterval = 3 * 60 * 60
private let wmfTempAccountConfigCheckInterval: CFTimeInterval = 3 * 60 * 60
private let wmfLastRemoteAppConfigCheckAbsoluteTimeKey = "WMFLastRemoteAppConfigCheckAbsoluteTimeKey"
private let wmfTempAccountConfigCheckAbsoluteTimeKey = "WMFTempAccountConfigCheckAbsoluteTimeKey"
private let wmfResetPreferredLanguages = "WMFResetPreferredLanguages"
private let wmfSuppressActivityTabOnboardingForTesting = "WMFSuppressActivityTabOnboardingForTesting"
private let wmfSuppressGamesAnnouncementForTesting = "WMFSuppressGamesAnnouncementForTesting"
private let wmfSuppressReadingChallengeAnnouncementForTesting = "WMFSuppressReadingChallengeAnnouncementForTesting"

// KVO context pointers
private var kvoSavedArticlesFetcherProgress = UInt8(0)
private var kvoNSUserDefaultsDefaultTabType = UInt8(0)

// MARK: - Public constant

public let WMFLanguageVariantAlertsLibraryVersion = "WMFLanguageVariantAlertsLibraryVersion"

// MARK: - WMFAppViewController

final class WMFAppViewController: UITabBarController, AppTabBarDelegate {

    // MARK: - Public properties

    private(set) var theme: Theme = Theme.standard
    var tabIdentifiersToDelete: [UUID] = []
    var tabItemIdentifiersToDelete: [UUID] = []
    let tipWrapper: WMFAppViewControllerTipWrapper

    // MARK: - Private stored properties

    private var periodicWorkerController: PeriodicWorkerController?
    private var backgroundFetcherController: BackgroundFetcherController?
    private var reachabilityNotifier: ReachabilityNotifier?

    private var transitionsController: ViewControllerTransitionsController?

    private var _settingsViewController: SettingsTabViewController?
    private var _exploreViewController: ExploreViewController?
    private var homeCoordinator: HomeCoordinator?
    private var _searchTabViewController: SearchViewController?
    private var _savedViewController: SavedViewController?
    private var _placesViewController: PlacesViewController?
    private var _activityTabViewController: WMFActivityTabViewController?

    private var splashScreenViewController: SplashScreenViewController?

    private var _savedArticlesFetcher: SavedArticlesFetcher?
    
    private var unprocessedUserActivity: NSUserActivity?
    private var unprocessedShortcutItem: UIApplicationShortcutItem?

    private var backgroundTasks: [String: UIBackgroundTaskIdentifier] = [:]
    private let backgroundTasksLock = NSLock()
    
    private var isWaitingToResumeApp: Bool = false
    private var isMigrationComplete: Bool = false
    private var isMigrationActive: Bool = false
    private var isResumeComplete: Bool = false
    private var isCheckingRemoteConfig: Bool = false

    private var notificationUserInfoToShow: [AnyHashable: Any]?

    private var _settingsNavigationController: WMFComponentNavigationController?

    var readingListsAlertController: ReadingListsAlertController!
    
    var syncStartDate: Date?
    
    var savedTabBarItemProgressBadgeManager: SavedTabBarItemProgressBadgeManager?
    
    private var hasSyncErrorBeenShownThisSession: Bool = false
    
    var readingListHintPresenter: WMFReadingListToastManager!

    private var _navigationStateController: NavigationStateController?
    
    private var configuration: Configuration?
    private var router: ViewControllerRouter?
    
    private var isUpdatingDefaultTab: Bool = false
    private var rootTabAccessibilityIdentifiers: [String?] = []

    // MARK: - init / deinit
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        UserDefaults.standard.removeObserver(self, forKeyPath: UserDefaults.Key.defaultTabType)
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }

    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        tipWrapper = WMFAppViewControllerTipWrapper()
        
        super.init(nibName: nil, bundle: nil)
        configuration = Configuration.current
        
        if let router = configuration?.router {
            self.router = ViewControllerRouter(appViewController: self, router: router)
        } else {
            router = nil
        }
        
        tabItemIdentifiersToDelete = []
        tabIdentifiersToDelete = []
        isUpdatingDefaultTab = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - viewDidLoad

    override func viewDidLoad() {
        super.viewDidLoad()
        theme = UserDefaults.standard.theme(compatibleWith: traitCollection)

        apply(theme: theme)

        updateAppEnvironment(theme: theme, traitCollection: traitCollection)

        backgroundTasks = Dictionary(minimumCapacity: 5)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(navigateToActivityNotification(_:)),
                                               name: NSNotification.Name.WMFNavigateToActivity,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(userDidChangeTheme(_:)),
                                               name: Notification.Name(ReadingThemesControlsViewController.WMFUserDidSelectThemeNotification),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(articleFontSizeWasUpdated(_:)),
                                               name: Notification.Name(FontSizeSliderViewController.WMFArticleFontSizeUpdatedNotification),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(entriesLimitReachedWithNotification(_:)),
                                               name: ReadingList.entriesLimitReachedNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(readingListsWereSplitNotification(_:)),
                                               name: WMFReadingListsController.readingListsWereSplitNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(readingListsServerDidConfirmSyncWasEnabledForAccountWithNotification(_:)),
                                               name: WMFReadingListsController.readingListsServerDidConfirmSyncWasEnabledForAccountNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(syncDidStartNotification(_:)),
                                               name: WMFReadingListsController.syncDidStartNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(syncDidFinishNotification(_:)),
                                               name: WMFReadingListsController.syncDidFinishNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(conflictingReadingListNameUpdatedNotification(_:)),
                                               name: ReadingList.conflictingReadingListNameUpdatedNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(articleSaveToDiskDidFail(_:)),
                                               name: SavedArticlesFetcher.saveToDiskDidFail,
                                               object: nil)

        UserDefaults.standard.addObserver(self,
                                          forKeyPath: UserDefaults.Key.defaultTabType,
                                          options: .new,
                                          context: &kvoNSUserDefaultsDefaultTabType)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(exploreFeedPreferencesDidChange(_:)),
                                               name: Notification.Name.WMFExploreFeedPreferencesDidChange,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(userWasLoggedOut(_:)),
                                               name: WMFAuthenticationManager.didLogOutNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(userWasLoggedIn(_:)),
                                               name: WMFAuthenticationManager.didLogInNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAppLanguageDidChangeNotification(_:)),
                                               name: Notification.Name.WMFAppLanguageDidChange,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(authManagerDidHandlePrimaryLanguageChange(_:)),
                                               name: WMFAuthenticationManager.didHandlePrimaryLanguageChange,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleExploreCenterBadgeNeedsUpdateNotification),
                                               name: NSNotification.notificationsCenterBadgeNeedsUpdate,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleNotificationsCenterContextDidSave),
                                               name: NSNotification.notificationsCenterContextDidSave,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(descriptionEditWasPublished(_:)),
                                               name: DescriptionEditViewController.didPublishNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(referenceLinkTapped(_:)),
                                               name: Notification.Name.WMFReferenceLinkTapped,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(showErrorBanner(_:)),
                                               name: .showErrorBanner,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(autoLoginNeedsEmailToken(_:)),
                                               name: WMFAuthenticationManager.autoLoginNeedsEmailToken,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(autoLoginNeedsOathToken(_:)),
                                               name: WMFAuthenticationManager.autoLoginNeedsOathToken,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(articleViewControllerDidDisappear(_:)),
                                               name: .articleViewControllerDidDisappear,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(dismissReadingListToast(_:)),
                                               name: .dismissReadingListToast,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleEnableHomeTabDidChange),
                                               name: WMFNSNotification.enableHomeTabDidChange,
                                               object: nil)

        observeArticleTabsNSNotifications()
        setupReadingListsHelpers()

        navigationItem.backButtonDisplayMode = .generic
        
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { [weak self] (_: WMFAppViewController, _: UITraitCollection) in
            self?.debounceTraitCollectionThemeUpdate()
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return theme.preferredStatusBarStyle
    }

    override var childForStatusBarStyle: UIViewController? {
        return nil
    }

    override var prefersStatusBarHidden: Bool {
        return false
    }

    var isPresentingOnboarding: Bool {
        return presentedViewController is WMFWelcomeInitialViewController
    }

    private var uiIsLoaded: Bool {
        return (viewControllers?.count ?? 0) > 0
    }

    private var siteURL: URL? {
        return dataStore.primarySiteURL
    }

    // MARK: - Setup

    private func setupControllers() {
        let periodicWorkerController = PeriodicWorkerController(30, initialDelay: 1, leeway: 15)
        periodicWorkerController.delegate = self
        periodicWorkerController.add(dataStore.readingListsController)
        periodicWorkerController.add(EventPlatformClientWorker.shared)
        self.periodicWorkerController = periodicWorkerController

        let backgroundFetcherController = BackgroundFetcherController()
        backgroundFetcherController.delegate = self
        backgroundFetcherController.add(dataStore.readingListsController)
        backgroundFetcherController.add(dataStore.feedContentController)
        backgroundFetcherController.add(EventPlatformClientWorker.shared)
        self.backgroundFetcherController = backgroundFetcherController
    }

    private func loadMainUI() {
        guard !uiIsLoaded else { return }
        configureTabController()

        tabBar.tintAdjustmentMode = .normal

        apply(theme: theme)

        transitionsController = ViewControllerTransitionsController()

        searchTabViewController.apply(theme: theme)
        if UserDefaults.standard.defaultTabType == .settings {
            settingsViewController.apply(theme: theme)
        }

        if let savedTabBarItem = savedViewController.tabBarItem {
            savedTabBarItemProgressBadgeManager = SavedTabBarItemProgressBadgeManager(with: savedTabBarItem)
        }
    }

    private func configureTabController() {
        self.delegate = self

        let nav1: WMFComponentNavigationController
        if WMFDeveloperSettingsDataController.shared.enableHomeTab {
            let coordinator = HomeCoordinator(theme: theme, dataStore: dataStore)
            let homeViewController = coordinator.makeHomeViewController()
            nav1 = rootNavigationController(with: homeViewController)
            coordinator.attach(navigationController: nav1)
            homeCoordinator = coordinator
        } else {
            homeCoordinator = nil
            let mainViewController: UIViewController
            switch UserDefaults.standard.defaultTabType {
            case .settings:
                mainViewController = settingsViewController
            default:
                mainViewController = exploreViewController
            }
            nav1 = rootNavigationController(with: mainViewController)
        }
        let nav2 = rootNavigationController(with: placesViewController)
        let nav3 = rootNavigationController(with: savedViewController)
        let nav4 = rootNavigationController(with: activityTabViewController)
        let nav5 = rootNavigationController(with: searchTabViewController)
        let rootNavigationControllers = [nav1, nav2, nav3, nav4, nav5]
        rootTabAccessibilityIdentifiers = rootNavigationControllers.map { nav in
            nav.viewControllers.first?.tabBarItem.accessibilityIdentifier
        }

        if #available(iOS 18.0, *) {
            // A magic fix for https://phabricator.wikimedia.org/T403896
            var potentialTabs: [UITab] = []
            for nav in rootNavigationControllers {
                guard let rootVC = nav.viewControllers.first,
                      let title = rootVC.title,
                      let image = rootVC.tabBarItem.image else { continue }
                
                let identifier = rootVC.tabBarItem.accessibilityIdentifier ?? title
                let tab = UITab(title: title, image: image, identifier: identifier) { tab in
                    return nav
                }
                
                tab.preferredPlacement = .fixed
                potentialTabs.append(tab)
            }
            self.tabs = potentialTabs
            // Once set, `UITabBarController.viewControllers` and related properties and methods will not be called.
        }

        // This should be called all the time for backward compatibility
        setViewControllers([nav1, nav2, nav3, nav4, nav5], animated: false)
        applyRootTabAccessibilityIdentifiers()

        updateUserInterfaceStyleOfNavigationControllersForCurrentTheme()

        let shouldOpenOnSearch = shouldOpenAppOnSearchTab()
        if shouldOpenOnSearch && selectedIndex != WMFAppTabType.search.rawValue {
            selectedIndex = WMFAppTabType.search.rawValue
            searchTabViewController.makeSearchBarBecomeFirstResponder()
        } else if selectedIndex != WMFAppTabType.main.rawValue {
            selectedIndex = WMFAppTabType.main.rawValue
        }
    }

    private func rootNavigationController(with rootViewController: UIViewController) -> WMFComponentNavigationController {
        let navigationController = WMFComponentNavigationController(rootViewController: rootViewController, modalPresentationStyle: .overFullScreen, customBarBackgroundColor: nil)
        navigationController.delegate = self
        return navigationController
    }

    private func applyRootTabAccessibilityIdentifiers() {
        for (tabBarItem, identifier) in zip(tabBar.items ?? [], rootTabAccessibilityIdentifiers) {
            tabBarItem.accessibilityIdentifier = identifier
        }
    }

    private func setupReadingListsHelpers() {
        readingListsAlertController = ReadingListsAlertController()
        readingListHintPresenter = WMFReadingListToastManager(dataStore: dataStore)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(userDidSaveOrUnsaveArticle(_:)),
                                               name: WMFReadingListsController.userDidSaveOrUnsaveArticleNotification,
                                               object: nil)
    }

    @objc private func userDidSaveOrUnsaveArticle(_ note: Notification) {
        assert(Thread.isMainThread, "User save/unsave article notification should only be posted on the main thread")
        guard let article = note.object as? WMFArticle else { return }
        showReadingListHintForArticle(article)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return currentTabNavigationController?.supportedInterfaceOrientations ?? .all
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return currentTabNavigationController?.preferredInterfaceOrientationForPresentation ?? .portrait
    }

    // MARK: - Notifications

    @objc private func appWillEnterForegroundWithNotification(_ note: Notification) {
    }

    // When the user launches from a terminated state, resume might not finish before didBecomeActive,
    // so these tasks are held until both items complete.
    @objc func performTasksThatShouldOccurAfterBecomeActiveAndResume() {
        SessionsFunnel.shared.appDidBecomeActive()
        checkRemoteAppConfigIfNecessary()
        updatePrimaryWikiHasTempAccountsStatusIfNecessary()
        periodicWorkerController?.start()
        savedArticlesFetcher?.start()
        assignMoreDynamicTabsV2ExperimentIfNeeded()
        AppIconUtility.shared.checkAndRevertIfExpired()
    }

    func performTasksThatShouldOccurAfterAnnouncementsUpdated() {
        if isResumeComplete {
            UserHistoryFunnel.shared.logSnapshot()
        }
    }

    @objc private func appDidBecomeActiveWithNotification(_ note: Notification) {
        // Retry migration if it was terminated by a background task ending
        migrateIfNecessary()

        guard uiIsLoaded else { return }

        if visibleViewController() == exploreViewController {
            exploreViewController.isGranularUpdatingEnabled = true
        }

        if isResumeComplete {
            performTasksThatShouldOccurAfterBecomeActiveAndResume()
            UserHistoryFunnel.shared.logSnapshot()
        }
    }

    @objc private func appWillResignActiveWithNotification(_ note: Notification) {
        guard uiIsLoaded else { return }

        exploreViewController.isGranularUpdatingEnabled = false

        navigationStateController.saveNavigationState(for: self, in: dataStore.viewContext)
        
        do {
            try dataStore.save()
        } catch let error {
            DDLogError("Error saving dataStore: \(error)")
        }
    }

    @objc private func appDidEnterBackgroundWithNotification(_ note: Notification) {
        guard uiIsLoaded else { return }
        startPauseAppBackgroundTask()
        DispatchQueue.main.async {
            self.pauseApp()
        }
    }

    @objc private func preferredLanguagesDidChange(_ note: Notification) {
        updateExploreFeedPreferencesIfNecessaryForChange(note)
        dataStore.feedContentController.updateContentSources()
        updateWMFDataEnvironmentFromLanguagesDidChange()
    }

    /// Updates explore feed preferences if new preferred language was appended or removed.
    private func updateExploreFeedPreferencesIfNecessaryForChange(_ note: Notification) {
        guard !isPresentingOnboarding else { return }

        guard let changeTypeValue = note.userInfo?[WMFPreferredLanguagesChangeTypeKey] as? NSNumber else { return }
        let changeType = WMFPreferredLanguagesChangeType(rawValue: changeTypeValue.intValue)
        guard changeType != nil, changeType != .reorder else { return }

        guard let changedLanguage = note.userInfo?[WMFPreferredLanguagesLastChangedLanguageKey] as? MWKLanguageLink else { return }
        let appendedNewPreferredLanguage = (changeType == .add)
        dataStore.feedContentController.toggleContent(forSiteURL: changedLanguage.siteURL, isOn: appendedNewPreferredLanguage, waitForCallbackFromCoordinator: false, updateFeed: false)
    }

    @objc private func readingListsWereSplitNotification(_ note: Notification) {
        let entryLimit = (note.userInfo?[WMFReadingListsController.readingListsWereSplitNotificationEntryLimitKey] as? Int) ?? 0
        let message = String.localizedStringWithFormat(WMFLocalizedString("reading-lists-split-notification", value: "There is a limit of %1$d articles per reading list. Existing lists with more than this limit have been split into multiple lists.", comment: "Alert message informing user that existing lists exceeding the entry limit have been split into multiple lists. %1$d will be replaced with the maximum number of articles allowed per reading list."), entryLimit)
        WMFToastManager.sharedInstance.showToast(message, sticky: true, dismissPreviousToasts: true, tapCallBack: nil)
    }

    @objc private func readingListsServerDidConfirmSyncWasEnabledForAccountWithNotification(_ note: Notification) {
        let wasSyncEnabledForAccount = (note.userInfo?[WMFReadingListsController.readingListsServerDidConfirmSyncWasEnabledForAccountWasSyncEnabledKey] as? NSNumber)?.boolValue ?? false
        let wasSyncEnabledOnDevice = (note.userInfo?[WMFReadingListsController.readingListsServerDidConfirmSyncWasEnabledForAccountWasSyncEnabledOnDeviceKey] as? NSNumber)?.boolValue ?? false
        let wasSyncDisabledOnDevice = (note.userInfo?[WMFReadingListsController.readingListsServerDidConfirmSyncWasEnabledForAccountWasSyncDisabledOnDeviceKey] as? NSNumber)?.boolValue ?? false
        if wasSyncEnabledForAccount {
            wmf_showSyncEnabledPanelOncePerLoginIfNeeded(wasSyncEnabledOnDevice: wasSyncEnabledOnDevice)
        } else if !wasSyncDisabledOnDevice {
            wmf_showEnableReadingListSyncPanel(theme: theme,
                                              oncePerLogin: true,
                                              didNotPresentPanelCompletion: {
                self.wmf_showSyncDisabledPanelIfNeeded(wasSyncEnabledOnDevice: wasSyncEnabledOnDevice)
                                              },
                                              dismissHandler: nil)
        }
    }

    @objc private func syncDidStartNotification(_ note: Notification) {
        syncStartDate = Date()
    }

    @objc private func syncDidFinishNotification(_ note: Notification) {
        let error = note.userInfo?[WMFReadingListsController.syncDidFinishErrorKey] as? NSError

        // Reminder: kind of class is checked here because `syncDidFinishErrorKey` is sometimes set to a
        // `WMF.ReadingListError` error type which doesn't bridge to Obj-C (causing wmf_isNetworkConnectionError to crash).
        if let error = error, error.wmf_isNetworkConnectionError() {
            if !hasSyncErrorBeenShownThisSession {
                hasSyncErrorBeenShownThisSession = true // only show sync error once for multiple failed syncs
                WMFToastManager.sharedInstance.showToast(WMFLocalizedString("reading-lists-sync-error-no-internet-connection", value: "Syncing will resume when internet connection is available", comment: "Alert message informing user that syncing will resume when internet connection is available."), sticky: true, dismissPreviousToasts: false, tapCallBack: nil)
            }
        }

        if error == nil {
            hasSyncErrorBeenShownThisSession = false // reset on successful sync
            if let syncStartDate = syncStartDate, Date().timeIntervalSince(syncStartDate) >= 5 {
                let syncedReadingListsCount = (note.userInfo?[WMFReadingListsController.syncDidFinishSyncedReadingListsCountKey] as? Int) ?? 0
                let syncedReadingListEntriesCount = (note.userInfo?[WMFReadingListsController.syncDidFinishSyncedReadingListEntriesCountKey] as? Int) ?? 0
                if syncedReadingListsCount > 0 && syncedReadingListEntriesCount > 0 {
                    let alertTitle = String.localizedStringWithFormat(WMFLocalizedString("reading-lists-large-sync-completed", value: "{{PLURAL:%1$d|%1$d article|%1$d articles}} and {{PLURAL:%2$d|%2$d reading list|%2$d reading lists}} synced from your account", comment: "Alert message informing user that large sync was completed. %1$d will be replaced with the number of articles which were synced and %2$d will be replaced with the number of reading lists which were synced"), syncedReadingListEntriesCount, syncedReadingListsCount)
                    WMFToastManager.sharedInstance.showToast(alertTitle, sticky: true, dismissPreviousToasts: true, tapCallBack: nil)
                }
            }
        }
    }

    @objc private func conflictingReadingListNameUpdatedNotification(_ note: Notification) {
        guard let oldName = note.userInfo?[ReadingList.conflictingReadingListNameUpdatedOldNameKey] as? String,
              let newName = note.userInfo?[ReadingList.conflictingReadingListNameUpdatedNewNameKey] as? String else {
            return
        }
        let alertTitle = String.localizedStringWithFormat(WMFLocalizedString("reading-lists-conflicting-reading-list-name-updated", value: "Your list '%1$@' has been renamed to '%2$@'", comment: "Alert message informing user that their reading list was renamed. %1$@ will be replaced the previous name of the list. %2$@ will be replaced with the new name of the list."), oldName, newName)
        WMFToastManager.sharedInstance.showToast(alertTitle, sticky: true, dismissPreviousToasts: true, tapCallBack: nil)
    }

    @objc private func exploreFeedPreferencesDidChange(_ note: Notification) {
        guard let coordinator = note.object as? ExploreFeedPreferencesUpdateCoordinator else { return }
        coordinator.coordinateUpdate(from: self)
    }

    @objc private func showErrorBanner(_ notification: Notification) {
        if let error = notification.userInfo?[NSNotification.showErrorBannerNSErrorKey] as? NSError {
            WMFToastManager.sharedInstance.showErrorAlert(error, sticky: false, dismissPreviousToasts: true, tapCallBack: nil)
        }
    }

    @objc private func autoLoginNeedsEmailToken(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo else {
            return
        }
        
        let vc = createTwoFactorViewControllerFromAutoLoginNotification(userInfo: userInfo, needsEmailToken: true)
        if let vc = vc {
            let navVC = WMFComponentNavigationController(rootViewController: vc, modalPresentationStyle: .overFullScreen, customBarBackgroundColor: nil)
            currentTabNavigationController?.present(navVC, animated: true, completion: nil)
        } else {
            dataStore.authenticationManager.logout(initiatedBy: .app) {}
        }
    }

    @objc private func autoLoginNeedsOathToken(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo else {
            return
        }
        
        let vc = createTwoFactorViewControllerFromAutoLoginNotification(userInfo: userInfo, needsEmailToken: false)
        if let vc = vc {
            let navVC = WMFComponentNavigationController(rootViewController: vc, modalPresentationStyle: .overFullScreen, customBarBackgroundColor: nil)
            currentTabNavigationController?.present(navVC, animated: true, completion: nil)
        } else {
            dataStore.authenticationManager.logout(initiatedBy: .app) {}
        }
    }

    @objc private func articleViewControllerDidDisappear(_ notification: Notification) {
        readingListHintPresenter.dismissToast()
    }

    @objc private func dismissReadingListToast(_ notification: Notification) {
        readingListHintPresenter.dismissToast()
    }

    // MARK: - Explore feed preferences

    private func updateDefaultTab() {
        guard !isUpdatingDefaultTab else { return }
        isUpdatingDefaultTab = true
        DispatchQueue.main.async {
            let update: () -> Void = {
                self.currentTabNavigationController?.popToRootViewController(animated: false)
                self.configureTabController()
                self.selectedIndex = WMFAppTabType.search.rawValue
                self.isUpdatingDefaultTab = false
            }
            if let presented = self.presentedViewController {
                presented.dismiss(animated: true, completion: update)
            } else {
                update()
            }
        }
    }

    @objc private func handleEnableHomeTabDidChange() {
        guard !isUpdatingDefaultTab else { return }
        isUpdatingDefaultTab = true
        DispatchQueue.main.async {
            let update: () -> Void = {
                self.currentTabNavigationController?.popToRootViewController(animated: false)

                self.resetCachedRootTabViewControllers()
                self.configureTabController()
                if let savedTabBarItem = self.savedViewController.tabBarItem {
                    self.savedTabBarItemProgressBadgeManager = SavedTabBarItemProgressBadgeManager(with: savedTabBarItem)
                }
                self.selectedIndex = WMFAppTabType.main.rawValue
                self.isUpdatingDefaultTab = false
            }
            if let presented = self.presentedViewController {
                presented.dismiss(animated: true, completion: update)
            } else {
                update()
            }
        }
    }

    private func resetCachedRootTabViewControllers() {
        _exploreViewController = nil
        _settingsViewController = nil
        _placesViewController = nil
        _savedViewController = nil
        _activityTabViewController = nil
        _searchTabViewController = nil
        homeCoordinator = nil
    }

    // MARK: - Hint

    private func showReadingListHintForArticle(_ article: WMFArticle) {
        guard let visibleVC = visibleViewController() else { return }
        readingListHintPresenter.toggle(presenter: visibleVC, article: article, theme: theme)
    }

    @objc private func descriptionEditWasPublished(_ note: Notification) {
        guard UserDefaults.standard.didShowDescriptionPublishedPanel else { return }
        WMFToastManager.sharedInstance.showRichToast("Your edit was successfully published", subtitle: nil, buttonTitle: nil, image: UIImage(named: "published-pencil"), duration: nil, dismissPreviousToasts: true, tapCallBack: nil, buttonCallBack: nil, completion: nil)
    }

    @objc private func referenceLinkTapped(_ note: Notification) {
        guard let url = note.object as? URL else { return }
        navigate(to: url)
    }

    @objc func visibleViewController() -> UIViewController? {
        let vc = currentTabNavigationController?.visibleViewController
        if vc === self {
            return selectedViewController
        }
        return vc
    }

    // MARK: - Background Fetch

    func performBackgroundFetch(completion: @escaping (UIBackgroundFetchResult) -> Void) {
        DispatchQueue.main.async {
            guard self.isMigrationComplete, let fetcher = self.backgroundFetcherController else {
                completion(.noData)
                return
            }
            fetcher.performBackgroundFetch(completion)
        }
    }

    // MARK: - Background Processing

    func performDatabaseHousekeeping(completion: @escaping (Error?) -> Void) {
        let housekeeper = WMFDatabaseHousekeeper()

        do {
            try housekeeper.performHousekeepingOnManagedObjectContext(dataStore.viewContext, navigationStateController: navigationStateController, cleanupLevel: .low)
        } catch {
            DDLogError("Error on cleanup: \(error)")
        }

        SharedContainerCacheHousekeeping.deleteStaleCachedItems(in: SharedContainerCacheCommonNames.talkPageCache, cleanupLevel: .low)
        SharedContainerCacheHousekeeping.deleteStaleCachedItems(in: SharedContainerCacheCommonNames.didYouKnowCache, cleanupLevel: .low)

        performWMFDataHousekeeping()

        completion(nil)
    }

    // MARK: - Background Tasks

    private func backgroundTaskIdentifier(forKey key: String?) -> UIBackgroundTaskIdentifier {
        guard let key = key else { return .invalid }
        backgroundTasksLock.lock()
        defer { backgroundTasksLock.unlock() }
        return backgroundTasks[key] ?? .invalid
    }

    private func setBackgroundTaskIdentifier(_ identifier: UIBackgroundTaskIdentifier, forKey key: String?) {
        guard let key = key else { return }
        backgroundTasksLock.lock()
        defer { backgroundTasksLock.unlock() }
        if identifier == .invalid {
            backgroundTasks.removeValue(forKey: key)
        } else {
            backgroundTasks[key] = identifier
        }
    }

    private var pauseAppBackgroundTaskIdentifier: UIBackgroundTaskIdentifier {
        get { backgroundTaskIdentifier(forKey: "pauseApp") }
        set { setBackgroundTaskIdentifier(newValue, forKey: "pauseApp") }
    }

    private var migrationBackgroundTaskIdentifier: UIBackgroundTaskIdentifier {
        get { backgroundTaskIdentifier(forKey: "migration") }
        set { setBackgroundTaskIdentifier(newValue, forKey: "migration") }
    }

    private var feedContentFetchBackgroundTaskIdentifier: UIBackgroundTaskIdentifier {
        get { backgroundTaskIdentifier(forKey: "feed") }
        set { setBackgroundTaskIdentifier(newValue, forKey: "feed") }
    }

    private var remoteConfigCheckBackgroundTaskIdentifier: UIBackgroundTaskIdentifier {
        get { backgroundTaskIdentifier(forKey: "remoteConfigCheck") }
        set { setBackgroundTaskIdentifier(newValue, forKey: "remoteConfigCheck") }
    }

    private func startRemoteConfigCheckBackgroundTask(_ expirationHandler: (() -> Void)?) {
        guard remoteConfigCheckBackgroundTaskIdentifier == .invalid else { return }
        remoteConfigCheckBackgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "com.wikipedia.background.task.remote.config.check") {
            expirationHandler?()
        }
    }

    private func endRemoteConfigCheckBackgroundTask() {
        guard remoteConfigCheckBackgroundTaskIdentifier != .invalid else { return }
        let taskID = remoteConfigCheckBackgroundTaskIdentifier
        remoteConfigCheckBackgroundTaskIdentifier = .invalid
        UIApplication.shared.endBackgroundTask(taskID)
    }

    private func startPauseAppBackgroundTask() {
        guard pauseAppBackgroundTaskIdentifier == .invalid else { return }
        pauseAppBackgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "com.wikipedia.background.task.pause.app") { [weak self] in
            self?.endPauseAppBackgroundTask()
        }
    }

    private func endPauseAppBackgroundTask() {
        guard pauseAppBackgroundTaskIdentifier != .invalid else { return }
        let taskID = pauseAppBackgroundTaskIdentifier
        pauseAppBackgroundTaskIdentifier = .invalid
        UIApplication.shared.endBackgroundTask(taskID)
    }

    private func startMigrationBackgroundTask(_ expirationHandler: (() -> Void)?) {
        guard migrationBackgroundTaskIdentifier == .invalid else { return }
        migrationBackgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "com.wikipedia.background.task.migration") {
            expirationHandler?()
        }
    }

    private func endMigrationBackgroundTask() {
        guard migrationBackgroundTaskIdentifier != .invalid else { return }
        let taskID = migrationBackgroundTaskIdentifier
        migrationBackgroundTaskIdentifier = .invalid
        UIApplication.shared.endBackgroundTask(taskID)
    }

    @objc private func feedContentControllerBusyStateDidChange(_ note: Notification) {
        guard note.object as AnyObject === dataStore.feedContentController else { return }
        if dataStore.feedContentController.isBusy {
            startFeedContentFetchBackgroundTask()
        } else {
            endFeedContentFetchBackgroundTask()
        }
    }

    private func startFeedContentFetchBackgroundTask() {
        guard feedContentFetchBackgroundTaskIdentifier == .invalid else { return }
        feedContentFetchBackgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "com.wikipedia.background.task.feed.content") { [weak self] in
            self?.dataStore.feedContentController.cancelAllFetches()
            self?.endFeedContentFetchBackgroundTask()
        }
    }

    private func endFeedContentFetchBackgroundTask() {
        guard feedContentFetchBackgroundTaskIdentifier != .invalid else { return }
        let taskID = feedContentFetchBackgroundTaskIdentifier
        feedContentFetchBackgroundTaskIdentifier = .invalid
        UIApplication.shared.endBackgroundTask(taskID)
    }

    // MARK: - Launch

    func launchApp(in window: UIWindow, waitToResumeApp: Bool) {

        isWaitingToResumeApp = waitToResumeApp

        window.rootViewController = self
        window.makeKeyAndVisible()

        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForegroundWithNotification(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActiveWithNotification(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActiveWithNotification(_:)), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackgroundWithNotification(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(feedContentControllerBusyStateDidChange(_:)), name: NSNotification.Name(rawValue: WMFExploreFeedContentControllerBusyStateDidChange), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(preferredLanguagesDidChange(_:)), name: NSNotification.Name.WMFPreferredLanguagesDidChange, object: nil)

        showSplashView()
        migrateIfNecessary()
    }

    private func migrateIfNecessary() {
        guard !isMigrationComplete && !isMigrationActive else { return }

        startMigrationBackgroundTask {
            self.endMigrationBackgroundTask()
        }

        isMigrationActive = true

        let store = dataStore // Triggers init
        store.finishSetup {
            if store.needsMigration() {
                self.triggerMigratingAnimation()
            }

            self.setupTips()
            self.setupWMFDataEnvironment()
            self.setupWMFDataCoreDataStore()

            store.performLibraryUpdates {
                DispatchQueue.main.async {
                    self.isMigrationComplete = true
                    self.isMigrationActive = false
                    self.endMigrationBackgroundTask()
                    self.applyUITestLaunchOverridesIfNeeded()
                    self.checkRemoteAppConfigIfNecessary()
                    self.setupControllers()
                    if !self.isWaitingToResumeApp {
                        self.resumeApp(nil)
                    }
                }
            }
        }
    }

    private func applyUITestLaunchOverridesIfNeeded() {
        if UserDefaults.standard.bool(forKey: wmfResetPreferredLanguages) {
            dataStore.languageLinkController.resetPreferredLanguages()
        }

        if UserDefaults.standard.bool(forKey: wmfSuppressReadingChallengeAnnouncementForTesting) {
            let sharedDefaults = UserDefaults(suiteName: "group.org.wikimedia.wikipedia")
            sharedDefaults?.set(
                true,
                forKey: WMFUserDefaultsKey.hasSeenFullPageReadingChallengeAnnouncement2026.rawValue
            )
            sharedDefaults?.synchronize()
        }

        if UserDefaults.standard.bool(forKey: wmfSuppressActivityTabOnboardingForTesting) {
            try? WMFDataEnvironment.current.userDefaultsStore?.save(
                key: WMFUserDefaultsKey.hasSeenActivityTabNewOnboarding.rawValue,
                value: true
            )
        }

        if UserDefaults.standard.bool(forKey: wmfSuppressGamesAnnouncementForTesting) {
            UserDefaults.standard.set(true, forKey: WMFUserDefaultsKey.hasSeenGamesAnnouncement.rawValue)
        }
    }

    // MARK: - Start/Pause/Resume App

    func hideSplashScreenAndResumeApp() {
        isWaitingToResumeApp = false
        if isMigrationComplete {
            resumeApp(nil)
        }
    }

    // resumeApp: should be called once and only once for every launch from a fully terminated state.
    // It should only be called when the app is active and being shown to the user.
    private func resumeApp(_ completion: (() -> Void)?) {
        presentOnboardingIfNeeded { didShowOnboarding in
            self.loadMainUI()
            let done: () -> Void = {
                DispatchQueue.main.async {
                    self.presentLanguageVariantAlerts {
                        DispatchQueue.main.async {
                            self.finishResumingApp()
                            completion?()
                        }
                    }
                }
            }

            let kTemporaryAccountAlertShownKey = "TemporaryAccountAlertShown"
            if self.dataStore.authenticationManager.authStateIsTemporary && !UserDefaults.standard.bool(forKey: kTemporaryAccountAlertShownKey) {
                WMFToastManager.sharedInstance.showRichToast(
                    WMFLocalizedString("alert-temporary-account", value: "You are using a temporary account. Account will expire in 90 days.", comment: "Alert message informing user that they are using a temporary account"),
                    subtitle: nil,
                    buttonTitle: WMFLocalizedString("alert-temporary-account-learn-more", value: "Learn more.", comment: "Button on alert for temporary accounts to learn more."),
                    image: UIImage(named: "exclamation-point"),
                    duration: 10,
                    dismissPreviousToasts: true,
                    tapCallBack: {
                        let tempVC = TempAccountExpiryViewController()
                        tempVC.start()
                        if let navController = self.navigationController {
                            navController.pushViewController(tempVC, animated: true)
                        } else {
                            let navController = UINavigationController(rootViewController: tempVC)
                            navController.modalPresentationStyle = .fullScreen
                            self.present(navController, animated: true, completion: nil)
                        }
                    },
                    buttonCallBack: nil,
                    completion: nil)

                UserDefaults.standard.set(true, forKey: kTemporaryAccountAlertShownKey)
                UserDefaults.standard.synchronize()
            }

            if let info = self.notificationUserInfoToShow {
                self.hideSplashView()
                self.showNotificationCenterForNotificationInfo(info)
                self.notificationUserInfoToShow = nil
                done()
            } else if let activity = self.unprocessedUserActivity {
                self.processUserActivity(activity, animated: false) {
                    self.hideSplashView()
                    done()
                }
            } else if let shortcutItem = self.unprocessedShortcutItem {
                self.hideSplashView()
                self.processShortcutItem(shortcutItem) { _ in
                    done()
                }
            } else if UserDefaults.standard.shouldRestoreNavigationStackOnResume {
                self.navigationStateController.restoreLastArticle(for: self, in: self.dataStore.viewContext, with: self.theme) {
                    self.hideSplashView()
                    
                    do {
                        try self.dataStore.save()
                    } catch {
                        DDLogError("Error saving dataStore: \(error)")
                    }

                    done()
                }
                _ = self.dataStore.authenticationManager.authStateIsTemporary
            } else if self.shouldShowExploreScreenOnLaunch() {
                self.hideSplashView()
                self.showExplore()
                done()
            } else {
                self.hideSplashView()
                done()
            }
        }
    }

    private func finishResumingApp() {
        let resumeAndAnnouncementsCompleteGroup = WMFTaskGroup()
        resumeAndAnnouncementsCompleteGroup.enter()
        dataStore.authenticationManager.attemptLogin {
            self.checkRemoteAppConfigIfNecessary()
            if self.reachabilityNotifier == nil {
                self.reachabilityNotifier = ReachabilityNotifier(Configuration.current.defaultSiteDomain) { [weak self] isReachable, _ in
                    DispatchQueue.main.async {
                        if isReachable {
                            self?.savedArticlesFetcher?.start()
                        } else {
                            self?.savedArticlesFetcher?.stop()
                        }
                    }
                }
            }
            self.isResumeComplete = true
            resumeAndAnnouncementsCompleteGroup.leave()
            self.performTasksThatShouldOccurAfterBecomeActiveAndResume()
            self.showLoggedOutPanelIfNeeded()
            let key = WMFUserDefaultsKey.needsDailyGameFeedRefresh.rawValue
            if UserDefaults.standard.bool(forKey: key) {
                UserDefaults.standard.removeObject(forKey: key)
                NotificationCenter.default.post(name: WMFNSNotification.refreshExploreForGamesCard, object: nil)
            }
        }

        dataStore.feedContentController.startContentSources()

        let defaults = UserDefaults.standard
        let feedRefreshDate = defaults.wmf_feedRefreshDate()
        let now = Date()

        let locationAuthorized = LocationManagerFactory.coarseLocationManager().isAuthorized
        if feedRefreshDate == nil || now.timeIntervalSince(feedRefreshDate!) > timeBeforeRefreshingExploreFeed() || NSCalendar.wmf_gregorian().wmf_days(from: feedRefreshDate!, to: now) > 0 {
            resumeAndAnnouncementsCompleteGroup.enter()
            exploreViewController.updateFeedSources(with: nil, userInitiated: false) {
                resumeAndAnnouncementsCompleteGroup.leave()
            }
        } else {
            if locationAuthorized != defaults.wmf_locationAuthorized() {
                dataStore.feedContentController.updateContentSource(WMFNearbyContentSource.self, force: false, completion: nil)
            }
            if !UserDefaults.standard.shouldRestoreNavigationStackOnResume {
                dataStore.feedContentController.updateContentSource(WMFContinueReadingContentSource.self, force: true, completion: nil)
            }

            resumeAndAnnouncementsCompleteGroup.enter()
            dataStore.feedContentController.updateContentSource(WMFAnnouncementsContentSource.self, force: true) {
                resumeAndAnnouncementsCompleteGroup.leave()
            }
        }

        resumeAndAnnouncementsCompleteGroup.waitInBackground {
            self.performTasksThatShouldOccurAfterAnnouncementsUpdated()
        }

        defaults.wmf_setLocationAuthorized(locationAuthorized)

        savedArticlesFetcher?.start()
    }

    private func timeBeforeRefreshingExploreFeed() -> TimeInterval {
        var timeInterval: TimeInterval = 2 * 60 * 60
        let key = WMFFeedDayResponse.wmfFeedDayResponseMaxAgeKey()
        if let value = dataStore.viewContext.wmf_numberValue(forKey: key) {
            timeInterval = value.doubleValue
        }
        return timeInterval
    }

    private func pauseApp() {
        SessionsFunnel.shared.appDidBackground()

        guard uiIsLoaded else {
            endPauseAppBackgroundTask()
            return
        }

        UserDefaults.standard.wmf_setDidShowSyncDisabledPanel(false)

        reachabilityNotifier?.stop()
        periodicWorkerController?.stop()
        savedArticlesFetcher?.stop()

        dataStore.feedContentController.stopContentSources()
        dataStore.clearMemoryCache()

        endPauseAppBackgroundTask()
    }

    // MARK: - Memory Warning

    override func didReceiveMemoryWarning() {
        guard uiIsLoaded else { return }
        super.didReceiveMemoryWarning()
        _settingsViewController = nil
        dataStore.clearMemoryCache()
    }

    // MARK: - Shortcut

    private func canProcessShortcutItem(_ item: UIApplicationShortcutItem?) -> Bool {
        guard let item else { return false }
        return item.type == WMFIconShortcutTypeSearch || item.type == WMFIconShortcutTypeRandom || item.type == WMFIconShortcutTypeNearby
    }

    func processShortcutItem(_ item: UIApplicationShortcutItem, completion: ((Bool) -> Void)?) {
        guard canProcessShortcutItem(item) else {
            completion?(false)
            return
        }

        guard uiIsLoaded else {
            unprocessedShortcutItem = item
            completion?(true)
            return
        }
        unprocessedShortcutItem = nil

        if item.type == WMFIconShortcutTypeSearch {
            if visibleArticleViewController() != nil {
                showSearchInCurrentNavigationController()
            } else {
                switchToSearch(animated: false)
                searchTabViewController.makeSearchBarBecomeFirstResponder()
            }
        } else if item.type == WMFIconShortcutTypeRandom {
            showRandomArticleFromShortcut(animated: false)
        } else if item.type == WMFIconShortcutTypeNearby {
            showNearby(animated: false)
        }
        completion?(true)
    }

    // MARK: - NSUserActivity

    private func canProcessUserActivity(_ activity: NSUserActivity?) -> Bool {
        guard let activity else { return false }
        switch activity.wmf_type() {
        case .explore, .places, .savedPages, .search, .settings, .appearanceSettings, .content, .activity, .random:
            return true
        case .searchResults:
            return activity.wmf_searchTerm() != nil
        case .link:
            return activity.wmf_linkURL() != nil
        default:
            return false
        }
    }

    @objc private func navigateToActivityNotification(_ note: Notification) {
        guard let activity = note.object as? NSUserActivity else { return }
        processUserActivity(activity, animated: true) {}
    }

    @discardableResult
    func processUserActivity(_ activity: NSUserActivity, animated: Bool, completion done: @escaping () -> Void) -> Bool {
        guard canProcessUserActivity(activity) else {
            done()
            return false
        }
        guard uiIsLoaded && !isWaitingToResumeApp else {
            unprocessedUserActivity = activity
            done()
            return true
        }
        unprocessedUserActivity = nil

        let type = activity.wmf_type()

        switch type {
        case .explore:
            dismissPresentedViewControllers()
            selectedIndex = WMFAppTabType.main.rawValue
            currentTabNavigationController?.popToRootViewController(animated: animated)

        case .places:
            dismissPresentedViewControllers()
            selectedIndex = WMFAppTabType.places.rawValue
            currentTabNavigationController?.popToRootViewController(animated: animated)
            if let articleURL = activity.wmf_linkURL() {
                placesViewController.updateViewModeToMap()
                placesViewController.showArticleURL(articleURL)
            }

        case .random:
            dismissPresentedViewControllers()
            showRandomArticleFromShortcut(siteURL: siteURL, animated: animated)

        case .activity:
            
            let activityVC = activityTabViewController
            activityVC.disableModalsOnAppearance = true
            
            dismissPresentedViewControllers()
            selectedIndex = WMFAppTabType.recent.rawValue
            currentTabNavigationController?.popToRootViewController(animated: animated)
            let shouldCollectPrize = activity.userInfo?["collectPrize"] as? Bool ?? false
            let tappedJoin = activity.userInfo?["join"] as? Bool ?? false
            let fromAppStoreEvent = activity.userInfo?["appStoreEvent"] as? Bool ?? false
            
            if shouldCollectPrize {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    activityVC.presentCollectPrize()
                }
            } else if tappedJoin {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    activityVC.presentReadingChallengeAnnouncementFromWidget()
                }
            } else if fromAppStoreEvent {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    activityVC.presentReadingChallengeAnnouncementFromAppStoreEvent()
                }
            }

        case .content:
            dismissPresentedViewControllers()
            selectedIndex = WMFAppTabType.main.rawValue
            let navController = currentTabNavigationController
            navController?.popToRootViewController(animated: animated)
            let url = contentURL(for: activity)
            if let url, let group = dataStore.viewContext.contentGroup(for: url) {
                switch group.detailType {
                case .gallery:
                    if let vc = group.detailViewControllerForPreviewItemAtIndex(0, dataStore: dataStore, theme: theme, source: .undefined) {
                        currentTabNavigationController?.present(vc, animated: false, completion: nil)
                    }
                default:
                    if let vc = group.detailViewControllerWithDataStore(dataStore, theme: theme) {
                        navController?.pushViewController(vc, animated: animated)
                    }
                }
            } else if let url {
                exploreViewController.updateFeedSources(with: nil, userInitiated: false) {
                    DispatchQueue.main.async {
                        if let group = self.dataStore.viewContext.contentGroup(for: url),
                           let vc = group.detailViewControllerWithDataStore( self.dataStore, theme: self.theme) {
                            navController?.pushViewController(vc, animated: false)
                        }
                    }
                }
            }

        case .savedPages:
            dismissPresentedViewControllers()
            selectedIndex = WMFAppTabType.saved.rawValue
            currentTabNavigationController?.popToRootViewController(animated: animated)

        case .search:
            switchToSearch(animated: animated)
            searchTabViewController.makeSearchBarBecomeFirstResponder()

        case .searchResults:
            dismissPresentedViewControllers()
            searchTabViewController.searchAndMakeResultsVisibleForSearchTerm( activity.wmf_searchTerm(), animated: animated)
            switchToSearch(animated: animated)

        case .settings:
            dismissPresentedViewControllers()
            selectedIndex = WMFAppTabType.main.rawValue
            currentTabNavigationController?.popToRootViewController(animated: false)
            showSettings(animated: animated)

        case .appearanceSettings:
            dismissPresentedViewControllers()
            selectedIndex = WMFAppTabType.main.rawValue
            currentTabNavigationController?.popToRootViewController(animated: false)
            let appearanceSettingsVC = AppearanceSettingsViewController()
            appearanceSettingsVC.apply(theme: theme)
            showSettings(with: appearanceSettingsVC, animated: animated)

        default:
            dismissPresentedViewControllers()
            if processLinkUserActivity(activity) {
                done()
                return true
            }
            // Fall back to legacy navigation
            var linkURL = activity.wmf_linkURL()
            if linkURL?.wmf_languageVariantCode == nil {
                let languageCode = linkURL?.wmf_languageCode
                linkURL?.wmf_languageVariantCode = dataStore.languageLinkController.preferredLanguageVariantCode(forLanguageCode: languageCode)
            }
            guard let url = linkURL else {
                done()
                return false
            }
            NSUserActivity.wmf_makeActive(activity)
            if let router = self.router {
                return router.route(url, userInfo: activity.userInfo, completion: done)
            } else {
                done()
                return false
            }
        }

        done()
        NSUserActivity.wmf_makeActive(activity)
        return true
    }

    private func contentURL(for activity: NSUserActivity) -> URL? {
        var contentURL = activity.wmf_contentURL()

        // T356255 - Picture Of The Day not opening when the primary language has a language variant code
        let path = contentURL.path
        if path.contains("picture-of-the-day") {
            let primaryLanguageVariantCode = dataStore.languageLinkController.appLanguage?.languageVariantCode
            if let code = primaryLanguageVariantCode, contentURL.wmf_languageVariantCode == nil {
                contentURL.wmf_languageVariantCode = code
            }
        }
        return contentURL
    }

    private func shouldShowExploreScreenOnLaunch() -> Bool {
        guard !shouldOpenAppOnSearchTab() else { return false }
        guard let resignActiveDate = UserDefaults.standard.wmf_appResignActiveDate() else { return false }
        return abs(resignActiveDate.timeIntervalSinceNow) >= wmfTimeBeforeShowingExploreScreenOnLaunch
    }

    private func visibleArticleViewController() -> ArticleViewController? {
        guard let topVC = currentTabNavigationController?.topViewController else { return nil }
        return topVC as? ArticleViewController
    }

    // MARK: - Accessors

    var savedArticlesFetcher: SavedArticlesFetcher? {
        guard uiIsLoaded else { return nil }
        
        guard let _savedArticlesFetcher else {
            let fetcher = SavedArticlesFetcher(dataStore: dataStore)
            fetcher?.addObserver(self,
                                forKeyPath: #keyPath(SavedArticlesFetcher.progress),
                                options: [.initial, .new, .old],
                                context: &kvoSavedArticlesFetcherProgress)
            _savedArticlesFetcher = fetcher
            return fetcher
        }
        
        return _savedArticlesFetcher
    }

    // swiftlint:disable:next block_based_kvo
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if context == &kvoSavedArticlesFetcherProgress {
            ProgressContainer.shared.articleFetcherProgress = _savedArticlesFetcher?.progress
        } else if context == &kvoNSUserDefaultsDefaultTabType {
            updateDefaultTab()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    private var notificationsController: WMFNotificationsController {
        return self.dataStore.notificationsController
    }
    
    var dataStore: MWKDataStore {
        return MWKDataStore.shared()
    }

    var navigationStateController: NavigationStateController {
        
        guard let _navigationStateController else {
            let navStateVC = NavigationStateController(dataStore: dataStore)
            _navigationStateController = navStateVC
            return navStateVC
        }
        
        return _navigationStateController
    }

    var exploreViewController: ExploreViewController {
        
        guard let _exploreViewController else {
            let vc = ExploreViewController()
            vc.dataStore = dataStore
            vc.notificationsCenterPresentationDelegate = self
            vc.tabBarItem.image = UIImage(named: "tabbar-explore")
            vc.tabBarItem.accessibilityIdentifier = AccessibilityIdentifiers.RootTab.exploreButton
            vc.title = WMFCommonStringsWrapper.exploreTabTitle
            vc.apply(theme: theme)
            _exploreViewController = vc
            return vc
        }
        
        return _exploreViewController
    }

    @objc func handleExploreCenterBadgeNeedsUpdateNotification() {
        DispatchQueue.main.async {
            if let homeViewController = self.homeCoordinator?.homeViewController {
                homeViewController.updateProfileButton()
            } else {
                self.exploreViewController.updateProfileButton()
            }
            if UserDefaults.standard.defaultTabType == .settings {
                self.settingsViewController.updateProfileButton()
            }
        }
    }

    @objc func handleNotificationsCenterContextDidSave() {
        DispatchQueue.main.async {
            try? UNUserNotificationCenter.current().setBadgeCount(self.dataStore.remoteNotificationsController.numberOfUnreadNotifications().intValue)
            try? self.dataStore.remoteNotificationsController.updateCacheWithCurrentUnreadNotificationsCount()
        }
    }

    var searchTabViewController: SearchViewController {
        
        guard let _searchTabViewController else {
            let vc = SearchViewController(source: .searchTab)
            vc.apply(theme: theme)
            vc.dataStore = dataStore
            vc.tabBarItem = UITabBarItem(tabBarSystemItem: .search, tag: Int(WMFAppTabType.search.rawValue))
            vc.tabBarItem.accessibilityIdentifier = AccessibilityIdentifiers.RootTab.searchButton
            vc.title = WMFCommonStringsWrapper.searchTitle
            _searchTabViewController = vc
            return vc
        }
        
        return _searchTabViewController
    }

    var savedViewController: SavedViewController {
        
        guard let _savedViewController else {
            guard let vc = UIStoryboard(name: "Saved", bundle: nil).instantiateInitialViewController() as? SavedViewController else {
                fatalError("Unable to instantiate Saved View Controller")
            }
            vc.apply(theme: theme)
            vc.dataStore = dataStore
            vc.tabBarDelegate = self
            vc.tabBarItem.image = UIImage(named: "tabbar-save")
            vc.tabBarItem.accessibilityIdentifier = AccessibilityIdentifiers.RootTab.savedButton
            vc.title = WMFCommonStringsWrapper.savedTabTitle
            _savedViewController = vc
            return vc
        }
        
        return _savedViewController
    }

    var activityTabViewController: WMFActivityTabViewController {
        
        guard let _activityTabViewController else {
            let vc = generateActivityTab()
            vc.tabBarItem.image = UIImage(named: "tabbar-recent")
            vc.tabBarItem.accessibilityIdentifier = AccessibilityIdentifiers.RootTab.activityButton
            vc.title = WMFCommonStringsWrapper.activityTitle
            _activityTabViewController = vc
            return vc
        }
        
        return _activityTabViewController
    }

    var placesViewController: PlacesViewController {
        
        guard let _placesViewController else {
            let vc = UIStoryboard(name: "Places", bundle: nil).instantiateInitialViewController() as! PlacesViewController
            vc.apply(theme: theme)
            vc.tabBarItem.image = UIImage(named: "tabbar-nearby")
            vc.tabBarItem.accessibilityIdentifier = AccessibilityIdentifiers.RootTab.placesButton
            vc.title = WMFCommonStringsWrapper.placesTabTitle
            _placesViewController = vc
            return vc
        }
        
        return _placesViewController
    }

    // MARK: - Onboarding

    private static let wmfDidShowOnboarding = "DidShowOnboarding5.3"

    private func shouldShowOnboarding() -> Bool {
        guard let unprocessedUserActivity,
              unprocessedUserActivity.shouldSkipOnboarding else {
            
            return !UserDefaults.standard.bool(forKey: Self.wmfDidShowOnboarding)
        }
        
        setDidShowOnboarding()
        return false
        
    }

    private func setDidShowOnboarding() {
        UserDefaults.standard.set(NSNumber(value: true), forKey: Self.wmfDidShowOnboarding)
        UserDefaults.standard.set(MWKDataStore.currentLibraryVersion, forKey: WMFLanguageVariantAlertsLibraryVersion)
    }

    private func presentOnboardingIfNeeded(completion: @escaping (Bool) -> Void) {
        guard shouldShowOnboarding() else {
            completion(false)
            return
        }
        
        let vc = WMFWelcomeInitialViewController.wmf_viewControllerFromWelcomeStoryboard()
        vc.apply(theme: theme)
        vc.completionBlock = {
            self.setDidShowOnboarding()
            completion(true)
        }
        hideSplashView()
        vc.modalPresentationStyle = .overFullScreen
        present(vc, animated: false, completion: nil)
    }

    // MARK: - Splash

    func showSplashView() {
        guard splashScreenViewController == nil else { return }
        let vc = SplashScreenViewController(nibName: nil, bundle: nil)
        vc.beginAppearanceTransition(true, animated: false)
        vc.apply(theme: theme)
        view.wmf_addSubviewWithConstraintsToEdges(vc.view)
        vc.endAppearanceTransition()
        splashScreenViewController = vc
    }

    func hideSplashView() {
        guard let vc = splashScreenViewController else { return }
        vc.beginAppearanceTransition(false, animated: false)
        vc.view.removeFromSuperview()
        vc.endAppearanceTransition()
        splashScreenViewController = nil
    }

    private func triggerMigratingAnimation() {
        splashScreenViewController?.triggerMigratingAnimation()
    }

    // MARK: - Explore VC

    private func showExplore() {
        selectedIndex = WMFAppTabType.main.rawValue
        currentTabNavigationController?.popToRootViewController(animated: false)
    }

    // MARK: - Show Search

    private func switchToSearch(animated: Bool) {
        dismissPresentedViewControllers()
        if selectedIndex != WMFAppTabType.search.rawValue {
            selectedIndex = WMFAppTabType.search.rawValue
        }
        currentTabNavigationController?.popToRootViewController(animated: animated)
    }

    /// Switches to the Search tab, optionally focusing the search bar. Dismisses any presented flow (e.g. modally presented Settings) first.
    func switchToSearchTab(focusSearchBar: Bool, animated: Bool) {
        switchToSearch(animated: animated)
        if focusSearchBar {
            searchTabViewController.makeSearchBarBecomeFirstResponder()
        }
    }

    // MARK: - App Shortcuts

    func dismissPresentedViewControllers() {
        if presentedViewController != nil {
            dismiss(animated: false, completion: nil)
        }
        if currentTabNavigationController?.presentedViewController != nil {
            currentTabNavigationController?.dismiss(animated: false, completion: nil)
        }
    }

    private func showRandomArticleFromShortcut(animated: Bool) {
        dismissPresentedViewControllers()
        showRandomArticleFromShortcut(siteURL: siteURL, animated: animated)
    }

    private func showNearby(animated: Bool) {
        dismissPresentedViewControllers()
        selectedIndex = WMFAppTabType.places.rawValue
        currentTabNavigationController?.popToRootViewController(animated: false)
        placesViewController.showNearbyArticles()
    }

    // MARK: - App config

    private func checkRemoteAppConfigIfNecessary() {
        assert(Thread.isMainThread, "Remote app config check must start from the main thread")
        guard !isCheckingRemoteConfig else { return }
        isCheckingRemoteConfig = true

        let lastCheckTime = (dataStore.viewContext.wmf_numberValue(forKey: wmfLastRemoteAppConfigCheckAbsoluteTimeKey))?.doubleValue ?? 0.0
        let now = CFAbsoluteTimeGetCurrent()
        let shouldCheck = (now - lastCheckTime) >= wmfRemoteAppConfigCheckInterval || !dataStore.remoteConfigsThatFailedUpdate.isEmpty
        guard shouldCheck else {
            isCheckingRemoteConfig = false
            return
        }

        dataStore.isLocalConfigUpdateAllowed = true
        startRemoteConfigCheckBackgroundTask {
            self.dataStore.isLocalConfigUpdateAllowed = false
            self.endRemoteConfigCheckBackgroundTask()
        }
        dataStore.updateLocalConfigurationFromRemoteConfiguration { error in
            if error == nil && self.dataStore.isLocalConfigUpdateAllowed {
                self.dataStore.viewContext.wmf_setValue(NSNumber(value: now), forKey: wmfLastRemoteAppConfigCheckAbsoluteTimeKey)
            }
            self.isCheckingRemoteConfig = false
            self.endRemoteConfigCheckBackgroundTask()
        }
    }

    private func updatePrimaryWikiHasTempAccountsStatusIfNecessary() {
        let lastCheckTime = (dataStore.viewContext.wmf_numberValue(forKey: wmfTempAccountConfigCheckAbsoluteTimeKey))?.doubleValue ?? 0.0
        let now = CFAbsoluteTimeGetCurrent()
        guard (now - lastCheckTime) >= wmfTempAccountConfigCheckInterval else { return }
        if let languageCode = dataStore.languageLinkController.appLanguage?.languageCode {
            WMFTempAccountDataController.shared.checkWikiTempAccountAvailability(language: languageCode, isCheckingPrimaryWiki: true)
        }
       
    }

}

// MARK: - UITabBarControllerDelegate

extension WMFAppViewController: UITabBarControllerDelegate {

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        wmf_hideKeyboard()
        logDidSelectViewController(viewController)
    }

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        
        guard let current = tabBarController.selectedViewController else {
            return false
        }
        
        let selected = viewController

        if viewController == tabBarController.selectedViewController {
            switch tabBarController.selectedIndex {
            case WMFAppTabType.main.rawValue:
                exploreViewController.scrollToTop()
            case WMFAppTabType.search.rawValue:
                searchTabViewController.makeSearchBarBecomeFirstResponder()
            default:
                break
            }

            if (currentTabNavigationController?.viewControllers.count ?? 0) > 1 {
                logTabBarSelectionsForActivityTab(currentTabSelection: current, newTabSelection: selected)
                return true
            } else {
                // Must return NO if already visible to prevent unintended effect when tapping the Search tab bar button multiple times.
                return false
            }
        }

        logTabBarSelectionsForActivityTab(currentTabSelection: current, newTabSelection: selected)

        // When switching to Activity via tab bar button, increment the visit count
        if let navVC = viewController as? UINavigationController,
           navVC.viewControllers.count == 1,
           navVC.viewControllers[0] is WMFActivityTabViewController {
            incrementActivityTabVisitCount()
        }

        return true
    }

    private func updateActiveTitleAccessibilityButton(_ viewController: UIViewController) {
        guard let vc = viewController as? ArticleViewController else { return }
        if selectedIndex == WMFAppTabType.main.rawValue {
            vc.navigationItem.titleView?.accessibilityLabel = WMFLocalizedString("home-button-explore-accessibility-label", value: "Wikipedia, return to Explore", comment: "Accessibility heading for articles shown within the explore tab, indicating that tapping it will take you back to explore. \"Explore\" is the same as {{msg-wikimedia|Wikipedia-ios-welcome-explore-title}}.")
        } else if selectedIndex == WMFAppTabType.saved.rawValue {
            vc.navigationItem.titleView?.accessibilityLabel = WMFLocalizedString("home-button-saved-accessibility-label", value: "Wikipedia, return to Saved", comment: "Accessibility heading for articles shown within the saved articles tab, indicating that tapping it will take you back to the list of saved articles. \"Saved\" is the same as {{msg-wikimedia|Wikipedia-ios-saved-title}}.")
        }
    }
}

// MARK: - UINavigationControllerDelegate

extension WMFAppViewController: UINavigationControllerDelegate {

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        updateActiveTitleAccessibilityButton(viewController)
    }

    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return transitionsController?.navigationController(navigationController, interactionControllerFor: animationController)
    }

    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return transitionsController?.navigationController(navigationController, animationControllerFor: operation, from: fromVC, to: toVC)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension WMFAppViewController: UNUserNotificationCenterDelegate {

    // The method will be called on the delegate only if the application is in the foreground.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if notification.request.content.threadIdentifier == EchoModelVersion.current {
            NotificationCenter.default.post(name: NSNotification.pushNotificationBannerDidDisplayInForeground, object: nil, userInfo: notification.request.content.userInfo)
        }
        completionHandler([.list, .banner])
    }

    // The method will be called on the delegate when the user responded to the notification by opening the application.
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let info = response.notification.request.content.userInfo

#if !TEST
        // Mark the app open source as "notification" so SceneDelegate will submit the apps-open instrument with actionSource = "notification".
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene,
               let sceneDelegate = windowScene.delegate as? SceneDelegate {
                sceneDelegate.lastOpenSource = "notification"
                break
            }
        }
#endif

        if response.notification.request.content.threadIdentifier == EchoModelVersion.current {
            showNotificationCenterForNotificationInfo(info)
        }

        completionHandler()
    }

    private func showNotificationCenterForNotificationInfo(_ info: [AnyHashable: Any]) {
        guard isMigrationComplete else {
            notificationUserInfoToShow = info
            return
        }
        userDidTapPushNotification()
    }
}

// MARK: - Themeable

extension WMFAppViewController: Themeable {

    private func applyTheme(_ theme: Theme, toNavigationControllers navigationControllers: [UINavigationController]) {
        var foundNavigationControllers = Set<UINavigationController>()
        for nc in navigationControllers {
            for vc in nc.viewControllers {
                if vc !== self, let themeable = vc as? Themeable {
                    themeable.apply(theme: theme)
                }
                if let presented = vc.presentedViewController as? UINavigationController {
                    foundNavigationControllers.insert(presented)
                }
            }
            if let presented = nc.presentedViewController as? UINavigationController {
                foundNavigationControllers.insert(presented)
            }
        }

        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).textColor = theme.colors.primaryText

        if !foundNavigationControllers.isEmpty {
            applyTheme(theme, toNavigationControllers: Array(foundNavigationControllers))
        }
    }

    private func allNavigationControllers() -> [UINavigationController] {
        var navControllers: [UINavigationController] = []
        for vc in viewControllers ?? [] {
            if let nav = vc as? UINavigationController {
                navControllers.append(nav)
            }
        }
        if let settingsNav = _settingsNavigationController {
            navControllers.append(settingsNav)
        }
        return navControllers
    }

    private func applyTheme(_ theme: Theme, toPresentedViewController viewController: UIViewController?) {
        guard let viewController = viewController else { return }

        if let themeable = viewController as? Themeable {
            themeable.apply(theme: theme)
        }

        if let navController = viewController.presentedViewController as? UINavigationController {
            applyTheme(theme, toNavigationControllers: [navController])
        } else {
            applyTheme(theme, toPresentedViewController: viewController.presentedViewController)
        }
    }

    func apply(theme: Theme) {
        self.theme = theme

        view.backgroundColor = theme.colors.baseBackground
        view.tintColor = theme.colors.link

        // Ensures theming happens after main UI is loaded
        
        guard (viewControllers?.count ?? 0) > 0 else {
            return
        }
        
        if UserDefaults.standard.defaultTabType == .settings {
            settingsViewController.apply(theme: theme)
        }
        exploreViewController.apply(theme: theme)
        placesViewController.apply(theme: theme)
        savedViewController.apply(theme: theme)
        searchTabViewController.apply(theme: theme)

        applyTheme(theme, toPresentedViewController: presentedViewController)

        WMFToastManager.sharedInstance.apply(theme: theme)

        applyTheme(theme, toNavigationControllers: allNavigationControllers())

        tabBar.apply(theme: theme)

        UISwitch.appearance().onTintColor = theme.colors.accent

        readingListHintPresenter.apply(theme: theme)

        setNeedsStatusBarAppearanceUpdate()
    }

    @objc private func updateAppThemeIfNecessary() {
        let traitCollection = self.traitCollection
        let newTheme = UserDefaults.standard.theme(compatibleWith: traitCollection)

        if theme != newTheme || appEnvironmentTraitCollectionIsDifferentThanTraitCollection(traitCollection) {
            updateAppEnvironment(theme: newTheme, traitCollection: self.traitCollection)
            apply(theme: newTheme)
        }
    }

    @objc private func userDidChangeTheme(_ note: Notification) {
        let themeName = note.userInfo?[ReadingThemesControlsViewController.WMFUserDidSelectThemeNotificationThemeNameKey] as? String
        let isImageDimmingEnabledNumber = note.userInfo?[ReadingThemesControlsViewController.WMFUserDidSelectThemeNotificationIsImageDimmingEnabledKey] as? NSNumber
        if let isImageDimmingEnabledNumber {
            UserDefaults.standard.wmf_isImageDimmingEnabled = isImageDimmingEnabledNumber.boolValue
        }
        if let themeName {
            UserDefaults.standard.themeName = themeName
        }
        updateUserInterfaceStyleOfNavigationControllersForCurrentTheme()
        updateAppThemeIfNecessary()
    }

    override var overrideUserInterfaceStyle: UIUserInterfaceStyle {
        get {
            let themeName = UserDefaults.standard.themeName
            if Theme.isDefaultThemeName(themeName) {
                return .unspecified
            } else if Theme.isDarkThemeName(themeName) {
                return .dark
            } else {
                return .light
            }
        }
        set {
            super.overrideUserInterfaceStyle = newValue
        }
    }

    private func updateUserInterfaceStyleOfNavigationControllersForCurrentTheme() {
        for vc in viewControllers ?? [] {
            if let nav = vc as? UINavigationController {
                nav.overrideUserInterfaceStyle = overrideUserInterfaceStyle
            }
        }
    }

    @objc private func debounceTraitCollectionThemeUpdate() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(updateAppThemeIfNecessary), object: nil)
        perform(#selector(updateAppThemeIfNecessary), with: nil, afterDelay: 0.3)
    }
}

// MARK: - WorkerControllerDelegate

extension WMFAppViewController: WorkerControllerDelegate {

    public func workerControllerWillStart(_ workerController: WorkerController, workWithIdentifier identifier: String) {
        beginBackgroundTask(workerController: workerController, identifier: identifier)
    }

    public func workerControllerDidEnd(_ workerController: WorkerController, workWithIdentifier identifier: String) {
        endBackgroundTask(workerController: workerController, identifier: identifier)
    }

    private func beginBackgroundTask(workerController: WorkerController, identifier: String) {
        let name = "\(NSStringFromClass(type(of: workerController)))-\(identifier)"
        let backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: name) { [weak self] in
            DDLogDebug("Ending background task with name: \(name)")
            workerController.cancelWorkWithIdentifier(identifier)
            self?.endBackgroundTask(workerController: workerController, identifier: identifier)
        }
        setBackgroundTaskIdentifier(backgroundTaskIdentifier, forKey: identifier)
    }

    private func endBackgroundTask(workerController: WorkerController, identifier: String) {
        let bgTaskID = backgroundTaskIdentifier(forKey: identifier)
        guard bgTaskID != .invalid else { return }
        UIApplication.shared.endBackgroundTask(bgTaskID)
    }
}

// MARK: - Article save to disk did fail

extension WMFAppViewController {

    @objc private func articleSaveToDiskDidFail(_ note: Notification) {
        if let error = note.userInfo?[SavedArticlesFetcher.saveToDiskDidFailErrorKey] as? NSError,
           error.domain == NSCocoaErrorDomain,
           error.code == NSFileWriteOutOfSpaceError {
            WMFToastManager.sharedInstance.showToast(WMFLocalizedString("article-save-error-not-enough-space", value: "You do not have enough space on your device to save this article", comment: "Alert message informing user that article cannot be save due to insufficient storage available"), sticky: true, dismissPreviousToasts: true, tapCallBack: nil)
        }
    }
}

// MARK: - Appearance

extension WMFAppViewController {

    @objc private func articleFontSizeWasUpdated(_ note: Notification) {
        if let multiplier = note.userInfo?[FontSizeSliderViewController.WMFArticleFontSizeMultiplierKey] as? NSNumber {
            UserDefaults.standard.wmf_setArticleFontSizeMultiplier(multiplier)
        }
        
    }
}

// MARK: - Search

extension WMFAppViewController {

    func showSearchInCurrentNavigationController() {
        showSearchInCurrentNavigationController(animated: true)
    }

    private func dismissReadingThemesPopoverIfActive() {
        if presentedViewController is ReadingThemesControlsViewController {
            presentedViewController?.dismiss(animated: true, completion: nil)
        }
    }

    var currentNavigationController: UINavigationController? {
        var presented = presentedViewController
        while presented?.presentedViewController != nil {
            presented = presented?.presentedViewController
        }

        // This next block fixes a weird bug: https://phabricator.wikimedia.org/T305112#7936784
        if let cls = presented.map({ NSStringFromClass(type(of: $0)) }),
           cls == "DDParsecCollectionViewController",
           let presenting = presented?.presentingViewController {
            presented = presenting
        }

        if let nav = presented as? UINavigationController {
            return nav
        }
        return currentTabNavigationController
    }

    private func showSearchInCurrentNavigationController(animated: Bool) {
        dismissReadingThemesPopoverIfActive()

        guard let nc = currentNavigationController else { return }

        let searchVC = SearchViewController(source: .unknown)
        searchVC.dataStore = dataStore
        searchVC.apply(theme: theme)
        nc.pushViewController(searchVC, animated: animated)
    }

    func showImportedReadingList(_ readingList: ReadingList) {
        dismissPresentedViewControllers()
        selectedIndex = WMFAppTabType.saved.rawValue
        currentTabNavigationController?.popToRootViewController(animated: false)
        let detailVC = ReadingListDetailViewController(for: readingList, with: dataStore, fromImport: true, theme: theme)
        currentTabNavigationController?.pushViewController(detailVC, animated: true)
    }

    var settingsViewController: SettingsTabViewController {
        
        guard let _settingsViewController else {
            let vc = generateSettingsTab()
            vc.apply(theme: theme)
            vc.title = WMFCommonStringsWrapper.settingsTitle
            vc.tabBarItem.image = UIImage(named: "tabbar-explore")
            _settingsViewController = vc
            return vc
        }
        
        return _settingsViewController
    }

    var settingsNavigationController: WMFComponentNavigationController {
        
        guard let _settingsNavigationController else {
            
            let navController = WMFComponentNavigationController(rootViewController: settingsViewController, modalPresentationStyle: .overFullScreen, customBarBackgroundColor: nil)
            applyTheme(theme, toNavigationControllers: [navController])
            navController.delegate = self
            _settingsNavigationController = navController
            
            return navController
        }
         
        if _settingsNavigationController.viewControllers.first !== settingsViewController {
            _settingsNavigationController.viewControllers = [settingsViewController]
        }
        
        return _settingsNavigationController
    }

    private func showSettings(with subViewController: UIViewController? = nil, animated: Bool) {
        dismissPresentedViewControllers()

        if let sub = subViewController {
            settingsNavigationController.pushViewController(sub, animated: false)
        }

        switch UserDefaults.standard.defaultTabType {
        case .settings:
            selectedIndex = WMFAppTabType.main.rawValue
            if let sub = subViewController {
                push(sub, animated: animated)
            }
        default:
            present(settingsNavigationController, animated: animated, completion: nil)
        }
    }

    private func showSettings(animated: Bool) {
        showSettings(with: nil, animated: animated)
    }
}

// MARK: - WMFReadingListsAlertPresenter

extension WMFAppViewController {

    @objc private func entriesLimitReachedWithNotification(_ notification: Notification) {
        guard let readingList = notification.userInfo?[ReadingList.entriesLimitReachedReadingListKey] as? ReadingList else { return }
        readingListsAlertController.showLimitHitForDefaultListPanelIfNecessary(presenter: self, dataStore: dataStore, readingList: readingList, theme: theme)
    }
}

// MARK: - Remote Notifications

extension WMFAppViewController {

    func setRemoteNotificationRegistrationStatus(deviceToken: Data?, error: Error?) {
        notificationsController.setRemoteNotificationRegistrationStatusWithDeviceToken(deviceToken, error: error)
    }
}

// MARK: - Navigation logging

extension WMFAppViewController {

    private func logDidSelectViewController(_ viewController: UIViewController) {
        guard let navVC = viewController as? UINavigationController,
              let rootViewController = navVC.viewControllers.first else { return }

        if rootViewController is ExploreViewController && UserDefaults.standard.defaultTabType == .explore {
            NavigationEventsFunnel.shared.logTappedExplore()
        } else if rootViewController is SettingsTabViewController && UserDefaults.standard.defaultTabType == .settings {
            NavigationEventsFunnel.shared.logTappedSettingsFromTabBar()
        } else if rootViewController is PlacesViewController {
            NavigationEventsFunnel.shared.logTappedPlaces()
        } else if rootViewController is SavedViewController {
            NavigationEventsFunnel.shared.logTappedSaved()
        } else if rootViewController is WMFActivityTabViewController {
            NavigationEventsFunnel.shared.logTappedActivityTab()
        } else if rootViewController is SearchViewController {
            NavigationEventsFunnel.shared.logTappedSearch()
        }
    }
}

// MARK: - User was logged out

extension WMFAppViewController {

    @objc private func userWasLoggedOut(_ note: Notification) {
        showLoggedOutPanelIfNeeded()
        DispatchQueue.main.async {
            self.exploreViewController.updateProfileButton()
            if UserDefaults.standard.defaultTabType == .settings {
                self.settingsViewController.updateProfileButton()
            }
            UNUserNotificationCenter.current().setBadgeCount(0, withCompletionHandler: nil)

            if self.isResumeComplete {
                self.dataStore.feedContentController.updateContentSource(WMFAnnouncementsContentSource.self, force: true, completion: nil)
            }

            self.dataStore.feedContentController.updateContentSource(WMFSuggestedEditsContentSource.self, force: true, completion: nil)
        }

        deleteYearInReviewPersonalizedNetworkData()
    }

    @objc private func userWasLoggedIn(_ note: Notification) {
        DispatchQueue.main.async {
            self.exploreViewController.updateProfileButton()
            if UserDefaults.standard.defaultTabType == .settings {
                self.settingsViewController.updateProfileButton()
            }

            if self.isResumeComplete {
                self.dataStore.feedContentController.updateContentSource(WMFAnnouncementsContentSource.self, force: true, completion: nil)
            }

            self.dataStore.feedContentController.updateContentSource(WMFSuggestedEditsContentSource.self, force: true, completion: nil)
        }
    }

    @objc private func handleAppLanguageDidChangeNotification(_ note: Notification) {
        deleteYearInReviewPersonalizedNetworkData()
    }

    @objc private func authManagerDidHandlePrimaryLanguageChange(_ note: Notification) {
        DispatchQueue.main.async {
            if self.isResumeComplete {
                self.dataStore.feedContentController.updateContentSource(WMFSuggestedEditsContentSource.self, force: true, completion: nil)
            }
        }
    }

    private func showLoggedOutPanelIfNeeded() {
        let authenticationManager = dataStore.authenticationManager
        guard authenticationManager.isUserUnawareOfLogout else { return }
        DispatchQueue.main.async {
            self.presentLoggedOutAlert(authenticationManager)
        }
    }

    private func presentLoggedOutAlert(_ authenticationManager: WMFAuthenticationManager) {
        let title = WMFLocalizedString("logged-out-title", value: "You have been logged out", comment: "Title for education panel letting user know they have been logged out.")
        let message = WMFLocalizedString("logged-out-subtitle", value: "There was a problem authenticating your account. In order to sync your reading lists and edit under your user name please log back in.", comment: "Subtitle for letting user know there was a problem authenticating their account.")
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(logBackInAction(for: authenticationManager))
        alert.addAction(continueWithoutLoggingInAction(for: authenticationManager))
        present(alert, animated: true, completion: nil)
    }

    private func logBackInAction(for authenticationManager: WMFAuthenticationManager) -> UIAlertAction {
        let title = WMFLocalizedString("logged-out-log-back-in-button-title", value: "Log back in to your account", comment: "Title for button allowing user to log back in to their account")
        return UIAlertAction(title: title, style: .default) { [weak self] _ in
            authenticationManager.userDidAcknowledgeUnintentionalLogout()
            self?.presentLoginViewControllerAfterLogout()
        }
    }

    private func continueWithoutLoggingInAction(for authenticationManager: WMFAuthenticationManager) -> UIAlertAction {
        let title = WMFLocalizedString("logged-out-continue-without-logging-in-button-title", value: "Continue without logging in", comment: "Title for button allowing user to continue without logging back in to their account")
        let theme = self.theme
        return UIAlertAction(title: title, style: .cancel) { [weak self] _ in
            authenticationManager.userDidAcknowledgeUnintentionalLogout()
            self?.wmf_objcShowKeepSavedArticlesOnDevicePanelIfNeeded(triggeredBy: .logout, theme: theme, completion: nil)
        }
    }

    private func presentLoginViewControllerAfterLogout() {
        guard let loginVC = WMFLoginViewController.wmf_initialViewControllerFromClassStoryboard() else { return }
        loginVC.apply(theme: theme)
        let theme = self.theme
        loginVC.loginDismissedHandler = { [weak self] in
            self?.wmf_objcShowKeepSavedArticlesOnDevicePanelIfNeeded(triggeredBy: .logout, theme: theme, completion: nil)
        }
        let navVC = WMFComponentNavigationController(rootViewController: loginVC, modalPresentationStyle: .overFullScreen, customBarBackgroundColor: nil)
        present(navVC, animated: true, completion: nil)
    }
}
