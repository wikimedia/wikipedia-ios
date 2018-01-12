struct BatchEditToolbar {
    fileprivate let height: CGFloat = 44
    internal var toolbar = UIToolbar()
    let owner: UIView
    
    init(for view: UIView) {
        self.owner = view
        setup()
    }
    
    fileprivate func setup() {
        toolbar.frame = CGRect(x: 0, y: owner.bounds.height - height, width: owner.bounds.width, height: height)
        toolbar.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
    }
}

extension BatchEditNavigationDelegate where Self: UIViewController {
    func didSetBatchEditToolbarVisible(_ isVisible: Bool) {
        tabBarController?.tabBar.isHidden = isVisible
    }
    
    func setToolbarButtons(enabled: Bool) {
        guard let items = batchEditToolbar.items else {
            return
        }
        for (index, item) in items.enumerated() where index != 0 {
            item.isEnabled = enabled
        }
    }
    
    func createBatchEditToolbar(with items: [UIBarButtonItem], setVisible visible: Bool) {
        if visible {
            batchEditToolbar.items = items
            view.addSubview(batchEditToolbar)
        } else {
            batchEditToolbar.removeFromSuperview()
        }
    }
}
