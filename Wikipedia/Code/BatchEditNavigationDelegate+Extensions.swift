extension BatchEditNavigationDelegate where Self: UIViewController {
    func didSetBatchEditToolbarHidden(_ batchEditToolbarViewController: BatchEditToolbarViewController, isHidden: Bool, with items: [UIButton]) {
        UIView.animate(withDuration: 0.5, delay: 0, options: [.layoutSubviews, .curveLinear], animations: {
            self.tabBarController?.tabBar.alpha = isHidden ? 1 : 0
        }, completion: nil)
    }
    
    func didCreateBatchEditToolbarViewController(_ batchEditToolbarViewController: BatchEditToolbarViewController) {
        addChildViewController(batchEditToolbarViewController)
        batchEditToolbarViewController.view.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        view.addSubview(batchEditToolbarViewController.view)
        let height = tabBarController?.tabBar.frame.height ?? navigationController?.navigationBar.frame.size.height ?? 0
        batchEditToolbarViewController.view.frame = CGRect(x: 0, y: view.bounds.height - height, width: view.bounds.width, height: height)
        batchEditToolbarViewController.didMove(toParentViewController: self)
    }
}
