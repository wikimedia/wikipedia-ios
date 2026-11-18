import UIKit
import WMF
import WMFComponents

/// Builds the Search tab.
@MainActor
final class SearchTabCoordinator: TabRootCoordinator {

    let tab: WMFAppTabType = .search

    private var tabNavigationController: UINavigationController?
    var navigationController: UINavigationController {
        guard let tabNavigationController else {
            fatalError("SearchTabCoordinator.navigationController accessed before attach(navigationController:)")
        }
        return tabNavigationController
    }

    private var theme: Theme
    private let dataStore: MWKDataStore
    private var searchViewController: SearchViewController?

    init(theme: Theme, dataStore: MWKDataStore) {
        self.theme = theme
        self.dataStore = dataStore
    }

    var viewController: SearchViewController {
        if let searchViewController {
            return searchViewController
        }
        let vc = SearchViewController(source: .searchTab)
        vc.apply(theme: theme)
        vc.dataStore = dataStore
        vc.tabBarItem = UITabBarItem(tabBarSystemItem: .search, tag: Int(WMFAppTabType.search.rawValue))
        vc.tabBarItem.accessibilityIdentifier = AccessibilityIdentifiers.RootTab.searchButton
        vc.title = WMFCommonStringsWrapper.searchTitle
        searchViewController = vc
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

    func tabWasReselected() {
        viewController.makeSearchBarBecomeFirstResponder()
    }
}
