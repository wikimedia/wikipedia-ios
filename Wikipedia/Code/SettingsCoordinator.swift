import UIKit
import WMF
import WMFComponents

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
}
