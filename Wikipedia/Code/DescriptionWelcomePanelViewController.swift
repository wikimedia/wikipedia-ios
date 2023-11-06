class DescriptionWelcomePanelViewController: UIViewController, Themeable {
    private var theme = Theme.standard
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        scrollViewGradientView.apply(theme: theme)
        titleLabel.textColor = theme.colors.primaryText
        bottomLabel.textColor = theme.colors.primaryText
        nextButton.backgroundColor = theme.colors.link
    }

    @IBOutlet private var containerView:UIView!
    @IBOutlet private var titleLabel:UILabel!
    @IBOutlet private var bottomLabel:UILabel!
    @IBOutlet private var nextButton:AutoLayoutSafeMultiLineButton!
    @IBOutlet private var scrollView:UIScrollView!
    @IBOutlet private var scrollViewGradientView:ScrollViewGradientView!
    @IBOutlet private var nextButtonContainerView:UIView!

    var nextButtonAction: ((UIButton) -> Void)?

    private var viewControllerForContainerView:UIViewController? = nil
    var pageType:DescriptionWelcomePageType = .intro

    override func viewDidLoad() {
        super.viewDidLoad()
        apply(theme: theme)
        embedContainerControllerView()
        updateUIStrings()

        // If the button itself was directly an arranged stackview subview we couldn't
        // set padding contraints and also get clean collapsing when enabling isHidden.
        nextButtonContainerView.isHidden = pageType != .exploration
        
        view.wmf_configureSubviewsForDynamicType()

        nextButton.addTarget(self, action: #selector(performNextButtonAction(_:)), for: .touchUpInside)
    }
    
    private func embedContainerControllerView() {
        let containerController = DescriptionWelcomeContentsViewController.wmf_viewControllerFromDescriptionWelcomeStoryboard() 
        containerController.pageType = pageType
        addChild(containerController)
        containerView.wmf_addSubviewWithConstraintsToEdges(containerController.view)
        containerController.apply(theme: theme)
        containerController.didMove(toParent: self)
    }
    
    private func updateUIStrings() {
        switch pageType {
        case .intro:
            titleLabel.text = WMFLocalizedString("description-welcome-descriptions-title", value:"Article descriptions", comment:"Title text explaining article descriptions")
        case .exploration:
            titleLabel.text = WMFLocalizedString("description-welcome-concise-title", value:"Keep it short", comment:"Title text explaining descriptions should be concise")
        }
    
        bottomLabel.text = CommonStrings.welcomePromiseTitle
        
        nextButton.setTitle(WMFLocalizedString("description-welcome-start-editing-button", value:"Start editing", comment:"Text for button for dismissing description editing welcome screens"), for: .normal)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if scrollView.wmf_contentSizeHeightExceedsBoundsHeight() {
            scrollView.wmf_flashVerticalScrollIndicatorAfterDelay(1.5)
        }
    }

    @objc private func performNextButtonAction(_ sender: UIButton) {
        nextButtonAction?(sender)
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
