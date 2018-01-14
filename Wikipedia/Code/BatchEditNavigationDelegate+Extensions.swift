extension BatchEditNavigationDelegate where Self: UIViewController {
    func didSetBatchEditToolbarHidden(_ batchEditToolbar: UIToolbar, isHidden: Bool, with items: [UIBarButtonItem]) {
        defer {
            batchEditToolbar.isHidden = isHidden
            tabBarController?.tabBar.isHidden = !isHidden
        }
        
        guard batchEditToolbar.superview == nil else {
            return
        }
        
        batchEditToolbar.items = items
        view.addSubview(batchEditToolbar)
        
        let layoutGuide = view.layoutMarginsGuide
        let bottomConstraint = batchEditToolbar.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor)
        let leadingConstraint = batchEditToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        let trailingConstraint = batchEditToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        
        if let tabBar = tabBarController?.tabBar {
            let topConstraint = batchEditToolbar.topAnchor.constraint(equalTo: tabBar.topAnchor)
            topConstraint.isActive = true
        } else if let navigationBar = navigationController?.navigationBar {
            let heightConstraint = batchEditToolbar.heightAnchor.constraint(equalToConstant: navigationBar.frame.size.height)
            heightConstraint.isActive = true
        }
        
        NSLayoutConstraint.activate([bottomConstraint, leadingConstraint, trailingConstraint])
    }
}
