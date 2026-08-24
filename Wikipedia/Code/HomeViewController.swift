import UIKit
import WMF
import WMFComponents
import WMFData
import WMFNativeLocalizations
import WMFTestKitchen

final class WMFHomeHostingController: WMFComponentHostingController<WMFHomeView> {}

/// App-side root view controller for the Home tab. Hosts the SwiftUI `WMFHomeView` and configures the
/// standard tab navigation bar (profile + tabs buttons), matching the other root tabs.
final class HomeViewController: UIViewController, WMFNavigationBarConfiguring, Themeable {

    private var theme: Theme
    private let dataStore: MWKDataStore
    let viewModel: WMFHomeViewModel
    private let hostingController: WMFHomeHostingController

    private var yirDataController: WMFYearInReviewDataController? {
        return try? WMFYearInReviewDataController()
    }

    private let homeDataController = WMFHomeDataController.shared
    
    private weak var homeCoordinator: HomeCoordinator?

    init(dataStore: MWKDataStore, theme: Theme, viewModel: WMFHomeViewModel, homeCoordinator: HomeCoordinator) {
        self.dataStore = dataStore
        self.theme = theme
        self.viewModel = viewModel
        self.hostingController = WMFHomeHostingController(rootView: WMFHomeView(viewModel: viewModel))
        self.homeCoordinator = homeCoordinator
        super.init(nibName: nil, bundle: nil)
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.accessibilityIdentifier = AccessibilityIdentifiers.RootTab.homeButton

        edgesForExtendedLayout = .all
        extendedLayoutIncludesOpaqueBars = true

        // Assigned before the hosting controller is embedded: embedding runs the SwiftUI `task`,
        // which loads the feed and refreshes saved state. If this closure is still nil at that
        // point, every card reads as unsaved.
        viewModel.isArticleSaved = { [weak self] card in
            guard let self, let articleURL = Self.articleURL(for: card) else { return false }
            return dataStore.savedPageList.isAnyVariantSaved(articleURL)
        }

        embedHostingController()

        viewModel.didSelectLanguage = { [weak self] language in
            self?.selectLanguage(language)
        }
        viewModel.didTapEditLanguages = { [weak self] in
            self?.presentLanguagesViewController()
        }
        viewModel.didTapCustomizeInterests = { [weak self] in
            self?.presentInterestsSettings()
        }
        viewModel.didTapCustomizeHomeFeed = { [weak self] in
            self?.presentHomeFeedSettings()
        }
        // While the reworked community feed (home phase 2) is in development, the Community segment
        // hosts the legacy Explore feed. With phase 2 enabled, the new community feed renders instead.
        if !WMFDeveloperSettingsDataController.shared.enableHomePhase2 {
            viewModel.makeEmbeddedCommunityViewController = { [weak self] in
                self?.embeddedExploreViewController() ?? UIViewController()
            }
            viewModel.didTapCustomizeCommunityFeed = { [weak self] in
                self?.pushCommunityFeedSettings()
            }
        }
        viewModel.didTapForYouCard = { [weak self] article in
            self?.navigateToForYouArticle(article)
        }
        viewModel.didSaveForYouCard = { [weak self] article in
            self?.saveForYouArticle(article)
        }
        viewModel.didShareForYouCard = { [weak self] article in
            self?.shareForYouArticle(article)
        }
        viewModel.didTapUnsaveForYouCard = { [weak self] article in
            self?.unsaveForYouArticle(article)
        }
        viewModel.didInteractWithForYouFeed = {
            // The reading list toast sits over the bottom of a card, so get it out of the way as
            // soon as the user swipes. Posting with no toast on screen is a no-op.
            NotificationCenter.default.post(name: NSNotification.dismissReadingListToast, object: nil)
        }

        viewModel.didChangeTab = { [weak self] tab in
            self?.updateChromeAppearance(for: tab)
        }

        UISegmentedControl.appearance(whenContainedInInstancesOf: [WMFHomeHostingController.self]).backgroundColor = .clear
        reloadLanguages()
        NotificationCenter.default.addObserver(self, selector: #selector(articleDidChange(_:)), name: NSNotification.Name.WMFArticleUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(dayMayHaveChanged), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(dayMayHaveChanged), name: UIApplication.significantTimeChangeNotification, object: nil)

        apply(theme: theme)
    }

    @objc private func dayMayHaveChanged() {
        viewModel.refreshFeedsIfDayChanged()
    }

    /// The article URL a For You card points at. Cards carry a `WMFProject` and a title, so the
    /// translation to a legacy article URL happens here on the app side.
    private static func articleURL(for card: WMFForYouArticleCardViewModel) -> URL? {
        guard let siteURL = card.project.siteURL,
              var articleURL = siteURL.wmf_URL(withTitle: card.title) else { return nil }
        articleURL.wmf_languageVariantCode = card.project.languageVariantCode
        return articleURL
    }

    @objc private func articleDidChange(_ note: Notification) {
        guard let article = note.object as? WMFArticle,
              article.hasChangedValuesForCurrentEventThatAffectSavedState,
              let changedKey = article.inMemoryKey else { return }

        // Only refresh the card for the article that actually changed. Matching on the in-memory
        // key is how the rest of the app identifies an article, and it handles language variants.
        viewModel.refreshSavedStates { card in
            Self.articleURL(for: card)?.wmf_inMemoryKey == changedKey
        }
    }
    
    private func unsaveForYouArticle(_ article: WMFForYouArticleCardViewModel) {
        guard let articleURL = Self.articleURL(for: article) else { return }
        dataStore.savedPageList.removeEntry(with: articleURL)
    }

    private func navigateToForYouArticle(_ article: WMFForYouArticleCardViewModel) {
        guard let articleURL = Self.articleURL(for: article) else { return }
        let source: ArticleSource
        switch article.module {
        case .basedOnInterests:
            source = .homeFeedForYouInterestCard
        case .becauseYouRead:
            source = .homeFeedForYouBecauseYouReadCard
        case .continueReading:
            source = .homeFeedForYouContinueReadingCard
        }
        let coordinator = ArticleCoordinator(
            navigationController: navigationController ?? UINavigationController(),
            articleURL: articleURL,
            dataStore: dataStore,
            theme: theme,
            source: source,
            tabConfig: .appendArticleAndAssignCurrentTab
        )
        coordinator.start()
    }

    private func saveForYouArticle(_ article: WMFForYouArticleCardViewModel) {
        guard let articleURL = Self.articleURL(for: article) else { return }
        dataStore.savedPageList.addSavedPage(with: articleURL)
    }

    private func shareForYouArticle(_ article: WMFForYouArticleCardViewModel) {
        guard let articleURL = Self.articleURL(for: article) else { return }
        let activityVC = UIActivityViewController(activityItems: [articleURL], applicationActivities: nil)
        if UIDevice.current.userInterfaceIdiom == .pad {
            activityVC.popoverPresentationController?.sourceView = view
            activityVC.popoverPresentationController?.sourceRect = view.bounds
        }
        present(activityVC, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        homeCoordinator?.startFunnelIfNeeded()
        configureNavigationBar()
        updateChromeAppearance(for: viewModel.selectedTab)
        reloadLanguages()

        // The notification does not always arrive for changes made by a background sync, so also
        // reconcile whenever the feed comes back on screen.
        viewModel.refreshSavedStates()

        apply(theme: theme)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateChromeAppearance(for: viewModel.selectedTab)
        apply(theme: theme)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        homeCoordinator?.stopFunnelIfNeeded()

        updateChromeAppearance(for: .community)
    }

    // MARK: - Chrome Appearance

    private func updateChromeAppearance(for tab: WMFHomeViewModel.Tab) {
        updateNavigationBarAppearance(for: tab)
        updateNavigationBarItemsAppearance(for: tab)
        updateTabBarAppearance(for: tab)
    }

    private func updateNavigationBarItemsAppearance(for tab: WMFHomeViewModel.Tab) {
        guard #unavailable(iOS 26.0) else { return }

        let isForYou = tab == .forYou
        navigationController?.navigationBar.tintColor = isForYou ? WMFTheme.black.navigationBarTintColor : WMFAppEnvironment.current.theme.navigationBarTintColor
        navigationItem.leftBarButtonItem?.tintColor = isForYou ? Theme.black.colors.logoTintColor : theme.colors.logoTintColor
        updateProfileButton()
    }

    private func updateNavigationBarAppearance(for tab: WMFHomeViewModel.Tab) {
        guard let navController = navigationController as? WMFComponentNavigationController else { return }
        navController.setTransparentAppearance(tab == .forYou)
    }

    private func updateTabBarAppearance(for tab: WMFHomeViewModel.Tab) {
        guard #unavailable(iOS 26.0), let tabBar = tabBarController?.tabBar else { return }
        tabBar.apply(theme: tab == .forYou ? .black : theme)
    }

    // MARK: - Languages

    private func reloadLanguages() {
        let preferredLanguages = dataStore.languageLinkController.preferredLanguages
        viewModel.languages = preferredLanguages.map { WMFLanguage(languageCode: $0.languageCode, languageVariantCode: $0.languageVariantCode) }

        if let persisted = homeDataController.selectedLanguage(), preferredLanguages.contains(where: { $0.languageCode == persisted.languageCode }) {
            viewModel.selectedLanguage = persisted
        } else if let appLanguage = dataStore.languageLinkController.appLanguage {
            viewModel.selectedLanguage = WMFLanguage(languageCode: appLanguage.languageCode, languageVariantCode: appLanguage.languageVariantCode)
        } else if let first = preferredLanguages.first {
            viewModel.selectedLanguage = WMFLanguage(languageCode: first.languageCode, languageVariantCode: first.languageVariantCode)
        }
    }

    private func selectLanguage(_ language: WMFLanguage) {
        homeDataController.setSelectedLanguage(language)
        viewModel.selectedLanguage = language
    }

    private func presentLanguagesViewController() {
        let languagesVC = WMFPreferredLanguagesViewController.preferredLanguagesViewController()
        languagesVC.showExploreFeedCustomizationSettings = true
        languagesVC.delegate = self
        (languagesVC as Themeable?)?.apply(theme: theme)
        let navVC = WMFComponentNavigationController(rootViewController: languagesVC, modalPresentationStyle: .overFullScreen)
        present(navVC, animated: true)
    }

    // MARK: - Interests

    private var homeFeedSettingsCoordinator: HomeFeedSettingsCoordinator?

    /// Opens the interests screen modally, from the "Customize interests" menu action on a card and
    /// from the button on the empty feed.
    /// Opens the root "Customize the home feed" screen, from the For You empty state's button.
    ///
    /// Pushed rather than presented: the coordinator only gives its modal a close button for the
    /// deep-linked screens, so presenting the root modally leaves no way back out of it.
    private func presentHomeFeedSettings() {
        guard let navigationController else { return }
        let coordinator = HomeFeedSettingsCoordinator(navigationController: navigationController, theme: theme, initialView: .root, presentation: .push)
        homeFeedSettingsCoordinator = coordinator
        coordinator.start()
    }

    private func presentInterestsSettings() {
        guard let navigationController else { return }
        let instrument = TestKitchenAdapter.shared.client.getInstrument(name: "apps-home-feed").startFunnel(name: "feed_customize")
        let coordinator = HomeFeedSettingsCoordinator(navigationController: navigationController, theme: theme, initialView: .interests(instrument), presentation: .modal)
        homeFeedSettingsCoordinator = coordinator
        coordinator.start()
    }

    // MARK: - Embedded Explore Feed

    // Temporary: while the native community feed is under development, the Community segment hosts
    // the legacy Explore feed. Remove once the community feed rework ships.
    private var _embeddedExploreViewController: ExploreViewController?
    private func embeddedExploreViewController() -> ExploreViewController {
        if let _embeddedExploreViewController {
            return _embeddedExploreViewController
        }
        let vc = ExploreViewController()
        vc.dataStore = dataStore
        vc.isEmbeddedInHomeTab = true
        vc.additionalSafeAreaInsets = UIEdgeInsets(top: 16, left: 0, bottom: 0, right: 0)
        vc.notificationsCenterPresentationDelegate = tabBarController as? NotificationsCenterPresentationDelegate
        vc.onEmbeddedEmptyStateChange = { [weak self] isEmpty in
            self?.viewModel.isEmbeddedCommunityFeedEmpty = isEmpty
        }
        vc.apply(theme: theme)
        _embeddedExploreViewController = vc
        return vc
    }

    /// Opens the legacy feed settings from the Community segment's empty state. Temporary phase 1 UI —
    /// remove with the community feed rework.
    private func pushCommunityFeedSettings() {
        let feedSettingsVC = ExploreFeedSettingsViewController()
        feedSettingsVC.dataStore = dataStore
        feedSettingsVC.apply(theme: theme)
        navigationController?.pushViewController(feedSettingsVC, animated: true)
    }

    private func embedHostingController() {
        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear
        view.addSubview(hostingController.view)
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hostingController.didMove(toParent: self)
    }

    // MARK: - Coordinators

    private var _yirCoordinator: YearInReviewCoordinator?
    private var yirCoordinator: YearInReviewCoordinator? {
        guard let navigationController, let yirDataController else { return nil }
        if let _yirCoordinator { return _yirCoordinator }
        let coordinator = YearInReviewCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore, dataController: yirDataController)
        coordinator.badgeDelegate = self
        _yirCoordinator = coordinator
        return coordinator
    }

    private lazy var tabsCoordinator: TabsOverviewCoordinator? = { [weak self] in
        guard let self, let nav = self.navigationController else { return nil }
        return TabsOverviewCoordinator(navigationController: nav, theme: self.theme, dataStore: self.dataStore)
    }()

    private var _profileCoordinator: ProfileCoordinator?
    private var profileCoordinator: ProfileCoordinator? {
        guard let navigationController, let yirCoordinator else { return nil }
        if let _profileCoordinator { return _profileCoordinator }
        let coordinator = ProfileCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore, donateSouce: .exploreProfile, logoutDelegate: self, sourcePage: .explore, yirCoordinator: yirCoordinator)
        coordinator.badgeDelegate = self
        _profileCoordinator = coordinator
        return coordinator
    }

    // MARK: - Navigation Bar

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: CommonStrings.homeTabTitle, customView: nil, alignment: .hidden)

        let profileButtonConfig = self.profileButtonConfig(target: self, action: #selector(userDidTapProfile), dataStore: dataStore, yirDataController: yirDataController)
        let tabsButtonConfig = self.tabsButtonConfig(target: self, action: #selector(userDidTapTabs), dataStore: dataStore)

        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: nil, profileButtonConfig: profileButtonConfig, tabsButtonConfig: tabsButtonConfig, searchBarConfig: nil, hideNavigationBarOnScroll: false)

        if #available(iOS 26.0, *) {
            let transparentAppearance = UINavigationBarAppearance()
            transparentAppearance.configureWithTransparentBackground()
            navigationItem.standardAppearance = transparentAppearance
            navigationItem.scrollEdgeAppearance = transparentAppearance
            navigationItem.compactAppearance = transparentAppearance
        }

        let logoBarButtonItem = UIBarButtonItem(image: UIImage(named: "W"), style: .plain, target: self, action: #selector(userDidTapLogo))
        logoBarButtonItem.accessibilityLabel = CommonStrings.homeScrollToTopAccessibilityLabel
        navigationItem.leftBarButtonItem = logoBarButtonItem
        if #unavailable(iOS 26.0) {
            logoBarButtonItem.tintColor = theme.colors.logoTintColor
        }
    }

    @objc func userDidTapLogo() {
        scrollSelectedFeedToTop()
    }

    func scrollSelectedFeedToTop() {
        if viewModel.selectedTab == .community, let embeddedExploreViewController = _embeddedExploreViewController {
            embeddedExploreViewController.scrollToTop()
            return
        }

        viewModel.scrollSelectedFeedToTop()
    }

    @objc func userDidTapTabs() {
        tabsCoordinator?.start()
        ArticleTabsFunnel.shared.logIconClick(interface: .feed, project: nil)
    }

    @objc func userDidTapProfile() {
        guard let languageCode = dataStore.languageLinkController.appLanguage?.languageCode,
              DonateCoordinator.metricsID(for: .exploreProfile, languageCode: languageCode) != nil else {
            return
        }
        profileCoordinator?.start()
    }

    func updateProfileButton() {
        let config = self.profileButtonConfig(target: self, action: #selector(userDidTapProfile), dataStore: dataStore, yirDataController: yirDataController)
        updateNavigationBarProfileButton(needsBadge: config.needsBadge, needsBadgeLabel: CommonStrings.profileButtonBadgeTitle, noBadgeLabel: CommonStrings.profileButtonTitle, theme: navigationBarItemsTheme)
    }

    /// The theme for the buttons of the navigation bar. For You is always dark, and before iOS 26 the
    /// buttons do not get that from the theme of the app.
    private var navigationBarItemsTheme: WMFTheme {
        guard #unavailable(iOS 26.0), viewModel.selectedTab == .forYou else {
            return WMFAppEnvironment.current.theme
        }
        return WMFTheme.black
    }

    // MARK: - Themeable

    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else { return }
        updateProfileButton()
        profileCoordinator?.theme = theme
        _embeddedExploreViewController?.apply(theme: theme)
        if #unavailable(iOS 26.0) {
            navigationItem.leftBarButtonItem?.tintColor = theme.colors.logoTintColor
        }

        updateChromeAppearance(for: viewModel.selectedTab)
    }
}

extension HomeViewController: LogoutCoordinatorDelegate {
    func didTapLogout(authInstrument: InstrumentImpl) {
        wmf_showKeepSavedArticlesOnDevicePanelIfNeeded(triggeredBy: .logout, theme: theme, authInstrument: authInstrument) {
            self.dataStore.authenticationManager.logout(initiatedBy: .user, authInstrument: authInstrument)
        }
    }
}

extension HomeViewController: YearInReviewBadgeDelegate {
    func updateYIRBadgeVisibility() {
        updateProfileButton()
    }
}

extension HomeViewController: WMFPreferredLanguagesViewControllerDelegate {
    func languagesController(_ controller: WMFPreferredLanguagesViewController, didUpdatePreferredLanguages languages: [MWKLanguageLink]) {
        reloadLanguages()
    }
}
