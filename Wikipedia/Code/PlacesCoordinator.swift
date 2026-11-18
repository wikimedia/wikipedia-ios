import UIKit
import WMF
import WMFComponents

/// Builds the Places tab.
@MainActor
final class PlacesCoordinator: TabRootCoordinator {

    let tab: WMFAppTabType = .places

    private var tabNavigationController: UINavigationController?
    var navigationController: UINavigationController {
        guard let tabNavigationController else {
            fatalError("PlacesCoordinator.navigationController accessed before attach(navigationController:)")
        }
        return tabNavigationController
    }

    private var theme: Theme
    private var placesViewController: PlacesViewController?

    init(theme: Theme) {
        self.theme = theme
    }

    var viewController: PlacesViewController {
        if let placesViewController {
            return placesViewController
        }
        let vc = UIStoryboard(name: "Places", bundle: nil).instantiateInitialViewController() as! PlacesViewController
        vc.apply(theme: theme)
        vc.tabBarItem.image = UIImage(named: "tabbar-nearby")
        vc.tabBarItem.accessibilityIdentifier = AccessibilityIdentifiers.RootTab.placesButton
        vc.title = WMFCommonStringsWrapper.placesTabTitle
        placesViewController = vc
        return vc
    }

    var rootViewController: UIViewController {
        viewController
    }

    func attach(navigationController: UINavigationController) {
        tabNavigationController = navigationController
    }

    @discardableResult
    func start() -> Bool {
        navigationController.setViewControllers([viewController], animated: false)
        return true
    }

    func apply(theme: Theme) {
        self.theme = theme
        viewController.apply(theme: theme)
    }
}
