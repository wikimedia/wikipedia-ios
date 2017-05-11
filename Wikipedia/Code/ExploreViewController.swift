import UIKit

@objc(WMFExploreViewController)
class ExploreViewController: UIViewController, WMFExploreCollectionViewControllerDelegate {
    
    public var collectionViewController: WMFExploreCollectionViewController!
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

    @IBOutlet weak var extendedNavBarView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var extendNavBarViewTopSpaceConstraint: NSLayoutConstraint!
    
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

        let b = UIButton(type: .custom)
        b.adjustsImageWhenHighlighted = true
        b.setImage(#imageLiteral(resourceName: "wikipedia"), for: UIControlState.normal)
        b.sizeToFit()
        b.addTarget(self, action: #selector(titleBarButtonPressed), for: UIControlEvents.touchUpInside)
        self.navigationItem.titleView = b
        self.navigationItem.isAccessibilityElement = true
        self.navigationItem.accessibilityTraits |= UIAccessibilityTraitHeader
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // programmatically add sub view controller
        // originally did via an embed segue but this caused the `exploreViewController` to load too late
        self.collectionViewController.willMove(toParentViewController: self)
        self.containerView.addSubview(collectionViewController.view)
        self.addChildViewController(collectionViewController)
        self.collectionViewController.didMove(toParentViewController: self)

        self.navigationItem.titleView = UIImageView(image: #imageLiteral(resourceName: "wikipedia"))
        self.navigationItem.leftBarButtonItem = settingsBarButtonItem()
        //self.navigationItem.rightBarButtonItem = self.wmf_searchBarButtonItem()
        
        self.wmf_addBottomShadow(view: extendedNavBarView)
    }

    override func viewWillAppear(_ animated: Bool) {
        self.wmf_updateNavigationBar(removeUnderline: true)
    }
    
    private func settingsBarButtonItem() -> UIBarButtonItem {
        return UIBarButtonItem(image: #imageLiteral(resourceName: "settings"), style: .plain, target: self, action: #selector(didTapSettingsButton(_:)))
    }
    
    public func didTapSettingsButton(_ sender: UIBarButtonItem) {
        showSettings()
    }
    
    // MARK: - Actions
    
    public func showSettings() {
        let settingsContainer = UINavigationController(rootViewController: WMFSettingsViewController.init(dataStore: self.userStore))
        present(settingsContainer, animated: true, completion: nil)
    }
    
    public func titleBarButtonPressed() {
        self.collectionViewController.collectionView?.setContentOffset(CGPoint.zero, animated: true)
    }
    
    // MARK: - WMFExploreCollectionViewControllerDelegate

    func exploreCollectionViewDidScroll(_ scrollView: UIScrollView) {
        DDLogDebug("scrolled! \(scrollView.contentOffset)")
        
        guard self.view != nil else {
            // view not loaded yet
            return
        }
        
        let h = extendedNavBarView.frame.size.height
        let offset = abs(extendNavBarViewTopSpaceConstraint.constant)
        let scrollY = scrollView.contentOffset.y
        
        // no change in scrollY
        if (scrollY == 0) {
            DDLogDebug("no change in scroll")
            return
        }

        // pulling down when nav bar is already extended
        if (offset == 0 && scrollY < 0) {
            DDLogDebug("  bar already extended")
            return
        }
        
        // pulling up when navbar isn't fully collapsed
        if (offset == h && scrollY > 0) {
            DDLogDebug("  bar already collapsed")
            return
        }
        
        let newOffset: CGFloat
        
        // pulling down when nav bar is partially hidden
        if (scrollY < 0) {
            newOffset = max(offset - abs(scrollY), 0)
            DDLogDebug("  showing bar newOffset:\(newOffset)")

        // pulling up when navbar isn't fully collapsed
        } else {
            newOffset = min(offset + abs(scrollY), h)
            DDLogDebug("  hiding bar newOffset:\(newOffset)")
        }

        extendNavBarViewTopSpaceConstraint.constant = -newOffset
        
        if (newOffset == h) {
            self.navigationItem.rightBarButtonItem = self.wmf_searchBarButtonItem()
        } else if (newOffset == 0) {
            self.navigationItem.rightBarButtonItem = nil
        }
        
        scrollView.contentOffset = CGPoint(x: 0, y: 0)
    }
    
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
