import UIKit

final class LoginCoordinator: Coordinator {

    // MARK: Coordinator Protocol Properties
    
    var navigationController: UINavigationController

    // MARK: Properties

    private let theme: Theme

    // MARK: Lifecycle

    init(navigationController: UINavigationController, theme: Theme) {
        self.navigationController = navigationController
        self.theme = theme
    }

    func start() {
        if let loginVC = WMFLoginViewController.wmf_initialViewControllerFromClassStoryboard() {
            loginVC.apply(theme: theme)
            let navVC = WMFThemeableNavigationController(rootViewController: loginVC, theme: theme)
            navigationController.present(navVC, animated: true)
        }
    }
}
