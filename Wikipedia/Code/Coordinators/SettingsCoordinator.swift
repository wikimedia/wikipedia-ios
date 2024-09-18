import UIKit
import WMF

public class SettingsCoordinator: Coordinator {

    internal var navigationController: UINavigationController
    private let theme: Theme
    private let dataStore: MWKDataStore

    public init(navigationController: UINavigationController, theme: Theme, dataStore: MWKDataStore) {
        self.navigationController = navigationController
        self.theme = theme
        self.dataStore = dataStore
    }

    public func start() {
        let settingsViewController = WMFSettingsViewController(dataStore: dataStore)
        settingsViewController.theme = theme
        navigationController.pushViewController(settingsViewController, animated: true)
    }
}
