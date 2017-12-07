import UIKit

@objc(WMFExploreViewController)
class ExploreViewController: ViewController, WMFExploreCollectionViewControllerDelegate, UISearchBarDelegate, AnalyticsViewNameProviding, AnalyticsContextProviding
{
    public var collectionViewController: WMFExploreCollectionViewController!

    @IBOutlet weak var containerView: UIView!
    
    fileprivate var searchBar: UISearchBar!
    
    private var longTitleButton: UIButton?
    private var shortTitleButton: UIButton?
    
    private var isUserScrolling = false
    
    @objc public var userStore: MWKDataStore? {
        didSet {
            guard let newValue = userStore else {
                assertionFailure("cannot set CollectionViewController.userStore to nil")
                return
            }
            collectionViewController.userStore = newValue
        }
    }
    
    @objc public var titleButton: UIButton? {
        guard let button = self.navigationItem.titleView as? UIButton else {
            return nil
        }
        return button
    }
    
    required init?(coder aDecoder: NSCoder) {
         super.init(coder: aDecoder)

        // manually instiate child exploreViewController
        // originally did via an embed segue but this caused the `exploreViewController` to load too late
        let storyBoard = UIStoryboard(name: "Explore", bundle: nil)
        let vc = storyBoard.instantiateViewController(withIdentifier: "CollectionViewController")
        guard let collectionViewController = (vc as? WMFExploreCollectionViewController) else {
            assertionFailure("Could not load WMFExploreCollectionViewController")
            return nil
        }
        self.collectionViewController = collectionViewController
        self.collectionViewController.delegate = self

        let longTitleButton = UIButton(type: .custom)
        longTitleButton.adjustsImageWhenHighlighted = true
        longTitleButton.setImage(#imageLiteral(resourceName: "wikipedia"), for: UIControlState.normal)
        longTitleButton.sizeToFit()
        longTitleButton.addTarget(self, action: #selector(titleBarButtonPressed), for: UIControlEvents.touchUpInside)
        self.longTitleButton = longTitleButton
        let shortTitleButton = UIButton(type: .custom)
        shortTitleButton.adjustsImageWhenHighlighted = true
        shortTitleButton.setImage(#imageLiteral(resourceName: "W"), for: UIControlState.normal)
        shortTitleButton.sizeToFit()
        shortTitleButton.alpha = 0
        shortTitleButton.addTarget(self, action: #selector(titleBarButtonPressed), for: UIControlEvents.touchUpInside)
        self.shortTitleButton = shortTitleButton
        
        let titleView = UIView()
        titleView.frame = longTitleButton.bounds
        titleView.addSubview(longTitleButton)
        titleView.addSubview(shortTitleButton)
        shortTitleButton.center = titleView.center
        
        self.navigationItem.titleView = titleView
        self.navigationItem.isAccessibilityElement = true
        self.navigationItem.accessibilityTraits |= UIAccessibilityTraitHeader
    }
    
    override var scrollView: UIScrollView? {
        return collectionViewController.collectionView
    }
    
    override func viewDidLoad() {
        searchBar = UISearchBar()
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        navigationBar.addExtendedNavigationBarView(searchBar)
        
        // programmatically add sub view controller
        // originally did via an embed segue but this caused the `exploreViewController` to load too late
        self.addChildViewController(collectionViewController)
        self.collectionViewController.view.frame = self.containerView.bounds
        self.collectionViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.containerView.addSubview(collectionViewController.view)
        self.collectionViewController.didMove(toParentViewController: self)
        
        self.searchBar.placeholder = WMFLocalizedString("search-field-placeholder-text", value:"Search Wikipedia", comment:"Search field placeholder text")
        
        super.viewDidLoad()
    }
    
    // MARK: - Actions
    
    @objc public func titleBarButtonPressed() {
        self.showSearchBar(animated: true)
        
        guard let cv = self.collectionViewController.collectionView else {
            return
        }
        cv.setContentOffset(CGPoint(x: 0, y: -cv.contentInset.top), animated: true)
    }
    
    // MARK: - WMFExploreCollectionViewControllerDelegate
    
    public func showSearchBar(animated: Bool) {
        navigationBar.setNavigationBarPercentHidden(0, extendedViewPercentHidden: 0, animated: true)
    }
    
    func exploreCollectionViewController(_ collectionVC: WMFExploreCollectionViewController, willBeginScrolling scrollView: UIScrollView) {
        isUserScrolling = true
    }
    
    func exploreCollectionViewController(_ collectionVC: WMFExploreCollectionViewController, didScroll scrollView: UIScrollView) {
        //DDLogDebug("scrolled! \(scrollView.contentOffset)")
        
        guard isUserScrolling else {
            return
        }
        
        let extNavBarHeight = searchBar.frame.size.height
        let scrollY = scrollView.contentOffset.y + scrollView.contentInset.top
        
        let currentPercentage = navigationBar.extendedViewPercentHidden
        let updatedPercentage = min(max(0, scrollY/extNavBarHeight), 1)
        
        // no change in scrollY
        if (scrollY == 0) {
            //DDLogDebug("no change in scroll")
            return
        }

        if (currentPercentage == updatedPercentage) {
            return
        }
        
        setNavigationBarPercentHidden(navigationBar.navigationBarPercentHidden, extendedViewPercentHidden: updatedPercentage, animated: false)
    }
    
    fileprivate func setNavigationBarPercentHidden(_ navigationBarPercentHidden: CGFloat, extendedViewPercentHidden: CGFloat, animated: Bool) {
        let changes = {
            self.shortTitleButton?.alpha = extendedViewPercentHidden
            self.longTitleButton?.alpha = 1.0 - extendedViewPercentHidden
            self.navigationItem.rightBarButtonItem?.customView?.alpha = extendedViewPercentHidden
            self.navigationBar.setNavigationBarPercentHidden(navigationBarPercentHidden, extendedViewPercentHidden: extendedViewPercentHidden, animated: false)
        }
        if animated {
            UIView.animate(withDuration: 0.2, animations: changes)
        } else {
            changes()
        }
    }
    
    func exploreCollectionViewController(_ collectionVC: WMFExploreCollectionViewController, didEndScrolling scrollView: UIScrollView) {
        
        defer {
            isUserScrolling = false
        }

        let currentPercentage = navigationBar.extendedViewPercentHidden

        var newPercentage: CGFloat?
        if (currentPercentage > 0 && currentPercentage < 0.5) {
            //DDLogDebug("Need to scroll down")
            newPercentage = 0
        } else if (currentPercentage > 0.5 && currentPercentage < 1) {
            //DDLogDebug("Need to scroll up")
            newPercentage = 1
        }
        
        guard let percentage = newPercentage else {
            return
        }
        
        setNavigationBarPercentHidden(navigationBar.navigationBarPercentHidden, extendedViewPercentHidden: percentage, animated: true)
        if percentage < 1 {
            scrollView.setContentOffset(CGPoint(x: 0, y: 0 - scrollView.contentInset.top), animated: true)
        } else {
            scrollView.setContentOffset(CGPoint(x: 0, y: 0 - scrollView.contentInset.top + searchBar.frame.size.height), animated: true)
        }
    }
    
    func exploreCollectionViewController(_ collectionVC: WMFExploreCollectionViewController, shouldScrollToTop scrollView: UIScrollView) -> Bool {
        showSearchBar(animated: true)
        return true
    }
    
    func exploreCollectionViewController(_ collectionVC: WMFExploreCollectionViewController, willEndDragging scrollView: UIScrollView, velocity: CGPoint) {
        let velocity = velocity.y
        guard velocity != 0 else { // don't hide or show on 0 velocity tap
            return
        }
        let percentHidden: CGFloat = velocity > 0 ? 1 : 0
        guard percentHidden != navigationBar.navigationBarPercentHidden else {
            return
        }
        setNavigationBarPercentHidden(percentHidden, extendedViewPercentHidden: navigationBar.extendedViewPercentHidden, animated: true)
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        let searchActivity = NSUserActivity.wmf_searchView()
        NotificationCenter.default.post(name: NSNotification.Name.WMFNavigateToActivity, object: searchActivity)
        return false
    }
    
    // MARK: - Analytics
    
    public var analyticsContext: String {
        return "Explore"
    }
    
    public var analyticsName: String {
        return analyticsContext
    }
    
    // MARK: -
    
    @objc(updateFeedSourcesUserInitiated:completion:)
    public func updateFeedSources(userInitiated wasUserInitiated: Bool, completion: @escaping () -> Void) {
        self.collectionViewController.updateFeedSourcesUserInitiated(wasUserInitiated, completion: completion)
    }

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        searchBar.setSearchFieldBackgroundImage(theme.searchBarBackgroundImage, for: .normal)
        searchBar.wmf_enumerateSubviewTextFields{ (textField) in
            textField.textColor = theme.colors.primaryText
            textField.keyboardAppearance = theme.keyboardAppearance
            textField.font = UIFont.systemFont(ofSize: 14)
        }
        searchBar.searchTextPositionAdjustment = UIOffset(horizontal: 7, vertical: 0)
        view.backgroundColor = theme.colors.baseBackground
        if let cvc = collectionViewController as Themeable? {
            cvc.apply(theme: theme)
        }
    }
}
