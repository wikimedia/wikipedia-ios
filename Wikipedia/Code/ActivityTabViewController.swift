import WMFData
import CocoaLumberjackSwift
import WMFComponents
import WMF
import Combine
import SwiftUI

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
        NotificationCenter.default.addObserver(self, selector: #selector(updateLoginState), name:WMFAuthenticationManager.didHandlePrimaryLanguageChange, object: nil)
        addComponent(hostingController, pinToEdges: true, respectSafeArea: true)

        setupLoginState(needsRefetch: false)
        
        viewModel.openCustomize = userDidTapCustomize
        viewModel.pushToContributions = pushToContributions
        viewModel.exploreWikipedia = presentExplore
        viewModel.makeAnEdit = makeAnEdit
        
        viewModel.fetchDataCompleteAction = { [weak self] onAppearance in
            guard let self else { return }
            if onAppearance {
                if viewModel.isEmpty {
                    ActivityTabFunnel.shared.logActivityTabImpressionState(empty: "empty")
                } else {
                    let allModulesOff = !viewModel.customizeViewModel.isTimeSpentReadingOn &&
                                       !viewModel.customizeViewModel.isReadingInsightsOn &&
                                       !viewModel.customizeViewModel.isEditingInsightsOn &&
                                       !viewModel.customizeViewModel.isTimelineOfBehaviorOn
                    
                    if allModulesOff {
                        ActivityTabFunnel.shared.logActivityTabOffImpression()
                    } else {
                        ActivityTabFunnel.shared.logActivityTabImpressionState(empty: "complete")
                    }
                }
            }
        }
        
        viewModel.presentCustomizeLogInToastAction = { [weak self] in
            guard let self else {
                return
            }
            
            let localizableStrings = WMFToastViewBasicViewModel.LocalizableStrings(title: WMFLocalizedString("activity-tab-customize-logout-warning", value: "You must be logged in to turn on this activity insight.", comment: "Activity tab - warning toast title displayed when a logged out user tries to enable a module requiring login."), buttonTitle: CommonStrings.logIn)
            
            let buttonAction: () -> Void = { [weak self] in
                self?.presentFullLoginFlow(fromCustomizeToast: true)
            }
            
            let viewModel = WMFToastViewBasicViewModel(localizableStrings: localizableStrings, buttonAction: buttonAction)
            let view = WMFToastViewBasicView(viewModel: viewModel)
            WMFToastPresenter.shared.presentToastView(view: view)
        }

        dataController.historyDataController = historyDataController
    }
    
    var editingFAQURLString: String {
        guard let appLanguage = WMFDataEnvironment.current.primaryAppLanguage else {
            return ""
        }
        
        let url = WMFProject.mediawiki.translatedHelpURL(pathComponents: ["Wikimedia Apps", "iOS FAQ"], section: "Editing", language: appLanguage)
        return url?.absoluteString ?? ""
    }
    
    public func makeAnEdit() {
        ActivityTabFunnel.shared.logMakeEditClick()
        guard let url = URL(string: editingFAQURLString) else { return }
        navigate(to: url)
    }

    public func getURL(item: WMFUserImpactData.TopViewedArticle, project: WMFProject) -> URL? {
        guard let siteURL = project.siteURL,
              let articleURL = siteURL.wmf_URL(withTitle: item.title) else {
            return nil
        }
        return articleURL
    }
    
    public func pushToContributions() {
        guard let url =  userContributionsURL else { return }
        navigate(to: url)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reachabilityNotifier.start()

        if !reachabilityNotifier.isReachable {
            showOfflineAlertIfNeeded()
        }
        
        presentModalsIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        reachabilityNotifier.stop()
    }
    
    private func setupLoginState(needsRefetch: Bool) {
        var userID: Int?

        if let siteURL = dataStore?.languageLinkController.appLanguage?.siteURL,
           let permanentUser = dataStore?.authenticationManager.permanentUser(siteURL: siteURL) {
            userID = permanentUser.userID
        }
        
        let primaryAppLanguageCode = dataStore?.languageLinkController.appLanguage?.languageCode
        
        viewModel.updateID(userID: userID)
        viewModel.updateYourImpactOnWikipediaSubtitle(CommonStrings.onLangWikipedia(with: primaryAppLanguageCode))
        viewModel.getURL = getURL
        
        if let username = dataStore?.authenticationManager.authStatePermanentUsername {
            viewModel.updateUsername(username: username)
            viewModel.timelineViewModel.setUser(username: username)
        } else {
            viewModel.updateUsername(username: nil)
            viewModel.timelineViewModel.setUser(username: nil)
        }
        
        if let isLoggedIn = dataStore?.authenticationManager.authStateIsPermanent, isLoggedIn {
            viewModel.updateAuthenticationState(authState: .loggedIn, needsRefetch: needsRefetch)
        } else if let isTemp = dataStore?.authenticationManager.authStateIsTemporary, isTemp {
            viewModel.updateAuthenticationState(authState: .temp, needsRefetch: needsRefetch)
        } else {
            viewModel.updateAuthenticationState(authState: .loggedOut, needsRefetch: needsRefetch)
        }
    }

    @objc private func updateLoginState() {
        setupLoginState(needsRefetch: true)
    }

    private func presentFullLoginFlow(fromCustomizeToast: Bool = false) {
        if fromCustomizeToast {
            // TODO: Will probably need some special logging here.
        } else {
            ActivityTabFunnel.shared.logLoginClick()
            LoginFunnel.shared.logLoginStartFromActivityTab()
        }
        
        guard let nav = navigationController else { return }

        let loginCoordinator = LoginCoordinator(
            navigationController: nav,
            theme: theme,
            loggingCategory: .activity
        )
        
        loginCoordinator.loginSuccessCompletion = {
            WMFToastPresenter.shared.dismissCurrentToast()
        }

        loginCoordinator.createAccountSuccessCustomDismissBlock = {
            WMFToastPresenter.shared.dismissCurrentToast()
            if let createVC = nav.presentedViewController {
                createVC.dismiss(animated: true)
            }
        }

        loginCoordinator.start()
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
            viewModel.timelineViewModel.setUser(username: username)
        } else {
            viewModel.updateUsername(username: nil)
            viewModel.timelineViewModel.setUser(username: nil)
        }

        viewModel.articlesSavedViewModel.onTapSaved = onTapSaved
        viewModel.timelineViewModel.onTapArticle = onTapArticle
        viewModel.onTapArticle = onTapArticleURL(articleURL:)
        viewModel.timelineViewModel.onTapEditArticle = onTapEditArticle
        viewModel.onTapGlobalEdits = onTapGlobalEdits


        configureNavigationBar()
    }
    
    @MainActor
    private func presentModalsIfNeeded() {
        Task {
            let hasSeenActivityTab = await dataController.getHasSeenActivityTab()
            if !hasSeenActivityTab {
                presentOnboarding()
                ActivityTabFunnel.shared.logOnboardingDidAppear()
                await dataController.setHasSeenActivityTab(true)
            } else {
                presentSurveyIfNeeded()
            }
            presentSurveyIfNeeded()
        }
        
        viewModel.didTapPrimaryLoggedOutCTA = { [weak self] in
            self?.presentFullLoginFlow()
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
    
    private func presentExplore() {
        ActivityTabFunnel.shared.logExploreClick()
        navigationController?.popToRootViewController(animated: false)
        
        if let tabBar = self.tabBarController {
            tabBar.selectedIndex = 0 
        }
    }

    private let firstItemTitle = WMFLocalizedString("activity-tab-onboarding-first-item-title", value: "Reading patterns", comment: "Title for activity tabs first item")
    private let firstItemSubtitle = WMFLocalizedString("activity-tab-onboarding-first-item-subtitle", value: "See how much time you've spent reading and which articles or topics you've explored over time.", comment: "Activity tabs first item subtitle")

    private let secondItemTitle = WMFLocalizedString("activity-tab-onboarding-second-item-title", value: "Impact highlights", comment: "Title for activity tabs second item")
    private let secondItemSubtitle = WMFLocalizedString("activity-tab-onboarding-second-item-subtitle", value: "Discover insights about your contributions and the reach of the knowledge you've shared.", comment: "Activity tabs second item subtitle")

    private let thirdItemTitle = WMFLocalizedString("activity-tab-onboarding-third-item-title-updated", value: "Reading history is now in Search", comment: "Title for activity tabs third item")
    private let thirdItemSubtitle = WMFLocalizedString("activity-tab-onboarding-third-item-subtitle-updated", value: "Activity includes a comprehensive timeline of articles read, saved, and edited. Your reading history is now within the Search tab.", comment: "Activity tabs third item subtitle")

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
            ActivityTabFunnel.shared.logActivityTabOverflowMenuClearHistory()
        })

        let learnMoreAction = UIAction(title: CommonStrings.learnMoreTitle(), image: WMFSFSymbolIcon.for(symbol: .infoCircle), handler: { _ in
            self.userDidTapLearnMore()
            ActivityTabFunnel.shared.logActivityTabOverflowMenuLearnMore()
        })

        let reportIssueAction = UIAction(title: CommonStrings.problemWithFeatureTitle, image: WMFSFSymbolIcon.for(symbol: .flag), handler: { _ in
            self.userDidTapReportIssue()
            ActivityTabFunnel.shared.logActivityTabOverflowMenuProblem()
        })
        
        let customizeAction = UIAction(title: CommonStrings.customize, image: WMFSFSymbolIcon.for(symbol: .gearShape), handler: { _ in
            self.userDidTapCustomize()
        })
        
        let mainMenu = UIMenu(title: String(), children: [customizeAction, learnMoreAction, clearAction, reportIssueAction])

        return mainMenu
    }
    
    private func userDidTapCustomize() {
        let allModulesOff = !viewModel.customizeViewModel.isTimeSpentReadingOn &&
                           !viewModel.customizeViewModel.isReadingInsightsOn &&
                           !viewModel.customizeViewModel.isEditingInsightsOn &&
                           !viewModel.customizeViewModel.isTimelineOfBehaviorOn
        
        if allModulesOff {
            ActivityTabFunnel.shared.logActivityTabOffCustomizeClick()
        } else {
            ActivityTabFunnel.shared.logActivityTabCustomizeClick()
        }
        
        let customizeVC = self.customizeViewController()
        navigationController?.present(customizeVC, animated: true)
    }

    private func customizeViewController() -> UIViewController {
        let customizationView = WMFActivityTabCustomizeView(
            viewModel: viewModel.customizeViewModel
        )

        let hostedView = WMFActivityCustomizeHostingController(
            rootView: customizationView,
            theme: theme
        )

        let navController = WMFComponentNavigationController(rootViewController: hostedView, modalPresentationStyle: .pageSheet)

        return navController
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
              DonateCoordinator.metricsID(for: .activityTabProfile, languageCode: languageCode) != nil else {
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

    // MARK: - Private funcs

    private func onTapSaved() {
        navigationController?.popToRootViewController(animated: false)

        if let tabBar = self.tabBarController {
            tabBar.selectedIndex = 2
        }
    }

    private var userContributionsURL: URL? {
        if let appLanguage = WMFDataEnvironment.current.primaryAppLanguage,
           let username = dataStore?.authenticationManager.authStatePermanentUsername,
           let siteURL = WMFProject.wikipedia(appLanguage).siteURL {
            return siteURL.wmf_URL(withPath: "/wiki/Special:Contributions/\(username)")

        }
        return nil
    }

    private func onTapGlobalEdits() {
        if let url = userContributionsURL {
            let config = SinglePageWebViewController.StandardConfig(url: url, useSimpleNavigationBar: true)
            let webVC = SinglePageWebViewController(configType: .standard(config), theme: theme)
            navigationController?.pushViewController(webVC, animated: true)
        }
    }

   private func onTapArticle(item: TimelineItem) {
       ActivityTabFunnel.shared.logActivityTabArticleTap()
        if let articleURL = item.url, let dataStore, let navVC = navigationController {
            let articleCoordinator = ArticleCoordinator(navigationController: navVC, articleURL: articleURL, dataStore: dataStore, theme: theme, source: .activity)
            articleCoordinator.start()
        }
    }
    
    private func onTapArticleURL(articleURL: URL) {
        if let dataStore, let navVC = navigationController {
            let articleCoordinator = ArticleCoordinator(navigationController: navVC, articleURL: articleURL, dataStore: dataStore, theme: theme, source: .activity)
            articleCoordinator.start()
        }
    }
    
    private func onTapEditArticle(item: TimelineItem) {
        ActivityTabFunnel.shared.logActivityTabArticleTap()
        
        guard let articleURL = item.url,
              let revID = item.revisionID,
              let parentID = item.parentRevisionID else {
            return
        }

        var components = URLComponents(url: articleURL, resolvingAgainstBaseURL: false)
        components?.path = "/w/index.php"
        components?.queryItems = [
            URLQueryItem(name: "title", value: articleURL.wmf_title),
            URLQueryItem(name: "diff", value: "\(revID)"),
            URLQueryItem(name: "oldid", value: "\(parentID)")
        ]

        if let diffURL = components?.url {
            navigate(to: diffURL)
        }
    }
    
    // MARK: - Theming

    public func apply(theme: Theme) {
        guard viewIfLoaded != nil else {
            return
        }
        updateProfileButton()
        profileCoordinator?.theme = theme
        self.theme = theme
    }

    // MARK: - Reachability

    private lazy var reachabilityNotifier: ReachabilityNotifier = {
        let notifier = ReachabilityNotifier(Configuration.current.defaultSiteDomain) { [weak self] (reachable, flags) in
            if reachable {
                DispatchQueue.main.async {
                    self?.hideOfflineAlertIfNeeded()
                }
            } else {
                DispatchQueue.main.async {
                    self?.showOfflineAlertIfNeeded()
                }
            }
        }
        return notifier
    }()

    private func hideOfflineAlertIfNeeded() {
        WMFAlertManager.sharedInstance.dismissAllAlerts()
    }

    private func showOfflineAlertIfNeeded() {
        let title = CommonStrings.noInternetConnection
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: title)
        } else {
            WMFAlertManager.sharedInstance.showErrorAlertWithMessage(title, sticky: false, dismissPreviousAlerts: true)
        }
    }

    lazy var historyDataController: WMFHistoryDataController = {
        let recordsProvider: WMFHistoryDataController.RecordsProvider = { [weak self] in
            guard let self, let dataStore = self.dataStore else { return [] }

            let request: NSFetchRequest<WMFArticle> = WMFArticle.fetchRequest()
            request.predicate = NSPredicate(format: "viewedDate != NULL")
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \WMFArticle.viewedDateWithoutTime, ascending: false),
                NSSortDescriptor(keyPath: \WMFArticle.viewedDate, ascending: false)
            ]
            request.fetchLimit = 1 // we're not using the records provider here, just need it to build the data controller

            do {
                var articles: [HistoryRecord] = []
                let fetched = try dataStore.viewContext.fetch(request)

                for article in fetched {
                    if let viewedDate = article.viewedDate, let pageID = article.pageID {
                        let thumbnailImageWidth = ImageUtils.listThumbnailWidth()
                        let record = HistoryRecord(
                            id: Int(truncating: pageID),
                            title: article.displayTitle ?? article.displayTitleHTML,
                            descriptionOrSnippet: article.capitalizedWikidataDescriptionOrSnippet,
                            shortDescription: article.snippet,
                            articleURL: article.url,
                            imageURL: article.imageURL(forWidth: thumbnailImageWidth)?.absoluteString,
                            viewedDate: viewedDate,
                            isSaved: article.isSaved,
                            snippet: article.snippet,
                            variant: article.variant                        )
                        articles.append(record)
                    }
                }
                return articles
            } catch {
                DDLogError("Error fetching history: \(error)")
                return []
            }
        }

        let deleteRecordAction: WMFHistoryDataController.DeleteRecordAction = { [weak self] historyItem in

            guard let self else { return }

            guard let databaseKey = historyItem.url?.wmf_databaseKey else { return }

            Task { @MainActor [weak self] in
                guard let self, let dataStore = self.dataStore else { return }

                let context = dataStore.viewContext
                context.perform { [weak self] in
                    guard let self else { return }

                    let request: NSFetchRequest<WMFArticle> = WMFArticle.fetchRequest()
                    request.predicate = NSPredicate(format: "key == %@", databaseKey)
                    request.fetchLimit = 1

                    do {
                        if let article = try context.fetch(request).first {
                            try article.removeFromReadHistory()
                        }
                    } catch {
                        self.showError(error)
                    }
                }
            }
        }

        let controller = WMFHistoryDataController(recordsProvider: recordsProvider)
        controller.deleteRecordAction = deleteRecordAction
        return controller
    }()

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
        presentedViewController?.dismiss(animated: true)
        ActivityTabFunnel.shared.logOnboardingDidTapContinue()
    }

    public func onboardingViewDidClickSecondaryButton() {
        guard let url = learnMoreAboutActivityURL else {
            return
        }

        UIApplication.shared.open(url)

        ActivityTabFunnel.shared.logOnboardingDidTapLearnMore()
    }
    
    @MainActor
    private func presentSurveyIfNeeded() {
        Task { [weak self] in
            
            guard let self else {
                return
            }
            
            guard await dataController.shouldShowSurvey() else {
                return
            }
            
            let surveyView = createSurveyView()
            let hostedView = WMFComponentHostingController(rootView: surveyView)
            present(hostedView, animated: true)
            ActivityTabFunnel.shared.logActivityTabSurveyImpression()
            
            await dataController.setHasSeenSurvey(value: true)
        }
    }
    
    private func createSurveyView() -> WMFSurveyView {
        let surveyLocalizedStrings = WMFSurveyViewModel.LocalizedStrings(
            title: CommonStrings.satisfactionSurveyTitle,
            cancel: CommonStrings.cancelActionTitle,
            submit: CommonStrings.surveySubmitActionTitle,
            subtitle: WMFLocalizedString("activity-tab-survey-subtitle", value: "Help improve Activity. Are you satisfied with this feature?", comment: "Title for activity tab survey."),
            instructions: nil,
            otherPlaceholder: CommonStrings.surveyAdditionalThoughts
        )

        let surveyOptions = [
            WMFSurveyViewModel.OptionViewModel(text: CommonStrings.surveyVerySatisfied, apiIdentifer: "1"),
            WMFSurveyViewModel.OptionViewModel(text: CommonStrings.surveySatisfied, apiIdentifer: "2"),
            WMFSurveyViewModel.OptionViewModel(text: CommonStrings.surveyNeutral, apiIdentifer: "3"),
            WMFSurveyViewModel.OptionViewModel(text: CommonStrings.surveyUnsatisfied, apiIdentifer: "4"),
            WMFSurveyViewModel.OptionViewModel(text: CommonStrings.surveyVeryUnsatisfied, apiIdentifer: "5")
        ]

        return WMFSurveyView(viewModel: WMFSurveyViewModel(localizedStrings: surveyLocalizedStrings, options: surveyOptions, selectionType: .single), cancelAction: { [weak self] in
            
            ActivityTabFunnel.shared.logActivityTabSurveyCancel()
            
            self?.dismiss(animated: true)
        }, submitAction: { [weak self] options, otherText in
            
            ActivityTabFunnel.shared.logFeedbackSubmit(selectedItems: options, comment: otherText)
            
            self?.dismiss(animated: true, completion: {
                let image = UIImage(systemName: "checkmark.circle.fill")
                WMFAlertManager.sharedInstance.showBottomAlertWithMessage(CommonStrings.feedbackSurveyToastTitle, subtitle: nil, image: image, type: .custom, customTypeName: "feedback-submitted", dismissPreviousAlerts: true)
            })
        })
    }
}

final class WMFActivityCustomizeHostingController: WMFComponentHostingController<WMFActivityTabCustomizeView>, WMFNavigationBarConfiguring, UIAdaptivePresentationControllerDelegate {
    
    init(rootView: WMFActivityTabCustomizeView, theme: Theme) {
        self.theme = theme
        super.init(rootView: rootView)
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var theme: Theme

    override func viewDidLoad() {
        super.viewDidLoad()

        let titleConfig = WMFNavigationBarTitleConfig(
            title: CommonStrings.customize,
            customView: nil,
            alignment: .centerCompact
        )
        
        navigationController?.presentationController?.delegate = self

        let closeConfig = WMFNavigationBarCloseButtonConfig(
            text: CommonStrings.doneTitle,
            target: self,
            action: #selector(closeTapped),
            alignment: .trailing
        )

        configureNavigationBar(
            titleConfig: titleConfig,
            closeButtonConfig: closeConfig,
            profileButtonConfig: nil,
            tabsButtonConfig: nil,
            searchBarConfig: nil,
            hideNavigationBarOnScroll: false
        )
    }
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        ActivityTabFunnel.shared.logActivityTabCustomizeExit(
            viewModel: rootView.viewModel
        )
    }

    @objc private func closeTapped() {
        ActivityTabFunnel.shared.logActivityTabCustomizeExit(viewModel: rootView.viewModel)
        dismiss(animated: true)
    }
}
