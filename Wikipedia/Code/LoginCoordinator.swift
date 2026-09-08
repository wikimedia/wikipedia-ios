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

    private let startsOnAccountCreation: Bool

    // MARK: Lifecycle

    init(navigationController: UINavigationController, theme: Theme, loggingCategory: EventCategoryMEP? = nil, startsOnAccountCreation: Bool = false) {
        self.navigationController = navigationController
        self.theme = theme
        self.loggingCategory = loggingCategory
        self.startsOnAccountCreation = startsOnAccountCreation
    }

    @discardableResult
    func start() -> Bool {
        return startsOnAccountCreation ? startAccountCreation() : startLogin()
    }

    private func startLogin() -> Bool {
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

        present(loginNavVC)

        return true
    }

    /// Mirrors what `WMFLoginViewController` does when its own create account link is tapped.
    private func startAccountCreation() -> Bool {
        guard let accountCreationVC = WMFAccountCreationViewController.wmf_initialViewControllerFromClassStoryboard() else {
            return false
        }

        accountCreationVC.category = loggingCategory
        accountCreationVC.createAccountSuccessCustomDismissBlock = createAccountSuccessCustomDismissBlock
        accountCreationVC.apply(theme: theme)
        LoginFunnel.shared.logCreateAccountAttempt(category: loggingCategory)

        let accountCreationNavVC = WMFComponentNavigationController(rootViewController: accountCreationVC, modalPresentationStyle: .overFullScreen)

        present(accountCreationNavVC)

        return true
    }

    private func present(_ viewController: UIViewController) {
        if let presentedVC = navigationController.presentedViewController {
            presentedVC.present(viewController, animated: true)
        } else {
            navigationController.present(viewController, animated: true)
        }
    }
}
