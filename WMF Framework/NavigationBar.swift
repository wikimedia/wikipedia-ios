import WMF

public class SetupView: UIView {
    // MARK - Initializers
    // Don't override these initializers, use setup() instead
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    open func setup() {
        
    }
}

@objc(WMFNavigationBar)
public class NavigationBar: SetupView {
    fileprivate let statusBarUnderlay: UIView =  UIView()
    fileprivate let bar: UINavigationBar = UINavigationBar()
    fileprivate let underBarView: UIView = UIView()
    fileprivate let shadow: UIView = UIView()
    
    /// status bar height constraint only used on iOS 10 due to lack of safeAreaLayoutGuide
    fileprivate var statusBarHeightConstraint: NSLayoutConstraint?
    
    override open func setup() {
        super.setup()
        statusBarUnderlay.translatesAutoresizingMaskIntoConstraints = false
        bar.translatesAutoresizingMaskIntoConstraints = false
        underBarView.translatesAutoresizingMaskIntoConstraints = false
        shadow.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(statusBarUnderlay)
        addSubview(bar)
        addSubview(underBarView)
        addSubview(shadow)
        
        bar.delegate = self
        
        let shadowHeightConstraint = shadow.heightAnchor.constraint(equalToConstant: 0.5)
        shadow.addConstraint(shadowHeightConstraint)
        
    
        let statusBarUnderlayTopConstraint = topAnchor.constraint(equalTo: statusBarUnderlay.topAnchor)
        addConstraint(statusBarUnderlayTopConstraint)

        if #available(iOS 11.0, *) {
            let statusBarUnderlayBottomConstraint = safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: statusBarUnderlay.bottomAnchor)
            addConstraint(statusBarUnderlayBottomConstraint)
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(statusBarFrameChanged(with:)), name: NSNotification.Name.UIApplicationWillChangeStatusBarFrame, object: nil)
            let underlayHeightConstraint = statusBarUnderlay.heightAnchor.constraint(equalToConstant: 0)
            statusBarHeightConstraint = underlayHeightConstraint
            updateStatusBarHeightConstraint(with: UIApplication.shared.statusBarFrame)
            statusBarUnderlay.addConstraint(underlayHeightConstraint)
        }
        let statusBarUnderlayLeadingConstraint = leadingAnchor.constraint(equalTo: statusBarUnderlay.leadingAnchor)
        addConstraint(statusBarUnderlayLeadingConstraint)
        let statusBarUnderlayTrailingConstraint = trailingAnchor.constraint(equalTo: statusBarUnderlay.trailingAnchor)
        addConstraint(statusBarUnderlayTrailingConstraint)

        let barTopConstraint = statusBarUnderlay.bottomAnchor.constraint(equalTo: bar.topAnchor)
        let barLeadingConstraint = leadingAnchor.constraint(equalTo: bar.leadingAnchor)
        let barTrailingConstraint = trailingAnchor.constraint(equalTo: bar.trailingAnchor)
        
        let underBarTopConstraint = bar.bottomAnchor.constraint(equalTo: underBarView.topAnchor)
        let underBarLeadingConstraint = leadingAnchor.constraint(equalTo: underBarView.leadingAnchor)
        let underBarTrailingConstraint = trailingAnchor.constraint(equalTo: underBarView.trailingAnchor)
        
        let shadowTopConstraint = underBarView.bottomAnchor.constraint(equalTo: shadow.topAnchor)
        let shadowLeadingConstraint = leadingAnchor.constraint(equalTo: shadow.leadingAnchor)
        let shadowTrailingConstraint = trailingAnchor.constraint(equalTo: shadow.trailingAnchor)
        let shadowBottomConstraint = bottomAnchor.constraint(equalTo: shadow.bottomAnchor)
        
        addConstraints([barTopConstraint, barLeadingConstraint, barTrailingConstraint, underBarTopConstraint, underBarLeadingConstraint, underBarTrailingConstraint, shadowTopConstraint, shadowLeadingConstraint, shadowTrailingConstraint, shadowBottomConstraint])
    }
    
    @objc public func statusBarFrameChanged(with notification: Notification) {
        guard let userInfo = notification.userInfo,
            let frame = userInfo[UIApplicationStatusBarFrameUserInfoKey] as? CGRect else {
                return
        }
        updateStatusBarHeightConstraint(with: frame)
    }
    
    fileprivate func updateStatusBarHeightConstraint(with statusBarFrame: CGRect) {
        let adjustedFrame = convert(statusBarFrame, from: nil)
        statusBarHeightConstraint?.constant = adjustedFrame.maxY
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc public var navigationItem: UINavigationItem = UINavigationItem() {
        didSet {
            let back = UINavigationItem()
            bar.setItems([back, navigationItem], animated: false)
        }
    }
}

extension NavigationBar: Themeable {
    public func apply(theme: Theme) {
        backgroundColor = .clear
        
        statusBarUnderlay.backgroundColor = theme.colors.chromeBackground

        bar.setBackgroundImage(theme.navigationBarBackgroundImage, for: .default)
        bar.titleTextAttributes = theme.navigationBarTitleTextAttributes
        bar.isTranslucent = false
        bar.barTintColor = theme.colors.chromeBackground
        bar.shadowImage = #imageLiteral(resourceName: "transparent-pixel")
        bar.tintColor = theme.colors.chromeText
        
        underBarView.backgroundColor = theme.colors.chromeBackground
        
        shadow.backgroundColor = theme.colors.shadow
    }
}

extension NavigationBar: UINavigationBarDelegate {
    public func navigationBar(_ navigationBar: UINavigationBar, shouldPop item: UINavigationItem) -> Bool {
        return false
    }
}
