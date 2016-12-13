
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
        nextButton.setTitleColor(UIColor.wmf_blueTint(), for: UIControlState())
        containerView.layer.borderWidth = 1.0 / UIScreen.main.scale
        self.view.wmf_configureSubviewsForDynamicType()
    }
    
    fileprivate func embedContainerControllerView() {
        if let containerController = containerController {
            containerController.willMove(toParentViewController: self)
            containerController.view.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview((containerController.view)!)
            containerController.view.mas_makeConstraints { make in
                make?.top.bottom().leading().and().trailing().equalTo()(self.containerView)
            }
            self.addChildViewController(containerController)
            containerController.didMove(toParentViewController: self)
        }
    }
    
    fileprivate lazy var containerController: UIViewController? = {
        switch self.welcomePageType {
        case .intro:
            assert(false, "Intro welcome view is not embedded in a panel.")
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
            assert(false, "Intro welcome view is not embedded in a panel.")
        case .languages:
            titleLabel.text = localizedStringForKeyFallingBackOnEnglish("welcome-languages-title").uppercased(with: Locale.current)
            subtitleLabel.text = localizedStringForKeyFallingBackOnEnglish("welcome-languages-sub-title")
            nextButton.setTitle(localizedStringForKeyFallingBackOnEnglish("welcome-languages-continue-button").uppercased(with: Locale.current), for: UIControlState())
        case .analytics:
            titleLabel.text = localizedStringForKeyFallingBackOnEnglish("welcome-send-data-title").uppercased(with: Locale.current)
            subtitleLabel.text = localizedStringForKeyFallingBackOnEnglish("welcome-send-data-sub-title")
            nextButton.setTitle(localizedStringForKeyFallingBackOnEnglish("button-done").uppercased(with: Locale.current), for: UIControlState())
        }
    }
}
