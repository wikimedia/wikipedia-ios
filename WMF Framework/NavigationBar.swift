@objc(WMFNavigationBar)
public class NavigationBar: SetupView {
    fileprivate let statusBarUnderlay: UIView =  UIView()
    public let bar: UINavigationBar = UINavigationBar()
    public let underBarView: UIView = UIView() // this is always visible below the navigation bar
    public let extendedView: UIView = UIView()
    fileprivate let shadow: UIView = UIView()
    fileprivate let progressView: UIProgressView = UIProgressView()
    fileprivate let backgroundView: UIView = UIView()
    
    /// back button presses will be forwarded to this nav controller
    @objc public weak var delegate: UIViewController? {
        didSet {
            updateNavigationItems()
        }
    }
    
    public var isBackVisible: Bool = true {
        didSet {
            updateNavigationItems()
        }
    }
    
    fileprivate func updateNavigationItems() {
        var items: [UINavigationItem] = []
        if isBackVisible {
            items.append(UINavigationItem())
        }
        if let item = delegate?.navigationItem {
            items.append(item)
        }
        bar.setItems(items, animated: false)
    }
    
    fileprivate var underBarViewHeightConstraint: NSLayoutConstraint!
    
    fileprivate var shadowHeightConstraint: NSLayoutConstraint!
    fileprivate var extendedViewHeightConstraint: NSLayoutConstraint!

    /// Remove this when dropping iOS 10
    fileprivate var statusBarHeightConstraint: NSLayoutConstraint?
    /// Remove this when dropping iOS 10
    /// `statusBarHeight` only used on iOS 10 due to lack of safeAreaLayoutGuide
    @objc public var statusBarHeight: CGFloat = 0 {
        didSet {
            statusBarHeightConstraint?.constant = statusBarHeight
            setNeedsLayout()
        }
    }
    
    override open func setup() {
        super.setup()
        translatesAutoresizingMaskIntoConstraints = false
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        statusBarUnderlay.translatesAutoresizingMaskIntoConstraints = false
        bar.translatesAutoresizingMaskIntoConstraints = false
        underBarView.translatesAutoresizingMaskIntoConstraints = false
        extendedView.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false
        shadow.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(backgroundView)
        addSubview(shadow)
        addSubview(extendedView)
        addSubview(underBarView)
        addSubview(bar)
        addSubview(progressView)
        addSubview(statusBarUnderlay)
        
        accessibilityElements = [extendedView, underBarView, bar]

        bar.delegate = self
        
        shadowHeightConstraint = shadow.heightAnchor.constraint(equalToConstant: 0.5)
        shadowHeightConstraint.priority = .defaultHigh
        shadow.addConstraint(shadowHeightConstraint)
        
        var updatedConstraints: [NSLayoutConstraint] = []

        let statusBarUnderlayTopConstraint = topAnchor.constraint(equalTo: statusBarUnderlay.topAnchor)
        updatedConstraints.append(statusBarUnderlayTopConstraint)

        if #available(iOS 11.0, *) {
            let statusBarUnderlayBottomConstraint = safeAreaLayoutGuide.topAnchor.constraint(equalTo: statusBarUnderlay.bottomAnchor)
            updatedConstraints.append(statusBarUnderlayBottomConstraint)
        } else {
            let underlayHeightConstraint = statusBarUnderlay.heightAnchor.constraint(equalToConstant: 0)
            statusBarHeightConstraint = underlayHeightConstraint
            statusBarUnderlay.addConstraint(underlayHeightConstraint)
        }
        
        let statusBarUnderlayLeadingConstraint = leadingAnchor.constraint(equalTo: statusBarUnderlay.leadingAnchor)
        updatedConstraints.append(statusBarUnderlayLeadingConstraint)
        let statusBarUnderlayTrailingConstraint = trailingAnchor.constraint(equalTo: statusBarUnderlay.trailingAnchor)
        updatedConstraints.append(statusBarUnderlayTrailingConstraint)

        let barTopConstraint = statusBarUnderlay.bottomAnchor.constraint(equalTo: bar.topAnchor)
        let barLeadingConstraint = leadingAnchor.constraint(equalTo: bar.leadingAnchor)
        let barTrailingConstraint = trailingAnchor.constraint(equalTo: bar.trailingAnchor)
        
        underBarViewHeightConstraint = underBarView.heightAnchor.constraint(equalToConstant: 0)
        underBarView.addConstraint(underBarViewHeightConstraint)
        
        let underBarViewTopConstraint = bar.bottomAnchor.constraint(equalTo: underBarView.topAnchor)
        let underBarViewLeadingConstraint = leadingAnchor.constraint(equalTo: underBarView.leadingAnchor)
        let underBarViewTrailingConstraint = trailingAnchor.constraint(equalTo: underBarView.trailingAnchor)
        
        extendedViewHeightConstraint = extendedView.heightAnchor.constraint(equalToConstant: 0)
        extendedView.addConstraint(extendedViewHeightConstraint)
        
        let extendedViewTopConstraint = underBarView.bottomAnchor.constraint(equalTo: extendedView.topAnchor)
        let extendedViewLeadingConstraint = leadingAnchor.constraint(equalTo: extendedView.leadingAnchor)
        let extendedViewTrailingConstraint = trailingAnchor.constraint(equalTo: extendedView.trailingAnchor)
        
        let backgroundViewTopConstraint = topAnchor.constraint(equalTo: backgroundView.topAnchor)
        let backgroundViewLeadingConstraint = leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor)
        let backgroundViewTrailingConstraint = trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor)
        let backgroundViewBottomConstraint = extendedView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor)
        
        let progressViewBottomConstraint = shadow.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 1)
        let progressViewLeadingConstraint = leadingAnchor.constraint(equalTo: progressView.leadingAnchor)
        let progressViewTrailingConstraint = trailingAnchor.constraint(equalTo: progressView.trailingAnchor)
        
        let shadowTopConstraint = extendedView.bottomAnchor.constraint(equalTo: shadow.topAnchor)
        let shadowLeadingConstraint = leadingAnchor.constraint(equalTo: shadow.leadingAnchor)
        let shadowTrailingConstraint = trailingAnchor.constraint(equalTo: shadow.trailingAnchor)
        let shadowBottomConstraint = bottomAnchor.constraint(equalTo: shadow.bottomAnchor)
        
        updatedConstraints.append(contentsOf: [barTopConstraint, barLeadingConstraint, barTrailingConstraint, underBarViewTopConstraint, underBarViewLeadingConstraint, underBarViewTrailingConstraint, extendedViewTopConstraint, extendedViewLeadingConstraint, extendedViewTrailingConstraint, backgroundViewTopConstraint, backgroundViewLeadingConstraint, backgroundViewTrailingConstraint, backgroundViewBottomConstraint, progressViewBottomConstraint, progressViewLeadingConstraint, progressViewTrailingConstraint, shadowTopConstraint, shadowLeadingConstraint, shadowTrailingConstraint, shadowBottomConstraint])
        addConstraints(updatedConstraints)
        
        setNavigationBarPercentHidden(0, extendedViewPercentHidden: 0, animated: false)
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.displayScale > 0 else {
            return
        }
        shadowHeightConstraint.constant = 1.0 / traitCollection.displayScale
    }
    
    fileprivate var _navigationBarPercentHidden: CGFloat = 0
    @objc public var navigationBarPercentHidden: CGFloat {
        get {
            return _navigationBarPercentHidden
        }
        set {
            _navigationBarPercentHidden = newValue
            setNavigationBarPercentHidden(_navigationBarPercentHidden, extendedViewPercentHidden: _extendedViewPercentHidden, animated: false)
        }
    }
    
    fileprivate var _extendedViewPercentHidden: CGFloat = 0
    @objc public var extendedViewPercentHidden: CGFloat {
        get {
            return _extendedViewPercentHidden
        }
        set {
            _extendedViewPercentHidden = newValue
            setNavigationBarPercentHidden(_navigationBarPercentHidden, extendedViewPercentHidden: _extendedViewPercentHidden, animated: false)
        }
    }
    
    @objc public var visibleHeight: CGFloat = 0
    
    @objc public func setNavigationBarPercentHidden(_ navigationBarPercentHidden: CGFloat, extendedViewPercentHidden: CGFloat, animated: Bool, additionalAnimations: (() -> Void)?) {
        layoutIfNeeded()
        _navigationBarPercentHidden = navigationBarPercentHidden
        _extendedViewPercentHidden = extendedViewPercentHidden
        setNeedsLayout()
        //print("nb: \(navigationBarPercentHidden) ev: \(extendedViewPercentHidden)")
        let changes = {
            self.layoutIfNeeded()
            additionalAnimations?()
        }
        if animated {
            UIView.animate(withDuration: 0.2, animations: changes)
        } else {
            changes()
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        let navigationBarPercentHidden = _navigationBarPercentHidden
        let extendedViewPercentHidden = _extendedViewPercentHidden
        let barHeight = bar.frame.height + underBarView.frame.height
        let extendedViewHeight = extendedView.frame.height
        visibleHeight = statusBarUnderlay.frame.size.height + barHeight * (1.0 - navigationBarPercentHidden) + extendedViewHeight * (1.0 - extendedViewPercentHidden)
        let barTransformHeight = barHeight * navigationBarPercentHidden
        let underBarTransformHeight = extendedViewHeight * extendedViewPercentHidden
        let barTransform = CGAffineTransform(translationX: 0, y: 0 - barTransformHeight)
        let barScaleTransform = CGAffineTransform(scaleX: 1.0 - navigationBarPercentHidden * navigationBarPercentHidden, y: 1.0 - navigationBarPercentHidden * navigationBarPercentHidden)
        self.bar.transform = barTransform
        self.underBarView.transform = barTransform
        for subview in self.bar.subviews {
            for subview in subview.subviews {
                subview.transform = barScaleTransform
            }
        }
        self.bar.alpha = 1.0 - 2.0 * navigationBarPercentHidden
        let totalTransform = CGAffineTransform(translationX: 0, y: 0 - barTransformHeight - underBarTransformHeight)
        self.extendedView.transform = totalTransform
        self.backgroundView.transform = totalTransform
        self.extendedView.alpha = 1.0 - extendedViewPercentHidden
        self.progressView.transform = totalTransform
        self.shadow.transform = totalTransform
    }


    @objc public func setNavigationBarPercentHidden(_ navigationBarPercentHidden: CGFloat, extendedViewPercentHidden: CGFloat, animated: Bool) {
        setNavigationBarPercentHidden(navigationBarPercentHidden, extendedViewPercentHidden: extendedViewPercentHidden, animated: animated, additionalAnimations: nil)
    }
    
    @objc public func setPercentHidden(_ percentHidden: CGFloat, animated: Bool) {
        setNavigationBarPercentHidden(percentHidden, extendedViewPercentHidden: percentHidden, animated: animated)
    }
    
    @objc public func setProgressViewHidden(_ hidden: Bool, animated: Bool) {
        let changes = {
            self.progressView.alpha = hidden ? 0 : 1
        }
        if animated {
            UIView.animate(withDuration: 0.2, animations: changes)
        } else {
            changes()
        }
    }
    
    @objc public func setProgress(_ progress: Float, animated: Bool) {
        progressView.setProgress(progress, animated: animated)
    }
    
    @objc public var progress: Float {
        get {
            return progressView.progress
        }
        set {
            progressView.progress = progress
        }
    }
    
    @objc public func addExtendedNavigationBarView(_ view: UIView) {
        extendedViewHeightConstraint.isActive = false
        extendedView.wmf_addSubviewWithConstraintsToEdges(view)
    }
    
    
    @objc public func addUnderNavigationBarView(_ view: UIView) {
        underBarViewHeightConstraint.isActive = false
        underBarView.wmf_addSubviewWithConstraintsToEdges(view)
    }
    
    @objc public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return point.y <= visibleHeight
    }
}

extension NavigationBar: Themeable {
    public func apply(theme: Theme) {
        backgroundColor = .clear
        
        //statusBarUnderlay.backgroundColor = theme.colors.chromeBackground
        backgroundView.backgroundColor = theme.colors.chromeBackground
        
        bar.setBackgroundImage(theme.navigationBarBackgroundImage, for: .default)
        bar.titleTextAttributes = theme.navigationBarTitleTextAttributes
        bar.isTranslucent = false
        bar.barTintColor = theme.colors.chromeBackground
        bar.shadowImage = #imageLiteral(resourceName: "transparent-pixel")
        bar.tintColor = theme.colors.chromeText
        
        extendedView.backgroundColor = theme.colors.chromeBackground
        
        shadow.backgroundColor = theme.colors.chromeShadow
        
        progressView.progressViewStyle = .bar
        progressView.trackTintColor = .clear
        progressView.progressTintColor = theme.colors.link
    }
}

extension NavigationBar: UINavigationBarDelegate {
    public func navigationBar(_ navigationBar: UINavigationBar, shouldPop item: UINavigationItem) -> Bool {
        delegate?.navigationController?.popViewController(animated: true)
        return false
    }
}
