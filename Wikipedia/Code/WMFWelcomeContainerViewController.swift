
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
    @IBOutlet fileprivate var bottomContainerViewTopConstraint:NSLayoutConstraint!
    
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
            let height = view.bounds.size.height
            if height <= 480 {
                // Just hide animations on iPhone 4s
                hideAndCollapseTopContainerView()
            } else if height <= 568 {
                // On iPhone 5 reduce size of animations.
                reduceTopAnimationsSizes(reduction: 30)
            } else {
                // On everything else add vertical separation between bottom container and animations.
                bottomContainerViewTopConstraint.constant = 20
            }
            useBottomAlignmentIfPhone()
            needsDeviceAdjustments = false
        }
    }
    
    fileprivate func reduceTopAnimationsSizes(reduction: CGFloat) {
        topBackgroundContainerViewHeightConstraint.constant = topBackgroundContainerViewHeightConstraint.constant - reduction
        topBackgroundContainerViewLeadingConstraint.constant = reduction
        topBackgroundContainerViewTrailingConstraint.constant = reduction
        topForegroundContainerViewHeightConstraint.constant = topForegroundContainerViewHeightConstraint.constant - reduction
        topForegroundContainerViewWidthConstraint.constant = topForegroundContainerViewWidthConstraint.constant - reduction
    }
    
    fileprivate func hideAndCollapseTopContainerView() {
        topForegroundContainerView.alpha = 0
        topForegroundContainerViewHeightConstraint.constant = 0
        topBackgroundContainerView.alpha = 0
        topBackgroundContainerViewHeightConstraint.constant = 0
    }
    
    fileprivate func useBottomAlignmentIfPhone() {
        assert(Int(overallContainerViewCenterYConstraint.priority.rawValue) == 999, "The Y centering constraint must not have required '1000' priority because on non-tablets we add a required bottom alignment constraint on overallContainerView which we want to be favored when present.")
        if (UI_USER_INTERFACE_IDIOM() == .phone) {
            overallContainerView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor, constant: 0).isActive = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? WMFWelcomePanelViewController {
            vc.welcomePageType = welcomePageType
        } else if let vc = segue.destination as? WMFWelcomeAnimationViewController{
            vc.welcomePageType = welcomePageType
        }
    }
    
    @IBAction fileprivate func next(withSender sender: AnyObject) {
        welcomeNavigationDelegate?.showNextWelcomePage(self)
    }
}
