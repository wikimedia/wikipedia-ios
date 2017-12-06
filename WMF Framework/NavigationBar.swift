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
    fileprivate let extendedView: UIView = UIView()
    fileprivate let shadow: UIView = UIView()
    fileprivate let progressView: UIProgressView = UIProgressView()
    
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

    /// Remove this when dropping iOS 10
    fileprivate var statusBarHeightConstraint: NSLayoutConstraint?
    /// Remove this when dropping iOS 10
    /// `statusBarHeight` only used on iOS 10 due to lack of safeAreaLayoutGuide
    @objc public var statusBarHeight: CGFloat = 0 {
        didSet {
            statusBarHeightConstraint?.constant = statusBarHeight
        }
    }
    
    override open func setup() {
        super.setup()
        statusBarUnderlay.translatesAutoresizingMaskIntoConstraints = false
        bar.translatesAutoresizingMaskIntoConstraints = false
        extendedView.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false
        shadow.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(shadow)
        addSubview(extendedView)
        addSubview(bar)
        addSubview(progressView)
        addSubview(statusBarUnderlay)

        bar.delegate = self
        
        shadowHeightConstraint = shadow.heightAnchor.constraint(equalToConstant: 0.5)
        shadow.addConstraint(shadowHeightConstraint)
        
        let statusBarUnderlayTopConstraint = topAnchor.constraint(equalTo: statusBarUnderlay.topAnchor)
        addConstraint(statusBarUnderlayTopConstraint)

        if #available(iOS 11.0, *) {
            let statusBarUnderlayBottomConstraint = safeAreaLayoutGuide.topAnchor.constraint(equalTo: statusBarUnderlay.bottomAnchor)
            addConstraint(statusBarUnderlayBottomConstraint)
        } else {
            let underlayHeightConstraint = statusBarUnderlay.heightAnchor.constraint(equalToConstant: 0)
            statusBarHeightConstraint = underlayHeightConstraint
            statusBarUnderlay.addConstraint(underlayHeightConstraint)
        }
        
        let statusBarUnderlayLeadingConstraint = leadingAnchor.constraint(equalTo: statusBarUnderlay.leadingAnchor)
        addConstraint(statusBarUnderlayLeadingConstraint)
        let statusBarUnderlayTrailingConstraint = trailingAnchor.constraint(equalTo: statusBarUnderlay.trailingAnchor)
        addConstraint(statusBarUnderlayTrailingConstraint)

        let barTopConstraint = statusBarUnderlay.bottomAnchor.constraint(equalTo: bar.topAnchor)
        let barLeadingConstraint = leadingAnchor.constraint(equalTo: bar.leadingAnchor)
        let barTrailingConstraint = trailingAnchor.constraint(equalTo: bar.trailingAnchor)
        
        let underBarTopConstraint = bar.bottomAnchor.constraint(equalTo: extendedView.topAnchor)
        let underBarLeadingConstraint = leadingAnchor.constraint(equalTo: extendedView.leadingAnchor)
        let underBarTrailingConstraint = trailingAnchor.constraint(equalTo: extendedView.trailingAnchor)
        
        let progressViewBottomConstraint = shadow.topAnchor.constraint(equalTo: progressView.bottomAnchor)
        let progressViewLeadingConstraint = leadingAnchor.constraint(equalTo: progressView.leadingAnchor)
        let progressViewTrailingConstraint = trailingAnchor.constraint(equalTo: progressView.trailingAnchor)
        
        let shadowTopConstraint = extendedView.bottomAnchor.constraint(equalTo: shadow.topAnchor)
        let shadowLeadingConstraint = leadingAnchor.constraint(equalTo: shadow.leadingAnchor)
        let shadowTrailingConstraint = trailingAnchor.constraint(equalTo: shadow.trailingAnchor)
        let shadowBottomConstraint = bottomAnchor.constraint(equalTo: shadow.bottomAnchor)
        
        addConstraints([barTopConstraint, barLeadingConstraint, barTrailingConstraint, underBarTopConstraint, underBarLeadingConstraint, underBarTrailingConstraint, progressViewBottomConstraint, progressViewLeadingConstraint, progressViewTrailingConstraint, shadowTopConstraint, shadowLeadingConstraint, shadowTrailingConstraint, shadowBottomConstraint])
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
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

    @objc public func setNavigationBarPercentHidden(_ navigationBarPercentHidden: CGFloat, extendedViewPercentHidden: CGFloat, animated: Bool) {
        _navigationBarPercentHidden = navigationBarPercentHidden
        _extendedViewPercentHidden = extendedViewPercentHidden
        let changes = {
            let barTransformHeight = self.bar.frame.height * navigationBarPercentHidden
            let underBarTransformHeight = self.extendedView.frame.height * extendedViewPercentHidden
            let barTransform = CGAffineTransform(translationX: 0, y: 0 - barTransformHeight)
            self.bar.transform = barTransform
            let totalTransform = CGAffineTransform(translationX: 0, y: 0 - barTransformHeight - underBarTransformHeight)
            self.extendedView.transform = totalTransform
            self.extendedView.subviews.first?.alpha = 1.0 - extendedViewPercentHidden
            self.progressView.transform = totalTransform
            self.shadow.transform = totalTransform
        }
        if animated {
            UIView.animate(withDuration: 0.2, animations: changes)
        } else {
            changes()
        }
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
    
    public func addExtendedNavigationBarView(_ view: UIView) {
        extendedView.wmf_addSubviewWithConstraintsToEdges(view)
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
        
        extendedView.backgroundColor = theme.colors.chromeBackground
        
        shadow.backgroundColor = theme.colors.shadow
        
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
