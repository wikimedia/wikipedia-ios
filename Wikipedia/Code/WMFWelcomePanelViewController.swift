
class WMFWelcomePanelViewController: UIViewController {
    fileprivate var theme = Theme.standard
    
    @IBOutlet fileprivate var containerView:UIView!
    @IBOutlet fileprivate var titleLabel:UILabel!
    @IBOutlet fileprivate var nextButton:UIButton!
    @IBOutlet fileprivate var scrollView:UIScrollView!
    @IBOutlet fileprivate var nextButtonContainerView:UIView!

    fileprivate var viewControllerForContainerView:UIViewController? = nil
    var welcomePageType:WMFWelcomePageType = .intro

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // For iPhone 4s and iPhone 5 a smaller size is used.
        if view.bounds.size.height <= 568 {
            titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .medium)
        }
        
        nextButton.backgroundColor = .wmf_blue
        embedContainerControllerView()
        updateUIStrings()

        // If the button itself was directly an arranged stackview subview we couldn't
        // set padding contraints and also get clean collapsing when enabling isHidden.
        nextButtonContainerView.isHidden = welcomePageType != .analytics
        
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
    
        nextButton.setTitle(WMFLocalizedString("welcome-explore-continue-button", value:"Get started", comment:"Text for button for dismissing welcome screens\n{{Identical|Get started}}"), for: .normal)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if scrollView.wmf_contentSizeHeightExceedsBoundsHeight() {
            scrollView.wmf_flashVerticalScrollIndicatorAfterDelay(1.5)
        }
    }
}

fileprivate extension UIScrollView {
    func wmf_contentSizeHeightExceedsBoundsHeight() -> Bool {
        return contentSize.height - bounds.size.height > 0
    }
    func wmf_flashVerticalScrollIndicatorAfterDelay(_ delay: TimeInterval) {
        dispatchOnMainQueueAfterDelayInSeconds(delay) {
            self.flashScrollIndicators()
        }
    }
}
