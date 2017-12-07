import UIKit

class ViewController: UIViewController, Themeable {
    var theme: Theme = Theme.standard
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    let navigationBar: NavigationBar = NavigationBar()
    open var showsNavigationBar: Bool {
        guard let navigationController = navigationController else {
            return false
        }
        return parent == navigationController && navigationController.isNavigationBarHidden
    }
    
    open var scrollView: UIScrollView? {
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        apply(theme: theme)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard showsNavigationBar else {
            return
        }
        if navigationBar.superview == nil {
            navigationBar.delegate = self
            navigationBar.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(navigationBar)
            let navTopConstraint = view.topAnchor.constraint(equalTo: navigationBar.topAnchor)
            let navLeadingConstraint = view.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor)
            let navTrailingConstraint = view.trailingAnchor.constraint(equalTo: navigationBar.trailingAnchor)
            view.addConstraints([navTopConstraint, navLeadingConstraint, navTrailingConstraint])
            
            automaticallyAdjustsScrollViewInsets = false
            if #available(iOS 11.0, *) {
                scrollView?.contentInsetAdjustmentBehavior = .never
            }
        }
        updateNavigationBarStatusBarHeight()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard showsNavigationBar else {
            return
        }
        
        updateScrollViewInsets()
    }
    
    // MARK - Scroll View Insets
    
    fileprivate func updateNavigationBarStatusBarHeight() {
        guard showsNavigationBar else {
            return
        }
        
        if #available(iOS 11.0, *) {
        } else {
            let newHeight = navigationController?.topLayoutGuide.length ?? topLayoutGuide.length
            if newHeight != navigationBar.statusBarHeight {
                navigationBar.statusBarHeight = newHeight
                view.setNeedsLayout()
            }
        }
        
    }
    
    fileprivate func updateScrollViewInsets() {
        guard let scrollView = scrollView else {
            return
        }
        
        let frame = navigationBar.frame
        let top = frame.maxY
        var safeInsets = UIEdgeInsets.zero
        if #available(iOS 11.0, *) {
            safeInsets = view.safeAreaInsets
        }
        let bottom = bottomLayoutGuide.length
        let contentInset = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
        let scrollIndicatorInsets = UIEdgeInsets(top: top, left: safeInsets.left, bottom: bottom, right: safeInsets.right)
        guard contentInset != scrollView.contentInset || scrollIndicatorInsets != scrollView.scrollIndicatorInsets else {
            return
        }
        let wasAtTop = scrollView.contentOffset.y == 0 - scrollView.contentInset.top
        scrollView.scrollIndicatorInsets = scrollIndicatorInsets
        scrollView.contentInset = contentInset
        if wasAtTop {
            scrollView.contentOffset = CGPoint(x: 0, y: 0 - scrollView.contentInset.top)
        }
    }

    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        navigationBar.apply(theme: theme)
    }
}
