extension CollectionViewEditControllerNavigationDelegate where Self: UIViewController {
    func didSetBatchEditToolbarHidden(_ batchEditToolbarViewController: BatchEditToolbarViewController, isHidden: Bool, with items: [UIButton]) {
        
        let tabBar = self.tabBarController?.tabBar
        
        if batchEditToolbarViewController.parent == nil {
            addChildViewController(batchEditToolbarViewController)
            batchEditToolbarViewController.view.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(batchEditToolbarViewController.view)
            batchEditToolbarViewController.didMove(toParentViewController: self)
            
            let leadingConstraint = batchEditToolbarViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor)
            let trailingConstraint = batchEditToolbarViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            let heightConstraint = batchEditToolbarViewController.view.heightAnchor.constraint(equalTo: bottomLayoutGuide.heightAnchor)
            let bottomConstraint = batchEditToolbarViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            view.addConstraints([leadingConstraint, trailingConstraint, heightConstraint, bottomConstraint])
            
            // if a vc has no tab bar to cover the toolbar view, hide the toolbar view initally
            if tabBar == nil {
                batchEditToolbarViewController.view.alpha = 0
            }
        }
        
        batchEditToolbarViewController.apply(theme: currentTheme)
        UIView.animate(withDuration: 0.3, delay: 0, options: [.beginFromCurrentState, .curveLinear], animations: {
            if let tabBar = tabBar {
                tabBar.alpha = isHidden ? 1 : 0
            } else {
                batchEditToolbarViewController.view.alpha = isHidden ? 0 : 1
            }
        }, completion: nil)
        
        if isHidden {
            batchEditToolbarViewController.view.removeFromSuperview()
            batchEditToolbarViewController.willMove(toParentViewController: nil)
            batchEditToolbarViewController.removeFromParentViewController()
        }
    }
    
    func emptyStateDidChange(_ empty: Bool) {
        // conforming types can provide their own implementations
    }
}
