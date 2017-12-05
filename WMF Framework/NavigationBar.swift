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

fileprivate class StatusBarLayoutGuide: UILayoutGuide {
    override init() {
        super.init()
        identifier = "WMFStatusBarLayoutGuide"
        NotificationCenter.default.addObserver(self, selector: #selector(statusBarFrameChanged(with:)), name: NSNotification.Name.UIApplicationWillChangeStatusBarFrame, object: nil)
        statusBarFrame = UIApplication.shared.statusBarFrame
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate var statusBarFrame: CGRect = .zero {
        didSet {
            updateLayoutFrame()
        }
    }
    
    override var owningView: UIView? {
        didSet {
            updateLayoutFrame()
        }
    }
    
    fileprivate var _layoutFrame: CGRect = .zero
    fileprivate func updateLayoutFrame() {
        let newValue: CGRect
        if let owningView = owningView {
            newValue = owningView.convert(statusBarFrame, from: nil)
        } else {
            newValue = statusBarFrame
        }
        
        guard _layoutFrame != newValue else {
            return
        }
        
        willChangeValue(forKey: "layoutFrame")
        _layoutFrame = newValue
        didChangeValue(forKey: "layoutFrame")
    }
    
    override var layoutFrame: CGRect {
        return _layoutFrame
    }
    
    override var bottomAnchor: NSLayoutYAxisAnchor {
        return NSLayoutYAxisAnchor.anchorWithOffset(owningView?.topAnchor)
    }
    
    @objc public func statusBarFrameChanged(with notification: Notification) {
        guard let userInfo = notification.userInfo,
            let frame = userInfo[UIApplicationStatusBarFrameUserInfoKey] as? CGRect else {
                return
        }
        statusBarFrame = frame
    }
}

@objc(WMFNavigationBar)
public class NavigationBar: SetupView {
    fileprivate let statusBarUnderlay: UIView =  UIView()
    fileprivate let bar: UINavigationBar = UINavigationBar()
    fileprivate let underBarView: UIView = UIView()
    fileprivate let shadow: UIView = UIView()
    fileprivate var customConstraints: [NSLayoutConstraint] = []
    fileprivate var topLayoutGuide: UILayoutGuide! {
        didSet {
            setNeedsUpdateConstraints()
        }
    }
    
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
        
        
        if #available(iOS 11.0, *) {
            topLayoutGuide = safeAreaLayoutGuide
        } else {
            let layoutGuide = StatusBarLayoutGuide()
            addLayoutGuide(layoutGuide)
            topLayoutGuide = layoutGuide
        }
    }
    
    @objc public var navigationItem: UINavigationItem = UINavigationItem() {
        didSet {
            let back = UINavigationItem()
            bar.setItems([back, navigationItem], animated: false)
        }
    }
    
    public override func updateConstraints() {
        super.updateConstraints()
        removeConstraints(customConstraints)
        
        let topConstraint = topAnchor.constraint(equalTo: statusBarUnderlay.topAnchor)
        let bottomConstraint = topLayoutGuide.bottomAnchor.constraint(equalTo: statusBarUnderlay.bottomAnchor)
        let leadingConstraint = leadingAnchor.constraint(equalTo: statusBarUnderlay.leadingAnchor)
        let trailingConstraint = trailingAnchor.constraint(equalTo: statusBarUnderlay.trailingAnchor)
        
        let barTopConstraint = topLayoutGuide.bottomAnchor.constraint(equalTo: bar.topAnchor)
        let barLeadingConstraint = leadingAnchor.constraint(equalTo: bar.leadingAnchor)
        let barTrailingConstraint = trailingAnchor.constraint(equalTo: bar.trailingAnchor)
        
        let underBarTopConstraint = bar.bottomAnchor.constraint(equalTo: underBarView.topAnchor)
        let underBarLeadingConstraint = leadingAnchor.constraint(equalTo: underBarView.leadingAnchor)
        let underBarTrailingConstraint = trailingAnchor.constraint(equalTo: underBarView.trailingAnchor)
        
        let shadowTopConstraint = underBarView.bottomAnchor.constraint(equalTo: shadow.topAnchor)
        let shadowLeadingConstraint = leadingAnchor.constraint(equalTo: shadow.leadingAnchor)
        let shadowTrailingConstraint = trailingAnchor.constraint(equalTo: shadow.trailingAnchor)
        let shadowBottomConstraint = bottomAnchor.constraint(equalTo: shadow.bottomAnchor)
    
        customConstraints = [topConstraint, bottomConstraint, leadingConstraint, trailingConstraint, barTopConstraint, barLeadingConstraint, barTrailingConstraint, underBarTopConstraint, underBarLeadingConstraint, underBarTrailingConstraint, shadowTopConstraint, shadowLeadingConstraint, shadowTrailingConstraint, shadowBottomConstraint]
        addConstraints(customConstraints)
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
