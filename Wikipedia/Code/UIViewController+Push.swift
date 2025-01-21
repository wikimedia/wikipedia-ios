import Foundation

extension UIViewController {
    @objc(wmf_pushViewController:animated:)
    func push(_ viewController: UIViewController, animated: Bool = true) {
        
        if let navigationController = navigationController {
            if #available(iOS 18, *) {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    // Need to do some fanciness here to handle iPad floating tab bar layout
                    if navigationController.navigationBar.isHidden {
                        navigationController.setNavigationBarHidden(false, animated: true)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            navigationController.pushViewController(viewController, animated: true)
                        }
                    } else {
                        navigationController.pushViewController(viewController, animated: true)
                    }
                } else {
                    navigationController.pushViewController(viewController, animated: true)
                }
            } else {
                navigationController.pushViewController(viewController, animated: true)
            }
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
