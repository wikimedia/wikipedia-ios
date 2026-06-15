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

    func makeHomeViewController() -> HomeViewController {
        let viewModel = WMFHomeViewModel()

        let vc = HomeViewController(dataStore: dataStore, theme: theme, viewModel: viewModel)
        vc.title = CommonStrings.homeTabTitle
        vc.tabBarItem.image = WMFSFSymbolIcon.for(symbol: .house)
        vc.tabBarItem.accessibilityIdentifier = AccessibilityIdentifiers.RootTab.homeButton
        vc.apply(theme: theme)

        homeViewController = vc
        return vc
    }
}
