import UIKit
import SwiftUI
import WMF
import WMFComponents
import WMFData
import CocoaLumberjackSwift

@MainActor
final class SettingsCoordinator: Coordinator, @MainActor SettingsCoordinatorDelegate {

    // MARK: Coordinator Protocol Properties

    internal var navigationController: UINavigationController

    // MARK: Properties

    private let theme: Theme
    private let dataStore: MWKDataStore

    private let dataController: WMFSettingsDataController
    @MainActor private weak var settingsViewModel: WMFSettingsViewModel?

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

    func tempNewSettings() async { // TEST CODE

        let isExploreFeedOn = UserDefaults.standard.defaultTabType == .explore
        let themeName = UserDefaults.standard.themeDisplayName

        let username = dataStore.authenticationManager.authStatePermanentUsername

        let tempUsername = dataStore.authenticationManager.authStateTemporaryUsername
        let isTempAccount = WMFTempAccountDataController.shared.primaryWikiHasTempAccountsEnabled && dataStore.authenticationManager.authStateIsTemporary

        let language = dataStore.languageLinkController.appLanguage?.languageCode.uppercased() ?? String()

        let viewModel = await WMFSettingsViewModel(localizedStrings: locStrings(), username: username, tempUsername: tempUsername, isTempAccount: isTempAccount, primaryLanguage: language, exploreFeedStatus: isExploreFeedOn, readingPreferenceTheme: themeName, dataController: WMFSettingsDataController())

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

        let accountVC = AccountViewController()
        accountVC.dataStore = dataStore
        accountVC.delegate = self
        accountVC.apply(theme: theme)
        settingsNav.pushViewController(accountVC, animated: true)
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

        let searchSettingsVC = SearchSettingsViewController()
        searchSettingsVC.apply(theme: theme)
        settingsNav.pushViewController(searchSettingsVC, animated: true)
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

        let pushSettingsVC = PushNotificationsSettingsViewController(authenticationManager: dataStore.authenticationManager, notificationsController: dataStore.notificationsController)
        pushSettingsVC.apply(theme: theme)
        settingsNav.pushViewController(pushSettingsVC, animated: true)
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

        let storageAndSyncingVC = StorageAndSyncingSettingsViewController()
        storageAndSyncingVC.dataStore = dataStore
        storageAndSyncingVC.apply(theme: theme)
        settingsNav.pushViewController(storageAndSyncingVC, animated: true)
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
