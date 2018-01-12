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
    func didSetBatchEditToolbarHidden(_ hidden: Bool, with items: [UIBarButtonItem]) {

        if hidden {
            batchEditToolbar.removeFromSuperview()
        } else {
            batchEditToolbar.items = items
            view.addSubview(batchEditToolbar)
        }
        
        tabBarController?.tabBar.isHidden = !hidden
    }
    
    func setToolbarButtons(enabled: Bool) {
        guard let items = batchEditToolbar.items else {
            return
        }
        for (index, item) in items.enumerated() where index != 0 {
            item.isEnabled = enabled
        }
    }
}
