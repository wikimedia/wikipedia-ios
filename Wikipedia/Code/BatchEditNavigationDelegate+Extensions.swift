extension BatchEditNavigationDelegate where Self: UIViewController {
    func didSetBatchEditToolbarHidden(_ batchEditToolbarViewController: BatchEditToolbarViewController, isHidden: Bool, with items: [UIButton]) {
        
        let tabBar = self.tabBarController?.tabBar
        
        if batchEditToolbarViewController.parent == nil {
            addChildViewController(batchEditToolbarViewController)
            batchEditToolbarViewController.view.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
            view.addSubview(batchEditToolbarViewController.view)
            let height = tabBarController?.tabBar.frame.height ?? navigationController?.navigationBar.frame.size.height ?? 0
            batchEditToolbarViewController.view.frame = CGRect(x: 0, y: view.bounds.height - height, width: view.bounds.width, height: height)
            batchEditToolbarViewController.didMove(toParentViewController: self)
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
    }
    
    func emptyStateDidChange(_ empty: Bool) {
        //
    }
}
