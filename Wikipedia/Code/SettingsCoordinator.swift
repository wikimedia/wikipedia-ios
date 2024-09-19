import UIKit
import WMF

public class SettingsCoordinator: Coordinator {

    // MARK: Coordinator Protocol Properties
    
    internal var navigationController: UINavigationController

    // MARK: Properties

    private let theme: Theme
    private let dataStore: MWKDataStore

    // MARK: Lifecycle

    public init(navigationController: UINavigationController, theme: Theme, dataStore: MWKDataStore) {
        self.navigationController = navigationController
        self.theme = theme
        self.dataStore = dataStore
    }

    // MARK: Coordinator Protocol Methods

    public func start() {
        let settingsViewController = WMFSettingsViewController(dataStore: dataStore)
        settingsViewController.theme = theme
        let navVC = WMFThemeableNavigationController(rootViewController: settingsViewController, theme: theme)
        navigationController.present(navVC, animated: true)
    }
}
