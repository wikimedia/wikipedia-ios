@objc public enum NavigationBarDisplayType: Int {
    case backVisible
    case largeTitle
    case centeredLargeTitle // If left, title, and right bar button items exist, center title. Otherwise, revert to `largeTitle` behavior.
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
    public var isUnderBarFadingEnabled: Bool = true
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
            isTitleShrinkingEnabled = _displayType == .largeTitle || _displayType == .centeredLargeTitle
            updateTitleBarConstraints()
            updateNavigationItems()
            updateAccessibilityElements()
        }
    }
    
    private func updateAccessibilityElements() {
        let titleElement = (displayType == .largeTitle || displayType == .centeredLargeTitle) ? titleBar : bar
        accessibilityElements = [titleElement, underBarView, extendedView]
    }
    
    @objc public func updateNavigationItems() {
        var items: [UINavigationItem] = []
        if displayType == .backVisible, let vc = delegate, let nc = vc.navigationController {
            nc.viewControllers.forEach({ items.append($0.navigationItem) })
        } else if let item = delegate?.navigationItem {
            items.append(item)
        }
        
        if (displayType == .largeTitle || displayType == .centeredLargeTitle), let navigationItem = items.last {
            configureTitleBar(with: navigationItem, centerTitle: displayType == .centeredLargeTitle)
        } else {
            bar.setItems([], animated: false)
            bar.setItems(items, animated: false)
        }
        apply(theme: theme)
    }

    private var cachedTitleViewItem: UIBarButtonItem?
    private var titleView: UIView?
    
    private func configureTitleBar(with navigationItem: UINavigationItem, centerTitle: Bool) {
        var titleBarItems: [UIBarButtonItem] = []
        titleView = nil

        var extractedTitleBarButtonItem: UIBarButtonItem?
        var extractedLeftBarButtonItem: UIBarButtonItem?
        var extractedRightBarButtonItem: UIBarButtonItem?

        if let titleView = navigationItem.titleView {
            if let cachedTitleViewItem = cachedTitleViewItem {
                extractedTitleBarButtonItem = cachedTitleViewItem
                titleBarItems.append(cachedTitleViewItem)
            } else {
                let titleItem = UIBarButtonItem(customView: titleView)
                extractedTitleBarButtonItem = titleItem
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
            extractedTitleBarButtonItem = titleItem
            titleBarItems.append(titleItem)
        }
        
        titleBarItems.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
        
        if let item = navigationItem.leftBarButtonItem {
            let leftBarButtonItem = barButtonItem(from: item)
            extractedLeftBarButtonItem = leftBarButtonItem
            titleBarItems.append(leftBarButtonItem)
        }

        if let item = navigationItem.rightBarButtonItem {
            let rightBarButtonItem = barButtonItem(from: item)
            extractedRightBarButtonItem = rightBarButtonItem
            titleBarItems.append(rightBarButtonItem)
        }

        // The default `largeTitle` behavior left aligns the title view, which isn't desirable for displaying the Notifications Center bar button in the Explore feed.
        // Center the title element with appropriate flexible space between left and right bar button items, if they exist.
        if centerTitle {
            titleBarItems = []

            if let extractedLeftBarButtonItem = extractedLeftBarButtonItem {
                titleBarItems.append(extractedLeftBarButtonItem)
                titleBarItems.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
            }

            if let extractedTitleBarButtonItem = extractedTitleBarButtonItem {
                titleBarItems.append(extractedTitleBarButtonItem)
            }

            titleBarItems.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))

            if let extractedRightBarButtonItem = extractedRightBarButtonItem {
                titleBarItems.append(extractedRightBarButtonItem)
            }
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
            if let customViewData = try? NSKeyedArchiver.archivedData(withRootObject: customView, requiringSecureCoding: false),
                let copiedView = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIView.self, from: customViewData) {
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

    private lazy var safeAreaUnderBarConstraints = [
        safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: underBarView.leadingAnchor),
        safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: underBarView.trailingAnchor)
    ]

    private lazy var fullWidthUnderBarConstraints = [
        leadingAnchor.constraint(equalTo: underBarView.leadingAnchor),
        trailingAnchor.constraint(equalTo: underBarView.trailingAnchor)
    ]
    
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

    /// See `updateHackyConstraint` for details
    public var needsUnderBarHack: Bool = false {
        didSet {
            underBarViewTopBarBottomConstraint.constant = (needsUnderBarHack ? -12 : 0)
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

        /// See `updateHackyConstraint` for explanation of the constant on the next line.
        underBarViewTopBarBottomConstraint = bar.bottomAnchor.constraint(equalTo: underBarView.topAnchor, constant: needsUnderBarHack ? -12 : 0)
        underBarViewTopTitleBarBottomConstraint = titleBar.bottomAnchor.constraint(equalTo: underBarView.topAnchor)
        underBarViewTopBottomConstraint = topAnchor.constraint(equalTo: underBarView.topAnchor)

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

        updatedConstraints.append(contentsOf: [titleBarTopConstraint, titleBarLeadingConstraint, titleBarTrailingConstraint, underBarViewTopTitleBarBottomConstraint, barTopConstraint, barLeadingConstraint, barTrailingConstraint, underBarViewTopBarBottomConstraint, underBarViewTopBottomConstraint, extendedViewTopConstraint, extendedViewLeadingConstraint, extendedViewTrailingConstraint, extendedViewBottomConstraint, backgroundViewTopConstraint, backgroundViewLeadingConstraint, backgroundViewTrailingConstraint, backgroundViewBottomConstraint, progressViewBottomConstraint, progressViewLeadingConstraint, progressViewTrailingConstraint, shadowTopUnderBarViewBottomConstraint, shadowTopExtendedViewBottomConstraint, shadowLeadingConstraint, shadowTrailingConstraint])
        updatedConstraints.append(contentsOf: safeAreaUnderBarConstraints)
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

    /// This function covers for a layout bug in iOS: When presenting a `pageSheet`, the navigation bar doesn't size appropriately. The top of the `underBarView` is appropriately pinned to the bottom of the navigation bar. The navigation bar's content view has a larger height than the actual navigation bar used in the constraint, however, and that causes the weird view: https://github.com/wikimedia/wikipedia-ios/pull/3683#issuecomment-693732339
    /// This is an issue that others experience as well: https://developer.apple.com/forums/thread/121861 , https://stackoverflow.com/questions/57784596/how-to-prevent-gap-between-uinavigationbar-and-view-in-ios-13 , and https://stackoverflow.com/questions/58296535/ios-13-new-pagesheet-formsheet-navigationbar-height .
    /// The layout bug will clear itself if you rotate the screen to landscape, then rotate it back to portrait. This allows it to also look good when the screen loads.
    /// From the links above, others have fixed this by forcing a layout pass on the navigation bar. Unfortunately that doesn't fix it in our case. (Perhaps because our nav bar is on the View Controller and not the Navigation Controller?)
    /// Hopefully some day this and `needsUnderBarHack` can be removed. To test if iOS has fixed it: Set `needsUnderBarHack` to always return `false`, open a modal w/ a presentation style of `pageSheet` and an underbar view (ex: `ArticleAsLivingDocViewController`, and ensure the top of the underbar view is not hidden behind the nav bar.
    public func updateHackyConstraint() {
        if needsUnderBarHack && underBarViewTopBarBottomConstraint.constant != 0 {
            underBarViewTopBarBottomConstraint.constant = 0
        }
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

    private var shouldUnderBarIgnoreSafeArea: Bool = false {
        didSet {
            guard shouldUnderBarIgnoreSafeArea != oldValue else {
                return
            }

            NSLayoutConstraint.deactivate(shouldUnderBarIgnoreSafeArea ? safeAreaUnderBarConstraints : fullWidthUnderBarConstraints)
            NSLayoutConstraint.activate(shouldUnderBarIgnoreSafeArea ? fullWidthUnderBarConstraints : safeAreaUnderBarConstraints)
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
        //DDLogDebug("nb: \(navigationBarPercentHidden) ev: \(extendedViewPercentHidden)")
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
        let isUsingTitleBarInsteadOfNavigationBar = (displayType == .largeTitle || displayType == .centeredLargeTitle)
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
        guard displayType == .largeTitle || displayType == .centeredLargeTitle else {
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
        return (displayType == .largeTitle || displayType == .centeredLargeTitle ? titleBar.frame.height : bar.frame.height)
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

        if isUnderBarFadingEnabled {
            self.underBarView.alpha = 1.0 - underBarViewPercentHidden
        }
        
        self.extendedView.transform = totalTransform
        
        if isExtendedViewFadingEnabled {
            self.extendedView.alpha = min(backgroundAlpha, 1.0 - extendedViewPercentHidden)
        } else {
            self.extendedView.alpha = CGFloat(1).isLessThanOrEqualTo(extendedViewPercentHidden) ? 0 : backgroundAlpha
        }
        
        self.progressView.transform = isShadowBelowUnderBarView ? underBarTransform : totalTransform
        self.shadow.transform = isShadowBelowUnderBarView ? underBarTransform : totalTransform
    
        insetTop = visibleHeight
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
    
    @objc public func addUnderNavigationBarView(_ view: UIView, shouldIgnoreSafeArea: Bool = false) {
        guard underBarView.subviews.first == nil else {
            return
        }
        underBarViewHeightConstraint.isActive = false
        shouldUnderBarIgnoreSafeArea = shouldIgnoreSafeArea
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

    public func navigationBar(_ navigationBar: UINavigationBar, didPop item: UINavigationItem) {
        /// During iOS 14's long press to access back history, this function is called *after* the unneeded navigationItems have been popped off.
        /// However, with our custom navBar the actual articleVC isn't changed. So we need to find the articleVC for the top navItem, and pop to it.
        /// This should be in `shouldPop`, but as of iOS 14.0, `shouldPop` isn't called when long pressing a back button. Once this is fixed by Apple,
        /// we should move this to `shouldPop` to improve animations. (Update: A bug tracker was filed w/ Apple, and this won't be fixed anytime soon.
        /// Apple: "This is expected behavior. Due to side effects that many clients have in the shouldPop handler, we do not consult it when using the back
        /// button menu. We instead recommend that you hide the back button when you wish to disallow popping past a particular point in the navigation stack.")
        if let topNavigationItem = navigationBar.items?.last,
           let navController = delegate?.navigationController,
           let tappedViewController = navController.viewControllers.first(where: {$0.navigationItem == topNavigationItem}) {
            delegate?.navigationController?.popToViewController(tappedViewController, animated: true)
        }
    }
}
