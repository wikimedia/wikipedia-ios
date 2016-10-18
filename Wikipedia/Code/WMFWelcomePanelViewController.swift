
class WMFWelcomePanelViewController: UIViewController {

    @IBOutlet private var containerView:UIView!
    @IBOutlet private var nextButton:UIButton!
    @IBOutlet private var titleLabel:UILabel!
    @IBOutlet private var subtitleLabel:UILabel!

    private var viewControllerForContainerView:UIViewController? = nil
    private var titleString:String? = nil
    private var subtitleString:String? = nil
    private var buttonString:String? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        embedViewControllerForContainerView()
        titleLabel.text = titleString
        subtitleLabel.text = subtitleString
        nextButton.setTitle(buttonString, forState: .Normal)
        nextButton.setTitleColor(UIColor.wmf_blueTintColor(), forState: .Normal)
        containerView.layer.borderWidth = 1.0 / UIScreen.mainScreen().scale
    }
    
    private func embedViewControllerForContainerView() {
        if((viewControllerForContainerView) != nil){
            viewControllerForContainerView?.willMoveToParentViewController(self)
            containerView.addSubview((viewControllerForContainerView?.view)!)
            viewControllerForContainerView?.view.mas_makeConstraints { make in
                make.top.bottom().leading().and().trailing().equalTo()(self.containerView)
            }
            self.addChildViewController(viewControllerForContainerView!)
            viewControllerForContainerView?.didMoveToParentViewController(self)
        }
    }
    
    func useLanguagesConfiguration(){
        viewControllerForContainerView = WMFWelcomeLanguageTableViewController.wmf_viewControllerWithIdentifier("WMFWelcomeLanguageTableViewController", fromStoryboardNamed: "WMFWelcome")
        titleString = localizedStringForKeyFallingBackOnEnglish("welcome-languages-title").uppercaseStringWithLocale(NSLocale.currentLocale())
        subtitleString = localizedStringForKeyFallingBackOnEnglish("welcome-languages-sub-title")
        buttonString = localizedStringForKeyFallingBackOnEnglish("welcome-languages-continue-button").uppercaseStringWithLocale(NSLocale.currentLocale())
    }

    func useUsageReportsConfiguration(){
        viewControllerForContainerView = WMFWelcomeAnalyticsViewController.wmf_viewControllerWithIdentifier("WMFWelcomeAnalyticsViewController", fromStoryboardNamed: "WMFWelcome")
        titleString = localizedStringForKeyFallingBackOnEnglish("welcome-volunteer-title").uppercaseStringWithLocale(NSLocale.currentLocale())
        subtitleString = localizedStringForKeyFallingBackOnEnglish("welcome-volunteer-sub-title")
        buttonString = localizedStringForKeyFallingBackOnEnglish("button-done").uppercaseStringWithLocale(NSLocale.currentLocale())
    }
}
