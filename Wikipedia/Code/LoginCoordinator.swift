import UIKit
import WMFComponents

final class LoginCoordinator: Coordinator {

    // MARK: Coordinator Protocol Properties
    
    var navigationController: UINavigationController
    
    var loginSuccessCompletion: (() -> Void)?
    var createAccountSuccessCustomDismissBlock: (() -> Void)?

    // MARK: Properties

    private let theme: Theme
    private let loggingCategory: EventCategoryMEP?

    // MARK: Lifecycle

    init(navigationController: UINavigationController, theme: Theme, loggingCategory: EventCategoryMEP? = nil) {
        self.navigationController = navigationController
        self.theme = theme
        self.loggingCategory = loggingCategory
    }

    @discardableResult
    func start() -> Bool {
        guard let loginVC = WMFLoginViewController.wmf_initialViewControllerFromClassStoryboard() else {
            return false
        }
        
        if let loggingCategory {
            loginVC.category = loggingCategory
        }
        
        loginVC.apply(theme: theme)
        let loginNavVC = WMFComponentNavigationController(rootViewController: loginVC, modalPresentationStyle: .overFullScreen)
        loginVC.loginSuccessCompletion = loginSuccessCompletion
        loginVC.createAccountSuccessCustomDismissBlock = createAccountSuccessCustomDismissBlock
        
        if let presentedVC = navigationController.presentedViewController {
            presentedVC.present(loginNavVC, animated: true)
        } else {
            navigationController.present(loginNavVC, animated: true)
        }
        
        return true
    }
}
