
class WMFWelcomeContainerViewController: UIViewController {
    
    @IBOutlet private var topContainerView:UIView!
    @IBOutlet private var bottomContainerView:UIView!

    @IBOutlet private var overallContainerView:UIView!
    @IBOutlet private var overallContainerViewCenterYConstraint:NSLayoutConstraint!
    @IBOutlet private var topContainerViewHeightConstraint:NSLayoutConstraint!
    
    var welcomePageType:WMFWelcomePageType = .intro
    private var animationVC:WMFWelcomeAnimationViewController? = nil

    weak var welcomeNavigationDelegate:WMFWelcomeNavigationDelegate? = nil
    
    private var hasAlreadyFadedInAndUp = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        embedBottomContainerControllerView()
        useBottomAlignmentIfPhone()
        hideAndCollapseTopContainerViewIfDeviceIsiPhone4s()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if (shouldFadeInAndUp() && !hasAlreadyFadedInAndUp) {
            view.wmf_zeroLayerOpacity()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if (shouldFadeInAndUp() && !hasAlreadyFadedInAndUp) {
            view.wmf_fadeInAndUpWithDuration(0.4, delay: 0.1)
            hasAlreadyFadedInAndUp = true
        }
    }
    
    private func shouldFadeInAndUp() -> Bool {
        switch welcomePageType {
        case .intro:
            return false
        case .languages:
            return true
        case .analytics:
            return true
        }
    }

    private func hideAndCollapseTopContainerViewIfDeviceIsiPhone4s() {
        if view.frame.size.height == 480 {
            topContainerView.alpha = 0
            topContainerViewHeightConstraint.constant = 0
        }
    }
    
    private func useBottomAlignmentIfPhone() {
        assert(overallContainerViewCenterYConstraint.priority == 999, "The Y centering constraint must not have required '1000' priority because on non-tablets we add a required bottom alignment constraint on overallContainerView which we want to be favored when present.")
        if (UI_USER_INTERFACE_IDIOM() == .Phone) {
            overallContainerView.mas_makeConstraints { make in
                make.bottom.equalTo()(self.mas_bottomLayoutGuideTop)
            }
        }
    }
    
    private func embedBottomContainerControllerView() {
        bottomContainerController.willMoveToParentViewController(self)
        bottomContainerView.addSubview((bottomContainerController.view)!)
        bottomContainerController.view.mas_makeConstraints { make in
            make.top.bottom().leading().and().trailing().equalTo()(self.bottomContainerView)
        }
        self.addChildViewController(bottomContainerController)
        bottomContainerController.didMoveToParentViewController(self)
    }

    private lazy var bottomContainerController: UIViewController = {
        switch self.welcomePageType {
        case .intro:
            return WMFWelcomeIntroductionViewController.wmf_viewControllerFromWelcomeStoryboard()
        case .languages:
            let langPanelVC = WMFWelcomePanelViewController.wmf_viewControllerFromWelcomeStoryboard()
            langPanelVC.welcomePageType = .languages
            return langPanelVC;
        case .analytics:
            let analyticsPanelVC = WMFWelcomePanelViewController.wmf_viewControllerFromWelcomeStoryboard()
            analyticsPanelVC.welcomePageType = .analytics
            return analyticsPanelVC;
        }
    }()
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.destinationViewController.isKindOfClass(WMFWelcomeAnimationViewController)){
            animationVC = segue.destinationViewController as? WMFWelcomeAnimationViewController
            animationVC!.welcomePageType = welcomePageType
        }
    }
    
    @IBAction private func next(withSender sender: AnyObject) {
        welcomeNavigationDelegate?.showNextWelcomePage(self)
    }
}
