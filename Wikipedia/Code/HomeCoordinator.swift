import UIKit
import WMF
import WMFComponents
import WMFData
import WMFNativeLocalizations

@MainActor
final class HomeCoordinator: NSObject, Coordinator {

    // The Home tab's navigation controller. Injected via `attach(navigationController:)` once the
    // Home view controller has been wrapped in its tab navigation controller.
    private var tabNavigationController: UINavigationController?
    var navigationController: UINavigationController {
        guard let tabNavigationController else {
            fatalError("HomeCoordinator.navigationController accessed before attach(navigationController:)")
        }
        return tabNavigationController
    }

    var theme: Theme
    let dataStore: MWKDataStore

    private(set) weak var homeViewController: HomeViewController?

    init(theme: Theme, dataStore: MWKDataStore) {
        self.theme = theme
        self.dataStore = dataStore
    }

    func attach(navigationController: UINavigationController) {
        self.tabNavigationController = navigationController
    }

    @discardableResult
    func start() -> Bool {
        let vc = makeHomeViewController()
        navigationController.setViewControllers([vc], animated: false)
        return true
    }

    /// Builds the configured Home tab root view controller, with its tab bar item title and icon set.
    func makeHomeViewController() -> HomeViewController {
        let localizedStrings = WMFHomeViewModel.LocalizedStrings(
            title: CommonStrings.homeTabTitle,
            forYouTabTitle: CommonStrings.homeForYouTabTitle,
            communityTabTitle: CommonStrings.homeCommunityTabTitle
        )

        let languageCode = dataStore.languageLinkController.appLanguage?.languageCode.uppercased() ?? String()

        let viewModel = WMFHomeViewModel(localizedStrings: localizedStrings, currentLanguageCode: languageCode)
        viewModel.didTapLanguagePicker = { [weak self] in
            self?.showLanguagePicker()
        }

        let vc = HomeViewController(dataStore: dataStore, theme: theme, viewModel: viewModel)
        vc.title = CommonStrings.homeTabTitle
        vc.tabBarItem.image = WMFSFSymbolIcon.for(symbol: .house)
        vc.tabBarItem.accessibilityIdentifier = AccessibilityIdentifiers.RootTab.homeButton
        vc.apply(theme: theme)

        homeViewController = vc
        return vc
    }

    private func showLanguagePicker() {
        // TODO: Present the Home language picker once it is designed.
    }
}
