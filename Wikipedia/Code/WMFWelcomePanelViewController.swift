
class WMFWelcomePanelViewController: UIViewController {

    @IBOutlet fileprivate var containerView:UIView!
    @IBOutlet fileprivate var nextButton:UIButton!
    @IBOutlet fileprivate var titleLabel:UILabel!
    @IBOutlet fileprivate var subtitleLabel:UILabel!

    fileprivate var viewControllerForContainerView:UIViewController? = nil
    var welcomePageType:WMFWelcomePageType = .intro

    override func viewDidLoad() {
        super.viewDidLoad()
        embedContainerControllerView()
        updateUIStrings()
        nextButton.setTitleColor(.wmf_blueTint, for: UIControlState())
        containerView.layer.borderWidth = 1.0 / UIScreen.main.scale
        self.view.wmf_configureSubviewsForDynamicType()
    }
    
    fileprivate func embedContainerControllerView() {
        if let containerController = containerController {
            containerController.willMove(toParentViewController: self)
            containerController.view.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview((containerController.view)!)
            containerController.view.mas_makeConstraints { make in
                _ = make?.top.bottom().leading().and().trailing().equalTo()(self.containerView)
            }
            self.addChildViewController(containerController)
            containerController.didMove(toParentViewController: self)
        }
    }
    
    fileprivate lazy var containerController: UIViewController? = {
        switch self.welcomePageType {
        case .intro:
            assertionFailure("Intro welcome view is not embedded in a panel.")
            return nil
        case .languages:
            return WMFWelcomeLanguageTableViewController.wmf_viewControllerFromWelcomeStoryboard()
        case .analytics:
            return WMFWelcomeAnalyticsViewController.wmf_viewControllerFromWelcomeStoryboard()
        }
    }()

    fileprivate func updateUIStrings(){
        switch self.welcomePageType {
        case .intro:
            assertionFailure("Intro welcome view is not embedded in a panel.")
        case .languages:
            titleLabel.text = NSLocalizedString("welcome-languages-title", value:"Languages", comment:"Title for welcome screen allowing user to select additional languages\n{{Identical|Language}}").uppercased(with: Locale.current)
            subtitleLabel.text = NSLocalizedString("welcome-languages-sub-title", value:"Choose your preferred languages to search Wikipedia", comment:"Sub-title for languages welcome screen")
            nextButton.setTitle(NSLocalizedString("welcome-languages-continue-button", value:"Continue", comment:"Text for button for moving to next welcome screen\n{{Identical|Continue}}").uppercased(with: Locale.current), for: UIControlState())
        case .analytics:
            titleLabel.text = NSLocalizedString("welcome-send-data-title", value:"Send Anonymous data", comment:"Title for welcome screen allowing user to opt in to send usage reports").uppercased(with: Locale.current)
            subtitleLabel.text = NSLocalizedString("welcome-send-data-sub-title", value:"Help the Wikimedia Foundation make the app better by letting us know how you use the app. Data collected is anonymous", comment:"Sub-title explaining how sending usage reports can help improve the app")
            nextButton.setTitle(NSLocalizedString("button-done", value:"Done", comment:"Button text for done button used in various places.\n{{Identical|Done}}").uppercased(with: Locale.current), for: UIControlState())
        }
    }
}
