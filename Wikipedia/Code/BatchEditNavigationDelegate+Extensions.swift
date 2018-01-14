extension BatchEditNavigationDelegate where Self: UIViewController {
    func didSetBatchEditToolbarHidden(_ batchEditToolbar: UIToolbar, isHidden: Bool, with items: [UIBarButtonItem]) {
        defer {
            UIView.animate(withDuration: 0.5, delay: 0, options: [.layoutSubviews, .curveLinear], animations: {
                self.tabBarController?.tabBar.alpha = isHidden ? 1 : 0
                batchEditToolbar.alpha = isHidden ? 0 : 1
            }, completion: nil)
        }
        
        guard batchEditToolbar.superview == nil else {
            return
        }
        
        let height = tabBarController?.tabBar.frame.height ?? navigationController?.navigationBar.frame.size.height ?? 0
        batchEditToolbar.frame = CGRect(x: 0, y: view.bounds.height - height, width: view.bounds.width, height: height)
        batchEditToolbar.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        batchEditToolbar.items = items
        view.addSubview(batchEditToolbar)
        batchEditToolbar.isHidden = false
    }
}
