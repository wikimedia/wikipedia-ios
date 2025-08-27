import UIKit
import WMF
import WMFComponents
import WMFData

final class NewArticleTabCoordinator: Coordinator {
    internal var navigationController: UINavigationController
    private var dataStore: MWKDataStore
    private var theme: Theme
    private let tabIdentifier: WMFArticleTabsDataController.Identifiers?
    private let cameFromNewTab: Bool

    // MARK: - Lifecycle
    init(navigationController: UINavigationController, dataStore: MWKDataStore, theme: Theme, tabIdentifier: WMFArticleTabsDataController.Identifiers? = nil, cameFromNewTab: Bool) {
        self.navigationController = navigationController
        self.dataStore = dataStore
        self.theme = theme
        self.tabIdentifier = tabIdentifier
        self.cameFromNewTab = cameFromNewTab
    }

    // MARK: - Methods
    @discardableResult
        func start() -> Bool {
            let searchVC = SearchViewController(
                source: .unknown,
                customArticleCoordinatorNavigationController: navigationController,
                needsAttachedView: true
            )
            searchVC.dataStore = dataStore
            searchVC.theme = theme
            searchVC.shouldBecomeFirstResponder = true
            searchVC.needsCenteredTitle = true
            searchVC.customTitle = CommonStrings.newTab
            searchVC.cameFromNewTab = cameFromNewTab
            navigationController.pushViewController(searchVC, animated: true)
            return true
        }

}
