import UIKit
import SwiftUI
import WMF
import WMFComponents
import WMFData
import CocoaLumberjackSwift
import UserNotifications

@MainActor
final class SettingsCoordinator: Coordinator, @MainActor SettingsCoordinatorDelegate {

    // MARK: Coordinator Protocol Properties

    internal var navigationController: UINavigationController

    // MARK: Properties

    private let theme: Theme
    private let dataStore: MWKDataStore

    private let dataController: WMFSettingsDataController
    @MainActor private weak var settingsViewModel: WMFSettingsViewModel?
    @MainActor private var pushNotificationsViewModel: WMFPushNotificationsSettingsViewModel?

    // MARK: Lifecycle

    init(navigationController: UINavigationController, theme: Theme, dataStore: MWKDataStore, dataController: WMFSettingsDataController = WMFSettingsDataController()) {
        self.navigationController = navigationController
        self.theme = theme
        self.dataStore = dataStore
        self.dataController = dataController
    }

    // MARK: Coordinator Protocol Methods

    @discardableResult
    func start() -> Bool {

        // If navigation controller already has WMFSettingsViewController as it's root view controller, no need to navigate anywhere
        if navigationController.viewControllers.count == 1,
           (navigationController.viewControllers.first as? WMFSettingsViewController) != nil {
            return true
        }

        let settingsViewController = WMFSettingsViewController(dataStore: dataStore, theme: theme)
        let navVC = WMFComponentNavigationController(rootViewController: settingsViewController, modalPresentationStyle: .overFullScreen)
        navigationController.present(navVC, animated: true)
        return true
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
            clearDonationHistoryTitle: CommonStrings.deleteDonationHistory)
    }

    func setupSettings() async {

        let isExploreFeedOn = UserDefaults.standard.defaultTabType == .explore
        let themeName = UserDefaults.standard.themeDisplayName

        let username = dataStore.authenticationManager.authStatePermanentUsername

        let tempUsername = dataStore.authenticationManager.authStateTemporaryUsername
        let isTempAccount = WMFTempAccountDataController.shared.primaryWikiHasTempAccountsEnabled && dataStore.authenticationManager.authStateIsTemporary

        let language = dataStore.languageLinkController.appLanguage?.languageCode.uppercased() ?? String()

        let viewModel = await WMFSettingsViewModel(localizedStrings: locStrings(), username: username, tempUsername: tempUsername, isTempAccount: isTempAccount, primaryLanguage: language, exploreFeedStatus: isExploreFeedOn, readingPreferenceTheme: themeName, dataController: dataController)

        self.settingsViewModel = viewModel
        let settingsViewController =  WMFSettingsViewControllerNEW(viewModel: viewModel, coordinatorDelegate: self)
        let navVC = WMFComponentNavigationController(rootViewController: settingsViewController, modalPresentationStyle: .overFullScreen)
        navigationController.present(navVC, animated: true)
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
        }
    }

    // MARK: - Private methods - Actions

    private func asyncDismissSettings() async {
        await withCheckedContinuation { continuation in
            navigationController.dismiss(animated: true) {
                continuation.resume()
            }
        }
    }

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
        WMFAlertManager.sharedInstance.showAlert(message, sticky: false, dismissPreviousAlerts: true)
    }

    private func showClearCacheErrorBanner() {
        let message = WMFLocalizedString("clearing-cache-error", value: "Error clearing cache.", comment: "Title of banner that appears when a user taps clear cache button in Settings and an error occurs during the clearing of cache.")
        WMFAlertManager.sharedInstance.showAlert(message, sticky: true, dismissPreviousAlerts: true)
    }

    private func showClearCacheComplete() {
        let message = WMFLocalizedString("clearing-cache-complete", value: "Clearing cache complete.", comment: "Title of banner that appears after clearing cache completes. Clearing cache is a button triggered by the user in Settings.")
        WMFAlertManager.sharedInstance.showAlert(message, sticky: false, dismissPreviousAlerts: true)
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

        guard let settingsNav = navigationController.presentedViewController as? UINavigationController else {
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
        guard let settingsNav = navigationController.presentedViewController as? UINavigationController else {
            return
        }

        settingsNav.present(navVC, animated: true)
    }

    // MARK: - External link Util

    private func tappedExternalLink(with urlString: String) {
        guard let presentedViewController = navigationController.presentedViewController else {
            return
        }

        if let url = URL(string: urlString) {
            let config = SinglePageWebViewController.StandardConfig(url: url, useSimpleNavigationBar: true)
            let webVC = SinglePageWebViewController(configType: .standard(config), theme: theme)
            let newNavigationVC =
            WMFComponentNavigationController(rootViewController: webVC, modalPresentationStyle: .fullScreen)
            presentedViewController.present(newNavigationVC, animated: true)
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
        dismissSettings {
            if let vc = AboutViewController(theme: self.theme) {
                self.navigationController.pushViewController(vc, animated: true)
            }
        }

    }

    // MARK: - Help and feedback

    private func tappedHelpAndFeedback() {
        dismissSettings {
            if let vc = HelpViewController(dataStore: self.dataStore, theme: self.theme) {
                self.navigationController.pushViewController(vc, animated: true)
            }
        }
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
        guard let settingsNav = navigationController.presentedViewController as? UINavigationController else {
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

        // Migration: Check if old key exists and migrate to WMFData store
        let currentAutoSignValue = migrateAutoSignTalkPageDiscussions()

        let viewModel = WMFAccountSettingsViewModel(
            localizedStrings: strings,
            username: username,
            autoSignDiscussions: currentAutoSignValue,
            userDefaultsStore: WMFDataEnvironment.current.userDefaultsStore,
            onVanishAccount: { [weak self] in
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

    /// Migrates autoSignTalkPageDiscussions from legacy UserDefaults key to WMFData store.
    /// Once migrated, all future reads/writes use WMFData. Returns current value or default (true).
    private func migrateAutoSignTalkPageDiscussions() -> Bool {
        let userDefaultsStore = WMFDataEnvironment.current.userDefaultsStore

        // First check if we already have the value in the new WMFData store
        if let existingValue: Bool = try? userDefaultsStore?.load(key: WMFUserDefaultsKey.autoSignTalkPageDiscussions.rawValue) {
            return existingValue
        }

        // If not in new store, check if old key exists
        let oldKey = "WMFAutoSignTalkPageDiscussions"
        if UserDefaults.standard.object(forKey: oldKey) != nil {
            // Migrate from old location
            let oldValue = UserDefaults.standard.bool(forKey: oldKey)

            // Save to new location in WMFData store
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.autoSignTalkPageDiscussions.rawValue, value: oldValue)

            // Optionally remove old key after migration
            UserDefaults.standard.removeObject(forKey: oldKey)

            return oldValue
        }

        // Default value if neither exists (matches AppDelegate default of true)
        let defaultValue = true
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.autoSignTalkPageDiscussions.rawValue, value: defaultValue)
        return defaultValue
    }

    private func saveAutoSignTalkPageDiscussions(_ newValue: Bool) {
        let userDefaultsStore = WMFDataEnvironment.current.userDefaultsStore
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.autoSignTalkPageDiscussions.rawValue, value: newValue)
    }

    private func showVanishAccountWarning() {
        guard let settingsNav = navigationController.presentedViewController as? UINavigationController else {
            return
        }

        let warningViewController = VanishAccountWarningViewHostingViewController(theme: theme)
        warningViewController.delegate = self
        settingsNav.present(warningViewController, animated: true)
    }

    // MARK: - Temporary Account

    private func showTemporaryAccount() {
        guard let settingsNav = navigationController.presentedViewController as? UINavigationController else {
            return
        }

        let tempAccountVC = TempAccountsSettingsViewController(dataStore: dataStore)
        tempAccountVC.apply(theme: theme)
        settingsNav.pushViewController(tempAccountVC, animated: true)
    }

    // MARK: - Login

    private func showLogin() {
        guard let settingsNav = navigationController.presentedViewController as? UINavigationController else {
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
        guard let settingsNav = navigationController.presentedViewController as? UINavigationController else {
            return
        }

        let languagesVC = WMFPreferredLanguagesViewController.preferredLanguagesViewController()
        languagesVC.showExploreFeedCustomizationSettings = true
        languagesVC.apply(theme)
        let languagesNavVC = WMFComponentNavigationController(rootViewController: languagesVC, modalPresentationStyle: .overFullScreen)
        settingsNav.present(languagesNavVC, animated: true)
    }

    // MARK: - Search

    private func showSearch() {
        guard let settingsNav = navigationController.presentedViewController as? UINavigationController else {
            return
        }

        let strings = WMFSearchSettingsViewModel.LocalizedStrings(
            title: CommonStrings.searchTitle,
            showLanguagesTitle: WMFLocalizedString("settings-language-bar", value: "Show languages on search", comment: "Title in Settings for toggling the display the language bar in the search view"),
            openOnSearchTabTitle: WMFLocalizedString("settings-search-open-app-on-search", value: "Open app on Search tab", comment: "Title for setting that allows users to open app on Search tab"),
            footerText: WMFLocalizedString("settings-search-footer-text", value: "Set the app to open to the Search tab instead of the Explore tab", comment: "Footer text for section that allows users to customize certain Search settings")
        )

        let viewModel = WMFSearchSettingsViewModel(localizedStrings: strings)
        let rootView = WMFSearchSettingsView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: rootView)
        hostingController.title = strings.title
        settingsNav.pushViewController(hostingController, animated: true)
    }

    // MARK: - Explore Feed

    private func showExploreFeedSettings() {
        guard let settingsNav = navigationController.presentedViewController as? UINavigationController else {
            return
        }

        let feedSettingsVC = ExploreFeedSettingsViewController()
        feedSettingsVC.dataStore = dataStore
        feedSettingsVC.apply(theme: theme)
        settingsNav.pushViewController(feedSettingsVC, animated: true)
    }

    // MARK: - Notifications

    private func showNotifications() {
        guard let settingsNav = navigationController.presentedViewController as? UINavigationController else {
            return
        }

        let strings = WMFPushNotificationsSettingsViewModel.LocalizedStrings(
            title: CommonStrings.pushNotifications,
            headerText: WMFLocalizedString("settings-notifications-header", value: "Be alerted to activity related to your account, such as messages from fellow contributors, alerts, and notices. All provided with respect to privacy and up to the minute data.", comment: "Text informing user of benefits of enabling push notifications."),
            pushNotificationsTitle: CommonStrings.pushNotifications
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
                await subscribeToEchoNotifications()
                await pushNotificationsViewModel?.refreshAfterPermissionRequest(granted: true)

            case .notDetermined:
                let result = await withCheckedContinuation { continuation in
                    dataStore.notificationsController.requestPermissionsIfNecessary { authorized, error in
                        continuation.resume(returning: (authorized: authorized, error: error))
                    }
                }

                if result.authorized {
                    UIApplication.shared.registerForRemoteNotifications()
                    await subscribeToEchoNotifications()
                }
                await pushNotificationsViewModel?.refreshAfterPermissionRequest(granted: result.authorized)

            case .denied:
                await pushNotificationsViewModel?.refreshAfterPermissionRequest(granted: false)

            @unknown default:
                await pushNotificationsViewModel?.refreshAfterPermissionRequest(granted: false)
            }
        }
    }

    private func subscribeToEchoNotifications() async {
        await withCheckedContinuation { continuation in
            dataStore.notificationsController.subscribeToEchoNotifications { error in
                if let error {
                    DDLogError("Error subscribing to echo notifications: \(error)")
                }
                continuation.resume()
            }
        }
        await pushNotificationsViewModel?.loadAndBuild()
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
        guard let settingsNav = navigationController.presentedViewController as? UINavigationController else {
            return
        }

        let appearanceSettingsVC = AppearanceSettingsViewController()
        appearanceSettingsVC.apply(theme: theme)
        settingsNav.pushViewController(appearanceSettingsVC, animated: true)
    }

    // MARK: - Article Syncing

    private func showArticleSyncing() {
        guard let settingsNav = navigationController.presentedViewController as? UINavigationController else {
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
            guard let settingsNav = navigationController.presentedViewController as? UINavigationController else {
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
                guard let settingsNav = navigationController.presentedViewController as? UINavigationController else {
                    return
                }
                settingsNav.wmf_showKeepSavedArticlesOnDevicePanelIfNeeded(triggeredBy: .syncDisabled, theme: theme) {
                    setSyncEnabled()
                }
            } else {
                setSyncEnabled()
            }
        }
    }

    private func showEraseArticlesAlert() {
        guard let settingsNav = navigationController.presentedViewController as? UINavigationController else {
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
        guard let settingsNav = navigationController.presentedViewController as? UINavigationController else {
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
        guard let settingsNav = navigationController.presentedViewController as? UINavigationController else {
            return
        }
        settingsNav.wmf_showAlertWithMessage(WMFLocalizedString("settings-storage-and-syncing-full-sync", value: "Your reading lists will be synced in the background", comment: "Message confirming to the user that their reading lists will be synced in the background"))
    }

    // MARK: - Logout

    private func logout() {
        guard let settingsNav = navigationController.presentedViewController as? UINavigationController else {
            return
        }

        settingsNav.wmf_showKeepSavedArticlesOnDevicePanelIfNeeded(triggeredBy: .logout, theme: theme) {
            self.dataStore.authenticationManager.logout(initiatedBy: .user) {
                LoginFunnel.shared.logLogoutInSettings()
            }
        }
    }

}

// MARK: - AccountViewControllerDelegate

@MainActor
extension SettingsCoordinator: @MainActor AccountViewControllerDelegate {
    func accountViewControllerDidTapLogout(_ accountViewController: AccountViewController) {
        logout()
    }
}

// MARK: - VanishAccountWarningViewDelegate

extension SettingsCoordinator: VanishAccountWarningViewDelegate {
    func userDidDismissVanishAccountWarningView(presentVanishView: Bool) {
        guard presentVanishView else {
            return
        }

        guard let url = URL(string: "https://meta.wikimedia.org/wiki/Special:GlobalVanishRequest") else {
            return
        }

        guard let settingsNav = navigationController.presentedViewController as? UINavigationController else {
            return
        }

        let config = SinglePageWebViewController.StandardConfig(url: url, useSimpleNavigationBar: false)
        let viewController = SinglePageWebViewController(configType: .standard(config), theme: theme)
        settingsNav.pushViewController(viewController, animated: true)
    }
}
