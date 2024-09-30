import UIKit
import WMF

final class SettingsCoordinator: Coordinator {

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

    func start() {
        
        // If navigation controller already has WMFSettingsViewController as it's root view controller, no need to navigate anywhere
        if navigationController.viewControllers.count == 1,
           (navigationController.viewControllers.first as? WMFSettingsViewController) != nil {
            return
        }
        
        let settingsViewController = WMFSettingsViewController(dataStore: dataStore)
        settingsViewController.theme = theme
        let navVC = WMFThemeableNavigationController(rootViewController: settingsViewController, theme: theme)
        navigationController.present(navVC, animated: true)
    }
}
