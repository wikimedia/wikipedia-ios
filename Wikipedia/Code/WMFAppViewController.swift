import UIKit
import WMF
import WMFData
import WMFComponents
import SystemConfiguration
import UserNotifications
import CocoaLumberjackSwift
import SwiftUI
import WMFNativeLocalizations
import TipKit
import WMFTestKitchen

// MARK: - Tab enum

@objc enum WMFAppTabType: Int {
    case main = 0
    case places = 1
    case saved = 2
    case recent = 3 // Activity tab
    case search = 4
}

// MARK: - Constants

private let wmfTimeBeforeShowingHomeScreenOnLaunch: TimeInterval = 24 * 60 * 60
private let wmfRemoteAppConfigCheckInterval: CFTimeInterval = 3 * 60 * 60
private let wmfTempAccountConfigCheckInterval: CFTimeInterval = 3 * 60 * 60
private let wmfLastRemoteAppConfigCheckAbsoluteTimeKey = "WMFLastRemoteAppConfigCheckAbsoluteTimeKey"
private let wmfTempAccountConfigCheckAbsoluteTimeKey = "WMFTempAccountConfigCheckAbsoluteTimeKey"
private let wmfResetPreferredLanguages = "WMFResetPreferredLanguages"
#if UITEST
private let wmfUITestCentralAuthUsername = "WMFUITestCentralAuthUsername"
#endif
private let wmfLegacyDefaultTabTypeKey = "WMFDefaultTabTypeKey"
private let wmfLegacyDefaultTabTypeSettingsValue = 1 // the old `WMFAppDefaultTabType.settings`
private let wmfSuppressActivityTabOnboardingForTesting = "WMFSuppressActivityTabOnboardingForTesting"
private let wmfSuppressGamesAnnouncementForTesting = "WMFSuppressGamesAnnouncementForTesting"
private let wmfSuppressYearInReviewAnnouncementForTesting = "WMFSuppressYearInReviewAnnouncementForTesting"
private let wmfSuppressHomeOnboardingForTesting = "WMFSuppressHomeOnboardingForTesting"
private let wmfUITestDiscoverState = "WMFUITestDiscoverState"
private let wmfHideTipsForTesting = "WMFHideTipsForTesting"

// KVO context pointers
private var kvoSavedArticlesFetcherProgress = UInt8(0)

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
    private var _tabBarCoordinator: TabBarCoordinator?
    private var tabBarCoordinator: TabBarCoordinator {
        if let _tabBarCoordinator {
            return _tabBarCoordinator
        }
        let coordinator = TabBarCoordinator(theme: theme, dataStore: dataStore)
        coordinator.home.startFeedCustomization = { [weak self] instrument in
            self?.startFeedCustomizationOnboarding(instrument: instrument)
        }
        _tabBarCoordinator = coordinator
        return coordinator
    }

    /// True when this activation was started by a deep link. Set by SceneDelegate, which resets it at
    /// the start of each foreground cycle. Home reads it to hold back modals.
    var didOpenAppFromExternalLink = false {
        didSet {
            _tabBarCoordinator?.home.homeViewController?.didOpenAppFromExternalLink = didOpenAppFromExternalLink
        }
    }

    /// Held while the evergreen account creation prompt is on screen, since it owns its outcome reporting.
    var evergreenAccountCreationCoordinator: EvergreenAccountCreationCoordinator?

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
    private var localNotificationTypeToShow: WMFLocalNotificationType?

    private var _settingsNavigationController: WMFComponentNavigationController?

    var readingListsAlertController: ReadingListsAlertController!
    
    var syncStartDate: Date?
    
    var savedTabBadgeController: SavedTabBadgeController?
    
    private var hasSyncErrorBeenShownThisSession: Bool = false
    
    var readingListHintPresenter: WMFReadingListToastManager!

    private var _navigationStateController: NavigationStateController?
    
    private var configuration: Configuration?
    private var router: ViewControllerRouter?
    
    private var rootTabAccessibilityIdentifiers: [String?] = []

    // MARK: - init / deinit
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(exploreFeedPreferencesDidChange(_:)),
                                               name: Notification.Name.WMFExploreFeedPreferencesDidChange,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(userWasLoggedOut(_:)),
                                               name: WMFAuthenticationManager.didLogOutNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(generateDiscoverReadingListIfNeeded),
                                               name: WMFNSNotification.coreDataStoreSetup,
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
                                               selector: #selector(handleYearInReviewActivityBadgeNeedsUpdate),
                                               name: WMFNSNotification.yearInReviewActivityTabBadgeNeedsUpdate,
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
                                               selector: #selector(databaseHousekeeperDidComplete),
                                               name: .databaseHousekeeperDidComplete,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(whichCameFirstSessionDidUpdate(_:)),
                                               name: WMFNSNotification.whichCameFirstSessionDidUpdate,
                                               object: nil)

        observeArticleTabsNSNotifications()
        setupReadingListsHelpers()

        navigationItem.backButtonDisplayMode = .generic
        
        registerForTraitChanges([UITraitUserInterfaceStyle.self, UITraitPreferredContentSizeCategory.self]) { [weak self] (_: WMFAppViewController, _: UITraitCollection) in
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
        return presentedViewController is WMFAppOnboardingHostingController
    }

    private var appOnboardingCoordinator: AppOnboardingCoordinator?

    private var uiIsLoaded: Bool {
        return (viewControllers?.count ?? 0) > 0
    }

    private var siteURL: URL? {
        return dataStore.primarySiteURL
    }

    // MARK: - Setup

    private func setupControllers() {
        // Must run before any reading list sync of the session
        dataStore.readingListsController.clearNeedsRemoteDisableSyncState()

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

        tabBarCoordinator.search.viewController.apply(theme: theme)

        if let savedTabBarItem = tabBarCoordinator.saved.savedViewController?.tabBarItem {
            savedTabBadgeController = SavedTabBadgeController(
                tabBarItem: savedTabBarItem,
                tabBar: tabBar,
                theme: theme,
                userInterfaceIdiom: traitCollection.userInterfaceIdiom,
                hasOtherBadges: yearInReviewBadgeIsNeeded()
            )
        }

        updateActivityTabYearInReviewBadge()
    }

    private func configureTabController() {
        self.delegate = self

        let rootNavigationControllers = tabBarCoordinator.makeRootNavigationControllers(delegate: self)
        tabBarCoordinator.home.homeViewController?.didOpenAppFromExternalLink = didOpenAppFromExternalLink
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
        setViewControllers(rootNavigationControllers, animated: false)
        applyRootTabAccessibilityIdentifiers()

        updateUserInterfaceStyleOfNavigationControllersForCurrentTheme()

        let shouldOpenOnSearch = shouldOpenAppOnSearchTab()
        if shouldOpenOnSearch && selectedIndex != WMFAppTabType.search.rawValue {
            selectedIndex = WMFAppTabType.search.rawValue
            tabBarCoordinator.search.viewController.makeSearchBarBecomeFirstResponder()
        } else if selectedIndex != WMFAppTabType.main.rawValue {
            selectedIndex = WMFAppTabType.main.rawValue
        }
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
        savedTabBadgeController?.refreshDiscover()
        generateDiscoverReadingListIfNeeded()
        startEvergreenAccountCreationSession()
        checkRemoteAppConfigIfNecessary()
        updateActivityTabYearInReviewBadge()
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

        if isResumeComplete {
            performTasksThatShouldOccurAfterBecomeActiveAndResume()
            UserHistoryFunnel.shared.logSnapshot()
        }
    }

    @objc private func appWillResignActiveWithNotification(_ note: Notification) {
        guard uiIsLoaded else { return }

        navigationStateController.saveNavigationState(for: self, in: dataStore.viewContext)
        
        do {
            try dataStore.save()
        } catch let error {
            DDLogError("Error saving dataStore: \(error)")
        }
    }

    @objc private func appDidEnterBackgroundWithNotification(_ note: Notification) {
        guard uiIsLoaded else { return }
        ClientErrorFunnel.shared.flushRateLimitSummaries()
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

    // MARK: - Local Notifications

    /// Only call from the background app refresh task. Schedules any local notifications that are due.
    func performLocalNotificationsBackgroundRefresh() async {
        await LocalNotificationCoordinator.scheduleNotificationsIfNeeded(dataStore: dataStore)
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
            MainActor.assumeIsolated {
                WMFToastPresenter.shared.startObservingKeyboard()
            }
            self.setupWMFDataEnvironment()
            self.setupWMFDataCoreDataStore()

            store.performLibraryUpdates {
                DispatchQueue.main.async {
                    self.isMigrationComplete = true
                    self.isMigrationActive = false
                    self.endMigrationBackgroundTask()
                    self.migrateLegacyDefaultTabTypeIfNeeded()
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

    /// The Explore tab setting no longer exists. A reader who had turned Explore off has `.settings` stored,
    /// and the old setter also turned on "open app on Search tab" for them. Reset that one so they land on Home.
    /// A reader who still had Explore on keeps their own Search setting.
    private func migrateLegacyDefaultTabTypeIfNeeded() {
        guard UserDefaults.standard.object(forKey: wmfLegacyDefaultTabTypeKey) != nil else { return }

        if UserDefaults.standard.integer(forKey: wmfLegacyDefaultTabTypeKey) == wmfLegacyDefaultTabTypeSettingsValue {
            // Keep the legacy key until the write succeeds, so the migration retries on the next launch instead of losing the reader's state.
            guard WMFSettingsDataController.shared.setOpenAppOnSearchTab(false) else { return }
        }

        UserDefaults.standard.removeObject(forKey: wmfLegacyDefaultTabTypeKey)
    }

    private func applyUITestLaunchOverridesIfNeeded() {
        if UserDefaults.standard.bool(forKey: wmfResetPreferredLanguages) {
            dataStore.languageLinkController.resetPreferredLanguages()
        }

        #if TEST || UITEST
        UITestReadingListsSeeder(dataStore: dataStore).applyIfNeeded()
        #endif

        #if UITEST
        // The flags persist in user defaults, so each launch states what it needs: "groupB" shows
        // the onboarding card again, "off" turns Discover off, and no value keeps the previous state.
        // The developer setting cannot turn the feature off when the remote config turns it on, as
        // it does against live services, so "off" also forces the control group, which sees nothing.
        switch UserDefaults.standard.string(forKey: wmfUITestDiscoverState) {
        case "groupB":
            WMFDeveloperSettingsDataController.shared.enableDiscover = true
            WMFDeveloperSettingsDataController.shared.forceDiscoverExperimentAssignment = .groupB
            try? WMFDiscoverDataController.shared.resetAnnouncement()
        case "off":
            WMFDeveloperSettingsDataController.shared.enableDiscover = false
            WMFDeveloperSettingsDataController.shared.forceDiscoverExperimentAssignment = .control
        default:
            break
        }
        #endif

        if UserDefaults.standard.bool(forKey: wmfSuppressActivityTabOnboardingForTesting) {
            try? WMFDataEnvironment.current.userDefaultsStore?.save(
                key: WMFUserDefaultsKey.hasSeenActivityTabOnboarding.rawValue,
                value: true
            )
        }

        if UserDefaults.standard.bool(forKey: wmfSuppressGamesAnnouncementForTesting) {
            UserDefaults.standard.set(true, forKey: WMFUserDefaultsKey.hasSeenGamesAnnouncement.rawValue)
        }

        #if UITEST
        // The cookie persists across launches, so an empty value clears what a previous test left behind.
        if let centralAuthUsername = UserDefaults.standard.string(forKey: wmfUITestCentralAuthUsername) {
            if centralAuthUsername.isEmpty {
                dataStore.session.setCentralAuthUserCookieForTesting(nil)
            } else {
                KeychainCredentialsManager.shared.username = nil
                KeychainCredentialsManager.shared.password = nil
                dataStore.session.setCentralAuthUserCookieForTesting(centralAuthUsername)
            }
        }
        #endif

        // The Year in Review announcement is a sheet that appears once per install, which for a
        // fresh UI-test install means once per test, at an unpredictable moment. Mark it as seen.
        // Written straight to the store: WMFYearInReviewDataController() throws while the Core Data
        // store is still being set up, which `try?` would hide.
        if UserDefaults.standard.bool(forKey: wmfSuppressYearInReviewAnnouncementForTesting) {
            try? WMFDataEnvironment.current.userDefaultsStore?.save(
                key: WMFUserDefaultsKey.seenYearInReview2026FeatureAnnouncement.rawValue,
                value: true
            )
        }

        // UI tests launch as an existing reader, so the one-time "Explore is now Home" sheet would cover Home.
        if UserDefaults.standard.bool(forKey: wmfSuppressHomeOnboardingForTesting) {
            WMFHomeDataController.shared.setHasSeenOneTimeOnboarding(true)
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
            } else if let localNotificationType = self.localNotificationTypeToShow {
                self.hideSplashView()
                self.localNotificationTypeToShow = nil
                self.showDestination(for: localNotificationType)
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
            } else if self.shouldShowHomeOnLaunch() {
                self.hideSplashView()
                self.showHome()
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
        dataStore.authenticationManager.attemptLogin { [self] in
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
            self._tabBarCoordinator?.home.presentOneTimeOnboardingIfNeeded(isExistingUser: UserDefaults.standard.bool(forKey: Self.wmfDidShowOnboarding))
            let key = WMFUserDefaultsKey.needsDailyGameFeedRefresh.rawValue
            if UserDefaults.standard.bool(forKey: key) {
                UserDefaults.standard.removeObject(forKey: key)
                self.dataStore.feedContentController.updateFeedSources(with: nil, userInitiated: false, completion: nil)
            }
        }

        dataStore.feedContentController.startContentSources()

        let defaults = UserDefaults.standard
        let feedRefreshDate = defaults.wmf_feedRefreshDate()
        let now = Date()

        let locationAuthorized = LocationManagerFactory.coarseLocationManager().isAuthorized
        let shouldRefreshFeed: Bool
        if let feedRefreshDate {
            shouldRefreshFeed = now.timeIntervalSince(feedRefreshDate) > timeBeforeRefreshingExploreFeed() || NSCalendar.wmf_gregorian().wmf_days(from: feedRefreshDate, to: now) > 0
        } else {
            shouldRefreshFeed = true
        }
        if shouldRefreshFeed {
            resumeAndAnnouncementsCompleteGroup.enter()
            dataStore.feedContentController.updateFeedSources(with: nil, userInitiated: false) {
                DispatchQueue.main.async {
                    resumeAndAnnouncementsCompleteGroup.leave()
                }
            }
        } else {
            if locationAuthorized != defaults.wmf_locationAuthorized() {
                dataStore.feedContentController.updateContentSource(WMFNearbyContentSource.self, force: false, completion: nil)
            }
            if !UserDefaults.standard.shouldRestoreNavigationStackOnResume {
                dataStore.feedContentController.updateContentSource(WMFContinueReadingContentSource.self, force: true, completion: nil)
            }

            resumeAndAnnouncementsCompleteGroup.enter()
            dataStore.feedContentController.updateContentSource(WMFFeedPromptsContentSource.self, force: true) {
                resumeAndAnnouncementsCompleteGroup.leave()
            }
        }

        resumeAndAnnouncementsCompleteGroup.waitInBackground {
            self.performTasksThatShouldOccurAfterAnnouncementsUpdated()
        }

        defaults.wmf_setLocationAuthorized(locationAuthorized)

        savedArticlesFetcher?.start()
    }
    
    private var homeFeedSettingsCoordinator: HomeFeedSettingsCoordinator?
    
    private func timeBeforeRefreshingExploreFeed() -> TimeInterval {
        var timeInterval: TimeInterval = 2 * 60 * 60
        let key = WMFFeedDayResponse.maxAgeKey()
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
                tabBarCoordinator.search.viewController.makeSearchBarBecomeFirstResponder()
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
        case .home, .places, .savedPages, .search, .settings, .appearanceSettings, .content, .activity, .random:
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
        case .home:
            dismissPresentedViewControllers()
            selectedIndex = WMFAppTabType.main.rawValue
            currentTabNavigationController?.popToRootViewController(animated: animated)

        case .places:
            dismissPresentedViewControllers()
            selectedIndex = WMFAppTabType.places.rawValue
            currentTabNavigationController?.popToRootViewController(animated: animated)
            if let articleURL = activity.wmf_linkURL() {
                tabBarCoordinator.places.viewController.updateViewModeToMap()
                tabBarCoordinator.places.viewController.showArticleURL(articleURL)
            }

        case .random:
            dismissPresentedViewControllers()
            showRandomArticleFromShortcut(siteURL: siteURL, animated: animated, userInfo: activity.userInfo)

        case .activity:
            
            let activityVC = tabBarCoordinator.activity.viewController
            activityVC.disableModalsOnAppearance = true
            
            dismissPresentedViewControllers()
            selectedIndex = WMFAppTabType.recent.rawValue
            currentTabNavigationController?.popToRootViewController(animated: animated)

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
                dataStore.feedContentController.updateFeedSources(with: nil, userInitiated: false) {
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
            tabBarCoordinator.search.viewController.makeSearchBarBecomeFirstResponder()

        case .searchResults:
            dismissPresentedViewControllers()
            tabBarCoordinator.search.viewController.searchAndMakeResultsVisibleForSearchTerm( activity.wmf_searchTerm(), animated: animated)
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

    private func shouldShowHomeOnLaunch() -> Bool {
        guard !shouldOpenAppOnSearchTab() else { return false }
        guard let resignActiveDate = UserDefaults.standard.wmf_appResignActiveDate() else { return false }
        return abs(resignActiveDate.timeIntervalSinceNow) >= wmfTimeBeforeShowingHomeScreenOnLaunch
    }

    func visibleArticleViewController() -> ArticleViewController? {
        guard let topVC = currentTabNavigationController?.topViewController else { return nil }
        return topVC as? ArticleViewController
    }

    // MARK: - Accessors

    var savedArticlesFetcher: SavedArticlesFetcher? {
        guard uiIsLoaded else { return nil }
        
        guard let _savedArticlesFetcher else {
            let fetcher = SavedArticlesFetcher(dataStore: dataStore)
            // The initial KVO callback reads this property, so set it before the observer starts.
            _savedArticlesFetcher = fetcher
            fetcher?.addObserver(self,
                                forKeyPath: #keyPath(SavedArticlesFetcher.progress),
                                options: [.initial, .new, .old],
                                context: &kvoSavedArticlesFetcherProgress)
            return fetcher
        }
        
        return _savedArticlesFetcher
    }

    // swiftlint:disable:next block_based_kvo
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if context == &kvoSavedArticlesFetcherProgress {
            ProgressContainer.shared.articleFetcherProgress = _savedArticlesFetcher?.progress
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

    @objc func handleExploreCenterBadgeNeedsUpdateNotification() {
        DispatchQueue.main.async {
            self._tabBarCoordinator?.home.homeViewController?.updateProfileButton()
        }
    }

    // MARK: - Feed content

    /// Housekeeping removes old feed content, so the feed refreshes after it. The Home tab may not
    /// have loaded the embedded Explore feed, so this refresh does not depend on it.
    /// Housekeeping also runs in the background processing task. Do not refresh the feed until the app resumes.
    @objc private func databaseHousekeeperDidComplete() {
        DispatchQueue.main.async {
            guard self.isResumeComplete else { return }
            self.dataStore.feedContentController.updateFeedSources(with: nil, userInitiated: true, completion: nil)
        }
    }

    /// Keeps today's daily game card preview current after the reader answers a question.
    @objc private func whichCameFirstSessionDidUpdate(_ note: Notification) {
        guard let projectID = note.userInfo?["projectID"] as? String,
              let date = note.userInfo?["dailyGameDate"] as? String else { return }

        let todayDateString = DateFormatter.onThisDayAPIDateFormatter.string(from: Date())
        guard date == todayDateString else { return }

        dataStore.feedContentController.updateDailyGameContentGroupPreview(forProjectID: projectID, date: date)
    }

    // MARK: - Year in Review Activity tab badge

    @objc private func handleYearInReviewActivityBadgeNeedsUpdate() {
        updateActivityTabYearInReviewBadge()
    }

    private func yearInReviewBadgeIsNeeded() -> Bool {
        guard let dataController = try? WMFYearInReviewDataController() else { return false }
        return dataController.shouldShowActivityTabBadge(countryCode: Locale.current.region?.identifier)
    }

    private func updateActivityTabYearInReviewBadge() {
        guard uiIsLoaded else { return }

        let needsBadge = yearInReviewBadgeIsNeeded()

        // The Saved tab controller owns the badge colors. Tell it before the star shows, so the star
        // takes the shared color, and after the star hides, so the Discover dot can go back to red.
        if needsBadge {
            savedTabBadgeController?.setHasOtherBadges(true)
        }
        if #available(iOS 18.0, *) {
            let identifier = AccessibilityIdentifiers.RootTab.activityButton
            tabs.first { $0.identifier == identifier }?.showYearInReviewBadge(needsBadge)
        }
        // Read the cached controller rather than the lazy getter — badging must never be the thing
        // that constructs the Activity tab.
        _tabBarCoordinator?.activity.activityTabViewController?.tabBarItem.showYearInReviewBadge(needsBadge)
        if !needsBadge {
            savedTabBadgeController?.setHasOtherBadges(false)
        }
    }

    @objc func handleNotificationsCenterContextDidSave() {
        DispatchQueue.main.async {
            try? UNUserNotificationCenter.current().setBadgeCount(self.dataStore.remoteNotificationsController.numberOfUnreadNotifications().intValue)
            try? self.dataStore.remoteNotificationsController.updateCacheWithCurrentUnreadNotificationsCount()
        }
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

        let coordinator = AppOnboardingCoordinator(
            presentingViewController: self,
            dataStore: dataStore,
            theme: theme,
            willDismiss: { [weak self] in
                self?.loadMainUI()
            },
            completion: { [weak self] in
                self?.setDidShowOnboarding()
                WMFHomeDataController.shared.setHasSeenUpdatedHomeOnboarding(true)
                self?.appOnboardingCoordinator = nil
                completion(true)
            })
        appOnboardingCoordinator = coordinator
        hideSplashView()
        coordinator.start()
    }

    private func startFeedCustomizationOnboarding(instrument: InstrumentImpl) {
        let coordinator = AppOnboardingCoordinator(
            presentingViewController: self,
            dataStore: dataStore,
            theme: theme,
            willDismiss: { [weak self] in
                self?.loadMainUI()
            },
            completion: { [weak self] in
                self?._tabBarCoordinator?.home.selectFeedChosenInOnboarding()
                self?.appOnboardingCoordinator = nil
            }
        )
        appOnboardingCoordinator = coordinator
        coordinator.startCondensed(instrument: instrument)
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

    // MARK: - Home

    private func showHome() {
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
            tabBarCoordinator.search.viewController.makeSearchBarBecomeFirstResponder()
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
        showRandomArticleFromShortcut(siteURL: siteURL, animated: animated, userInfo: nil)
    }

    private func showNearby(animated: Bool) {
        dismissPresentedViewControllers()
        selectedIndex = WMFAppTabType.places.rawValue
        currentTabNavigationController?.popToRootViewController(animated: false)
        tabBarCoordinator.places.viewController.showNearbyArticles()
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

            // Year in Review availability comes from this config, so the badge cannot settle
            // until the fetch lands. This completion carries no isolation, so hop explicitly.
            Task { @MainActor in
                self.updateActivityTabYearInReviewBadge()
            }
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
        recordEvergreenAccountCreationAppOpenIfNeeded()
        presentEvergreenAccountCreationPromptIfNeeded()
    }

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        
        guard let current = tabBarController.selectedViewController else {
            return false
        }
        
        let selected = viewController

        if viewController == tabBarController.selectedViewController {
            if let tab = WMFAppTabType(rawValue: tabBarController.selectedIndex) {
                tabBarCoordinator.coordinator(for: tab).tabWasReselected()
            }

            if (currentTabNavigationController?.viewControllers.count ?? 0) > 1 {
                tabBarCoordinator.activity.logTabBarSelectionsForActivityTab(currentTabSelection: current, newTabSelection: selected)
                return true
            } else {
                // Must return NO if already visible to prevent unintended effect when tapping the Search tab bar button multiple times.
                return false
            }
        }

        tabBarCoordinator.activity.logTabBarSelectionsForActivityTab(currentTabSelection: current, newTabSelection: selected)

        // When switching to Activity via tab bar button, increment the visit count
        if let navVC = viewController as? UINavigationController,
           navVC.viewControllers.count == 1,
           navVC.viewControllers[0] is WMFActivityTabViewController {
            tabBarCoordinator.activity.incrementActivityTabVisitCount()
        }

        return true
    }

    private func updateActiveTitleAccessibilityButton(_ viewController: UIViewController) {
        guard let vc = viewController as? ArticleViewController else { return }
        if selectedIndex == WMFAppTabType.main.rawValue {
            vc.navigationItem.titleView?.accessibilityLabel = CommonStrings.homeReturnToHomeAccessibilityLabel
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

// MARK: - Link user activity

extension WMFAppViewController {

    @objc func shouldOpenAppOnSearchTab() -> Bool {
        return WMFSettingsDataController.shared.openAppOnSearchTab()
    }

    @objc internal func processLinkUserActivity(_ userActivity: NSUserActivity) -> Bool {

        guard let linkURL = userActivity.wmf_linkURL() else {
            return false
        }

        guard let navigationController = self.currentTabNavigationController else {
            return false
        }

        // Use the article source from userInfo if provided (e.g. widget deep links inject .widget),
        // otherwise default to external_link for generic deep links from browsers etc.
        let articleSource: ArticleSource
        if let sourceInt = userActivity.userInfo?[ArticleSourceUserInfoKeys.articleSource] as? Int,
           let source = ArticleSource(rawValue: sourceInt) {
            articleSource = source
        } else {
            articleSource = .external_link
        }

        if let returnJourney = VisualEditorReturnJourney(url: linkURL) {
            return processVisualEditorReturnJourney(returnJourney, navigationController: navigationController, articleSource: articleSource)
        }

        // Any other article deep link (e.g. Safari's native app banner): if the linked article
        // is already on screen, bring the app to the foreground instead of pushing a duplicate
        if LinkCoordinator.destination(for: linkURL) == .article,
           let articleViewController = visibleArticleViewController(),
           let visibleArticleKey = articleViewController.articleURL.wmf_databaseKey,
           let incomingArticleKey = linkURL.wmf_databaseKey,
           visibleArticleKey == incomingArticleKey {
            if let fragment = linkURL.fragment?.removingPercentEncoding, !fragment.isEmpty {
                articleViewController.scroll(to: fragment, animated: true)
            }
            return true
        }

        let linkCoordinator = LinkCoordinator(navigationController: navigationController, url: linkURL, dataStore: dataStore, theme: theme, articleSource: articleSource, tabConfig: .appendArticleAndAssignNewTabAndSetToCurrent)
        return linkCoordinator.start()
    }

    /// Handles the redirect back into the app after a web Visual Editor session (T434236).
    /// If the same article is already on screen, refreshes it in place instead of pushing a duplicate.
    private func processVisualEditorReturnJourney(_ returnJourney: VisualEditorReturnJourney, navigationController: UINavigationController, articleSource: ArticleSource) -> Bool {

        if let articleViewController = visibleArticleViewController(),
           let visibleArticleKey = articleViewController.articleURL.wmf_databaseKey,
           let incomingArticleKey = returnJourney.articleURL.wmf_databaseKey,
           visibleArticleKey == incomingArticleKey {
            if returnJourney.saved {
                articleViewController.waitForNewContentAndRefresh(returnJourney.revisionID)
            }
            // saved == false: the edit was abandoned, leave the article as-is
            return true
        }

        // The user is continuing their journey, so append to the current tab rather than opening a new one
        let linkCoordinator = LinkCoordinator(navigationController: navigationController, url: returnJourney.articleURL, dataStore: dataStore, theme: theme, articleSource: articleSource, tabConfig: .appendArticleAndAssignCurrentTab, revisionID: returnJourney.revisionID)
        return linkCoordinator.start()
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension WMFAppViewController: UNUserNotificationCenterDelegate {

    // The method will be called on the delegate only if the application is in the foreground.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if notification.request.content.threadIdentifier == EchoModelVersion.current {
            dataStore.remoteNotificationsController.loadNotifications(force: true)
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
        } else if let rawType = info[WMFLocalNotificationType.userInfoKey] as? String,
                  let localNotificationType = WMFLocalNotificationType(rawValue: rawType) {
            handleLocalNotificationTap(type: localNotificationType)
        }

        completionHandler()
    }

    private func handleLocalNotificationTap(type: WMFLocalNotificationType) {
        LocalNotificationCoordinator.logTap(type: type)

        guard isMigrationComplete else {
            localNotificationTypeToShow = type
            return
        }
        showDestination(for: type)
    }

    /// Shows Explore, then lets the coordinator push the notification's destination on top of it.
    private func showDestination(for localNotificationType: WMFLocalNotificationType) {
        dismissPresentedViewControllers()
        showHome()
        guard let navigationController = currentTabNavigationController else {
            return
        }
        let coordinator = LocalNotificationCoordinator(navigationController: navigationController, dataStore: dataStore, theme: theme, type: localNotificationType)
        coordinator.start()
    }

    private func showNotificationCenterForNotificationInfo(_ info: [AnyHashable: Any]) {
        guard isMigrationComplete else {
            notificationUserInfoToShow = info
            return
        }
        userDidTapPushNotification()
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

    var topMostViewController: UIViewController? {

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
    
    @objc func showRandomArticleFromShortcut(siteURL: URL?, animated: Bool, userInfo: [AnyHashable: Any]? = nil) {
        guard let navVC = currentTabNavigationController else { return }
        let articleSource: ArticleSource
        if let sourceInt = userInfo?[ArticleSourceUserInfoKeys.articleSource] as? Int,
           let source = ArticleSource(rawValue: sourceInt) {
            articleSource = source
        } else {
            articleSource = .undefined
        }
        let coordinator = RandomArticleCoordinator(navigationController: navVC, articleURL: nil, siteURL: siteURL, dataStore: dataStore, theme: theme, source: articleSource, animated: animated)
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

// MARK: - Language Variant Migration Alerts

extension WMFAppViewController {

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

        let title = alertTitleForLanguageVariantCode(languageCode)
        let message = alertBodyForLanguageVariantCode(languageCode)
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        // If there are remaining codes, primary button shows the next variant alert
        if let nextCode = remainingCodes.first {
            alert.addAction(UIAlertAction(title: CommonStrings.gotItButtonTitle, style: .default) { [weak self] _ in
                self?.presentVariantAlert(for: nextCode, remainingCodes: Array(remainingCodes.dropFirst()), completion: completion)
            })
        } else {
            // No more to show: primary button navigates to language settings, secondary dismisses
            alert.addAction(UIAlertAction(title: CommonStrings.variantsAlertPreferencesButton, style: .default) { [weak self] _ in
                self?.displayPreferredLanguageSettings(completion: completion)
            })
            alert.addAction(UIAlertAction(title: CommonStrings.noThanksTitle, style: .cancel) { _ in
                completion()
            })
        }
        self.present(alert, animated: true, completion: nil)
    }

    private func alertTitleForLanguageVariantCode(_ languageCode: String) -> String {
        switch languageCode {
        case "crh": return CommonStrings.crimeanTatarVariantsAlertTitle
        case "gan": return CommonStrings.ganVariantsAlertTitle
        case "iu": return CommonStrings.inuktitutVariantsAlertTitle
        case "kk": return CommonStrings.kazakhVariantsAlertTitle
        case "ku": return CommonStrings.kurdishVariantsAlertTitle
        case "sr": return CommonStrings.serbianVariantsAlertTitle
        case "tg": return CommonStrings.tajikVariantsAlertTitle
        case "uz": return CommonStrings.uzbekVariantsAlertTitle
        case "zh": return CommonStrings.chineseVariantsAlertTitle
        case "shi": return CommonStrings.tachelhitVariantsAlertTitle
        default:
            assertionFailure("No language variant alert title for language code '\(languageCode)'")
            return ""
        }
    }

    private func alertBodyForLanguageVariantCode(_ languageCode: String) -> String {
        switch languageCode {
        case "crh": return CommonStrings.crimeanTatarVariantsAlertBody
        case "gan": return CommonStrings.ganVariantsAlertBody
        case "iu": return CommonStrings.inuktitutVariantsAlertBody
        case "kk": return CommonStrings.kazakhVariantsAlertBody
        case "ku": return CommonStrings.kurdishVariantsAlertBody
        case "sr": return CommonStrings.serbianVariantsAlertBody
        case "tg": return CommonStrings.tajikVariantsAlertBody
        case "uz": return CommonStrings.uzbekVariantsAlertBody
        case "zh": return CommonStrings.chineseVariantsAlertBody
        case "shi": return CommonStrings.tachelhitVariantsAlertBody
        default:
            assertionFailure("No language variant alert body for language code '\(languageCode)'")
            return ""
        }
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
        
        tabBarCoordinator.apply(theme: theme)

        applyTheme(theme, toPresentedViewController: presentedViewController)

        applyTheme(theme, toNavigationControllers: allNavigationControllers())

        applyTabBarTheme(theme)

        UISwitch.appearance().onTintColor = theme.colors.accent

        readingListHintPresenter.apply(theme: theme)

        setNeedsStatusBarAppearanceUpdate()
    }

    /// Themes the tab bar and puts the badge colors back. `UITabBar.apply(theme:)` replaces the appearance.
    func applyTabBarTheme(_ theme: Theme) {
        tabBar.apply(theme: theme)
        savedTabBadgeController?.apply(theme: theme)
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

// MARK: WMFComponents App Environment Helpers
extension WMFAppViewController {

    @objc func updateAppEnvironment(theme: Theme, traitCollection: UITraitCollection) {
        let wmfTheme = Theme.wmfTheme(from: theme)
        WMFAppEnvironment.current.set(theme: wmfTheme, traitCollection: traitCollection)
    }

    @objc func appEnvironmentTraitCollectionIsDifferentThanTraitCollection(_ traitCollection: UITraitCollection) -> Bool {
        return WMFAppEnvironment.current.traitCollection.hasDifferentColorAppearance(comparedTo: traitCollection)
        || WMFAppEnvironment.current.traitCollection.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory
    }

}

// MARK: - TipKit and WMFComponents theme

extension WMFAppViewController {
    @objc func setupTips() {
        do {
            try Tips.configure()
            if UserDefaults.standard.bool(forKey: wmfHideTipsForTesting) {
                Tips.hideAllTipsForTesting()
            }
        } catch {
            DDLogError("Error initializing TipKit: \(error.localizedDescription)")
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

    func showReadingList(_ readingList: ReadingList, fromImport: Bool) {
        tabBarCoordinator.saved.showReadingList(readingList, fromImport: fromImport)
    }

    var savedCoordinator: SavedCoordinator {
        tabBarCoordinator.saved
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

        present(settingsNavigationController, animated: animated, completion: nil)
    }

    private func showSettings(animated: Bool) {
        showSettings(with: nil, animated: animated)
    }
}

// MARK: - Settings tab

extension WMFAppViewController {

    @objc func generateSettingsTab() -> SettingsTabViewController {
        let dataController = WMFSettingsDataController.shared

        let themeName = UserDefaults.standard.themeDisplayName
        let username = dataStore.authenticationManager.authStatePermanentUsername
        let tempUsername = dataStore.authenticationManager.authStateTemporaryUsername
        let isTempAccount = WMFTempAccountDataController.shared.primaryWikiHasTempAccountsEnabled &&
                            dataStore.authenticationManager.authStateIsTemporary
        let language = dataStore.languageLinkController.appLanguage?.contentLanguageCode.uppercased() ?? String()

        let localizedStrings = WMFSettingsViewModel.LocalizedStrings(
            settingTitle: CommonStrings.settingsTitle,
            doneButtonTitle: CommonStrings.doneTitle,
            cancelButtonTitle: CommonStrings.cancelActionTitle,
            accountTitle: CommonStrings.account,
            logInTitle: CommonStrings.logIn,
            myLanguagesTitle: CommonStrings.myLanguages,
            searchTitle: CommonStrings.searchTitle,
            exploreFeedTitle: CommonStrings.exploreFeedTitle,
            homeFeedTitle: CommonStrings.homeFeedTitle,
            onTitle: CommonStrings.onTitle,
            offTitle: CommonStrings.offTitle,
            yirTitle: CommonStrings.yirTitle,
            pushNotificationsTitle: CommonStrings.pushNotifications,
            readingpreferences: CommonStrings.readingPreferences,
            articleSyncing: CommonStrings.settingsStorageAndSyncing,
            databasePopulation: "Database population",
            clearCacheTitle: CommonStrings.clearCachedDataSettings,
            privacyHeader: CommonStrings.privacyTermsHeader,
            privacyPolicyTitle: CommonStrings.privacyPolicyTitle,
            termsOfUseTitle: CommonStrings.termsOfUseTitle,
            rateTheAppTitle: CommonStrings.rateTheAppTitle,
            helpTitle: CommonStrings.helpAndfeedbackTitle,
            aboutTitle: CommonStrings.aboutTitle,
            safetyTitle: CommonStrings.legalAndSafety
        )

        let viewModel = WMFSettingsViewModel.__createSynchronously(
            localizedStrings: localizedStrings,
            username: username,
            tempUsername: tempUsername,
            isTempAccount: isTempAccount,
            primaryLanguage: language,
            readingPreferenceTheme: themeName,
            coordinatorDelegate: nil,
            dataController: dataController
        )

        let controller = SettingsTabViewController(
            viewModel: viewModel,
            coordinatorDelegate: nil,
            dataStore: dataStore,
            theme: theme,
            dataController: dataController
        )

        return controller
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

        if rootViewController is HomeViewController {
            NavigationEventsFunnel.shared.logTappedHome()
        } else if rootViewController is PlacesViewController {
            NavigationEventsFunnel.shared.logTappedPlaces()
        } else if rootViewController is WMFSavedHostingController {
            NavigationEventsFunnel.shared.logTappedSaved()
            SavedInstrumentation.shared.logSavedTabTap()
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
            self._tabBarCoordinator?.home.homeViewController?.updateProfileButton()
            UNUserNotificationCenter.current().setBadgeCount(0, withCompletionHandler: nil)

            if self.isResumeComplete {
                self.dataStore.feedContentController.updateContentSource(WMFFeedPromptsContentSource.self, force: true, completion: nil)
            }

            self.dataStore.feedContentController.updateContentSource(WMFSuggestedEditsContentSource.self, force: true, completion: nil)
        }

        deleteYearInReviewPersonalizedNetworkData()
    }

    @objc private func userWasLoggedIn(_ note: Notification) {
        DispatchQueue.main.async {
            self._tabBarCoordinator?.home.homeViewController?.updateProfileButton()

            if self.isResumeComplete {
                self.dataStore.feedContentController.updateContentSource(WMFFeedPromptsContentSource.self, force: true, completion: nil)
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
        guard WMFAuthenticationManager.shouldShowLoggedOutAlert(isUserUnawareOfLogout: authenticationManager.isUserUnawareOfLogout, isPermanentAccountLoggedIn: authenticationManager.authStateIsPermanent) else {
            // Logged in again since the logout, so the alert no longer applies.
            authenticationManager.userDidAcknowledgeUnintentionalLogout()
            return
        }
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

// MARK: - Two-factor login from auto login

extension WMFAppViewController {
    @objc func createTwoFactorViewControllerFromAutoLoginNotification(userInfo: [AnyHashable : Any], needsEmailToken: Bool) -> WMFTwoFactorPasswordViewController? {
        guard let message = userInfo["mediaWikiMessage"] as? String else {
            return nil
        }
        
        let authInstrument = userInfo["authInstrument"] as? WMFTestKitchen.InstrumentImpl
        
        let vc = WMFTwoFactorPasswordViewController.wmf_initialViewControllerFromClassStoryboard()
        vc?.mediaWikiMessage = message
        vc?.authInstrument = authInstrument
        
        if needsEmailToken {
            vc?.setDisplayModeToShortAlphanumeric()
        }
        
        vc?.cancelAction = { [weak self] in
            self?.dataStore.authenticationManager.logout(initiatedBy: .app)
        }
        
        return vc
    }
}

// MARK: WMFData setup

extension WMFAppViewController {

    @objc func setupWMFDataCoreDataStore() {
        WMFDataEnvironment.current.appContainerURL = FileManager.default.wmf_containerURL()

        migrateAutoSignTalkPageDiscussions()
        migrateShowLanguageBar()
        migrateOpenAppOnSearchTab()
        migrateIsSubscribedToEchoNotifications()

        Task(priority: .userInitiated) {
            do {
                WMFDataEnvironment.current.coreDataStore = try await WMFCoreDataStore()
                await self.migrateSavedArticleInfoWithBackgroundTask()
                await self.recoverReadingChallenge2026Completion()
            } catch let error {
                DDLogError("Error setting up WMFCoreDataStore: \(error)")
            }
        }
    }

    /// Determines whether the user completed the (since removed) 2026 Reading Challenge and saves it
    /// to user defaults. No-ops after it succeeds once. Retries on the next launch if it throws,
    /// which is why the error is logged rather than surfaced.
    private func recoverReadingChallenge2026Completion() async {
        do {
            try await WMFReadingChallengeCompletionDataController.shared.recoverCompletionIfNeeded()
        } catch let error {
            DDLogError("Error recovering 2026 Reading Challenge completion: \(error)")
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

    private func migrateAutoSignTalkPageDiscussions() {
        let settingsDataController = WMFSettingsDataController.shared
        guard !settingsDataController.didMigrateAutoSignTalkPageDiscussions() else {
            return
        }

        if settingsDataController.hasStoredAutoSignTalkPageDiscussions() {
            settingsDataController.setDidMigrateAutoSignTalkPageDiscussions(true)
            return
        }
        let legacyKey = "WMFAutoSignTalkPageDiscussions"
        let bundleID = Bundle.main.bundleIdentifier ?? ""
        let persistedValue = UserDefaults.standard.persistentDomain(forName: bundleID)?[legacyKey] as? Bool ?? true
        settingsDataController.setAutoSignTalkPageDiscussions(persistedValue)
        settingsDataController.setDidMigrateAutoSignTalkPageDiscussions(true)
        UserDefaults.standard.removeObject(forKey: legacyKey)
    }

    private func migrateShowLanguageBar() {
        let legacyKey = "ShowLanguageBar"
        let settingsDataController = WMFSettingsDataController.shared
        guard let legacyValue = UserDefaults.standard.object(forKey: legacyKey) as? NSNumber else {
            // No legacy value — set default to true if not yet stored
            let hasStoredValue = UserDefaults.standard.object(forKey: WMFUserDefaultsKey.showSearchLanguageBar.rawValue) != nil
            if !hasStoredValue {
                settingsDataController.setShowSearchLanguageBar(true)
            }
            return
        }
        settingsDataController.setShowSearchLanguageBar(legacyValue.boolValue)
        UserDefaults.standard.removeObject(forKey: legacyKey)
    }

    private func migrateOpenAppOnSearchTab() {
        let legacyKey = "WMFOpenAppOnSearchTab"
        guard UserDefaults.standard.object(forKey: legacyKey) != nil else {
            return
        }
        let legacyValue = UserDefaults.standard.bool(forKey: legacyKey)
        guard WMFSettingsDataController.shared.setOpenAppOnSearchTab(legacyValue) else {
            return
        }
        UserDefaults.standard.removeObject(forKey: legacyKey)
    }

    private func migrateIsSubscribedToEchoNotifications() {
        let legacyKey = "WMFIsSubscribedToEchoNotifications"
        guard UserDefaults.standard.object(forKey: legacyKey) != nil else {
            return
        }
        let legacyValue = UserDefaults.standard.bool(forKey: legacyKey)
        let store = WMFDataEnvironment.current.userDefaultsStore
        try? store?.save(key: WMFUserDefaultsKey.isSubscribedToEchoNotifications.rawValue, value: legacyValue)
        UserDefaults.standard.removeObject(forKey: legacyKey)
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
            return try? WMFDataEnvironment.current.crossProcessUserDefaultsStore?.load(key: WMFUserDefaultsKey.appInstallID.rawValue)
        }

        WMFDataEnvironment.current.acceptLanguageUtility = {
            return Locale.acceptLanguageHeaderForPreferredLanguages
        }

        WMFDataEnvironment.current.httpErrorLogger = { info in
            ClientErrorFunnel.shared.logHTTPError(info: info)
        }

        WMFDataEnvironment.current.sharedCacheStore = SharedContainerCacheStore()

        let languages = dataStore.languageLinkController.preferredLanguages.map { WMFLanguage(languageCode: $0.languageCode, languageVariantCode: $0.languageVariantCode) }
        WMFDataEnvironment.current.appData = WMFAppData(appLanguages: languages)

        WMFDataEnvironment.current.testKitchenClient = TestKitchenAdapter.shared.client

        evaluateAppInstallAndSessionIDs()

        // Warn level on purpose: the default log threshold (WMFLogging.h) is
        // warning, and this line must reach the log file that ships with the
        // "Export user data" package so errors in Logstash can be correlated
        // with an exported log through the same install ID.
        if let appInstallID: String = try? WMFDataEnvironment.current.crossProcessUserDefaultsStore?.load(key: WMFUserDefaultsKey.appInstallID.rawValue) {
            DDLogWarn("App install ID: \(appInstallID)")
        }

        // Notify the scene delegate that the data environment is ready, so it can submit any
        // deferred app_open event (e.g. on fresh install where languages weren't set up yet).
        #if !TEST
        if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
            sceneDelegate.dataEnvironmentDidSetup()
        }
        #endif
    }
    
    private func evaluateAppInstallAndSessionIDs() {
        
        let legacyAppInstallID = UserDefaults.standard.string(forKey: WMFAppInstallId)
        let legacySessionID = UserDefaults.standard.wmf_sessionID
        
        let store = WMFDataEnvironment.current.crossProcessUserDefaultsStore
        let appInstallID: String? = try? store?.load(key: WMFUserDefaultsKey.appInstallID.rawValue)
        let sessionID: String? = try? store?.load(key: WMFUserDefaultsKey.sessionID.rawValue)
        
        if legacyAppInstallID == nil && appInstallID == nil {
            // This is likely a fresh install! Generate a new app install ID
            
            let newAppInstallId = UUID().uuidString
            try? store?.save(key: WMFUserDefaultsKey.appInstallID.rawValue, value: newAppInstallId)
        } else {
            
            // Check to see if migrations are needed
            if legacyAppInstallID != nil && appInstallID == nil {
                try? store?.save(key: WMFUserDefaultsKey.appInstallID.rawValue, value: legacyAppInstallID)
                UserDefaults.standard.wmf_appInstallId = nil
            }
            
            if legacySessionID != nil && sessionID == nil {
                try? store?.save(key: WMFUserDefaultsKey.sessionID.rawValue, value: legacySessionID)
                UserDefaults.standard.wmf_sessionID = nil
            }
        }
    }

    @objc func updateWMFDataEnvironmentFromLanguagesDidChange() {
        let languages = dataStore.languageLinkController.preferredLanguages.map { WMFLanguage(languageCode: $0.languageCode, languageVariantCode: $0.languageVariantCode) }
        WMFDataEnvironment.current.appData = WMFAppData(appLanguages: languages)
    }

    @objc func performWMFDataHousekeeping() {
        WMFExperimentsDataController.pruneRetiredExperiments()

        let coreDataStore = WMFDataEnvironment.current.coreDataStore
        Task {
            do {
                try await coreDataStore?.performDatabaseHousekeeping()
            } catch {
                DDLogError("Error pruning WMFData database: \(error)")
            }

            do {
                let pageViewsDataController = try WMFPageViewsDataController()
                let clampedCount = try await pageViewsDataController.clampInflatedPageViewSecondsIfNeeded()
                if clampedCount > 0 {
                    DDLogInfo("Clamped inflated reading time on \(clampedCount) page views.")
                }
            } catch {
                DDLogError("Error clamping inflated page view seconds: \(error)")
            }
        }
    }

    @objc func deleteYearInReviewPersonalizedNetworkData() {
        Task {
            do {
                let yirDataController = try WMFYearInReviewDataController()
                try await yirDataController.deletePersonalizedData(for: .account)
            } catch {
                DDLogError("Failure deleting personalized editing data from year in review: \(error)")
            }
        }
    }
}

// MARK: - Discover

extension WMFAppViewController {

    /// Generates the Discover reading list when its cadence is due. Runs each time the app becomes
    /// active. On a cold launch the Core Data store is not ready yet, so it runs again when the
    /// store posts `coreDataStoreSetup`. Only group B gets a list. A reader in the control group
    /// who turned Discover on before the group gate gets it turned off, list included.
    @objc func generateDiscoverReadingListIfNeeded() {
        guard WMFDataEnvironment.current.coreDataStore != nil else { return }
        let discoverDataController = WMFDiscoverDataController.shared
        Task {
            let dataController = WMFDiscoverReadingListDataController.shared
            if discoverDataController.hasListTurnedOnInControlGroup {
                try? await dataController.turnOff()
                return
            }
            guard discoverDataController.isAvailableToReader, await dataController.settings.isEnabled else { return }
            _ = try? await dataController.generateRecommendationsIfNeeded()
        }
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
             tabIdentifiersToDelete.append(tabIdentifier)
         }

         if let tabItemIdentifier {
             tabItemIdentifiersToDelete.append(tabItemIdentifier)
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

         tabIdentifiersToDelete.removeAll()
         tabItemIdentifiersToDelete.removeAll()
      }
 }

// MARK: - Evergreen Account Creation

extension WMFAppViewController {

    /// Starts the prompt's session, then records the app open the session was launched by.
    ///
    /// `startSession` only weighs days before today, so it does not matter that the open being
    /// recorded here belongs to the session it is deciding about.
    @objc func startEvergreenAccountCreationSession() {
        Task {
            let dataController = WMFEvergreenAccountCreationDataController.shared
            await dataController.startSession()

            // Ordered deliberately: this session's app open has to be recorded before eligibility is
            // weighed, or a reader crossing the "two more app open days" line is passed over until
            // their next launch. Prompts presented synchronously by the resume have already taken the
            // screen by the time these awaits resolve, so this one still yields to them.
            if isViewingEligibleMainTab {
                await dataController.recordAppOpen()
            }

            presentEvergreenAccountCreationPromptIfNeeded()
        }
    }

    /// App opens are proxied by an impression of one of the main tabs, or of an article view.
    @objc func recordEvergreenAccountCreationAppOpenIfNeeded() {
        guard isViewingEligibleMainTab else { return }

        Task {
            await WMFEvergreenAccountCreationDataController.shared.recordAppOpen()
        }
    }

    /// Attempts the prompt on Home or Saved, from the currently selected tab.
    ///
    /// Deliberately last in the app's prompt chain — after the logged out panel and the one time
    /// Home onboarding — and it bails if any of them took the screen.
    @objc func presentEvergreenAccountCreationPromptIfNeeded() {
        guard presentedViewController == nil,
              let navigationController = currentTabNavigationController,
              let context = evergreenAccountCreationContextForSelectedTab else {
            return
        }

        let coordinator = EvergreenAccountCreationCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore, context: context)
        evergreenAccountCreationCoordinator = coordinator
        coordinator.start()
    }

    private var evergreenAccountCreationContextForSelectedTab: WMFEvergreenAccountCreationDataController.PresentationContext? {
        guard let rootViewController = currentTabNavigationController?.viewControllers.first,
              currentTabNavigationController?.viewControllers.count == 1 else {
            return nil
        }

        if rootViewController is HomeViewController || rootViewController is ExploreViewController {
            return .home
        }

        if rootViewController is WMFSavedHostingController {
            return .saved
        }

        return nil
    }

    /// Settings can take the first tab's place for some readers, and is not one of the main tabs.
    private var isViewingEligibleMainTab: Bool {
        guard let rootViewController = currentTabNavigationController?.viewControllers.first else { return false }

        return rootViewController is HomeViewController
            || rootViewController is ExploreViewController
            || rootViewController is PlacesViewController
            || rootViewController is WMFSavedHostingController
            || rootViewController is WMFActivityTabViewController
            || rootViewController is SearchViewController
    }
}

// MARK: - Year in Review badge glyph

/// Matches `SavedTabBadgeController`, which badges its tab with this same glyph.
private let wmfYearInReviewTabBadgeGlyph = "\u{2605}"

private extension UITabBarItem {
    func showYearInReviewBadge(_ shouldShow: Bool) {
        badgeValue = shouldShow ? wmfYearInReviewTabBadgeGlyph : nil
    }
}

@available(iOS 18.0, *)
private extension UITab {
    func showYearInReviewBadge(_ shouldShow: Bool) {
        badgeValue = shouldShow ? wmfYearInReviewTabBadgeGlyph : nil
    }
}
