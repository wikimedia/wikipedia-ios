import UIKit

protocol Peekable {
    
}

extension UIViewController {
    // Adds a peekable view controller on top of another view controller. Since the view controller is the one we want to show when the user peeks through, we're saving time by loading it behind the peekable view controller.
    @objc func wmf_addPeekableChildViewController(for articleURL: URL, dataStore: MWKDataStore, theme: Theme, containerView: UIView? = nil) {
        let articlePeekPreviewViewController = ArticlePeekPreviewViewController(articleURL: articleURL, dataStore: dataStore, theme: theme)
        
        addChild(articlePeekPreviewViewController)
        (containerView ?? view).wmf_addSubviewWithConstraintsToEdges(articlePeekPreviewViewController.view)
        articlePeekPreviewViewController.didMove(toParent: self)
    }
    
    @objc var wmf_PeekableChildViewController: UIViewController? {
        return children.first(where: { $0 is Peekable })
    }
    
    @objc func wmf_removePeekableChildViewControllers() {
        for vc in children {
            guard vc is Peekable else {
                return
            }
            vc.view.removeFromSuperview()
            vc.willMove(toParent: nil)
            vc.removeFromParent()
        }
    }

}
