extension CollectionViewEditControllerNavigationDelegate where Self: UIViewController {
    func didSetBatchEditToolbarHidden(_ batchEditToolbarViewController: BatchEditToolbarViewController, isHidden: Bool, with items: [UIButton]) {
        
        
        if batchEditToolbarViewController.parent == nil {
            addChild(batchEditToolbarViewController)
            batchEditToolbarViewController.view.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(batchEditToolbarViewController.view)
            batchEditToolbarViewController.didMove(toParent: self)
            
            let leadingConstraint = batchEditToolbarViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor)
            let trailingConstraint = batchEditToolbarViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            let bottomConstraint = batchEditToolbarViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            view.addConstraints([leadingConstraint, trailingConstraint, bottomConstraint])
            
            batchEditToolbarViewController.view.alpha = 0

        }

        UIView.transition(with: batchEditToolbarViewController.view, duration: 0.7, options: .transitionCrossDissolve, animations: {
             batchEditToolbarViewController.view.alpha = isHidden ? 0 : 1
        }) { _ in
            if isHidden {
                batchEditToolbarViewController.view.removeFromSuperview()
                batchEditToolbarViewController.willMove(toParent: nil)
                batchEditToolbarViewController.removeFromParent()
            }
        }
        batchEditToolbarViewController.apply(theme: currentTheme)
    }
    
    func emptyStateDidChange(_ empty: Bool) {
        // conforming types can provide their own implementations
    }
}
