import UIKit
import WMF
import WMFComponents
import WMFData

final class NewArticleTabCoordinator: Coordinator {
    internal var navigationController: UINavigationController
    private var dataStore: MWKDataStore
    private var theme: Theme
    private let tabIdentifier: WMFArticleTabsDataController.Identifiers?

    // MARK: - Lifecycle
    init(navigationController: UINavigationController, dataStore: MWKDataStore, theme: Theme, fetcher: RelatedSearchFetcher = RelatedSearchFetcher(), tabIdentifier: WMFArticleTabsDataController.Identifiers? = nil) {
        self.navigationController = navigationController
        self.dataStore = dataStore
        self.theme = theme
        self.tabIdentifier = tabIdentifier
    }

    // MARK: - Methods
    @discardableResult
        func start() -> Bool {
            let searchVC = SearchViewController(
                source: .unknown,
                customArticleCoordinatorNavigationController: navigationController,
                needsAttachedView: true,
                becauseYouReadViewModel: nil,
                didYouKnowViewModel: nil
            )
            searchVC.dataStore = dataStore
            searchVC.theme = theme
            searchVC.shouldBecomeFirstResponder = true
            searchVC.tabIdentifier = tabIdentifier
            searchVC.needsCenteredTitle = true
            searchVC.customTitle = CommonStrings.newTab
            navigationController.pushViewController(searchVC, animated: true)
            return true
        }

}
