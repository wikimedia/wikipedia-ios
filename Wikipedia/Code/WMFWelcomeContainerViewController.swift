
class WMFWelcomeContainerViewController: WMFWelcomeFadeInAndUpOnceViewController {
    
    @IBOutlet private var topContainerView:UIView!
    @IBOutlet private var bottomContainerView:UIView!

    var welcomePageType:WMFWelcomePageType = .intro
    private var animationVC:WMFWelcomeAnimationViewController? = nil

    weak var welcomeNavigationDelegate:WMFWelcomeNavigationDelegate? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        embedBottomContainerControllerView()
    }
    
    private func embedBottomContainerControllerView() {
        if let controller = controllerForBottomContainer() {
            controller.willMoveToParentViewController(self)
            bottomContainerView.addSubview((controller.view)!)
            controller.view.mas_makeConstraints { make in
                make.top.bottom().leading().and().trailing().equalTo()(self.bottomContainerView)
            }
            self.addChildViewController(controller)
            controller.didMoveToParentViewController(self)
        }
    }

    private func controllerForBottomContainer() -> UIViewController?{
        switch welcomePageType {
        case .intro:
            return WMFWelcomeIntroductionViewController.wmf_viewControllerWithIdentifier("WMFWelcomeIntroductionViewController", fromStoryboardNamed: "WMFWelcome")
        case .languages:
            let langPanelVC = WMFWelcomePanelViewController.wmf_viewControllerWithIdentifier("WMFWelcomePanelViewController", fromStoryboardNamed: "WMFWelcome")
            langPanelVC.useLanguagesConfiguration()
            return langPanelVC;
        case .analytics:
            let analyticsPanelVC = WMFWelcomePanelViewController.wmf_viewControllerWithIdentifier("WMFWelcomePanelViewController", fromStoryboardNamed: "WMFWelcome")
            analyticsPanelVC.useUsageReportsConfiguration()
            return analyticsPanelVC;
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.destinationViewController.isKindOfClass(WMFWelcomeAnimationViewController)){
            animationVC = segue.destinationViewController as? WMFWelcomeAnimationViewController
            animationVC!.welcomePageType = welcomePageType
        }
    }
    
    @IBAction func next(withSender sender: AnyObject) {
        welcomeNavigationDelegate?.showNextWelcomePage(self)
    }
}
