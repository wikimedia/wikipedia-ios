
class WMFWelcomePanelViewController: UIViewController {
    fileprivate var theme = Theme.standard
    
    @IBOutlet fileprivate var containerView:UIView!
    @IBOutlet fileprivate var titleLabel:UILabel!
    
    fileprivate var viewControllerForContainerView:UIViewController? = nil
    var welcomePageType:WMFWelcomePageType = .intro

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // For iPhone 4s and iPhone 5 a smaller size is used.
        if view.bounds.size.height <= 568 {
            titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .medium)
        }
            
        embedContainerControllerView()
        updateUIStrings()
        view.wmf_configureSubviewsForDynamicType()
    }
    
    fileprivate func embedContainerControllerView() {
        if let containerController = containerController {
            containerController.willMove(toParentViewController: self)
            containerView.wmf_addSubviewWithConstraintsToEdges(containerController.view)
            addChildViewController(containerController)
            containerController.didMove(toParentViewController: self)
        }
    }
    
    fileprivate lazy var containerController: UIViewController? = {
        switch welcomePageType {
        case .intro:
            return WMFWelcomeIntroductionViewController.wmf_viewControllerFromWelcomeStoryboard()
        case .exploration:
            return WMFWelcomeExplorationViewController.wmf_viewControllerFromWelcomeStoryboard()
        case .languages:
            return WMFWelcomeLanguageTableViewController.wmf_viewControllerFromWelcomeStoryboard()
        case .analytics:
            return WMFWelcomeAnalyticsViewController.wmf_viewControllerFromWelcomeStoryboard()
        }
    }()

    fileprivate func updateUIStrings(){
        switch welcomePageType {
        case .intro:
            titleLabel.text = WMFLocalizedString("welcome-intro-free-encyclopedia-title", value:"The free encyclopedia", comment:"Title for introductory welcome screen")
        case .exploration:
            titleLabel.text = WMFLocalizedString("welcome-explore-new-ways-title", value:"New ways to explore", comment:"Title for welcome screens including explanation of new notification features")
        case .languages:
            titleLabel.text = WMFLocalizedString("welcome-languages-search-title", value:"Search in nearly 300 languages", comment:"Title for welcome screen describing Wikipedia languages")
        case .analytics:
            titleLabel.text = WMFLocalizedString("welcome-send-data-helps-title", value:"Help make the app better", comment:"Title for welcome screen allowing user to opt in to send usage reports")
        }
    }
}
