import UIKit
import WMF
import WMFComponents

final class NewArticleTabCoordinator: Coordinator {
    var navigationController: UINavigationController
    var dataStore: MWKDataStore
    var theme: Theme
    

    init(navigationController: UINavigationController, dataStore: MWKDataStore, theme: Theme) {
        self.navigationController = navigationController
        self.dataStore = dataStore
        self.theme = theme
    }


    @discardableResult
    func start() -> Bool {
        let viewModel = WMFNewArticleTabViewModel(title: CommonStrings.newTab)
        let viewController = WMFNewArticleTabController(dataStore: dataStore, theme: theme, viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
        return true
    }

}
