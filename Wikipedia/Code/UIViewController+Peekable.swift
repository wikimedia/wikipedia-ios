import UIKit

extension UIViewController {
    // Adds a peekable view controller on top of another view controller. Since the view controller is the one we want to show when the user peeks through, we're saving time by loading it behind the peekable view controller.
    @objc func wmf_setupPeekable(_ peekableViewController: UIViewController, on viewController: UIViewController) -> UIViewController {
        viewController.addChildViewController(peekableViewController)
        viewController.view.wmf_addSubviewWithConstraintsToEdges(peekableViewController.view)
        peekableViewController.didMove(toParentViewController: viewController)
        return viewController
    }
    
    @objc func wmf_removePeekable(_ peekableViewController: UIViewController) {
        peekableViewController.view.removeFromSuperview()
        peekableViewController.removeFromParentViewController()
    }
}
