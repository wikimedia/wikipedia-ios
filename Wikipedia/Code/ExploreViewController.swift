import UIKit

@objc(WMFExploreViewController)
class ExploreViewController: UIViewController, WMFExploreCollectionViewControllerDelegate, UISearchBarDelegate, AnalyticsViewNameProviding, AnalyticsContextProviding
{
    public var collectionViewController: WMFExploreCollectionViewController!

    @IBOutlet weak var extendedNavBarView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var extendNavBarViewTopSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var searchBar: UISearchBar!
    
    private var searchBarButtonItem: WMFSearchButton?
    private var longTitleButton: UIButton?
    private var shortTitleButton: UIButton?
    
    private var isUserScrolling = false
    
    public var userStore: MWKDataStore? {
        didSet {
            guard let newValue = userStore else {
                assertionFailure("cannot set CollectionViewController.userStore to nil")
                return
            }
            collectionViewController.userStore = newValue
        }
    }
    
    public var titleButton: UIButton? {
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
        
        self.searchBarButtonItem = self.wmf_searchBarButtonItem()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .wmf_settingsBackground
        self.view.tintColor = .wmf_blue
        
        // programmatically add sub view controller
        // originally did via an embed segue but this caused the `exploreViewController` to load too late
        self.collectionViewController.willMove(toParentViewController: self)
        self.collectionViewController.view.frame = self.containerView.bounds
        self.collectionViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.containerView.addSubview(collectionViewController.view)
        self.addChildViewController(collectionViewController)
        self.collectionViewController.didMove(toParentViewController: self)

        self.navigationItem.leftBarButtonItem = settingsBarButtonItem()
        self.navigationItem.rightBarButtonItem = self.searchBarButtonItem
        
        self.wmf_addBottomShadow(view: extendedNavBarView)
        
        self.searchBar.placeholder = WMFLocalizedString("search-field-placeholder-text", value:"Search Wikipedia", comment:"Search field placeholder text")
    }

    override func viewWillAppear(_ animated: Bool) {
        self.wmf_updateNavigationBar(removeUnderline: true)
        self.updateNavigationBar()
    }
    
    private func settingsBarButtonItem() -> UIBarButtonItem {
        return UIBarButtonItem(image: #imageLiteral(resourceName: "settings"), style: .plain, target: self, action: #selector(didTapSettingsButton(_:)))
    }
    
    public func didTapSettingsButton(_ sender: UIBarButtonItem) {
        showSettings()
    }
    
    private func updateNavigationBar() {
        updateNavigationBar(newOffset: abs(extendNavBarViewTopSpaceConstraint.constant))
    }
    
    private func updateNavigationBar(newOffset extNavBarOffset: CGFloat) {
        let extNavBarHeight = extendedNavBarView.frame.size.height
        let percentHidden: CGFloat = extNavBarOffset / extNavBarHeight
        self.searchBarButtonItem?.alpha = percentHidden
        self.shortTitleButton?.alpha = percentHidden
        self.longTitleButton?.alpha = 1 - percentHidden
        self.searchBar.alpha = 1 - percentHidden
    }
    
    // MARK: - Actions
    
    public func showSettings() {
        let settingsContainer = UINavigationController(rootViewController: WMFSettingsViewController.init(dataStore: self.userStore))
        present(settingsContainer, animated: true, completion: nil)
    }
    
    public func titleBarButtonPressed() {
        self.collectionViewController.collectionView?.setContentOffset(CGPoint.zero, animated: true)
        self.showSearchBar(animated: true)
    }
    
    // MARK: - WMFExploreCollectionViewControllerDelegate
    
    func updateSearchBar(offset: CGFloat, animated: Bool)
    {
        if (animated) {
            self.view.layoutIfNeeded() // Apple recommends you call layoutIfNeeded before the animation block ensure all pending layout changes are applied
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
                self.extendNavBarViewTopSpaceConstraint.constant = -offset
                // self.searchBarButtonItem?.alpha = newAlpha
                self.updateNavigationBar(newOffset: offset)
                self.view.layoutIfNeeded() // layoutIfNeeded must be called from within the animation block
            });
        } else {
            self.extendNavBarViewTopSpaceConstraint.constant = -offset
            self.updateNavigationBar(newOffset: offset)
        }
    }
    
    public func showSearchBar(animated: Bool) {
        updateSearchBar(offset: 0, animated: animated)
    }
    
    public func hideSearchBar(animated: Bool) {
        let extNavBarHeight = extendedNavBarView.frame.size.height
        updateSearchBar(offset: extNavBarHeight, animated: animated)
    }
    
    func exploreCollectionViewController(_ collectionVC: WMFExploreCollectionViewController, willBeginScrolling scrollView: UIScrollView) {
        isUserScrolling = true
    }
    
    func exploreCollectionViewController(_ collectionVC: WMFExploreCollectionViewController, didScroll scrollView: UIScrollView) {
        //DDLogDebug("scrolled! \(scrollView.contentOffset)")
        
        guard isUserScrolling else {
            return
        }
        
        let extNavBarHeight = extendedNavBarView.frame.size.height
        let extNavBarOffset = abs(extendNavBarViewTopSpaceConstraint.constant)
        let scrollY = scrollView.contentOffset.y
        
        // no change in scrollY
        if (scrollY == 0) {
            //DDLogDebug("no change in scroll")
            return
        }

        // pulling down when nav bar is already extended
        if (extNavBarOffset == 0 && scrollY < 0) {
            //DDLogDebug("  bar already extended")
            return
        }
        
        // pulling up when navbar isn't fully collapsed
        if (extNavBarOffset == extNavBarHeight && scrollY > 0) {
            //DDLogDebug("  bar already collapsed")
            return
        }
        
        let newOffset: CGFloat
        
        // pulling down when nav bar is partially hidden
        if (scrollY <= 0) {
            newOffset = max(extNavBarOffset - abs(scrollY), 0)
            //DDLogDebug("  showing bar newOffset:\(newOffset)")

        // pulling up when navbar isn't fully collapsed
        } else {
            newOffset = min(extNavBarOffset + abs(scrollY), extNavBarHeight)
            //DDLogDebug("  hiding bar newOffset:\(newOffset)")
        }
        
        updateSearchBar(offset: newOffset, animated: false)
        
        scrollView.contentOffset = CGPoint(x: 0, y: 0)
    }
    
    func exploreCollectionViewController(_ collectionVC: WMFExploreCollectionViewController, didEndScrolling scrollView: UIScrollView) {
        
        defer {
            isUserScrolling = false
        }

        let extNavBarHeight = extendedNavBarView.frame.size.height
        let extNavBarOffset = abs(extendNavBarViewTopSpaceConstraint.constant)

        var newOffset: CGFloat?
        if (extNavBarOffset > 0 && extNavBarOffset < extNavBarHeight/2) {
            //DDLogDebug("Need to scroll down")
            newOffset = 0
        } else if (extNavBarOffset >= extNavBarHeight/2 && extNavBarOffset < extNavBarHeight) {
            //DDLogDebug("Need to scroll up")
            newOffset = extNavBarHeight
        }
        
        if (newOffset != nil) {
            updateSearchBar(offset: newOffset!, animated: true)
        } else {
            updateNavigationBar()
        }
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        self.wmf_showSearch(animated: true)
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
    
    @objc(updateFeedSourcesUserInitiated:)
    public func updateFeedSources(userInitiated wasUserInitiated: Bool) {
        self.collectionViewController.updateFeedSourcesUserInitiated(wasUserInitiated)
    }
    
    @objc(showInTheNewsForStory:date:animated:)
    public func showInTheNews(for story: WMFFeedNewsStory, date: Date?, animated: Bool)
    {
        self.collectionViewController.showInTheNews(for: story, date: date, animated: animated)
    }
    
    @objc(presentMoreViewControllerForGroup:animated:)
    public func presentMoreViewController(for group: WMFContentGroup, animated: Bool)
    {
        self.collectionViewController.presentMoreViewController(for: group, animated: animated)
    }
}
