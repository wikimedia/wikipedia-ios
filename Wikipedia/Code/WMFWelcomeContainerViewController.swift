
class WMFWelcomeContainerViewController: UIViewController {
    
    @IBOutlet fileprivate var topContainerView:UIView!
    @IBOutlet fileprivate var bottomContainerView:UIView!

    @IBOutlet fileprivate var overallContainerView:UIView!
    @IBOutlet fileprivate var overallContainerViewCenterYConstraint:NSLayoutConstraint!
    @IBOutlet fileprivate var topContainerViewHeightConstraint:NSLayoutConstraint!
    
    var welcomePageType:WMFWelcomePageType = .intro
    fileprivate var animationVC:WMFWelcomeAnimationViewController? = nil

    weak var welcomeNavigationDelegate:WMFWelcomeNavigationDelegate? = nil
    
    fileprivate var hasAlreadyFadedInAndUp = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        embedBottomContainerControllerView()
        useBottomAlignmentIfPhone()
        hideAndCollapseTopContainerViewIfDeviceIsiPhone4s()
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
        case .languages:
            return true
        case .analytics:
            return true
        }
    }

    fileprivate func hideAndCollapseTopContainerViewIfDeviceIsiPhone4s() {
        if view.frame.size.height == 480 {
            topContainerView.alpha = 0
            topContainerViewHeightConstraint.constant = 0
        }
    }
    
    fileprivate func useBottomAlignmentIfPhone() {
        assert(overallContainerViewCenterYConstraint.priority == 999, "The Y centering constraint must not have required '1000' priority because on non-tablets we add a required bottom alignment constraint on overallContainerView which we want to be favored when present.")
        if (UI_USER_INTERFACE_IDIOM() == .phone) {
            overallContainerView.mas_makeConstraints { make in
                _ = make?.bottom.equalTo()(self.mas_bottomLayoutGuideTop)
            }
        }
    }
    
    fileprivate func embedBottomContainerControllerView() {
        bottomContainerController.willMove(toParentViewController: self)
        bottomContainerController.view.translatesAutoresizingMaskIntoConstraints = false
        bottomContainerView.addSubview((bottomContainerController.view)!)
        bottomContainerController.view.mas_makeConstraints { make in
            _ = make?.top.bottom().leading().and().trailing().equalTo()(self.bottomContainerView)
        }
        self.addChildViewController(bottomContainerController)
        bottomContainerController.didMove(toParentViewController: self)
    }

    fileprivate lazy var bottomContainerController: UIViewController = {
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.destination.isKind(of: WMFWelcomeAnimationViewController.self)){
            animationVC = segue.destination as? WMFWelcomeAnimationViewController
            animationVC!.welcomePageType = welcomePageType
        }
    }
    
    @IBAction fileprivate func next(withSender sender: AnyObject) {
        welcomeNavigationDelegate?.showNextWelcomePage(self)
    }
}
