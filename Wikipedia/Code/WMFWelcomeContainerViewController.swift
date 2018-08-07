
class WMFWelcomeContainerViewController: UIViewController {
    
    @IBOutlet fileprivate var topContainerView:UIView!
    @IBOutlet fileprivate var bottomContainerView:UIView!
    @IBOutlet fileprivate var overallContainerStackView:UIStackView!
    @IBOutlet fileprivate var overallContainerStackViewCenterYConstraint:NSLayoutConstraint!
    @IBOutlet fileprivate var topContainerViewHeightConstraint:NSLayoutConstraint!
    @IBOutlet fileprivate var bottomContainerViewHeightConstraint:NSLayoutConstraint!

    var welcomePageType:WMFWelcomePageType = .intro
    weak var welcomeNavigationDelegate:WMFWelcomeNavigationDelegate? = nil
    
    fileprivate var hasAlreadyFadedInAndUp = false
    fileprivate var needsDeviceAdjustments = true
    
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
                bottomContainerViewHeightConstraint.constant = 367
                overallContainerStackView.spacing = 10
            } else {
                // On everything else add vertical separation between bottom container and animations.
                overallContainerStackView.spacing = 20
            }
            useBottomAlignmentIfPhone()
            needsDeviceAdjustments = false
        }
    }
    
    fileprivate func reduceTopAnimationsSizes(reduction: CGFloat) {
        topContainerViewHeightConstraint.constant = topContainerViewHeightConstraint.constant - reduction
    }
    
    fileprivate func hideAndCollapseTopContainerView() {
        topContainerView.isHidden = true
    }
    
    fileprivate func useBottomAlignmentIfPhone() {
        assert(Int(overallContainerStackViewCenterYConstraint.priority.rawValue) == 999, "The Y centering constraint must not have required '1000' priority because on non-tablets we add a required bottom alignment constraint on overallContainerView which we want to be favored when present.")
        if (UI_USER_INTERFACE_IDIOM() == .phone) {
            overallContainerStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true
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
