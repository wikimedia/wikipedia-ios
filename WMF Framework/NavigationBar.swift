/// This is a placeholder - the actual class is implemented in the Reading Lists branch
/// Delete this class when merging Reading Lists
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
    public let bar: UINavigationBar = UINavigationBar()
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
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        statusBarUnderlay.translatesAutoresizingMaskIntoConstraints = false
        bar.translatesAutoresizingMaskIntoConstraints = false
        extendedView.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false
        shadow.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(backgroundView)
        addSubview(shadow)
        addSubview(extendedView)
        addSubview(bar)
        addSubview(progressView)
        addSubview(statusBarUnderlay)

        bar.delegate = self
        
        shadowHeightConstraint = shadow.heightAnchor.constraint(equalToConstant: 0.5)
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
        
        extendedViewHeightConstraint = extendedView.heightAnchor.constraint(equalToConstant: 0)
        extendedView.addConstraint(extendedViewHeightConstraint)
        
        let extendedViewTopConstraint = bar.bottomAnchor.constraint(equalTo: extendedView.topAnchor)
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
        
        updatedConstraints.append(contentsOf: [barTopConstraint, barLeadingConstraint, barTrailingConstraint, extendedViewTopConstraint, extendedViewLeadingConstraint, extendedViewTrailingConstraint, backgroundViewTopConstraint, backgroundViewLeadingConstraint, backgroundViewTrailingConstraint, backgroundViewBottomConstraint, progressViewBottomConstraint, progressViewLeadingConstraint, progressViewTrailingConstraint, shadowTopConstraint, shadowLeadingConstraint, shadowTrailingConstraint, shadowBottomConstraint])
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
    var navigationBarPercentHidden: CGFloat {
        get {
            return _navigationBarPercentHidden
        }
        set {
            _navigationBarPercentHidden = newValue
            setNavigationBarPercentHidden(_navigationBarPercentHidden, extendedViewPercentHidden: _extendedViewPercentHidden, animated: false)
        }
    }
    
    fileprivate var _extendedViewPercentHidden: CGFloat = 0
    var extendedViewPercentHidden: CGFloat {
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
        _navigationBarPercentHidden = navigationBarPercentHidden
        _extendedViewPercentHidden = extendedViewPercentHidden
        let barHeight = bar.frame.height
        let extendedViewHeight = extendedView.frame.height
        visibleHeight = statusBarUnderlay.frame.size.height + barHeight * (1.0 - navigationBarPercentHidden) + extendedViewHeight * (1.0 - extendedViewPercentHidden)
        print("nb: \(navigationBarPercentHidden) ev: \(extendedViewPercentHidden)")
        let changes = {
            let barTransformHeight = barHeight * navigationBarPercentHidden
            let underBarTransformHeight = extendedViewHeight * extendedViewPercentHidden
            let barTransform = CGAffineTransform(translationX: 0, y: 0 - barTransformHeight)
            let barScaleTransform = CGAffineTransform(scaleX: 1.0 - navigationBarPercentHidden * navigationBarPercentHidden, y: 1.0 - navigationBarPercentHidden * navigationBarPercentHidden)
            self.bar.transform = barTransform
            
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
            additionalAnimations?()
        }
        if animated {
            UIView.animate(withDuration: 0.2, animations: changes)
        } else {
            changes()
        }
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
