import WMFData
import CocoaLumberjackSwift
import WMFComponents
import WMF
import Combine

final class WMFActivityTabHostingController: WMFComponentHostingController<WMFActivityTabView> {}

@objc final class WMFActivityTabViewController: WMFCanvasViewController, WMFNavigationBarConfiguring, Themeable {
    private var theme: Theme
    private var yirDataController: WMFYearInReviewDataController? {
        return try? WMFYearInReviewDataController()
    }
    private let dataStore: MWKDataStore?
    private let hostingController: WMFActivityTabHostingController
    public let viewModel: WMFActivityTabViewModel
    private let dataController: WMFActivityTabDataController

    public init(dataStore: MWKDataStore?, theme: Theme, viewModel: WMFActivityTabViewModel, dataController: WMFActivityTabDataController) {
        self.dataStore = dataStore
        self.viewModel = viewModel
        let view = WMFActivityTabView(viewModel: viewModel)
        self.hostingController = WMFActivityTabHostingController(rootView: view)
        self.dataController = dataController
        self.theme = theme
        super.init()
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(updateLoginState), name:WMFAuthenticationManager.didLogInNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateLoginState), name:WMFAuthenticationManager.didLogOutNotification, object: nil)
        addComponent(hostingController, pinToEdges: true, respectSafeArea: true)

        updateLoginState()
    }

    @objc private func updateLoginState() {
        if let isLoggedIn = dataStore?.authenticationManager.authStateIsPermanent, isLoggedIn {
            viewModel.updateIsLoggedIn(isLoggedIn: true)
        } else {
            viewModel.updateIsLoggedIn(isLoggedIn: false)
        }
        if let username = dataStore?.authenticationManager.authStatePermanentUsername {
            viewModel.updateUsername(username: username)
        }
    }

    // MARK: - Profile button dependencies

    private var _yirCoordinator: YearInReviewCoordinator?
    var yirCoordinator: YearInReviewCoordinator? {

        guard let navigationController,
              let yirDataController,
              let dataStore else {
            return nil
        }

        guard let existingYirCoordinator = _yirCoordinator else {
            _yirCoordinator = YearInReviewCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore, dataController: yirDataController)
            _yirCoordinator?.badgeDelegate = self
            return _yirCoordinator
        }

        return existingYirCoordinator
    }

    private lazy var tabsCoordinator: TabsOverviewCoordinator? = { [weak self] in
        guard let self, let nav = self.navigationController, let dataStore else { return nil }
        return TabsOverviewCoordinator(
            navigationController: nav,
            theme: self.theme,
            dataStore: dataStore
        )
    }()

    private var _profileCoordinator: ProfileCoordinator?
    private var profileCoordinator: ProfileCoordinator? {

        guard let navigationController,
              let yirCoordinator = self.yirCoordinator,
              let dataStore else {
            return nil
        }

        guard let existingProfileCoordinator = _profileCoordinator else {
            _profileCoordinator = ProfileCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore, donateSouce: .activityTabProfile, logoutDelegate: self, sourcePage: ProfileCoordinatorSource.activity, yirCoordinator: yirCoordinator)
            _profileCoordinator?.badgeDelegate = self
            return _profileCoordinator
        }

        return existingProfileCoordinator
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let username = dataStore?.authenticationManager.authStatePermanentUsername {
            viewModel.updateUsername(username: username)
        }

        viewModel.articlesSavedViewModel.navigateToSaved = goToSaved
        viewModel.timelineViewModel.onTapArticle = onTapArticle

        configureNavigationBar()

        Task {
            let hasSeen = await dataController.getHasSeenActivityTab()
            if !hasSeen {
                presentOnboarding()
            }
        }
    }

    private func presentOnboarding() {
        let firstItem = WMFOnboardingViewModel.WMFOnboardingCellViewModel(icon: WMFSFSymbolIcon.for(symbol: .bookPages), title: firstItemTitle, subtitle: firstItemSubtitle, fillIconBackground: false)
        let secondItem = WMFOnboardingViewModel.WMFOnboardingCellViewModel(icon: WMFSFSymbolIcon.for(symbol: .pencil), title: secondItemTitle, subtitle: secondItemSubtitle, fillIconBackground: false)
        let thirdItem = WMFOnboardingViewModel.WMFOnboardingCellViewModel(icon: WMFSFSymbolIcon.for(symbol: .bookmark), title: thirdItemTitle, subtitle: thirdItemSubtitle, fillIconBackground: false)
        let fourthItem = WMFOnboardingViewModel.WMFOnboardingCellViewModel(icon: WMFSFSymbolIcon.for(symbol: .lock), title: fourthItemTitle, subtitle: fourthItemSubtitle, fillIconBackground: false)

        let onboardingViewModel = WMFOnboardingViewModel(
            title: activityOnboardingHeader,
            cells: [firstItem, secondItem, thirdItem, fourthItem],
            primaryButtonTitle: CommonStrings.continueButton,
            secondaryButtonTitle: learnMoreAboutActivity)

        let onboardingController = WMFOnboardingViewController(viewModel: onboardingViewModel)
        onboardingController.delegate = self
        present(onboardingController, animated: true, completion: {
            UIAccessibility.post(notification: .layoutChanged, argument: nil)
        })
    }

    private let firstItemTitle = WMFLocalizedString("activity-tab-onboarding-first-item-title", value: "Reading patterns", comment: "Title for activity tabs first item")
    private let firstItemSubtitle = WMFLocalizedString("activity-tab-onboarding-first-item-subtitle", value: "See how much time you've spent reading and which articles or topics you've explored over time.", comment: "Activity tabs first item subtitle")

    private let secondItemTitle = WMFLocalizedString("activity-tab-onboarding-second-item-title", value: "Impact highlights", comment: "Title for activity tabs second item")
    private let secondItemSubtitle = WMFLocalizedString("activity-tab-onboarding-second-item-subtitle", value: "Discover insights about your contributions and the reach of the knowledge you've shared.", comment: "Activity tabs second item subtitle")

    private let thirdItemTitle = WMFLocalizedString("activity-tab-onboarding-third-item-title", value: "More ways to engage", comment: "Title for activity tabs third item")
    private let thirdItemSubtitle = WMFLocalizedString("activity-tab-onboarding-third-item-subtitle", value: "Explore stats for saved articles and other activities that connect you more deeply with Wikipedia.", comment: "Activity tabs third item subtitle")

    private let fourthItemTitle = WMFLocalizedString("activity-tab-onboarding-fourth-item-title", value: "Stay in control", comment: "Title for activity tabs fourth item")
    private let fourthItemSubtitle = WMFLocalizedString("activity-tab-onboarding-fourth-item-subtitle", value: "Choose which modules to display. All personal data stays private on your device and browsing history can be cleared at anytime.", comment: "Activity tabs fourth item subtitle")

    private let activityOnboardingHeader = WMFLocalizedString("activity-tab-onboarding-header", value: "Introducing Activity", comment: "Activity tabs onboarding header")
    private let learnMoreAboutActivity = WMFLocalizedString("activity-tab-onboarding-second-button-title", value: "Learn more about Activity", comment: "Activity tabs secondary button to learn more")

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 18, *) {
            if UIDevice.current.userInterfaceIdiom == .pad {
                if previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass {
                    configureNavigationBar()
                }
            }
        }
    }


    // MARK: - Overflow Menu

    private lazy var moreBarButtonItem: UIBarButtonItem = {
        let button = UIBarButtonItem(image: WMFSFSymbolIcon.for(symbol: .ellipsisCircle) , primaryAction: nil, menu: overflowMenu)
        button.accessibilityLabel = CommonStrings.moreButton
        return button
    }()

    private var overflowMenu: UIMenu {
        let clearTitle = WMFLocalizedString("activity-tab-menu-clear-history", value: "Clear reading history", comment: "Title for clar reading history option in the overflow menu button on activity tab")

        let clearAction = UIAction(title: clearTitle, image: WMFSFSymbolIcon.for(symbol: .clockBadgeX), handler: { _ in
            self.userDidTapClearReadingHistory()
        })

        let learnMoreAction = UIAction(title: CommonStrings.learnMoreTitle(), image: WMFSFSymbolIcon.for(symbol: .infoCircle), handler: { _ in
            self.userDidTapLearnMore()
        })

        let reportIssueAction = UIAction(title: CommonStrings.problemWithFeatureTitle, image: WMFSFSymbolIcon.for(symbol: .flag), handler: { _ in
            self.userDidTapReportIssue()
        })
        let mainMenu = UIMenu(title: String(), children: [learnMoreAction, clearAction, reportIssueAction])

        return mainMenu
    }

    var learnMoreAboutActivityURL: URL? {

        guard let appLanguage = WMFDataEnvironment.current.primaryAppLanguage else {
            return URL(string: "https://www.mediawiki.org/wiki/Special:MyLanguage/Wikimedia_Apps/Team/iOS/Activity_Tab")
        }

        return WMFProject.mediawiki.translatedHelpURL(pathComponents: ["Wikimedia Apps", "Team", "iOS", "Activity Tab"], section: nil, language: appLanguage)
    }

    private func userDidTapClearReadingHistory() {
        guard let dataStore else { return }
        do {
            try dataStore.viewContext.clearReadHistory()

        } catch let error {
            showError(error)
        }

        Task {
            do {
                let dataController = try WMFPageViewsDataController()
                try await dataController.deleteAllPageViewsAndCategories()
                viewModel.fetchData()

            } catch {
                DDLogError("Failure deleting WMFData WMFPageViews: \(error)")
            }
        }
    }

    private func userDidTapLearnMore() {
        if let url = learnMoreAboutActivityURL {
            let config = SinglePageWebViewController.StandardConfig(url: url, useSimpleNavigationBar: true)
            let webVC = SinglePageWebViewController(configType: .standard(config), theme: theme)
            let newNavigationVC =
            WMFComponentNavigationController(rootViewController: webVC, modalPresentationStyle: .formSheet)
            navigationController?.present(newNavigationVC, animated: true)
        }
    }

    private func userDidTapReportIssue() {
        let emailAddress = "ios-support@wikimedia.org"
        let emailSubject = WMFLocalizedString("activity-tab-email-title", value: "Issue Report - Activity Tab", comment: "Title text for Activity Tab pre-filled issue report email")
        let emailBodyLine1 = WMFLocalizedString("activity-tab-email-first-line", value: "I have encountered a problem with Activity Tab Feature:", comment: "Text for Activity Tab pre-filled issue report email")
        let emailBodyLine2 = WMFLocalizedString("activity-tab-email-second-line", value: "- [Describe specific problem]", comment: "Text for Activity Tab pre-filled issue report email. This text is intended to be replaced by the user with a description of the problem they are encountering")
        let emailBodyLine3 = WMFLocalizedString("activity-tab-email-third-line", value: "The behavior I would like to see is:", comment: "Text for Activity Tab pre-filled issue report email")
        let emailBodyLine4 = WMFLocalizedString("activity-tab-email-fourth-line", value: "[Describe desired behavior]", comment: "Text for Activity Tab pre-filled issue report email. This text is intended to be replaced by the user with a description of the desired behavior")
        let emailBodyLine5 = WMFLocalizedString("activity-tab-email-fifth-line", value: "[Screenshots or Links]", comment: "Text for Activity Tab pre-filled issue report email. This text is intended to be replaced by the user with a screenshot or link.")
        let emailBody = "\(emailBodyLine1)\n\n\(emailBodyLine2)\n\n\(emailBodyLine3)\n\n\(emailBodyLine4)\n\n\(emailBodyLine5)"
        let mailto = "mailto:\(emailAddress)?subject=\(emailSubject)&body=\(emailBody)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)

        guard
            let encodedMailto = mailto,
            let mailtoURL = URL(string: encodedMailto), UIApplication.shared.canOpenURL(mailtoURL)
        else {
            WMFAlertManager.sharedInstance.showErrorAlertWithMessage(CommonStrings.noEmailClient, sticky: false, dismissPreviousAlerts: false)
            return
        }
        UIApplication.shared.open(mailtoURL)
    }

    // MARK: - Navigation Bar
    private func configureNavigationBar() {

        var titleConfig: WMFNavigationBarTitleConfig = WMFNavigationBarTitleConfig(title: CommonStrings.activityTitle, customView: nil, alignment: .leadingCompact)
        extendedLayoutIncludesOpaqueBars = false
        if #available(iOS 18, *) {
            if UIDevice.current.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .regular {
                titleConfig = WMFNavigationBarTitleConfig(title: CommonStrings.activityTitle, customView: nil, alignment: .leadingLarge)
                extendedLayoutIncludesOpaqueBars = true
            }
        }

        let profileButtonConfig: WMFNavigationBarProfileButtonConfig?
        let tabsButtonConfig: WMFNavigationBarTabsButtonConfig?
        if let dataStore {
            profileButtonConfig = self.profileButtonConfig(target: self, action: #selector(userDidTapProfile), dataStore: dataStore, yirDataController: yirDataController, leadingBarButtonItem: nil)
            tabsButtonConfig = self.tabsButtonConfig(target: self, action: #selector(userDidTapTabs), dataStore: dataStore, leadingBarButtonItem: moreBarButtonItem)
        } else {
            profileButtonConfig = nil
            tabsButtonConfig = nil
        }

        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: nil, profileButtonConfig: profileButtonConfig, tabsButtonConfig: tabsButtonConfig, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }

    @objc func userDidTapTabs() {
        tabsCoordinator?.start()
        ArticleTabsFunnel.shared.logIconClick(interface: .activity, project: nil)
    }

    @objc func userDidTapProfile() {

        guard let dataStore else {
            return
        }

        guard let languageCode = dataStore.languageLinkController.appLanguage?.languageCode,
              let metricsID = DonateCoordinator.metricsID(for: .activityTabProfile, languageCode: languageCode) else {
            return
        }

        profileCoordinator?.start()
    }

    private func updateProfileButton() {

        guard let dataStore else {
            return
        }

        let config = self.profileButtonConfig(target: self, action: #selector(userDidTapProfile), dataStore: dataStore, yirDataController: yirDataController, leadingBarButtonItem: nil)
        updateNavigationBarProfileButton(needsBadge: config.needsBadge, needsBadgeLabel: CommonStrings.profileButtonBadgeTitle, noBadgeLabel: CommonStrings.profileButtonTitle)
    }

    @objc func goToSaved() {
        navigationController?.popToRootViewController(animated: false)

        if let tabBar = self.tabBarController {
            tabBar.selectedIndex = 2
        }
    }
    
    func onTapArticle(item: TimelineItem) {
        if let articleURL = item.url, let dataStore, let navVC = navigationController {
            let articleCoordinator = ArticleCoordinator(navigationController: navVC, articleURL: articleURL, dataStore: dataStore, theme: theme, source: .activity)
            articleCoordinator.start()
        }
    }
    
    // MARK: Theming

    public func apply(theme: Theme) {
        guard viewIfLoaded != nil else {
            return
        }
        updateProfileButton()
        profileCoordinator?.theme = theme
        self.theme = theme
    }
}

// MARK: - Extensions

extension WMFActivityTabViewController: YearInReviewBadgeDelegate {
    public func updateYIRBadgeVisibility() {
         updateProfileButton()
    }
}

extension WMFActivityTabViewController: LogoutCoordinatorDelegate {
    func didTapLogout() {

        guard let dataStore else {
            return
        }

        wmf_showKeepSavedArticlesOnDevicePanelIfNeeded(triggeredBy: .logout, theme: theme) {
            dataStore.authenticationManager.logout(initiatedBy: .user)
        }
    }
}

extension WMFActivityTabViewController: ShareableArticlesProvider {}

extension WMFActivityTabViewController: WMFOnboardingViewDelegate {

    public func onboardingViewDidClickPrimaryButton() {
        presentedViewController?.dismiss(animated: true, completion: { [weak self] in
            Task {
                await self?.dataController.setHasSeenActivityTab(true)
            }
        })

        // TODO: Log
    }

    public func onboardingViewDidClickSecondaryButton() {
        guard let url = learnMoreAboutActivityURL else {
            return
        }

        UIApplication.shared.open(url)

        // TODO: Log
    }

    public func onboardingViewWillSwipeToDismiss() {
        presentedViewController?.dismiss(animated: true, completion: { [weak self] in
            Task {
                await self?.dataController.setHasSeenActivityTab(true)
            }
        })
    }
}
