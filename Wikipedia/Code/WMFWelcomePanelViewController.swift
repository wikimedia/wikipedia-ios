
class WMFWelcomePanelViewController: ThemeableViewController {
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        scrollView.apply(theme: theme)
        nextButton.backgroundColor = theme.colors.link
        for child in children {
            guard let themeable = child as? Themeable else {
                continue
            }
            themeable.apply(theme: theme)
        }
    }
    
    @IBOutlet private var containerView:UIView!
    @IBOutlet private var titleLabel:UILabel!
    @IBOutlet private var nextButton:AutoLayoutSafeMultiLineButton!
    @IBOutlet private var scrollView:WMFWelcomePanelGradientScrollView!
    @IBOutlet private var nextButtonContainerView:UIView!

    private var viewControllerForContainerView:UIViewController? = nil
    var welcomePageType:WMFWelcomePageType = .intro

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // For iPhone 5 a smaller size is used.
        if view.bounds.size.height <= 568 {
            titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .medium)
        }
        
        
        embedContainerControllerView()
        updateUIStrings()

        // If the button itself was directly an arranged stackview subview we couldn't
        // set padding contraints and also get clean collapsing when enabling isHidden.
        nextButtonContainerView.isHidden = welcomePageType != .analytics
        
        view.wmf_configureSubviewsForDynamicType()
    }
    
    private func embedContainerControllerView() {
        if let containerController = containerController {
            containerController.apply(theme: theme)
            addChild(containerController)
            containerView.wmf_addSubviewWithConstraintsToEdges(containerController.view)
            containerController.didMove(toParent: self)
        }
    }
    
    private lazy var containerController: ThemeableViewController? = {
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

    private func updateUIStrings(){
        switch welcomePageType {
        case .intro:
            titleLabel.text = WMFLocalizedString("welcome-intro-free-encyclopedia-title", value:"The free encyclopedia", comment:"Title for introductory welcome screen")
        case .exploration:
            titleLabel.text = WMFLocalizedString("welcome-explore-new-ways-title", value:"New ways to explore", comment:"Title for welcome screens including explanation of new notification features")
        case .languages:
            titleLabel.text = WMFLocalizedString("welcome-languages-search-title", value:"Search in over 300 languages", comment:"Title for welcome screen describing Wikipedia languages")
        case .analytics:
            titleLabel.text = WMFLocalizedString("welcome-send-data-helps-title", value:"Help make the app better", comment:"Title for welcome screen allowing user to opt in to send usage reports")
        }
    
        nextButton.setTitle(CommonStrings.getStartedTitle, for: .normal)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if scrollView.wmf_contentSizeHeightExceedsBoundsHeight() {
            scrollView.wmf_flashVerticalScrollIndicatorAfterDelay(1.5)
        }
    }
}

private extension UIScrollView {
    func wmf_contentSizeHeightExceedsBoundsHeight() -> Bool {
        return contentSize.height - bounds.size.height > 0
    }
    func wmf_flashVerticalScrollIndicatorAfterDelay(_ delay: TimeInterval) {
        dispatchOnMainQueueAfterDelayInSeconds(delay) {
            self.flashScrollIndicators()
        }
    }
}

class WMFWelcomePanelGradientScrollView : UIScrollView, Themeable {
    func apply(theme: Theme) {
        fadeColor = theme.colors.paperBackground
        clear = theme.colors.paperBackground.withAlphaComponent(0)
        bottomGradientView.setStart(fadeColor, end: clear)
        topGradientView.setStart(fadeColor, end: clear)
    }
    
    private let fadeHeight: CGFloat = 8
    private var fadeColor = UIColor.white
    private var clear = UIColor.white.withAlphaComponent(0)
    private lazy var topGradientView: WMFGradientView = {
        let gradient = WMFGradientView()
        gradient.translatesAutoresizingMaskIntoConstraints = false
        gradient.startPoint = .zero
        gradient.endPoint = CGPoint(x: 0, y: 1)
        gradient.setStart(fadeColor, end: clear)
        addSubview(gradient)
        return gradient
    }()
    
    private lazy var bottomGradientView: WMFGradientView = {
        let gradient = WMFGradientView()
        gradient.translatesAutoresizingMaskIntoConstraints = false
        gradient.startPoint = CGPoint(x: 0, y: 1)
        gradient.endPoint = .zero
        gradient.setStart(fadeColor, end: clear)
        addSubview(gradient)
        return gradient
    }()

    override func layoutSubviews() {
        super.layoutSubviews()
        updateGradientFrames()
    }

    private func updateGradientFrames() {
        topGradientView.frame = CGRect(x: 0, y: contentOffset.y, width: bounds.size.width, height: fadeHeight)
        bottomGradientView.frame = topGradientView.frame.offsetBy(dx: 0, dy: bounds.size.height - fadeHeight)
    }
}
