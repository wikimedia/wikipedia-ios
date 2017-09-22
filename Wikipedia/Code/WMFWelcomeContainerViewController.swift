
class WMFWelcomeContainerViewController: UIViewController {
    
    @IBOutlet fileprivate var topForegroundContainerView:UIView!
    @IBOutlet fileprivate var topBackgroundContainerView:UIView!
    @IBOutlet fileprivate var bottomContainerView:UIView!

    @IBOutlet fileprivate var overallContainerView:UIView!
    @IBOutlet fileprivate var overallContainerViewCenterYConstraint:NSLayoutConstraint!
    @IBOutlet fileprivate var topForegroundContainerViewHeightConstraint:NSLayoutConstraint!
    @IBOutlet fileprivate var topForegroundContainerViewWidthConstraint:NSLayoutConstraint!
    @IBOutlet fileprivate var topBackgroundContainerViewHeightConstraint:NSLayoutConstraint!
    @IBOutlet fileprivate var topBackgroundContainerViewLeadingConstraint:NSLayoutConstraint!
    @IBOutlet fileprivate var topBackgroundContainerViewTrailingConstraint:NSLayoutConstraint!

    var welcomePageType:WMFWelcomePageType = .intro
    weak var welcomeNavigationDelegate:WMFWelcomeNavigationDelegate? = nil
    
    fileprivate var hasAlreadyFadedInAndUp = false
    
    fileprivate var needsDeviceAdjustments = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        topForegroundContainerView.backgroundColor = .clear
        topForegroundContainerView.isUserInteractionEnabled = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if (shouldFadeInAndUp() && !hasAlreadyFadedInAndUp) {
            view.wmf_zeroLayerOpacity()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if (shouldFadeInAndUp() && !hasAlreadyFadedInAndUp) {
            view.wmf_fadeInAndUpWithDuration(0.4, delay: 0.1)
            hasAlreadyFadedInAndUp = true
        }
    }
    
    fileprivate func shouldFadeInAndUp() -> Bool {
        switch welcomePageType {
        case .intro:
            return false
        case .exploration:
            return true
        case .languages:
            return true
        case .analytics:
            return true
        }
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()
        if needsDeviceAdjustments {
            reduceTopAnimationsSizesIfDeviceIsiPhone5()
            useBottomAlignmentIfPhone()
            hideAndCollapseTopContainerViewIfDeviceIsiPhone4s()
            needsDeviceAdjustments = false
        }
    }
    
    fileprivate func reduceTopAnimationsSizesIfDeviceIsiPhone5() {
        if view.frame.size.height == 568 {
            let reduction: CGFloat = 50
            topBackgroundContainerViewHeightConstraint.constant = topBackgroundContainerViewHeightConstraint.constant - reduction
            topBackgroundContainerViewLeadingConstraint.constant = reduction
            topBackgroundContainerViewTrailingConstraint.constant = reduction
            topForegroundContainerViewHeightConstraint.constant = topForegroundContainerViewHeightConstraint.constant - reduction
            topForegroundContainerViewWidthConstraint.constant = topForegroundContainerViewWidthConstraint.constant - reduction
        }
    }
    
    fileprivate func hideAndCollapseTopContainerViewIfDeviceIsiPhone4s() {
        if view.frame.size.height == 480 {
            topForegroundContainerView.alpha = 0
            topForegroundContainerViewHeightConstraint.constant = 0
            topBackgroundContainerView.alpha = 0
            topBackgroundContainerViewHeightConstraint.constant = 0
        }
    }
    
    fileprivate func useBottomAlignmentIfPhone() {
        assert(Int(overallContainerViewCenterYConstraint.priority.rawValue) == 999, "The Y centering constraint must not have required '1000' priority because on non-tablets we add a required bottom alignment constraint on overallContainerView which we want to be favored when present.")
        if (UI_USER_INTERFACE_IDIOM() == .phone) {
            overallContainerView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor, constant: 0).isActive = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.destination.isKind(of: WMFWelcomePanelViewController.self)){
            let vc = segue.destination as? WMFWelcomePanelViewController
            vc!.welcomePageType = welcomePageType
        }
        if(segue.destination.isKind(of: WMFWelcomeAnimationViewController.self)){
            let vc = segue.destination as? WMFWelcomeAnimationViewController
            vc!.welcomePageType = welcomePageType
        }
    }
    
    @IBAction fileprivate func next(withSender sender: AnyObject) {
        welcomeNavigationDelegate?.showNextWelcomePage(self)
    }
}
