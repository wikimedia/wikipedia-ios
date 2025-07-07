import UIKit
import WMF
import WMFComponents

final class SettingsCoordinator: Coordinator, SettingsCoordinatorDelegate {

    // MARK: Coordinator Protocol Properties

    internal var navigationController: UINavigationController

    // MARK: Properties

    private let theme: Theme
    private let dataStore: MWKDataStore

    // MARK: Lifecycle

    init(navigationController: UINavigationController, theme: Theme, dataStore: MWKDataStore) {
        self.navigationController = navigationController
        self.theme = theme
        self.dataStore = dataStore
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
            storageAndSync: CommonStrings.settingsStorageAndSyncing,
            dangerZoneTitle: "Reading lists danger zone",
            clearCacheTitle: CommonStrings.clearCachedDataSettings,
            privacyHeader: CommonStrings.privacyTermsHeader,
            privacyPolicyTitle: CommonStrings.privacyPolicyTitle,
            termsOfUseTitle: CommonStrings.termsOfUseTitle,
            rateTheAppTitle: CommonStrings.rateTheAppTitle,
            helpTitle: CommonStrings.helpAndfeedbackTitle,
            aboutTitle: CommonStrings.aboutTitle)
    }

    func tempNewSettings() { // TEST CODE
        var isExploreFeedOn: Bool = true // TODO -  get this status dinamically
        let yirIsOn = true // TODO get status
        let themeName = theme.displayName // TODO get preference, not theme name
        if navigationController.viewControllers.count == 1,
           (navigationController.viewControllers.first as? WMFSettingsViewController) != nil {
            isExploreFeedOn = false
        }
        let viewModel = WMFSettingsViewModel(localizedStrings: locStrings(), username: "test", mainLanguage: "PT", exploreFeedStatus: isExploreFeedOn, yirStatus: yirIsOn, readingPreferenceTheme: themeName)
        let settingsViewController =  WMFSettingsViewControllerNEW(viewModel: viewModel, coordinatorDelegate: self)
        let navVC = WMFComponentNavigationController(rootViewController: settingsViewController, modalPresentationStyle: .overFullScreen)
        navigationController.present(navVC, animated: true)
    }


    func handleSettingsAction(_ action: SettingsAction) {
        switch action {

        case .account:
            print("account ⭐️")
        case .logIn:
            print("login ⭐️")
        case .myLanguages:
            print("lang ⭐️")
        case .search:
            print("search ⭐️")
        case .exploreFeed:
            print("explore ⭐️")
        case .yearInReview:
            print("yir ⭐️")
        case .notifications:
            print("notif ⭐️")
        case .readingPreferences:
            print("read pref ⭐️")
        case .articleSyncing:
            print("sync ⭐️")
        case .readingListDangerZone:
            print("danger ⭐️")
        case .clearCachedData:
            print("clear data ⭐️")
        case .privacyPolicy:
            print("privacy ⭐️")
        case .termsOfUse:
            print("terms ⭐️")
        case .rateTheApp:
            print("rate ⭐️")
        case .helpAndFeedback:
            print("help ⭐️")
        case .about:
            print("about ⭐️")
        }
    }
}
