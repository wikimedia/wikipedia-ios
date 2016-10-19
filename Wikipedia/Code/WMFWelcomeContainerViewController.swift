
class WMFWelcomeContainerViewController: WMFWelcomeFadeInAndUpOnceViewController {
    
    @IBOutlet private var topContainerView:UIView!
    @IBOutlet private var bottomContainerView:UIView!

    @IBOutlet private var overallContainerView:UIView!
    @IBOutlet private var overallContainerViewCenterYConstraint:NSLayoutConstraint!
    @IBOutlet private var topContainerViewHeightConstraint:NSLayoutConstraint!
    
    var welcomePageType:WMFWelcomePageType = .intro
    private var animationVC:WMFWelcomeAnimationViewController? = nil

    weak var welcomeNavigationDelegate:WMFWelcomeNavigationDelegate? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        embedBottomContainerControllerView()
        useBottomAlignmentIfPhone()
        hideAndCollapseTopContainerViewIfDeviceIsiPhone4s()
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
            return WMFWelcomeIntroductionViewController.wmf_viewControllerWithIdentifier("WMFWelcomeIntroductionViewController", fromStoryboardNamed: "WMFWelcome")
        case .languages:
            let langPanelVC = WMFWelcomePanelViewController.wmf_viewControllerWithIdentifier("WMFWelcomePanelViewController", fromStoryboardNamed: "WMFWelcome")
            langPanelVC.welcomePageType = .languages
            return langPanelVC;
        case .analytics:
            let analyticsPanelVC = WMFWelcomePanelViewController.wmf_viewControllerWithIdentifier("WMFWelcomePanelViewController", fromStoryboardNamed: "WMFWelcome")
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
