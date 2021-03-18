import UIKit
import WMF

class ViewController: PreviewingViewController, NavigationBarHiderDelegate {
    @objc public init(theme: Theme) {
        super.init(nibName: nil, bundle: nil)
        self.theme = theme
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // keep objc until WMFAppViewController is rewritten in Swift
    // it checks at run time for VCs that respond to navigationBar
    @objc lazy var navigationBar: NavigationBar = {
        return NavigationBar()
    }()
    
    lazy var navigationBarHider: NavigationBarHider = {
        return NavigationBarHider()
    }()

    var isProgramaticallyScrolling: Bool = false {
        didSet {
            guard let yOffset = scrollView?.contentOffset.y, let topInset = scrollView?.contentInset.top else {
                return
            }
            navigationBarHider.setIsProgramaticallyScrolling(isProgramaticallyScrolling, yOffset: yOffset, topContentInset: topInset)
        }
    }

    private var keyboardFrame: CGRect? {
        didSet {
            keyboardDidChangeFrame(from: oldValue, newKeyboardFrame: keyboardFrame)
        }
    }
    private var showsNavigationBar: Bool = false
    private var ownsNavigationBar: Bool = true
    
    public enum NavigationMode {
        case bar
        case detail
        case forceBar
    }
    
    var navigationMode: NavigationMode = .bar {
        didSet {
            switch navigationMode {
            case .forceBar:
                showsNavigationBar = true
                ownsNavigationBar = true
            case .detail:
                showsNavigationBar = false
                ownsNavigationBar = false
                hidesBottomBarWhenPushed = true
                addCloseButton()
                addScrollToTopButton()
            default:
                hidesBottomBarWhenPushed = false
                removeCloseButton()
                removeScrollToTopButton()
                break
            }
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    // MARK - Close Button
    
    @objc private func close() {
        navigationController?.popViewController(animated: true)
    }
    
    private var closeButton: UIButton?
   
    private func addCloseButton() {
        guard closeButton == nil else {
            return
        }
        let button = UIButton(type: .custom)
        button.setImage(#imageLiteral(resourceName: "close-inverse"), for: .normal)
        button.addTarget(self, action: #selector(close), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityLabel = CommonStrings.closeButtonAccessibilityLabel
        view.addSubview(button)
        let height = button.heightAnchor.constraint(greaterThanOrEqualToConstant: 50)
        let width = button.widthAnchor.constraint(greaterThanOrEqualToConstant: 32)
        button.addConstraints([height, width])
        let top = button.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 45)
        let trailing = button.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor)
        view.addConstraints([top, trailing])
        closeButton = button
        applyThemeToCloseButton()
    }
    
    private func applyThemeToCloseButton() {
        closeButton?.tintColor = theme.colors.tertiaryText
    }
    
    private func removeCloseButton() {
        guard closeButton != nil else {
            return
        }
        closeButton?.removeFromSuperview()
        closeButton = nil
    }
    
    private var scrollToTopButton: UIButton?
    
    private func addScrollToTopButton() {
        guard scrollToTopButton == nil else {
            return
        }
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(scrollToTop), for: .touchUpInside)
        view.addSubview(button)
        let top = button.topAnchor.constraint(equalTo: view.topAnchor)
        let bottom = button.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor)
        let leading = button.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        let trailing = button.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        view.addConstraints([top, bottom, leading, trailing])
        button.isAccessibilityElement = false
        scrollToTopButton = button
    }
    
    private func removeScrollToTopButton() {
        scrollToTopButton?.removeFromSuperview()
        scrollToTopButton = nil
    }
    
    override var prefersStatusBarHidden: Bool {
        guard navigationMode != .detail else {
            return true
        }
        return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.phone ? view.bounds.size.width > view.bounds.size.height : false
    }
    
    open var scrollView: UIScrollView? {
        didSet {
            updateScrollViewInsets()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 13.0, *) {
            scrollView?.automaticallyAdjustsScrollIndicatorInsets = false
        }
        scrollView?.contentInsetAdjustmentBehavior = .never
 
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIWindow.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(_:)), name: UIWindow.keyboardDidHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_ :)), name: UIWindow.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_ :)), name: UIWindow.keyboardWillShowNotification, object: nil)
    }
    
    var isFirstAppearance = true
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupGestureRecognizerDependencies()
        guard navigationMode == .bar || navigationMode == .forceBar else {
            if let closeButton = closeButton, view.accessibilityElements?.first as? UIButton !== closeButton {
                var updatedElements: [Any] = [closeButton]
                let existingElements: [Any] = view.accessibilityElements ?? view.subviews
                for element in existingElements {
                    guard element as? UIButton !== closeButton else {
                        continue
                    }
                    updatedElements.append(element)
                }
                view.accessibilityElements = updatedElements
            }
            return
        }

        /// Need to prune on every VC appearance, and must be done prior to updateNavigationItems being called.
        (navigationController as? RootNavigationController)?.pruneSearchControllers()

        if navigationMode == .forceBar {
            ownsNavigationBar = true
            showsNavigationBar = true
            navigationBar.updateNavigationItems()
        } else if let parentVC = parent as? ViewController {
            showsNavigationBar = true
            ownsNavigationBar = false
            navigationBar = parentVC.navigationBar
        }  else if let navigationController = navigationController {
            ownsNavigationBar = true
            showsNavigationBar = (parent is UITabBarController || parent == navigationController) && navigationController.isNavigationBarHidden
            navigationBar.updateNavigationItems()
        } else {
            showsNavigationBar = false
        }
    
        navigationBarHider.navigationBar = navigationBar
        navigationBarHider.delegate = self
        
        guard ownsNavigationBar else {
            return
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
            if navigationBar.shouldTransformUnderBarViewWithBar {
                navigationBar.underBarViewPercentHidden = 0
            }
        } else {
            if navigationBar.superview != nil {
                navigationBar.removeFromSuperview()
            }
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        navigationBar.updateHackyConstraint()
    }
 
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateScrollViewInsets()
    }
    
    // MARK - Scroll View Insets
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        toolbarHeightConstraint.constant = toolbarHeightForCurrentSafeAreaInsets
        updateScrollViewInsets()
    }
    
    var useNavigationBarVisibleHeightForScrollViewInsets: Bool = false
    
    //override if needed to preserve scroll view inset animation
    public var shouldAnimateWhileUpdatingScrollViewInsets: Bool {
        return false
    }
    
    public final func updateScrollViewInsets() {
        guard let scrollView = scrollView, scrollView.contentInsetAdjustmentBehavior == .never else {
            return
        }
        
        var top: CGFloat
        if showsNavigationBar {
            if useNavigationBarVisibleHeightForScrollViewInsets {
                top = navigationBar.visibleHeight
            } else {
                top = navigationBar.frame.maxY
            }
        } else if let navigationController = navigationController {
            let navBarMaxY = navigationController.view.convert(navigationController.navigationBar.frame, to: view).maxY
            top = max(navBarMaxY, view.layoutMargins.top)
        } else {
            top = view.layoutMargins.top
        }
        
        let safeInsets = view.safeAreaInsets
        
        var bottom = safeInsets.bottom
        if let keyboardFrame = keyboardFrame {
            let adjustedKeyboardFrame = view.convert(keyboardFrame, to: scrollView)
            let keyboardIntersection = adjustedKeyboardFrame.intersection(scrollView.bounds)
            bottom = max(bottom, scrollView.bounds.maxY - keyboardIntersection.minY)
        }
        
        if !isToolbarHidden {
            bottom += toolbar.frame.height
        }
        
        let scrollIndicatorInsets: UIEdgeInsets = UIEdgeInsets(top: top, left: safeInsets.left, bottom: bottom, right: safeInsets.right)
        
        if let rc = scrollView.refreshControl, rc.isRefreshing {
            top += rc.frame.height
        }
        let contentInset = UIEdgeInsets(top: top, left: scrollView.contentInset.left, bottom: bottom, right: scrollView.contentInset.right)
        if scrollView.setContentInset(contentInset, scrollIndicatorInsets: scrollIndicatorInsets, preserveContentOffset: navigationBar.isAdjustingHidingFromContentInsetChangesEnabled, preserveAnimation: shouldAnimateWhileUpdatingScrollViewInsets) {
            scrollViewInsetsDidChange()
        }
    }

    open func scrollViewInsetsDidChange() {
        if showsNavigationBar && ownsNavigationBar {
            for child in children {
                guard let vc = child as? ViewController, !vc.ownsNavigationBar else {
                    continue
                }
                vc.scrollViewInsetsDidChange()
            }
        }
    }
        
    // MARK: - Notifications
    
    @objc func keyboardWillChangeFrame(_ notification: Notification) {
        if let window = view.window, let endFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let windowFrame = window.convert(endFrame, from: nil)
            keyboardFrame = window.convert(windowFrame, to: view)
        }
    }

    open func keyboardDidChangeFrame(from oldKeyboardFrame: CGRect?, newKeyboardFrame: CGRect?) {
        updateScrollViewInsets()
    }
        
    @objc func keyboardDidHide(_ notification: Notification) {
        keyboardFrame = nil
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        //subclasses to override if needed
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        //subclasses to override if needed
    }
    
    // MARK: - Scrolling
    
    @objc func scrollToTop() {
        guard let scrollView = scrollView else {
            return
        }
        navigationBarHider.scrollViewWillScrollToTop(scrollView)
        scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: 0 - scrollView.contentInset.top), animated: true)
    }
    
    // MARK: - NavigationBar
    
    func showNavigationBar() {
        navigationBar.setNavigationBarPercentHidden(0, underBarViewPercentHidden: 0, extendedViewPercentHidden: 0, topSpacingPercentHidden: 0, animated: false)
    }
    
    // MARK: - WMFNavigationBarHiderDelegate
    
    func navigationBarHider(_ hider: NavigationBarHider, didSetNavigationBarPercentHidden: CGFloat, underBarViewPercentHidden: CGFloat, extendedViewPercentHidden: CGFloat, animated: Bool) {
        //
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.preferredStatusBarStyle
    }

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        navigationBar.apply(theme: theme)
        applyThemeToCloseButton()
        scrollView?.refreshControl?.tintColor = theme.colors.refreshControlTint
        
        toolbar.setBackgroundImage(theme.navigationBarBackgroundImage, forToolbarPosition: .any, barMetrics: .default)
        toolbar.isTranslucent = false
        
        secondToolbar.setBackgroundImage(theme.clearImage, forToolbarPosition: .any, barMetrics: .default)
        secondToolbar.setShadowImage(theme.clearImage, forToolbarPosition: .any)
    }
    
    // MARK: Toolbars
    
    static let toolbarHeight: CGFloat = 44
    static let constrainedToolbarHeight: CGFloat = 32
    static let secondToolbarSpacing: CGFloat = 8
    static let toolbarAnimationDuration: TimeInterval = 0.3
    
    var toolbarHeightForCurrentSafeAreaInsets: CGFloat {
        return view.safeAreaInsets.top == 0 ? ViewController.constrainedToolbarHeight : ViewController.toolbarHeight
    }

    lazy var toolbar: UIToolbar = {
        let tb = UIToolbar(frame: CGRect(origin: .zero, size: CGSize(width: 44, height: 44)))
        tb.translatesAutoresizingMaskIntoConstraints = false
        return tb
    }()
    
    lazy var toolbarHeightConstraint: NSLayoutConstraint = {
        return toolbar.heightAnchor.constraint(equalToConstant: toolbarHeightForCurrentSafeAreaInsets)
    }()
    
    lazy var toolbarVisibleConstraint: NSLayoutConstraint = {
        return view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: toolbar.bottomAnchor)
    }()
    
    lazy var toolbarHiddenConstraint: NSLayoutConstraint = {
        return view.bottomAnchor.constraint(equalTo: toolbar.topAnchor)
    }()
    
    lazy var secondToolbar: UIToolbar = {
        let tb = UIToolbar()
        tb.translatesAutoresizingMaskIntoConstraints = false
        return tb
    }()
    
    lazy var secondToolbarHeightConstraint: NSLayoutConstraint = {
        return secondToolbar.heightAnchor.constraint(equalToConstant: ViewController.toolbarHeight)
    }()
    
    lazy var secondToolbarVisibleConstraint: NSLayoutConstraint = {
        return toolbar.topAnchor.constraint(equalTo: secondToolbar.bottomAnchor, constant: ViewController.secondToolbarSpacing)
    }()
    
    lazy var secondToolbarHiddenConstraint: NSLayoutConstraint = {
        return secondToolbar.topAnchor.constraint(equalTo: toolbar.topAnchor)
    }()
    
    /// Setup toolbars for use
    private var isToolbarEnabled: Bool = false
    func enableToolbar() {
        guard !isToolbarEnabled else {
            return
        }
        isToolbarEnabled = true
        view.addSubview(toolbar)
        let leadingConstraint = view.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor)
        let trailingConstraint = toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        
        view.insertSubview(secondToolbar, belowSubview: toolbar)
        let secondLeadingConstraint = view.leadingAnchor.constraint(equalTo: secondToolbar.leadingAnchor)
        let secondTrailingConstraint = secondToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        
        NSLayoutConstraint.activate([toolbarHeightConstraint, secondToolbarHeightConstraint, toolbarHiddenConstraint, leadingConstraint, trailingConstraint, secondToolbarHiddenConstraint, secondLeadingConstraint, secondTrailingConstraint])
    }

    var isToolbarHidden: Bool {
        guard isToolbarEnabled else {
            return true
        }
        return toolbarHiddenConstraint.isActive
    }
    
    func setToolbarHidden(_ hidden: Bool, animated: Bool) {
        guard isToolbarEnabled else {
            assert(false, "Toolbar not enabled. Call enableToolbar before this function.")
            return
        }
        let animations = {
            if hidden {
                NSLayoutConstraint.deactivate([self.toolbarVisibleConstraint])
                NSLayoutConstraint.activate([self.toolbarHiddenConstraint])
            } else {
                NSLayoutConstraint.deactivate([self.toolbarHiddenConstraint])
                NSLayoutConstraint.activate([self.toolbarVisibleConstraint])
            }
            self.view.layoutIfNeeded()
        }
        if animated {
            UIView.animate(withDuration: ViewController.toolbarAnimationDuration, animations: animations)
        } else {
            animations()
        }
    }
    
    var isSecondToolbarHidden: Bool {
        guard isToolbarEnabled else {
            return true
        }
        return secondToolbarHiddenConstraint.isActive
    }
    
    func setSecondToolbarHidden(_ hidden: Bool, animated: Bool) {
        guard isToolbarEnabled else {
            assert(false, "Toolbars not enabled. Call enableToolbar before this function.")
            return
        }
        let animations = {
            if hidden {
                NSLayoutConstraint.deactivate([self.secondToolbarVisibleConstraint])
                NSLayoutConstraint.activate([self.secondToolbarHiddenConstraint])
            } else {
                NSLayoutConstraint.deactivate([self.secondToolbarHiddenConstraint])
                NSLayoutConstraint.activate([self.secondToolbarVisibleConstraint])
            }
            self.view.layoutIfNeeded()
        }
        if animated {
            UIView.animate(withDuration: ViewController.toolbarAnimationDuration, animations: animations)
        } else {
            animations()
        }
    }
    
    func setAdditionalSecondToolbarSpacing(_ spacing: CGFloat, animated: Bool) {
        guard isToolbarEnabled else {
            assert(false, "Toolbars not enabled. Call enableToolbar before this function.")
            return
        }
        let animations = {
            self.secondToolbarVisibleConstraint.constant = 0 - ViewController.secondToolbarSpacing - spacing
            self.view.layoutIfNeeded()
        }
        if animated {
            UIView.animate(withDuration: ViewController.toolbarAnimationDuration, animations: animations)
        } else {
            animations()
        }
    }
    
    // MARK: W button
    
    func setupWButton() {
        let wButton = UIButton(type: .custom)
        wButton.setImage(UIImage(named: "W"), for: .normal)
        wButton.sizeToFit()
        wButton.addTarget(self, action: #selector(wButtonTapped(_:)), for: .touchUpInside)
        navigationItem.titleView = wButton
    }
    
    @objc func wButtonTapped(_ sender: UIButton) {
        navigationController?.popToRootViewController(animated: true)
    }
    
    // MARK: Errors
    
    internal let alertManager: WMFAlertManager = WMFAlertManager.sharedInstance
    
    func showError(_ error: Error, sticky: Bool = false) {
        alertManager.showErrorAlert(error, sticky: sticky, dismissPreviousAlerts: false, viewController: self)
    }
    
    func showGenericError() {
        showError(RequestError.unknown)
    }
    
    // MARK: Gestures
    
    func setupGestureRecognizerDependencies() {
        // Prevent the scroll view from scrolling while interactively dismissing
        guard let popGR = navigationController?.interactivePopGestureRecognizer else {
            return
        }
        scrollView?.panGestureRecognizer.require(toFail: popGR)
    }
}

extension ViewController: WMFEmptyViewContainer {
    func addEmpty(_ emptyView: UIView) {
        if navigationBar.superview === view {
            view.insertSubview(emptyView, belowSubview: navigationBar)
        } else {
            view.addSubview(emptyView)
        }
    }
}


// Workaround for adjustedContentInset.bottom mismatch
// even when contentInsetAdjustmentBehavior == .never
// on WKWebView's scrollView when the keyboard is presented
extension UIScrollView {
    var isExperiencingContentAdjustmentMismatchBug: Bool {
        guard
            contentInsetAdjustmentBehavior == .never,
            contentInset.bottom > 0,
            contentInset.bottom != adjustedContentInset.bottom
        else {
            return false
        }
        return true
    }
    
    func fixAdjustedContentInsetMismatchBugIfNecessary() {
        guard isExperiencingContentAdjustmentMismatchBug else {
            return
        }
        var adjustedInsets = contentInset
        adjustedInsets.bottom = 0
        contentInset = adjustedInsets
    }
}

extension ViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        navigationBarHider.scrollViewDidScroll(scrollView)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        navigationBarHider.scrollViewWillBeginDragging(scrollView)
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        navigationBarHider.scrollViewWillEndDragging(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }
    
    func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
        scrollView.fixAdjustedContentInsetMismatchBugIfNecessary()
    }
    
    #if UI_TEST
    // Needed because XCUIApplication's `pressforDuration:thenDragTo:` method causes inertial scrolling if the
    // distance scrolled exceeds a certain amount. When we use `pressforDuration:thenDragTo:` to scroll an
    // element to the top of the screen this can be problematic because the extra inertia can cause the element
    // to be scrolled beyond the top of the screen.
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        scrollView.setContentOffset(scrollView.contentOffset, animated: false)
    }
    #endif
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        navigationBarHider.scrollViewDidEndDecelerating(scrollView)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        navigationBarHider.scrollViewDidEndScrollingAnimation(scrollView)

        if let scrollableArticle = self as? ArticleScrolling {
            // call the first completion
            scrollableArticle.scrollViewAnimationCompletions.popLast()?()
        }
    }

    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        navigationBarHider.scrollViewWillScrollToTop(scrollView)
        return true
    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        navigationBarHider.scrollViewDidScrollToTop(scrollView)
    }
}
