
class WMFWelcomePanelViewController: UIViewController {

    @IBOutlet var containerView:UIView!
    @IBOutlet var nextButton:UIButton!
    @IBOutlet var titleLabel:UILabel!
    @IBOutlet var subtitleLabel:UILabel!

    var viewControllerForContainerView:UIViewController? = nil
    var titleString:String? = nil
    var subtitleString:String? = nil
    var buttonString:String? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        embedViewControllerForContainerView()
        titleLabel.text = titleString
        subtitleLabel.text = subtitleString
        nextButton.setTitle(buttonString, forState: .Normal)
        nextButton.setTitleColor(UIColor.wmf_blueTintColor(), forState: .Normal)
    }
    
    func embedViewControllerForContainerView() {
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
    
    internal func useLanguagesConfiguration(){
        viewControllerForContainerView = WMFWelcomeLanguageTableViewController.wmf_viewControllerWithIdentifier("WMFWelcomeLanguageTableViewController", fromStoryboardNamed: "WMFWelcome")
        titleString = localizedStringForKeyFallingBackOnEnglish("welcome-languages-title").uppercaseStringWithLocale(NSLocale.currentLocale())
        subtitleString = localizedStringForKeyFallingBackOnEnglish("welcome-languages-sub-title")
        buttonString = localizedStringForKeyFallingBackOnEnglish("welcome-languages-continue-button").uppercaseStringWithLocale(NSLocale.currentLocale())
    }

    internal func useUsageReportsConfiguration(){
        viewControllerForContainerView = WMFWelcomeUsageReportViewController.wmf_viewControllerWithIdentifier("WMFWelcomeUsageReportViewController", fromStoryboardNamed: "WMFWelcome")
        titleString = localizedStringForKeyFallingBackOnEnglish("welcome-volunteer-title").uppercaseStringWithLocale(NSLocale.currentLocale())
        subtitleString = localizedStringForKeyFallingBackOnEnglish("welcome-volunteer-sub-title")
        buttonString = localizedStringForKeyFallingBackOnEnglish("button-done").uppercaseStringWithLocale(NSLocale.currentLocale())
    }
}
