import UIKit
import WMF
import WMFComponents

@objc final class SettingsCoordinator: NSObject, Coordinator {

    // MARK: Coordinator Protocol Properties
    
    internal var navigationController: UINavigationController

    // MARK: Properties

    private let theme: Theme
    private let dataStore: MWKDataStore
    private(set) weak var settingsViewController: WMFSettingsViewController?

    // MARK: Lifecycle

    @objc init(navigationController: UINavigationController, theme: Theme, dataStore: MWKDataStore) {
        self.navigationController = navigationController
        self.theme = theme
        self.dataStore = dataStore
        super.init()
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

    @discardableResult
    @objc
    func startEmbed() -> Bool {
        guard settingsViewController == nil else { return true }

        let vc = WMFSettingsViewController(dataStore: dataStore, theme: theme)
//        vc.apply(theme)


        self.settingsViewController = vc
        return true
    }

    // Convenience for Obj-C
    @objc var embeddedRootViewController: UIViewController? { settingsViewController }
}
