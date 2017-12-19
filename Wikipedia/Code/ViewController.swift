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
    open var showsNavigationBar: Bool = false
    
    open var scrollView: UIScrollView? {
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        apply(theme: theme)
        automaticallyAdjustsScrollViewInsets = false
        if #available(iOS 11.0, *) {
            scrollView?.contentInsetAdjustmentBehavior = .never
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let navigationController = navigationController {
            showsNavigationBar = parent == navigationController && navigationController.isNavigationBarHidden
        } else {
            showsNavigationBar = false
        }

        if showsNavigationBar {
            if navigationBar.superview == nil {
                navigationBar.delegate = self
                navigationBar.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(navigationBar)
                let navTopConstraint = view.topAnchor.constraint(equalTo: navigationBar.topAnchor)
                let navLeadingConstraint = view.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor)
                let navTrailingConstraint = view.trailingAnchor.constraint(equalTo: navigationBar.trailingAnchor)
                view.addConstraints([navTopConstraint, navLeadingConstraint, navTrailingConstraint])
            }
            navigationBar.navigationBarPercentHidden = 0
            updateNavigationBarStatusBarHeight()
        } else {
            if navigationBar.superview != nil {
                navigationBar.removeFromSuperview()
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
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
    
    override func viewSafeAreaInsetsDidChange() {
        if #available(iOS 11.0, *) {
            super.viewSafeAreaInsetsDidChange()
        }
        self.updateScrollViewInsets()
    }
    
    fileprivate func updateScrollViewInsets() {
        guard let scrollView = scrollView else {
            return
        }
        
        var frame = CGRect.zero
        if showsNavigationBar {
            frame = navigationBar.frame
        } else if let navigationController = navigationController {
            frame = navigationController.view.convert(navigationController.navigationBar.frame, to: view)
        }

        var top = frame.maxY
        var safeInsets = UIEdgeInsets.zero
        if #available(iOS 11.0, *) {
            safeInsets = view.safeAreaInsets
        } else {
            safeInsets = UIEdgeInsets(top: topLayoutGuide.length, left: 0, bottom: min(44, bottomLayoutGuide.length), right: 0) // MIN 44 is a workaround for an iOS 10 only issue where the bottom layout guide is too tall when pushing from explore
        }
        
        let bottom = safeInsets.bottom
        let scrollIndicatorInsets = UIEdgeInsets(top: top, left: safeInsets.left, bottom: bottom, right: safeInsets.right)
        if let rc = scrollView.refreshControl, rc.isRefreshing {
            top += rc.frame.height
        }
        let contentInset = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
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
