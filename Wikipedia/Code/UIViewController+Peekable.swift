import UIKit

protocol Peekable {
    
}

extension UIViewController {
    // Adds a peekable view controller on top of another view controller. Since the view controller is the one we want to show when the user peeks through, we're saving time by loading it behind the peekable view controller.
    @objc func wmf_addPeekableChildViewController(for articleURL: URL, dataStore: MWKDataStore, theme: Theme) {
        let articlePeekPreviewViewController = ArticlePeekPreviewViewController(articleURL: articleURL, dataStore: dataStore, theme: theme)
        
        addChildViewController(articlePeekPreviewViewController)
        view.wmf_addSubviewWithConstraintsToEdges(articlePeekPreviewViewController.view)
        articlePeekPreviewViewController.didMove(toParentViewController: self)
    }
    
    @objc func wmf_removePeekableChildViewControllers() {
        for vc in childViewControllers {
            guard vc is Peekable else {
                return
            }
            vc.view.removeFromSuperview()
            vc.willMove(toParentViewController: nil)
            vc.removeFromParentViewController()
        }
    }

}
