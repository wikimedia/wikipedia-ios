@objc public enum NavigationBarDisplayType: Int {
    case backVisible
    case largeTitle
    case modal
    case hidden
}

@objc(WMFNavigationBar)
public class NavigationBar: SetupView, FakeProgressReceiving, FakeProgressDelegate {
    fileprivate let statusBarUnderlay: UIView =  UIView()
    fileprivate let titleBar: UIToolbar = UIToolbar()
    fileprivate let bar: UINavigationBar = UINavigationBar()
    fileprivate let underBarView: UIView = UIView() // this is always visible below the navigation bar
    fileprivate let extendedView: UIView = UIView()
    fileprivate let shadow: UIView = UIView()
    fileprivate let progressView: UIProgressView = UIProgressView()
    fileprivate let backgroundView: UIView = UIView()
    public var underBarViewPercentHiddenForShowingTitle: CGFloat?
    public var title: String?

    convenience public init() {
        self.init(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        assert(frame.size != .zero, "Non-zero frame size required to prevent iOS 13 constraint breakage")
        titleBar.frame = bounds
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var isAdjustingHidingFromContentInsetChangesEnabled: Bool = true
    
    public var isShadowHidingEnabled: Bool = false // turn on/off shadow alpha adjusment
    public var isTitleShrinkingEnabled: Bool = false
    public var isInteractiveHidingEnabled: Bool = true // turn on/off any interactive adjustment of bar or view visibility
    @objc public var isShadowBelowUnderBarView: Bool = false {
        didSet {
            updateShadowConstraints()
        }
    }
    public var isShadowShowing: Bool = true {
        didSet {
            updateShadowHeightConstraintConstant()
        }
    }
    
    @objc public var isTopSpacingHidingEnabled: Bool = true
    @objc public var isBarHidingEnabled: Bool = true
    @objc public var isUnderBarViewHidingEnabled: Bool = false
    @objc public var isExtendedViewHidingEnabled: Bool = false
    @objc public var isExtendedViewFadingEnabled: Bool = true // fade out extended view as it hides
    public var shouldTransformUnderBarViewWithBar: Bool = false // hide/show underbar view when bar is hidden/shown // TODO: change this stupid name
    public var allowsUnderbarHitsFallThrough: Bool = false //if true, this only considers underBarView's subviews for hitTest, not self. Use if you need underlying view controller's scroll view to capture scrolling.
    public var allowsExtendedHitsFallThrough: Bool = false //if true, this only considers extendedView's subviews for hitTest, not self. Use if you need underlying view controller's scroll view to capture scrolling.
    
    private var theme = Theme.standard

    public var shadowColorKeyPath: KeyPath<Theme, UIColor> = \Theme.colors.chromeShadow
    
    /// back button presses will be forwarded to this nav controller
    @objc public weak var delegate: UIViewController? {
        didSet {
            updateNavigationItems()
        }
    }
    
    private var _displayType: NavigationBarDisplayType = .backVisible
    @objc public var displayType: NavigationBarDisplayType {
        get {
            return _displayType
        }
        set {
            guard newValue != _displayType else {
                return
            }
            _displayType = newValue
            isTitleShrinkingEnabled = _displayType == .largeTitle
            updateTitleBarConstraints()
            updateNavigationItems()
            updateAccessibilityElements()
        }
    }
    
    private func updateAccessibilityElements() {
        let titleElement = displayType == .largeTitle ? titleBar : bar
        accessibilityElements = [titleElement, underBarView, extendedView]
    }
    
    @objc public func updateNavigationItems() {
        var items: [UINavigationItem] = []
        if displayType == .backVisible {
            
            if let vc = delegate, let nc = vc.navigationController {
                
                var indexToAppend: Int = 0
                if let index = nc.viewControllers.firstIndex(of: vc), index > 0 {
                    indexToAppend = index
                } else if let parentVC = vc.parent,
                    let index = nc.viewControllers.firstIndex(of: parentVC),
                    index > 0 {
                    indexToAppend = index
                }
                
                if indexToAppend > 0 {
                    items.append(nc.viewControllers[indexToAppend].navigationItem)
                }
            }
        }
        
        if let item = delegate?.navigationItem {
            items.append(item)
        }
        
        if displayType == .largeTitle, let navigationItem = items.last {
            configureTitleBar(with: navigationItem)
        } else {
            bar.setItems([], animated: false)
            bar.setItems(items, animated: false)
        }
        apply(theme: theme)
    }

    private var cachedTitleViewItem: UIBarButtonItem?
    private var titleView: UIView?
    
    private func configureTitleBar(with navigationItem: UINavigationItem) {
        var titleBarItems: [UIBarButtonItem] = []
        titleView = nil
        if let titleView = navigationItem.titleView {
            if let cachedTitleViewItem = cachedTitleViewItem {
                titleBarItems.append(cachedTitleViewItem)
            } else {
                let titleItem = UIBarButtonItem(customView: titleView)
                titleBarItems.append(titleItem)
                cachedTitleViewItem = titleItem
            }
        } else if let title = navigationItem.title {
            let navigationTitleLabel = UILabel()
            navigationTitleLabel.text = title
            navigationTitleLabel.sizeToFit()
            navigationTitleLabel.font = UIFont.wmf_font(.boldTitle1)
            titleView = navigationTitleLabel
            let titleItem = UIBarButtonItem(customView: navigationTitleLabel)
            titleBarItems.append(titleItem)
        }
        
        titleBarItems.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
        
        if let item = navigationItem.leftBarButtonItem {
            let leftBarButtonItem = barButtonItem(from: item)
            titleBarItems.append(leftBarButtonItem)
        }
        
        if let item = navigationItem.rightBarButtonItem {
            let rightBarButtonItem = barButtonItem(from: item)
            titleBarItems.append(rightBarButtonItem)
        }
        titleBar.setItems(titleBarItems, animated: false)
    }
    
    // HAX: barButtonItem that we're getting from the navigationItem will not be shown on iOS 11 so we need to recreate it
    private func barButtonItem(from item: UIBarButtonItem) -> UIBarButtonItem {
        let barButtonItem: UIBarButtonItem
        if let title = item.title {
            barButtonItem = UIBarButtonItem(title: title, style: item.style, target: item.target, action: item.action)
        } else if let systemBarButton = item as? SystemBarButton, let systemItem = systemBarButton.systemItem {
            barButtonItem = SystemBarButton(with: systemItem, target: systemBarButton.target, action: systemBarButton.action)
        } else if let customView = item.customView {
            let customViewData = NSKeyedArchiver.archivedData(withRootObject: customView)
            if let copiedView = NSKeyedUnarchiver.unarchiveObject(with: customViewData) as? UIView {
                if let button = customView as? UIButton, let copiedButton = copiedView as? UIButton {
                    for target in button.allTargets {
                        guard let actions = button.actions(forTarget: target, forControlEvent: .touchUpInside) else {
                            continue
                        }
                        for action in actions {
                            copiedButton.addTarget(target, action: Selector(action), for: .touchUpInside)
                        }
                    }
                }
                barButtonItem = UIBarButtonItem(customView: copiedView)
            } else {
                assert(false, "unable to copy custom view")
                barButtonItem = item
            }
        } else if let image = item.image {
            barButtonItem = UIBarButtonItem(image: image, landscapeImagePhone: item.landscapeImagePhone, style: item.style, target: item.target, action: item.action)
        } else {
            assert(false, "barButtonItem must have title OR be of type SystemBarButton OR have image OR have custom view")
            barButtonItem = item
        }
        barButtonItem.isEnabled = item.isEnabled
        barButtonItem.isAccessibilityElement = item.isAccessibilityElement
        barButtonItem.accessibilityLabel = item.accessibilityLabel
        return barButtonItem
    }
    
    private var titleBarHeightConstraint: NSLayoutConstraint!
    
    private var underBarViewHeightConstraint: NSLayoutConstraint!
    
    private var shadowTopUnderBarViewBottomConstraint: NSLayoutConstraint!
    private var shadowTopExtendedViewBottomConstraint: NSLayoutConstraint!

    private var shadowHeightConstraint: NSLayoutConstraint!
    private var extendedViewHeightConstraint: NSLayoutConstraint!
    
    private var titleBarTopConstraint: NSLayoutConstraint!
    private var barTopConstraint: NSLayoutConstraint!
    public var barTopSpacing: CGFloat = 0 {
        didSet {
            titleBarTopConstraint.constant = barTopSpacing
            barTopConstraint.constant = barTopSpacing
            setNeedsLayout()
        }
    }
    
    var underBarViewTopBarBottomConstraint: NSLayoutConstraint!
    var underBarViewTopTitleBarBottomConstraint: NSLayoutConstraint!
    var underBarViewTopBottomConstraint: NSLayoutConstraint!
    
    override open func setup() {
        super.setup()
        translatesAutoresizingMaskIntoConstraints = false
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        statusBarUnderlay.translatesAutoresizingMaskIntoConstraints = false
        bar.translatesAutoresizingMaskIntoConstraints = false
        underBarView.translatesAutoresizingMaskIntoConstraints = false
        extendedView.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.alpha = 0
        shadow.translatesAutoresizingMaskIntoConstraints = false
        titleBar.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(backgroundView)
        addSubview(extendedView)
        addSubview(underBarView)
        addSubview(bar)
        addSubview(titleBar)
        addSubview(progressView)
        addSubview(statusBarUnderlay)
        addSubview(shadow)

        updateAccessibilityElements()
        
        bar.delegate = self
        
        shadowHeightConstraint = shadow.heightAnchor.constraint(equalToConstant: 0.5)
        shadowHeightConstraint.priority = .defaultHigh
        shadow.addConstraint(shadowHeightConstraint)
        
        var updatedConstraints: [NSLayoutConstraint] = []
        
        let statusBarUnderlayTopConstraint = topAnchor.constraint(equalTo: statusBarUnderlay.topAnchor)
        updatedConstraints.append(statusBarUnderlayTopConstraint)
        
        let statusBarUnderlayBottomConstraint = safeAreaLayoutGuide.topAnchor.constraint(equalTo: statusBarUnderlay.bottomAnchor)
        updatedConstraints.append(statusBarUnderlayBottomConstraint)
        
        let statusBarUnderlayLeadingConstraint = leadingAnchor.constraint(equalTo: statusBarUnderlay.leadingAnchor)
        updatedConstraints.append(statusBarUnderlayLeadingConstraint)
        let statusBarUnderlayTrailingConstraint = trailingAnchor.constraint(equalTo: statusBarUnderlay.trailingAnchor)
        updatedConstraints.append(statusBarUnderlayTrailingConstraint)
        
        titleBarHeightConstraint = titleBar.heightAnchor.constraint(equalToConstant: 44)
        titleBarHeightConstraint.priority = UILayoutPriority(rawValue: 999)
        titleBar.addConstraint(titleBarHeightConstraint)
        
        titleBarTopConstraint = titleBar.topAnchor.constraint(equalTo: statusBarUnderlay.bottomAnchor, constant: barTopSpacing)
        let titleBarLeadingConstraint = leadingAnchor.constraint(equalTo: titleBar.leadingAnchor)
        let titleBarTrailingConstraint = trailingAnchor.constraint(equalTo: titleBar.trailingAnchor)
        
        barTopConstraint = bar.topAnchor.constraint(equalTo: statusBarUnderlay.bottomAnchor, constant: barTopSpacing)
        let barLeadingConstraint = leadingAnchor.constraint(equalTo: bar.leadingAnchor)
        let barTrailingConstraint = trailingAnchor.constraint(equalTo: bar.trailingAnchor)
        
        underBarViewHeightConstraint = underBarView.heightAnchor.constraint(equalToConstant: 0)
        underBarView.addConstraint(underBarViewHeightConstraint)
        
        underBarViewTopBarBottomConstraint = bar.bottomAnchor.constraint(equalTo: underBarView.topAnchor)
        underBarViewTopTitleBarBottomConstraint = titleBar.bottomAnchor.constraint(equalTo: underBarView.topAnchor)
        underBarViewTopBottomConstraint = topAnchor.constraint(equalTo: underBarView.topAnchor)
        
        let underBarViewLeadingConstraint = leadingAnchor.constraint(equalTo: underBarView.leadingAnchor)
        let underBarViewTrailingConstraint = trailingAnchor.constraint(equalTo: underBarView.trailingAnchor)
        
        extendedViewHeightConstraint = extendedView.heightAnchor.constraint(equalToConstant: 0)
        extendedView.addConstraint(extendedViewHeightConstraint)
        
        let extendedViewTopConstraint = underBarView.bottomAnchor.constraint(equalTo: extendedView.topAnchor)
        let extendedViewLeadingConstraint = leadingAnchor.constraint(equalTo: extendedView.leadingAnchor)
        let extendedViewTrailingConstraint = trailingAnchor.constraint(equalTo: extendedView.trailingAnchor)
        let extendedViewBottomConstraint = extendedView.bottomAnchor.constraint(equalTo: bottomAnchor)
        
        let backgroundViewTopConstraint = topAnchor.constraint(equalTo: backgroundView.topAnchor)
        let backgroundViewLeadingConstraint = leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor)
        let backgroundViewTrailingConstraint = trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor)
        let backgroundViewBottomConstraint = extendedView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor)
        
        let progressViewBottomConstraint = shadow.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 1)
        let progressViewLeadingConstraint = leadingAnchor.constraint(equalTo: progressView.leadingAnchor)
        let progressViewTrailingConstraint = trailingAnchor.constraint(equalTo: progressView.trailingAnchor)
        
        let shadowLeadingConstraint = leadingAnchor.constraint(equalTo: shadow.leadingAnchor)
        let shadowTrailingConstraint = trailingAnchor.constraint(equalTo: shadow.trailingAnchor)
        
        shadowTopExtendedViewBottomConstraint = extendedView.bottomAnchor.constraint(equalTo: shadow.topAnchor)
        shadowTopUnderBarViewBottomConstraint = underBarView.bottomAnchor.constraint(equalTo: shadow.topAnchor)

        updatedConstraints.append(contentsOf: [titleBarTopConstraint, titleBarLeadingConstraint, titleBarTrailingConstraint, underBarViewTopTitleBarBottomConstraint, barTopConstraint, barLeadingConstraint, barTrailingConstraint, underBarViewTopBarBottomConstraint, underBarViewTopBottomConstraint, underBarViewLeadingConstraint, underBarViewTrailingConstraint, extendedViewTopConstraint, extendedViewLeadingConstraint, extendedViewTrailingConstraint, extendedViewBottomConstraint, backgroundViewTopConstraint, backgroundViewLeadingConstraint, backgroundViewTrailingConstraint, backgroundViewBottomConstraint, progressViewBottomConstraint, progressViewLeadingConstraint, progressViewTrailingConstraint, shadowTopUnderBarViewBottomConstraint, shadowTopExtendedViewBottomConstraint, shadowLeadingConstraint, shadowTrailingConstraint])
        addConstraints(updatedConstraints)
        
        updateTitleBarConstraints()
        updateShadowConstraints()
        updateShadowHeightConstraintConstant()
        
        setNavigationBarPercentHidden(0, underBarViewPercentHidden: 0, extendedViewPercentHidden: 0, topSpacingPercentHidden: 0, animated: false)
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateShadowHeightConstraintConstant()
    }

    private func updateShadowHeightConstraintConstant() {
        guard traitCollection.displayScale > 0 else {
            return
        }
        
        if !isShadowShowing {
            shadowHeightConstraint.constant = 0
        } else {
            shadowHeightConstraint.constant = 1.0 / traitCollection.displayScale
        }
    }
    
    
    fileprivate var _topSpacingPercentHidden: CGFloat = 0
    @objc public var topSpacingPercentHidden: CGFloat {
        get {
            return _topSpacingPercentHidden
        }
        set {
            setNavigationBarPercentHidden(_navigationBarPercentHidden, underBarViewPercentHidden: _underBarViewPercentHidden, extendedViewPercentHidden: _extendedViewPercentHidden, topSpacingPercentHidden: newValue, animated: false)
        }
    }
    
    fileprivate var _navigationBarPercentHidden: CGFloat = 0
    @objc public var navigationBarPercentHidden: CGFloat {
        get {
            return _navigationBarPercentHidden
        }
        set {
            setNavigationBarPercentHidden(newValue, underBarViewPercentHidden: _underBarViewPercentHidden, extendedViewPercentHidden: _extendedViewPercentHidden, topSpacingPercentHidden: _topSpacingPercentHidden, animated: false)
        }
    }
    
    private var _underBarViewPercentHidden: CGFloat = 0
    @objc public var underBarViewPercentHidden: CGFloat {
        get {
            return _underBarViewPercentHidden
        }
        set {
            setNavigationBarPercentHidden(_navigationBarPercentHidden, underBarViewPercentHidden: newValue, extendedViewPercentHidden: _extendedViewPercentHidden, topSpacingPercentHidden: _topSpacingPercentHidden, animated: false)
        }
    }
    
    fileprivate var _extendedViewPercentHidden: CGFloat = 0
    @objc public var extendedViewPercentHidden: CGFloat {
        get {
            return _extendedViewPercentHidden
        }
        set {
            setNavigationBarPercentHidden(_navigationBarPercentHidden, underBarViewPercentHidden: _underBarViewPercentHidden, extendedViewPercentHidden: newValue, topSpacingPercentHidden: _topSpacingPercentHidden, animated: false)
        }
    }
    
    @objc dynamic public var visibleHeight: CGFloat = 0
    @objc dynamic public var insetTop: CGFloat = 0
    @objc public var hiddenHeight: CGFloat = 0

    public var shadowAlpha: CGFloat {
        get {
            return shadow.alpha
        }
        set {
            shadow.alpha = newValue
        }
    }
    
    @objc public func setNavigationBarPercentHidden(_ navigationBarPercentHidden: CGFloat, underBarViewPercentHidden: CGFloat, extendedViewPercentHidden: CGFloat, topSpacingPercentHidden: CGFloat, shadowAlpha: CGFloat = -1, animated: Bool, additionalAnimations: (() -> Void)? = nil) {
        if (animated) {
            layoutIfNeeded()
        }

        if isTopSpacingHidingEnabled {
            _topSpacingPercentHidden = topSpacingPercentHidden
        }

        if isBarHidingEnabled {
            _navigationBarPercentHidden = navigationBarPercentHidden
        }
        
        if isUnderBarViewHidingEnabled {
            _underBarViewPercentHidden = underBarViewPercentHidden
        }
        
        if isExtendedViewHidingEnabled {
            _extendedViewPercentHidden = extendedViewPercentHidden
        }
        
        setNeedsLayout()
        //print("nb: \(navigationBarPercentHidden) ev: \(extendedViewPercentHidden)")
        let applyChanges = {
            let changes = {
                if shadowAlpha >= 0  {
                    self.shadowAlpha = shadowAlpha
                }
                if (animated) {
                    self.layoutIfNeeded()
                }
                additionalAnimations?()
            }
            if animated {
                UIView.animate(withDuration: 0.2, animations: changes)
            } else {
                changes()
            }
        }
        
        if let underBarViewPercentHiddenForShowingTitle = self.underBarViewPercentHiddenForShowingTitle {
            UIView.animate(withDuration: 0.2, animations: {
                self.delegate?.title = underBarViewPercentHidden >= underBarViewPercentHiddenForShowingTitle ? self.title : nil
            }, completion: { (_) in
                applyChanges()
            })
        } else {
            applyChanges()
        }
    }
    
    private func updateTitleBarConstraints() {
        let isUsingTitleBarInsteadOfNavigationBar = displayType == .largeTitle
        underBarViewTopTitleBarBottomConstraint.isActive = isUsingTitleBarInsteadOfNavigationBar
        underBarViewTopBarBottomConstraint.isActive = !isUsingTitleBarInsteadOfNavigationBar && displayType != .hidden
        underBarViewTopBottomConstraint.isActive = displayType == .hidden
        bar.isHidden = isUsingTitleBarInsteadOfNavigationBar || displayType == .hidden
        titleBar.isHidden = !isUsingTitleBarInsteadOfNavigationBar || displayType == .hidden
        updateBarTopSpacing()
        setNeedsUpdateConstraints()
    }
    
    public override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        updateBarTopSpacing()
    }
    
    // collapse bar top spacing if there's no status bar
    private func updateBarTopSpacing() {
        guard displayType == .largeTitle else {
            barTopSpacing = 0
            return
        }
        let isSafeAreaInsetsTopGreaterThanZero = safeAreaInsets.top > 0
        barTopSpacing = isSafeAreaInsetsTopGreaterThanZero ? 30 : 0
        titleBarHeightConstraint.constant = isSafeAreaInsetsTopGreaterThanZero ? 44 : 32 // it doesn't seem like there's a way to force update of bar metrics - as it stands the bar height gets stuck in whatever mode the app was launched in
    }
    
    private func updateShadowConstraints() {
        shadowTopUnderBarViewBottomConstraint.isActive = isShadowBelowUnderBarView
        shadowTopExtendedViewBottomConstraint.isActive = !isShadowBelowUnderBarView
        setNeedsUpdateConstraints()
    }
    
    var barHeight: CGFloat {
        return (displayType == .largeTitle ? titleBar.frame.height : bar.frame.height)
    }
    
    var underBarViewHeight: CGFloat {
        return underBarView.frame.size.height
    }
    
    var extendedViewHeight: CGFloat {
        return extendedView.frame.size.height
    }

    var topSpacingHideableHeight: CGFloat {
        return isTopSpacingHidingEnabled ? barTopSpacing : 0
    }
    
    var barHideableHeight: CGFloat {
        return isBarHidingEnabled ? barHeight : 0
    }
    
    var underBarViewHideableHeight: CGFloat {
        return isUnderBarViewHidingEnabled ? underBarViewHeight : 0
    }
    
    var extendedViewHideableHeight: CGFloat {
        return isExtendedViewHidingEnabled ? extendedViewHeight : 0
    }
    
    var hideableHeight: CGFloat {
        return topSpacingHideableHeight + barHideableHeight + underBarViewHideableHeight + extendedViewHideableHeight
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        let navigationBarPercentHidden = _navigationBarPercentHidden
        let extendedViewPercentHidden = _extendedViewPercentHidden
        let underBarViewPercentHidden = _underBarViewPercentHidden
        let topSpacingPercentHidden = safeAreaInsets.top > 0 ? _topSpacingPercentHidden : 1 // treat top spacing as hidden if there's no status bar so that the title is smaller
        
        let underBarViewHeight = underBarView.frame.height
        let barHeight = self.barHeight
        let extendedViewHeight = extendedView.frame.height
        
        visibleHeight = statusBarUnderlay.frame.size.height + barHeight * (1.0 - navigationBarPercentHidden) + extendedViewHeight * (1.0 - extendedViewPercentHidden) + underBarViewHeight * (1.0 - underBarViewPercentHidden) + (barTopSpacing * (1.0 - topSpacingPercentHidden))
        
        let spacingTransformHeight = barTopSpacing * topSpacingPercentHidden
        let barTransformHeight = barHeight * navigationBarPercentHidden + spacingTransformHeight
        let extendedViewTransformHeight = extendedViewHeight * extendedViewPercentHidden
        let underBarTransformHeight = underBarViewHeight * underBarViewPercentHidden
        
        hiddenHeight = barTransformHeight + extendedViewTransformHeight + underBarTransformHeight

        let barTransform = CGAffineTransform(translationX: 0, y: 0 - barTransformHeight)
        let barScaleTransform = CGAffineTransform(scaleX: 1.0 - navigationBarPercentHidden * navigationBarPercentHidden, y: 1.0 - navigationBarPercentHidden * navigationBarPercentHidden)
        
        self.bar.transform = barTransform
        self.titleBar.transform = barTransform
        
        if isTitleShrinkingEnabled {
            let titleScale: CGFloat = 1.0 - 0.2 * topSpacingPercentHidden
            self.titleView?.transform = CGAffineTransform(scaleX: titleScale, y: titleScale)
        }
        
        for subview in self.bar.subviews {
            for subview in subview.subviews {
                subview.transform = barScaleTransform
            }
        }
        self.bar.alpha = min(backgroundAlpha, (1.0 - 2.0 * navigationBarPercentHidden).wmf_normalizedPercentage)
        self.titleBar.alpha = self.bar.alpha
        
        let totalTransform = CGAffineTransform(translationX: 0, y: 0 - hiddenHeight)
        self.backgroundView.transform = totalTransform
        
        let underBarTransform = CGAffineTransform(translationX: 0, y: 0 - barTransformHeight - underBarTransformHeight)
        self.underBarView.transform = underBarTransform
        self.underBarView.alpha = 1.0 - underBarViewPercentHidden
        
        self.extendedView.transform = totalTransform
        
        if isExtendedViewFadingEnabled {
            self.extendedView.alpha = min(backgroundAlpha, 1.0 - extendedViewPercentHidden)
        } else {
            self.extendedView.alpha = CGFloat(1).isLessThanOrEqualTo(extendedViewPercentHidden) ? 0 : backgroundAlpha
        }
        
        self.progressView.transform = isShadowBelowUnderBarView ? underBarTransform : totalTransform
        self.shadow.transform = isShadowBelowUnderBarView ? underBarTransform : totalTransform
    
        // HAX: something odd going on with iOS 11...
        insetTop = backgroundView.frame.origin.y
        if #available(iOS 12, *) {
            insetTop = visibleHeight
        }
    }
    
    
    @objc public func setProgressHidden(_ hidden: Bool, animated: Bool) {
        let changes = {
            self.progressView.alpha = min(hidden ? 0 : 1, self.backgroundAlpha)
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
            progressView.progress = newValue
        }
    }
    
    @objc public func addExtendedNavigationBarView(_ view: UIView) {
        guard extendedView.subviews.first == nil else {
            return
        }
        extendedViewHeightConstraint.isActive = false
        extendedView.wmf_addSubviewWithConstraintsToEdges(view)
    }
    
    @objc public func removeExtendedNavigationBarView() {
        guard let subview = extendedView.subviews.first else {
            return
        }
        subview.removeFromSuperview()
        extendedViewHeightConstraint.isActive = true
    }
    
    @objc public func addUnderNavigationBarView(_ view: UIView) {
        guard underBarView.subviews.first == nil else {
            return
        }
        underBarViewHeightConstraint.isActive = false
        underBarView.wmf_addSubviewWithConstraintsToEdges(view)
    }
    
    @objc public func removeUnderNavigationBarView() {
        guard let subview = underBarView.subviews.first else {
            return
        }
        subview.removeFromSuperview()
        underBarViewHeightConstraint.isActive = true
    }
    
    @objc public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        
        if allowsUnderbarHitsFallThrough
            && underBarView.frame.contains(point)
            && !bar.frame.contains(point) {
            
            for subview in underBarView.subviews {
                let convertedPoint = self.convert(point, to: subview)
                if subview.point(inside: convertedPoint, with: event) {
                    return true
                }
            }
            
            return false
        }
        
        if allowsExtendedHitsFallThrough
            && extendedView.frame.contains(point)
            && !bar.frame.contains(point) {
            
            for subview in extendedView.subviews {
                let convertedPoint = self.convert(point, to: subview)
                if subview.point(inside: convertedPoint, with: event) {
                    return true
                }
            }
            
            return false
        }
        
        return point.y <= visibleHeight
    }
    
    public var backgroundAlpha: CGFloat = 1 {
        didSet {
            statusBarUnderlay.alpha = backgroundAlpha
            backgroundView.alpha = backgroundAlpha
            bar.alpha = backgroundAlpha
            titleBar.alpha = backgroundAlpha
            extendedView.alpha = backgroundAlpha
            if backgroundAlpha < progressView.alpha {
                progressView.alpha = backgroundAlpha
            }
        }
    }
}

extension NavigationBar: Themeable {
    public func apply(theme: Theme) {
        self.theme = theme
        
        backgroundColor = .clear
        
        statusBarUnderlay.backgroundColor = theme.colors.paperBackground
        backgroundView.backgroundColor = theme.colors.paperBackground
        
        titleBar.setBackgroundImage(theme.navigationBarBackgroundImage, forToolbarPosition: .any, barMetrics: .default)
        titleBar.isTranslucent = false
        titleBar.tintColor = theme.colors.chromeText
        titleBar.setShadowImage(theme.navigationBarShadowImage, forToolbarPosition: .any)
        titleBar.barTintColor = theme.colors.chromeBackground
        if let items = titleBar.items {
            for item in items {
                if let label = item.customView as? UILabel {
                    label.textColor = theme.colors.chromeText
                } else if item.image == nil {
                    item.tintColor = theme.colors.link
                }
            }
        }
        
        bar.setBackgroundImage(theme.navigationBarBackgroundImage, for: .default)
        bar.titleTextAttributes = theme.navigationBarTitleTextAttributes
        bar.isTranslucent = false
        bar.barTintColor = theme.colors.chromeBackground
        bar.shadowImage = theme.navigationBarShadowImage
        bar.tintColor = theme.colors.chromeText
        
        extendedView.backgroundColor = .clear
        underBarView.backgroundColor = .clear
        
        shadow.backgroundColor = theme[keyPath: shadowColorKeyPath]
        
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
