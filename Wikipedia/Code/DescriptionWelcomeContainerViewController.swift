
class DescriptionWelcomeContainerViewController: UIViewController, Themeable {
    private var theme = Theme.standard
    func apply(theme: Theme) {
        self.theme = theme
    }
    
    @IBOutlet private var topContainerView:UIView!
    @IBOutlet private var bottomContainerView:UIView!
    @IBOutlet private var overallContainerStackView:UIStackView!
    @IBOutlet private var overallContainerStackViewCenterYConstraint:NSLayoutConstraint!
    @IBOutlet private var topContainerViewHeightConstraint:NSLayoutConstraint!

    var pageType:DescriptionWelcomePageType = .intro
    weak var welcomeNavigationDelegate:DescriptionWelcomeNavigationDelegate? = nil
    
    private var hasAlreadyFadedInAndUp = false
    private var needsDeviceAdjustments = true

    var nextButtonAction: ((UIButton) -> Void)?
    
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
    
    private func shouldFadeInAndUp() -> Bool {
        switch pageType {
        case .intro:
            return false
        case .exploration:
            return true
        }
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()
        if needsDeviceAdjustments {
            useBottomAlignmentIfPhone()
            needsDeviceAdjustments = false
        }
    }
    
    private func useBottomAlignmentIfPhone() {
        assert(Int(overallContainerStackViewCenterYConstraint.priority.rawValue) == 999, "The Y centering constraint must not have required '1000' priority because on non-tablets we add a required bottom alignment constraint on overallContainerView which we want to be favored when present.")
        if (UI_USER_INTERFACE_IDIOM() == .phone) {
            overallContainerStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? DescriptionWelcomePanelViewController {
            vc.nextButtonAction = nextButtonAction
            vc.pageType = pageType
            vc.apply(theme: theme)
        } else if let vc = segue.destination as? DescriptionWelcomeImageViewController{
            vc.pageType = pageType
        }
    }
    
    @IBAction private func next(withSender sender: AnyObject) {
        welcomeNavigationDelegate?.showNextWelcomePage(self)
    }
}
