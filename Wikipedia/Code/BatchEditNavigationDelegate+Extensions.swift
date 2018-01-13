extension BatchEditNavigationDelegate where Self: UIViewController {
    func didSetBatchEditToolbarHidden(_ batchEditToolbar: UIToolbar, isHidden: Bool, with items: [UIBarButtonItem]) {

        if isHidden {
            batchEditToolbar.removeFromSuperview()
        } else {
            batchEditToolbar.items = items
            view.addSubview(batchEditToolbar)
        }
        
        tabBarController?.tabBar.isHidden = !isHidden
    }
    
    var frameForBatchEditToolbar: CGRect {
        let height = tabBarController?.tabBar.frame.height ?? navigationController?.navigationBar.frame.height ?? 0
        return CGRect(x: 0, y: view.bounds.height - height, width: view.bounds.width, height: height)
    }
}
