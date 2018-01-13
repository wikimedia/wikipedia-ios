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
        let topConstraint = batchEditToolbar.topAnchor.constraint(equalTo: tabBarController!.tabBar.topAnchor)
        NSLayoutConstraint.activate([topConstraint, bottomConstraint, leadingConstraint, trailingConstraint])
    }
}
