import Foundation

extension UIViewController {
    @objc(wmf_pushViewController:animated:)
    func push(_ viewController: UIViewController, animated: Bool = true) {
        if let navigationController = navigationController {
            navigationController.pushViewController(viewController, animated: true)
        } else if let presentingViewController = presentingViewController {
            presentingViewController.dismiss(animated: true) {
                presentingViewController.push(viewController, animated: animated)
            }
        } else if let parent = parent {
            parent.push(viewController, animated: animated)
        } else if let navigationController = self as? UINavigationController {
            navigationController.pushViewController(viewController, animated: animated)
        }
    }
}
