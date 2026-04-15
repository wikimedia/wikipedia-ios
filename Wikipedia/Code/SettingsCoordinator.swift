import UIKit
import SwiftUI
import WMF
import WMFComponents
import WMFData
import CocoaLumberjackSwift
import UserNotifications
import WMFTestKitchen


@MainActor
final class SettingsCoordinator: Coordinator, SettingsCoordinatorDelegate {

    // MARK: Coordinator Protocol Properties

    internal var navigationController: UINavigationController

    // MARK: Properties

    private let theme: Theme
    private var currentTheme: Theme {
        return UserDefaults.standard.theme(compatibleWith: UITraitCollection.current)
    }
    private let dataStore: MWKDataStore

    private let dataController: WMFSettingsDataController
    @MainActor private weak var settingsViewModel: WMFSettingsViewModel?
    @MainActor private var pushNotificationsViewModel: WMFPushNotificationsSettingsViewModel?
    private let languagesDelegateBridge = SettingsLanguagesDelegateBridge()

    /// Returns the appropriate navigation controller for both modal and embedded contexts
    private var settingsNavigationController: UINavigationController? {
        // Modal context (presented from Profile): Settings is presented modally
        if let presentedNav = navigationController.presentedViewController as? UINavigationController {
            return presentedNav
        }
        // Embedded context (tab bar): Settings IS the navigation controller
        return navigationController
    }
    
    private lazy var authInstrument: InstrumentImpl = {
        TestKitchenAdapter.shared.client.getInstrument(name: "apps-authentication")
            .setDefaultActionSource("account_settings")
            .startFunnel(name: "vanish_account")
    }()

    // MARK: Lifecycle

    init(navigationController: UINavigationController, theme: Theme, dataStore: MWKDataStore, dataController: WMFSettingsDataController = WMFSettingsDataController.shared) {
        self.navigationController = navigationController
        self.theme = theme
        self.dataStore = dataStore
        self.dataController = dataController
        self.languagesDelegateBridge.coordinator = self
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: WMFAuthenticationManager.didLogInNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: WMFAuthenticationManager.didLogOutNotification, object: nil)
    }

    // MARK: Coordinator Protocol Methods

    @discardableResult
    func start() -> Bool {

        // If navigation controller already has SettingsViewController as it's root view controller, no need to navigate anywhere
        if navigationController.viewControllers.count == 1,
           (navigationController.viewControllers.first as? SettingsTabViewController) != nil {
            return true
        }
        Task { @MainActor in
            await self.asyncStart()
        }

        return false
    }

    private func locStrings() -> WMFSettingsViewModel.LocalizedStrings {
        WMFSettingsViewModel.LocalizedStrings(
            settingTitle: CommonStrings.settingsTitle,
            doneButtonTitle: CommonStrings.doneTitle,
            cancelButtonTitle: CommonStrings.cancelActionTitle,
            accountTitle: CommonStrings.account,
            logInTitle: CommonStrings.logIn,
            myLanguagesTitle: CommonStrings.myLanguages,
            searchTitle: CommonStrings.searchTitle,
            exploreFeedTitle: CommonStrings.exploreFeedTitle,
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
            clearDonationHistoryTitle: CommonStrings.deleteDonationHistory,
            safetyTitle: CommonStrings.legalAndSafety)
    }

    func asyncStart() async {

        let isExploreFeedOn = UserDefaults.standard.defaultTabType == .explore
        let themeName = UserDefaults.standard.themeDisplayName

        let username = dataStore.authenticationManager.authStatePermanentUsername

        let tempUsername = dataStore.authenticationManager.authStateTemporaryUsername
        let isTempAccount = WMFTempAccountDataController.shared.primaryWikiHasTempAccountsEnabled && dataStore.authenticationManager.authStateIsTemporary

        let language = dataStore.languageLinkController.appLanguage?.languageCode.uppercased() ?? String()

        let viewModel = await WMFSettingsViewModel(localizedStrings: locStrings(), username: username, tempUsername: tempUsername, isTempAccount: isTempAccount, primaryLanguage: language, exploreFeedStatus: isExploreFeedOn, readingPreferenceTheme: themeName, dataController: dataController)

        self.settingsViewModel = viewModel
        let settingsViewController =  WMFSettingsViewController(viewModel: viewModel, coordinatorDelegate: self)
        let navVC = WMFComponentNavigationController(rootViewController: settingsViewController, modalPresentationStyle: .overFullScreen)
        navigationController.present(navVC, animated: true)
        registerAuthNotificationObservers()
    }

    func fetchDynamicValues() -> (primaryLanguage: String, exploreFeedStatus: Bool, readingPreferenceTheme: String) {
        let primaryLanguage = dataStore.languageLinkController.appLanguage?.languageCode.uppercased() ?? String()
        let exploreFeedStatus = UserDefaults.standard.defaultTabType == .explore
        let readingPreferenceTheme = UserDefaults.standard.themeDisplayName
        return (primaryLanguage: primaryLanguage, exploreFeedStatus: exploreFeedStatus, readingPreferenceTheme: readingPreferenceTheme)
    }

    func handleSettingsAction(_ action: SettingsAction) {
        switch action {

        case .account:
            showAccount()
        case .tempAccount:
            showTemporaryAccount()
        case .logIn:
            showLogin()
        case .myLanguages:
            showLanguages()
        case .search:
            showSearch()
        case .exploreFeed:
            showExploreFeedSettings()
        case .yearInReview:
            self.goToYearInReviewSettings()
        case .notifications:
            showNotifications()
        case .readingPreferences:
            showReadingPreferences()
        case .articleSyncing:
            showArticleSyncing()
        case .databasePopulation:
            tappedDatabasePopulation()
        case .clearCachedData:
            showClearCacheActionSheet()
        case .privacyPolicy:
            tappedExternalLink(with: CommonStrings.privacyPolicyURLString)
        case .termsOfUse:
            tappedExternalLink(with: CommonStrings.termsOfUseURLString)
        case .rateTheApp:
            tappedRateApp()
        case .helpAndFeedback:
            tappedHelpAndFeedback()
        case .about:
            tappedAbout()
        case .deleteDonationHistory:
            clearDonationHistory()
        case .legalAndSafety:
            tappedExternalLink(with: CommonStrings.legalAndSafetyContactUsURLString)
        }
    }

    // MARK: - Private methods - Actions

    private func dismissSettings(completion: @escaping () -> Void) {
        navigationController.dismiss(animated: true) {
            completion()
        }
    }

    // MARK: - Clear cache

    private func clearCache() {
        Task {
            showClearCacheInProgressBanner()
        }

        dataStore.clearTemporaryCache()

        let databaseHousekeeper = WMFDatabaseHousekeeper()
        let navigationStateController = NavigationStateController(dataStore: dataStore)

        var cleanupError: Error? = nil

        self.dataStore.performBackgroundCoreDataOperation { moc in
            do {
                try databaseHousekeeper.performHousekeepingOnManagedObjectContext(moc, navigationStateController: navigationStateController, cleanupLevel: .high)

            } catch {
                cleanupError = error
                DDLogError("Error on cleanup: \(error)")
            }
        }

        SharedContainerCacheHousekeeping.deleteStaleCachedItems(
            in: SharedContainerCacheCommonNames.talkPageCache,
            cleanupLevel: .high
        )
        SharedContainerCacheHousekeeping.deleteStaleCachedItems(
            in: SharedContainerCacheCommonNames.didYouKnowCache,
            cleanupLevel: .high
        )

        Task {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            if cleanupError != nil {
                self.showClearCacheErrorBanner()
            }
            self.showClearCacheComplete()
        }
    }

    private func showClearCacheActionSheet() {

        let baseMessage = WMFLocalizedString("settings-clear-cache-are-you-sure-message", value: "Clearing cached data will free up about %1$@ of space. It will not delete your saved pages.", comment: "Message for the confirmation presented to the user to verify they are sure they want to clear clear cached data. %1$@ is replaced with the approximate file size in bytes that will be made available. Also explains that the action will not delete their saved pages.")

        let bytesString = ByteCountFormatter.string(
            fromByteCount: Int64(URLCache.shared.currentDiskUsage),
            countStyle: .file
        )

        let message = String.localizedStringWithFormat(baseMessage, bytesString)

        let title = WMFLocalizedString("settings-clear-cache-are-you-sure-title", value: "Clear cached data?", comment: "Title for the confirmation presented to the user to verify they are sure they want to clear clear cached data.")

        let sheet = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let clearTitle = WMFLocalizedString("settings-clear-cache-ok", value: "Clear cache", comment: "Confirm action to clear cached data")

        sheet.addAction(UIAlertAction(title: clearTitle, style: .destructive) { [weak self] _ in
            self?.clearCache()
        })

        let cancelTitle = CommonStrings.cancelActionTitle

        sheet.addAction(UIAlertAction(title: cancelTitle, style: .cancel))

        let presenter = (navigationController.presentedViewController ?? navigationController)
        presenter.present(sheet, animated: true)
    }

    private func showClearCacheInProgressBanner() {
        let message = WMFLocalizedString("clearing-cache-in-progress", value: "Clearing cache in progress.", comment: "Title of banner that appears when a user taps clear cache button in Settings. Informs the user that clearing of cache is in progress.")
        WMFToastManager.sharedInstance.showToast(message, sticky: false, dismissPreviousToasts: true)
    }

    private func showClearCacheErrorBanner() {
        let message = WMFLocalizedString("clearing-cache-error", value: "Error clearing cache.", comment: "Title of banner that appears when a user taps clear cache button in Settings and an error occurs during the clearing of cache.")
        WMFToastManager.sharedInstance.showToast(message, sticky: true, dismissPreviousToasts: true)
    }

    private func showClearCacheComplete() {
        let message = WMFLocalizedString("clearing-cache-complete", value: "Clearing cache complete.", comment: "Title of banner that appears after clearing cache completes. Clearing cache is a button triggered by the user in Settings.")
        WMFToastManager.sharedInstance.showToast(message, sticky: true, dismissPreviousToasts: true)
    }

    // MARK: - YiR

    private func goToYearInReviewSettings() {

        let strings = WMFYearInReviewSettingsViewModel.LocalizedStrings(title: CommonStrings.yirTitle, description: WMFLocalizedString("settings-year-in-review-header", value: "Turning off Year in Review will clear all stored personalized insights and hide the Year in Review.", comment: "Text informing user of benefits of hiding the year in review feature."), toggleTitle: CommonStrings.yirTitle)

        let viewModel = WMFYearInReviewSettingsViewModel(
            dataController: dataController,
            localizedStrings: strings,
            onToggle: { isOn in
                DonateFunnel.shared.logYearInReviewSettingsDidToggle(isOn: isOn)
            }
        )

        let rootView = WMFYearInReviewSettingsView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: rootView)

        guard let settingsNav = settingsNavigationController else {
            return
        }

        DonateFunnel.shared.logYearInReviewSettingsDidTapItem()
        hostingController.title = strings.title
        settingsNav.pushViewController(hostingController, animated: true)
    }

    // MARK: - Database population

    private func tappedDatabasePopulation() {
        let vc = DatabasePopulationHostingController()
        let navVC = WMFComponentNavigationController(rootViewController: vc, modalPresentationStyle: .pageSheet)
        guard let settingsNav = settingsNavigationController else {
            return
        }

        settingsNav.present(navVC, animated: true)
    }

    // MARK: - External link Util

    private func tappedExternalLink(with urlString: String) {
        guard let settingsNav = settingsNavigationController else {
            return
        }

        if let url = URL(string: urlString) {
            let config = SinglePageWebViewController.StandardConfig(url: url, useSimpleNavigationBar: true)
            let webVC = SinglePageWebViewController(configType: .standard(config), theme: theme)
            let newNavigationVC = WMFComponentNavigationController(rootViewController: webVC, modalPresentationStyle: .fullScreen)
            settingsNav.present(newNavigationVC, animated: true)
        }
    }

    // MARK: - Rate App

    private func tappedRateApp() {
        if let url = URL(string: "itms-apps://itunes.apple.com/app/id324715238") {
            self.navigationController.navigate(to: url, useSafari: true)
        }
    }

    // MARK: - About

    private func tappedAbout() {
        guard let vc = AboutViewController(theme: self.theme),
              let settingsNav = settingsNavigationController else { return }
        settingsNav.pushViewController(vc, animated: true)
    }

    // MARK: - Help and feedback

    private func tappedHelpAndFeedback() {
        guard let vc = HelpViewController(dataStore: self.dataStore, theme: self.theme),
              let settingsNav = settingsNavigationController else { return }
        settingsNav.pushViewController(vc, animated: true)
    }

    // MARK: - Donation History

    private func clearDonationHistory() {
        let alertController = UIAlertController(title: CommonStrings.confirmDeletionTitle, message: CommonStrings.confirmDeletionSubtitle, preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: CommonStrings.deleteActionTitle, style: .destructive) { _ in
            Task {
                await self.deleteLocalHistory()
                await self.settingsViewModel?.refreshSections()
                self.showDeletionConfirmation()

            }
        }
        alertController.addAction(deleteAction)
        alertController.addAction(UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel))
        let presenter = (navigationController.presentedViewController ?? navigationController)
        presenter.present(alertController, animated: true)
    }

    private func deleteLocalHistory() async {
        await dataController.deleteLocalDonations()
    }

    private func showDeletionConfirmation() {
        let alertController = UIAlertController(title: CommonStrings.confirmedDeletion, message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: CommonStrings.okTitle, style: .default))
        let presenter = (navigationController.presentedViewController ?? navigationController)
        presenter.present(alertController, animated: true)
    }

    // MARK: - Account

    private func showAccount() {
        guard let settingsNav = settingsNavigationController else {
            return
        }

        guard let username = dataStore.authenticationManager.authStatePermanentUsername else {
            assertionFailure("Should not reach account settings if user isn't logged in.")
            return
        }

        let strings = WMFAccountSettingsViewModel.LocalizedStrings(
            title: CommonStrings.account,
            accountGroupTitle: WMFLocalizedString("account-group-title", value: "Your Account", comment: "Title for account group on account settings screen."),
            vanishAccountTitle: CommonStrings.vanishAccount,
            autoSignDiscussionsTitle: WMFLocalizedString("account-talk-preferences-auto-sign-discussions", value: "Auto-sign discussions", comment: "Title for talk page preference that configures adding signature to new posts"),
            talkPagePreferencesTitle: WMFLocalizedString("account-talk-preferences-title", value: "Talk page preferences", comment: "Title for talk page preference sections in account settings"),
            talkPagePreferencesFooter: WMFLocalizedString("account-talk-preferences-auto-sign-discussions-setting-explanation", value: "Auto-signing of discussions will use the signature defined in Signature settings", comment: "Text explaining how setting the auto-signing of talk page discussions preference works")
        )

        Task {
            let currentAutoSignValue = dataController.autoSignTalkPageDiscussions()

            let viewModel = WMFAccountSettingsViewModel(
                localizedStrings: strings,
                username: username,
                autoSignDiscussions: currentAutoSignValue,
                userDefaultsStore: WMFDataEnvironment.current.userDefaultsStore,
                onVanishAccount: { [weak self] in
                    self?.authInstrument
                                    .submitInteraction(action: "click", elementId: "vanish")
                    self?.showVanishAccountWarning()
                },
                onToggleAutoSign: { [weak self] newValue in
                    self?.saveAutoSignTalkPageDiscussions(newValue)
                }

            )
            let rootView = WMFAccountSettingsView(viewModel: viewModel)
            let hostingController = UIHostingController(rootView: rootView)
            hostingController.title = strings.title
            settingsNav.pushViewController(hostingController, animated: true)
        }
    }

    private func saveAutoSignTalkPageDiscussions(_ newValue: Bool) {
        let userDefaultsStore = WMFDataEnvironment.current.userDefaultsStore
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.autoSignTalkPageDiscussions.rawValue, value: newValue)
    }

    private func showVanishAccountWarning() {
        guard let settingsNav = settingsNavigationController else {
            return
        }

        let warningViewController = VanishAccountWarningViewHostingViewController(theme: theme)
        warningViewController.delegate = self
        settingsNav.present(warningViewController, animated: true) { [weak self] in
            self?.authInstrument
                .submitInteraction(action: "impression", actionSource: "vanish_warning")
        }
    }

    // MARK: - Temporary Account

    private func showTemporaryAccount() {
        guard let settingsNav = settingsNavigationController else {
            return
        }

        let tempAccountVC = TempAccountsSettingsViewController(dataStore: dataStore)
        tempAccountVC.apply(theme: theme)
        settingsNav.pushViewController(tempAccountVC, animated: true)
    }

    // MARK: - Login

    private func showLogin() {
        guard let settingsNav = settingsNavigationController else {
            return
        }

        guard let loginVC = WMFLoginViewController.wmf_initialViewControllerFromClassStoryboard() else {
            return
        }

        loginVC.apply(theme: theme)
        let loginNavVC = WMFComponentNavigationController(rootViewController: loginVC, modalPresentationStyle: .overFullScreen)
        settingsNav.present(loginNavVC, animated: true)
        LoginFunnel.shared.logLoginStartInSettings()
    }

    // MARK: - Languages

    private func showLanguages() {
        guard let settingsNav = settingsNavigationController else {
            return
        }

        let languagesVC = WMFPreferredLanguagesViewController.preferredLanguagesViewController()
        languagesVC.showExploreFeedCustomizationSettings = true
        languagesVC.apply(currentTheme)
        languagesVC.delegate = languagesDelegateBridge
        let languagesNavVC = WMFComponentNavigationController(rootViewController: languagesVC, modalPresentationStyle: .overFullScreen)
        settingsNav.present(languagesNavVC, animated: true)
    }

    func handleLanguagesDidUpdate() {
        if let newLanguage = dataStore.languageLinkController.appLanguage?.languageCode.uppercased() {
            settingsViewModel?.updateDynamicValues(
                primaryLanguage: newLanguage,
                exploreFeedStatus: UserDefaults.standard.defaultTabType == .explore,
                readingPreferenceTheme: UserDefaults.standard.themeDisplayName
            )
        }
    }

    @objc private func userAuthenticationStateDidChange() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }

            let username = self.dataStore.authenticationManager.authStatePermanentUsername
            let tempUsername = self.dataStore.authenticationManager.authStateTemporaryUsername
            let isTempAccount = WMFTempAccountDataController.shared.primaryWikiHasTempAccountsEnabled &&
                                self.dataStore.authenticationManager.authStateIsTemporary == true

            await self.settingsViewModel?.updateAuthenticationState(
                username: username,
                tempUsername: tempUsername,
                isTempAccount: isTempAccount
            )
        }
    }

    private func registerAuthNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userAuthenticationStateDidChange),
            name: WMFAuthenticationManager.didLogInNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userAuthenticationStateDidChange),
            name: WMFAuthenticationManager.didLogOutNotification,
            object: nil
        )
    }

    // MARK: - Search

    private func showSearch() {
        guard let settingsNav = settingsNavigationController else {
            return
        }

        let strings = WMFSearchSettingsViewModel.LocalizedStrings(
            title: CommonStrings.searchTitle,
            showLanguagesTitle: WMFLocalizedString("settings-language-bar", value: "Show languages on search", comment: "Title in Settings for toggling the display the language bar in the search view"),
            openOnSearchTabTitle: WMFLocalizedString("settings-search-open-app-on-search", value: "Open app on Search tab", comment: "Title for setting that allows users to open app on Search tab"),
            footerText: WMFLocalizedString("settings-search-footer-text", value: "Set the app to open to the Search tab instead of the Explore tab", comment: "Footer text for section that allows users to customize certain Search settings")
        )

        Task { [weak self] in
            guard let self else { return }

            let showLanguageBar = dataController.showSearchLanguageBar()
            let openAppOnSearchTab = dataController.openAppOnSearchTab()

            let viewModel = WMFSearchSettingsViewModel(
                localizedStrings: strings,
                showLanguageBar: showLanguageBar,
                openAppOnSearchTab: openAppOnSearchTab,
                userDefaultsStore: WMFDataEnvironment.current.userDefaultsStore,
                onToggleShowLanguageBar: { [weak self] newValue in
                     self?.dataController.setShowSearchLanguageBar(newValue)
                },
                onToggleOpenAppOnSearchTab: { [weak self] newValue in
                    Task { [weak self] in await self?.dataController.setOpenAppOnSearchTab(newValue) }
                }
            )

            let rootView = WMFSearchSettingsView(viewModel: viewModel)
            let hostingController = UIHostingController(rootView: rootView)
            hostingController.title = strings.title
            settingsNav.pushViewController(hostingController, animated: true)
        }
    }

    // MARK: - Explore Feed

    private func showExploreFeedSettings() {
        guard let settingsNav = settingsNavigationController else {
            return
        }

        let feedSettingsVC = ExploreFeedSettingsViewController()
        feedSettingsVC.dataStore = dataStore
        feedSettingsVC.apply(theme: currentTheme)
        settingsNav.pushViewController(feedSettingsVC, animated: true)
    }

    // MARK: - Notifications

    private func showNotifications() {
        guard let settingsNav = settingsNavigationController else {
            return
        }

        let strings = WMFPushNotificationsSettingsViewModel.LocalizedStrings(
            title: CommonStrings.pushNotifications,
            headerText: WMFLocalizedString("settings-notifications-header", value: "Be alerted to activity related to your account, such as messages from fellow contributors, alerts, and notices. All provided with respect to privacy and up to the minute data.", comment: "Text informing user of benefits of enabling push notifications."),
            pushNotificationsTitle: CommonStrings.pushNotifications,
            permissionErrorTitle: WMFLocalizedString("settings-notifications-echo-failure-title", value: "Unable to Check for Echo Notification subscriptions", comment: "Alert title text informing user of failure when subscribing to Echo Notifications."),
            permissionErrorMessage: WMFLocalizedString("settings-notifications-echo-failure-message", value: "An error occurred while checking for notification subscriptions related to your account.", comment: "Alert message text informing user of failure when subscribing to Echo Notifications."),
            errorAlertDismissButton: CommonStrings.okTitle
        )

        let viewModel = WMFPushNotificationsSettingsViewModel(
            localizedStrings: strings,
            onRequestPermissions: { [weak self] in
                self?.requestPushPermissions()
            },
            onUnsubscribe: { [weak self] in
                self?.unsubscribeFromEchoNotifications()
            },
            onOpenSystemSettings: {
                UIApplication.shared.wmf_openAppSpecificSystemSettings()
            }
        )

        self.pushNotificationsViewModel = viewModel

        let rootView = WMFPushNotificationsSettingsView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: rootView)
        hostingController.title = strings.title
        settingsNav.pushViewController(hostingController, animated: true)
    }

    private func requestPushPermissions() {
        Task { @MainActor in
            let settings = await UNUserNotificationCenter.current().notificationSettings()

            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                UIApplication.shared.registerForRemoteNotifications()
                let subscribed = await subscribeToEchoNotifications()
                await pushNotificationsViewModel?.refreshAfterPermissionRequest(granted: true)
                if !subscribed {
                    pushNotificationsViewModel?.showPermissionRequestError()
                }

            case .notDetermined:
                let result = await withCheckedContinuation { continuation in
                    dataStore.notificationsController.requestPermissionsIfNecessary { authorized, error in
                        continuation.resume(returning: (authorized: authorized, error: error))
                    }
                }

                if result.authorized {
                    UIApplication.shared.registerForRemoteNotifications()
                    let subscribed = await subscribeToEchoNotifications()
                    if !subscribed {
                        pushNotificationsViewModel?.showPermissionRequestError()
                    }
                }
                await pushNotificationsViewModel?.refreshAfterPermissionRequest(granted: result.authorized)

            case .denied:
                await pushNotificationsViewModel?.refreshAfterPermissionRequest(granted: false)

            @unknown default:
                await pushNotificationsViewModel?.refreshAfterPermissionRequest(granted: false)
            }
        }
    }

    @discardableResult
    private func subscribeToEchoNotifications() async -> Bool {
        let success = await withCheckedContinuation { continuation in
            dataStore.notificationsController.subscribeToEchoNotifications { error in
                if let error {
                    DDLogError("Error subscribing to echo notifications: \(error)")
                    continuation.resume(returning: false)
                } else {
                    continuation.resume(returning: true)
                }
            }
        }
        await pushNotificationsViewModel?.loadAndBuild()
        return success
    }

    private func unsubscribeFromEchoNotifications() {
        Task { @MainActor in
            await withCheckedContinuation { continuation in
                dataStore.notificationsController.unsubscribeFromEchoNotifications { error in
                    if let error {
                        DDLogError("Error unsubscribing from echo notifications: \(error)")
                    }
                    continuation.resume()
                }
            }
            await pushNotificationsViewModel?.loadAndBuild()
        }
    }

    // MARK: - Reading Preferences

    private func showReadingPreferences() {
        guard let settingsNav = settingsNavigationController else {
            return
        }

        let appearanceSettingsVC = AppearanceSettingsViewController()
        appearanceSettingsVC.apply(theme: currentTheme)
        settingsNav.pushViewController(appearanceSettingsVC, animated: true)
    }

    // MARK: - Article Syncing

    private func showArticleSyncing() {
        guard let settingsNav = settingsNavigationController else {
            return
        }

        let strings = WMFStorageAndSyncingSettingsViewModel.LocalizedStrings(
            title: CommonStrings.settingsStorageAndSyncing,
            syncSavedArticlesTitle: WMFLocalizedString("settings-storage-and-syncing-enable-sync-title", value: "Sync saved articles and lists", comment: "Title of the settings option that enables saved articles and reading lists syncing"),
            syncSavedArticlesFooter: WMFLocalizedString("settings-storage-and-syncing-enable-sync-footer-text", value: "Allow Wikimedia to save your saved articles and reading lists to your user preferences when you login and sync.", comment: "Footer text of the settings option that enables saved articles and reading lists syncing"),
            showSavedReadingListTitle: WMFLocalizedString("settings-storage-and-syncing-show-default-reading-list-title", value: "Show Saved reading list", comment: "Title of the settings option that enables showing the default reading list"),
            showSavedReadingListFooter: WMFLocalizedString("settings-storage-and-syncing-show-default-reading-list-footer-text", value: "Show the Saved (eg. default) reading list as a separate list in your reading lists view. This list appears on Android devices.", comment: "Footer text of the settings option that enables showing the default reading list"),
            eraseSavedArticlesTitle: CommonStrings.eraseAllSavedArticles,
            eraseSavedArticlesButtonTitle: WMFLocalizedString("settings-storage-and-syncing-erase-saved-articles-button-title", value: "Erase", comment: "Title of the settings button that enables erasing saved articles"),
            eraseSavedArticlesFooterFormat: WMFLocalizedString("settings-storage-and-syncing-erase-saved-articles-footer-text", value: "Erasing your saved articles will remove them from your user account if you have syncing turned on as well as from this device.\n\nErasing your saved articles will free up about %1$@ of space.", comment: "Footer text of the settings option that enables erasing saved articles. %1$@ will be replaced with a number and a system provided localized unit indicator for MB or KB."),
            syncWithServerTitle: WMFLocalizedString("settings-storage-and-syncing-server-sync-title", value: "Update synced reading lists", comment: "Title of the settings button that initiates saved articles and reading lists server sync"),
            syncWithServerFooter: WMFLocalizedString("settings-storage-and-syncing-server-sync-footer-text", value: "Request an update to your synced articles and reading lists.", comment: "Footer text of the settings button that initiates saved articles and reading lists server sync"),
            eraseAlertTitle: WMFLocalizedString("settings-storage-and-syncing-erase-saved-articles-alert-title", value: "Erase all saved articles?", comment: "Title of the alert shown before erasing all saved article."),
            eraseAlertMessage: WMFLocalizedString("settings-storage-and-syncing-erase-saved-articles-alert-message", value: "Erasing your saved articles will remove them from your user account if you have syncing turned on as well as from this device. You cannot undo this action.", comment: "Message for the alert shown before erasing all saved articles."),
            syncAlertMessage: WMFLocalizedString("settings-storage-and-syncing-full-sync", value: "Your reading lists will be synced in the background", comment: "Message confirming to the user that their reading lists will be synced in the background")
        )

        let viewModel = WMFStorageAndSyncingSettingsViewModel(
            localizedStrings: strings,
            onToggleSync: { [weak self] isOn in
                self?.handleSyncToggle(isOn)
            },
            onToggleShowSavedList: { [weak self] isOn in
                self?.dataStore.readingListsController.isDefaultListEnabled = isOn
            },
            onEraseArticles: { [weak self] in
                self?.showEraseArticlesAlert()
            },
            onSyncWithServer: { [weak self] in
                self?.handleSyncWithServer()
            }
        )

        // Update initial state
        viewModel.updateSyncStatus(dataStore.readingListsController.isSyncEnabled)
        viewModel.updateShowSavedList(dataStore.readingListsController.isDefaultListEnabled)

        let cacheSize = CacheController.totalCacheSizeInBytes
        let dataSizeString = ByteCountFormatter.string(fromByteCount: cacheSize, countStyle: .file)
        viewModel.updateCacheSize(dataSizeString)

        let rootView = WMFStorageAndSyncingSettingsView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: rootView)
        hostingController.title = strings.title
        settingsNav.pushViewController(hostingController, animated: true)
    }

    private func handleSyncToggle(_ isOn: Bool) {
        let isPermanent = dataStore.authenticationManager.authStateIsPermanent

        if !isPermanent && isOn {
            // User needs to log in first
            guard let settingsNav = settingsNavigationController else {
            return
        }

            let dismissHandler = {
                // Revert toggle if dismissed
            }

            let loginSuccessCompletion = {
                self.dataStore.readingListsController.setSyncEnabled(true, shouldDeleteLocalLists: false, shouldDeleteRemoteLists: false)
                SettingsFunnel.shared.logSyncEnabledInSettings()
            }

            settingsNav.wmf_showLoginOrCreateAccountToSyncSavedArticlesToReadingListPanel(theme: theme, dismissHandler: dismissHandler, loginSuccessCompletion: loginSuccessCompletion, loginDismissedCompletion: dismissHandler)
        } else if isPermanent {
            let setSyncEnabled = {
                self.dataStore.readingListsController.setSyncEnabled(isOn, shouldDeleteLocalLists: false, shouldDeleteRemoteLists: !isOn)
                if isOn {
                    SettingsFunnel.shared.logSyncEnabledInSettings()
                } else {
                    SettingsFunnel.shared.logSyncDisabledInSettings()
                }
            }

            if !isOn {
                guard let settingsNav = settingsNavigationController else {
            return
        }
                settingsNav.wmf_showKeepSavedArticlesOnDevicePanelIfNeeded(triggeredBy: .syncDisabled, theme: theme, authInstrument: nil) {
                    setSyncEnabled()
                }
            } else {
                setSyncEnabled()
            }
        }
    }

    private func showEraseArticlesAlert() {
        guard let settingsNav = settingsNavigationController else {
            return
        }

        let alert = UIAlertController(
            title: WMFLocalizedString("settings-storage-and-syncing-erase-saved-articles-alert-title", value: "Erase all saved articles?", comment: "Title of the alert shown before erasing all saved article."),
            message: WMFLocalizedString("settings-storage-and-syncing-erase-saved-articles-alert-message", value: "Erasing your saved articles will remove them from your user account if you have syncing turned on as well as from this device. You cannot undo this action.", comment: "Message for the alert shown before erasing all saved articles."),
            preferredStyle: .alert
        )

        let cancel = UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel)
        let erase = UIAlertAction(title: CommonStrings.eraseAllSavedArticles, style: .destructive) { _ in
            self.dataStore.readingListsController.eraseAllSavedArticlesAndReadingLists()
        }

        alert.addAction(cancel)
        alert.addAction(erase)
        settingsNav.present(alert, animated: true)
    }

    private func handleSyncWithServer() {
        guard let settingsNav = settingsNavigationController else {
            return
        }

        let isPermanent = dataStore.authenticationManager.authStateIsPermanent
        let isSyncEnabled = dataStore.readingListsController.isSyncEnabled

        if isPermanent && isSyncEnabled {
            // Already logged in and sync enabled - just sync
            dataStore.readingListsController.fullSync({})
            showSyncAlert()
        } else if !isPermanent {
            // Need to log in
            let loginSuccessCompletion = {
                self.dataStore.readingListsController.fullSync({})
                self.showSyncAlert()
            }
            settingsNav.wmf_showLoginOrCreateAccountToSyncSavedArticlesToReadingListPanel(theme: theme, dismissHandler: nil, loginSuccessCompletion: loginSuccessCompletion, loginDismissedCompletion: nil)
        } else {
            // Logged in but sync not enabled
            settingsNav.wmf_showEnableReadingListSyncPanel(theme: theme, oncePerLogin: false, didNotPresentPanelCompletion: nil) {
                // Sync enabled
            }
        }
    }

    private func showSyncAlert() {
        guard let settingsNav = settingsNavigationController else {
            return
        }
        settingsNav.wmf_showAlertWithMessage(WMFLocalizedString("settings-storage-and-syncing-full-sync", value: "Your reading lists will be synced in the background", comment: "Message confirming to the user that their reading lists will be synced in the background"))
    }
}

// MARK: - VanishAccountWarningViewDelegate

extension SettingsCoordinator: VanishAccountWarningViewDelegate {
    func userDidDismissVanishAccountWarningView(presentVanishView: Bool) {
        guard presentVanishView else {
            authInstrument
                .submitInteraction(action: "click", actionSource: "vanish_warning", elementId: "cancel")
            return
        }
        
        authInstrument
            .submitInteraction(action: "click", actionSource: "vanish_warning", elementId: "vanish_confirm")


        guard let url = URL(string: "https://meta.wikimedia.org/wiki/Special:GlobalVanishRequest") else {
            return
        }

        guard let settingsNav = settingsNavigationController else {
            return
        }

        let config = SinglePageWebViewController.StandardConfig(url: url, useSimpleNavigationBar: false)
        let viewController = SinglePageWebViewController(configType: .standard(config), theme: theme)
        settingsNav.pushViewController(viewController, animated: true)
    }
}

// MARK: - SettingsLanguagesDelegateBridge

/// Bridges the Obj-C WMFPreferredLanguagesViewControllerDelegate to @MainActor SettingsCoordinator.
private final class SettingsLanguagesDelegateBridge: NSObject, WMFPreferredLanguagesViewControllerDelegate {
    weak var coordinator: SettingsCoordinator?

    func languagesController(_ controller: WMFPreferredLanguagesViewController, didUpdatePreferredLanguages languages: [MWKLanguageLink]) {
        guard let coordinator else { return }
        MainActor.assumeIsolated {
            coordinator.handleLanguagesDidUpdate()
        }
    }
}
