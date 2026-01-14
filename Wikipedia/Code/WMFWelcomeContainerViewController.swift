class WMFWelcomeContainerViewController: ThemeableViewController {
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        for child in children {
            guard let themeable = child as? Themeable else {
                continue
            }
            themeable.apply(theme: theme)
        }
    }
    
    @IBOutlet private var bottomContainerView:UIView!
    @IBOutlet private var overallContainerStackView:UIStackView!
    @IBOutlet private var overallContainerStackViewCenterYConstraint:NSLayoutConstraint!
    @IBOutlet private var topContainerViewHeightConstraint:NSLayoutConstraint!
    @IBOutlet private var bottomContainerViewHeightConstraint:NSLayoutConstraint!

    var welcomePageType:WMFWelcomePageType = .intro
    weak var welcomeNavigationDelegate:WMFWelcomeNavigationDelegate? = nil
    
    private var hasAlreadyFadedInAndUp = false
    private var needsDeviceAdjustments = true
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if shouldFadeInAndUp() && !hasAlreadyFadedInAndUp {
            view.wmf_zeroLayerOpacity()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if shouldFadeInAndUp() && !hasAlreadyFadedInAndUp {
            view.wmf_fadeInAndUpWithDuration(0.4, delay: 0.1)
            hasAlreadyFadedInAndUp = true
        }
        UIAccessibility.post(notification: .screenChanged, argument: view)
    }
    
    private func shouldFadeInAndUp() -> Bool {
        switch welcomePageType {
        case .intro:
            return false
        case .exploration:
            return true
        case .languages:
            return true
        case .analytics:
            return true
        }
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()
        if needsDeviceAdjustments {
            let height = view.bounds.size.height
            if height <= 568 {
                // On iPhone 5 reduce size of animations.
                reduceTopAnimationsSizes(reduction: 30)
                bottomContainerViewHeightConstraint.constant = 367
                overallContainerStackView.spacing = 10
            } else {
                // On everything else add vertical separation between bottom container and animations.
                overallContainerStackView.spacing = 20
            }
            useBottomAlignmentIfPhone()
            needsDeviceAdjustments = false
        }
    }
    
    private func reduceTopAnimationsSizes(reduction: CGFloat) {
        topContainerViewHeightConstraint.constant = topContainerViewHeightConstraint.constant - reduction
    }
    
    private func useBottomAlignmentIfPhone() {
        assert(Int(overallContainerStackViewCenterYConstraint.priority.rawValue) == 999, "The Y centering constraint must not have required '1000' priority because on non-tablets we add a required bottom alignment constraint on overallContainerView which we want to be favored when present.")
        if UIDevice.current.userInterfaceIdiom == .phone {
            overallContainerStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? WMFWelcomePanelViewController {
            vc.welcomePageType = welcomePageType
            vc.apply(theme: theme)
        } else if let vc = segue.destination as? WMFWelcomeAnimationViewController {
            vc.welcomePageType = welcomePageType
            vc.apply(theme: theme)
        }
    }
    
    @IBAction private func next(withSender sender: AnyObject) {
        welcomeNavigationDelegate?.showNextWelcomePage(self)
    }
}
