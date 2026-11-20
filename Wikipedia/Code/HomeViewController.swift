import UIKit
import WMF
import WMFComponents
import WMFData
import WMFNativeLocalizations
import WMFTestKitchen
import CocoaLumberjackSwift

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

    private var isPresentingYearInReview = false

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
        view.accessibilityIdentifier = AccessibilityIdentifiers.Home.view

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
        }
        // Both Community feeds offer "Customize Community feed": the embedded Explore feed from its
        // empty state, the native feed from each module's menu.
        viewModel.didTapCustomizeCommunityFeed = { [weak self] in
            self?.pushCommunityFeedSettings()
        }
        viewModel.didTapForYouCard = { [weak self] article in
            self?.navigateToForYouArticle(article)
        }
        viewModel.isCommunityArticleSaved = { [weak self] title, project in
            guard let self, let articleURL = Self.articleURL(title: title, project: project) else { return false }
            return dataStore.savedPageList.isAnyVariantSaved(articleURL)
        }
        viewModel.didTapCommunityArticle = { [weak self] title, project, module, action in
            self?.performCommunityArticleAction(action, title: title, project: project, module: module)
        }
        viewModel.didTapCommunityTopReadList = { [weak self] titles, project, date in
            self?.pushCommunityTopReadList(titles: titles, project: project, date: date)
        }
        viewModel.didTapCommunityOnThisDay = { [weak self] project, date, event in
            self?.pushCommunityOnThisDay(project: project, date: date, event: event)
        }
        viewModel.didTapCommunityNewsStory = { [weak self] story, project in
            self?.pushCommunityNewsStory(story, project: project)
        }
        viewModel.didTapCommunityPictureOfTheDay = { [weak self] date in
            self?.presentPictureOfTheDayGallery(date: date)
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
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(coreDataStoreSetup), name: WMFNSNotification.coreDataStoreSetup, object: nil)

        apply(theme: theme)
    }

    @objc private func dayMayHaveChanged() {
        viewModel.refreshFeedsIfDayChanged()
    }

    @objc private func applicationDidBecomeActive() {
        // Home stays alive in the tab bar when another tab is on screen. Only run when Home is visible.
        guard viewIfLoaded?.window != nil else { return }
        presentYearInReviewAnnouncementIfNeeded()
    }
    
    @objc private func coreDataStoreSetup() {
        // The store is ready now, so the data controller and coordinator can be built.
        configureNavigationBar()

        // Same visibility check as applicationDidBecomeActive().
        guard viewIfLoaded?.window != nil else { return }
        presentYearInReviewAnnouncementIfNeeded()
    }

    // MARK: - Year in Review Announcement

    /// The Community segment embeds Explore, which runs its own modal chain. So this only runs when
    /// that embedded feed is not on screen, such as on the For You segment.
    private func presentYearInReviewAnnouncementIfNeeded() {
        guard _embeddedExploreViewController?.viewIfLoaded?.window == nil else { return }
        guard !isPresentingYearInReview, canShowModalNow, let yirCoordinator else { return }

        isPresentingYearInReview = true
        Task { [weak self] in
            guard let self else { return }
            defer { isPresentingYearInReview = false }

            // TODO: Confirm the logging ID for Home with data before release.
            if await yirCoordinator.presentFeatureAnnouncement(introSlideLoggingID: "") {
                updateProfileButton()
            }
        }
    }

    /// Home decides whether a pop-up may show now. The coordinator only loads, shows and reports back.
    private var canShowModalNow: Bool {
        guard WMFYearInReviewDataController.AnnouncementPresentationContext.home(isFromDeepLink: didOpenAppFromExternalLink).allowsAnnouncement else {
            return false
        }

        if UIDevice.current.userInterfaceIdiom == .pad, navigationController?.navigationBar.isHidden == true {
            return false
        }

        guard let navigationController,
              presentedViewController == nil,
              navigationController.presentedViewController == nil,
              isViewLoaded, view.window != nil else {
            return false
        }
        return true
    }

    /// True when this session was started by a deep link. Set by `WMFAppViewController`, which is
    /// told about the link when `SceneDelegate` routes it. Modals are suppressed in that case so we
    /// do not interrupt whatever the link was pointing at. The embedded Explore feed runs its own
    /// modal chain, so it gets the same value.
    var didOpenAppFromExternalLink = false {
        didSet {
            _embeddedExploreViewController?.didOpenAppFromExternalLink = didOpenAppFromExternalLink
        }
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

    /// Opens the Picture of the day gallery from the native Community feed, the same way the legacy
    /// Explore feed opens it from its card.
    private func presentPictureOfTheDayGallery(date: Date) {
        let gallery = WMFPOTDImageGalleryViewController(dates: [date], theme: theme, overlayViewTopBarHidden: false)
        present(gallery, animated: true)
    }

    /// Opens an In the news story with its linked articles, the screen the legacy Explore feed
    /// opens from its news card. Android opens the tapped story too.
    private func pushCommunityNewsStory(_ newsItem: WMFFeedNewsItem, project: WMFProject) {
        let story = WMFFeedNewsStory(newsItem: newsItem, languageVariantCode: project.languageVariantCode)
        let newsViewController = NewsViewController(stories: [story], dataStore: dataStore, contentGroup: nil, theme: theme)
        navigationController?.pushViewController(newsViewController, animated: true)
    }

    /// The article URL of a Community card's article. Cards carry a `WMFProject` and a database
    /// title, so the translation to a legacy article URL happens here on the app side.
    private static func articleURL(title: String, project: WMFProject) -> URL? {
        guard let siteURL = project.siteURL,
              var articleURL = siteURL.wmf_URL(withTitle: title) else { return nil }
        articleURL.wmf_languageVariantCode = project.languageVariantCode
        return articleURL
    }

    /// Acts on an article of the native Community feed (Home phase 2): a tap, the long-press menu
    /// or the Save button. The actions match the Explore feed's article cards.
    private func performCommunityArticleAction(_ action: WMFCommunityArticleAction, title: String, project: WMFProject, module: WMFCommunityModule) {
        guard let articleURL = Self.articleURL(title: title, project: project) else { return }
        switch action {
        case .open:
            openCommunityArticle(articleURL, module: module, tabConfig: .appendArticleAndAssignCurrentTab)
        case .openInNewTab:
            WMFArticleTabsDataController.shared.didTapOpenNewTab()
            ArticleTabsFunnel.shared.logLongPressOpenInNewTab()
            openCommunityArticle(articleURL, module: module, tabConfig: .appendArticleAndAssignNewTabAndSetToCurrent)
        case .openInBackgroundTab:
            openCommunityArticleInBackgroundTab(articleURL, title: title, project: project)
        case .save:
            dataStore.savedPageList.addSavedPage(with: articleURL)
        case .unsave:
            dataStore.savedPageList.removeEntry(with: articleURL)
        case .share:
            presentShareSheet(for: articleURL)
        }
    }

    /// The share sheet is a popover on iPad. The card menus give no source rect, so it is centered
    /// with no arrow.
    private func presentShareSheet(for articleURL: URL) {
        let activityVC = UIActivityViewController(activityItems: [articleURL], applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        present(activityVC, animated: true)
    }

    private func openCommunityArticle(_ articleURL: URL, module: WMFCommunityModule, tabConfig: ArticleTabConfig) {
        let source: ArticleSource
        switch module {
        case .featuredArticle: source = .homeFeedCommunityFeaturedArticleCard
        case .topRead: source = .homeFeedCommunityTopReadCard
        case .onThisDay: source = .homeFeedCommunityOnThisDayCard
        // These two do not open a single article: a story opens its own screen, and the
        // picture opens the gallery.
        case .inTheNews, .pictureOfDay: source = .undefined
        }
        let coordinator = ArticleCoordinator(
            navigationController: navigationController ?? UINavigationController(),
            articleURL: articleURL,
            dataStore: dataStore,
            theme: theme,
            source: source,
            tabConfig: tabConfig
        )
        coordinator.start()
    }

    /// "Open in background tab", the same way the Discover reading list does it: a new tab that
    /// does not become current, or the current tab when the tab limit is reached.
    private func openCommunityArticleInBackgroundTab(_ articleURL: URL, title: String, project: WMFProject) {
        Task {
            do {
                let articleTabsDataController = WMFArticleTabsDataController.shared
                articleTabsDataController.didTapOpenNewTab()

                let tabsCount = try await articleTabsDataController.tabsCount()
                let tabsMax = articleTabsDataController.tabsMax
                let article = WMFArticleTabsDataController.WMFArticle(identifier: nil, title: title, project: project, articleURL: articleURL)
                if tabsCount >= tabsMax {
                    if let currentTabIdentifier = try await articleTabsDataController.currentTabIdentifier() {
                        _ = try await articleTabsDataController.appendArticle(article, toTabIdentifier: currentTabIdentifier)
                    } else {
                        _ = try await articleTabsDataController.createArticleTab(initialArticle: article)
                    }
                    try await Task.sleep(for: .seconds(1))
                    WMFToastManager.sharedInstance.showRichToast(String.localizedStringWithFormat(CommonStrings.articleTabsLimitToastFormat, tabsMax), subtitle: nil, image: WMFSFSymbolIcon.for(symbol: .exclamationMarkTriangleFill), dismissPreviousToasts: true)
                } else {
                    _ = try await articleTabsDataController.createArticleTab(initialArticle: article, setAsCurrent: false)
                    ArticleTabsFunnel.shared.logLongPressOpenInBackgroundTab()
                }
            } catch {
                DDLogError("Failed to create background tab: \(error)")
            }
        }
    }

    /// "More top read": the day's full most read list, the list the Explore card's footer opens.
    private func pushCommunityTopReadList(titles: [String], project: WMFProject, date: Date) {
        let articleURLs = titles.compactMap { Self.articleURL(title: $0, project: project) }
        guard !articleURLs.isEmpty else { return }
        let listViewController = ArticleURLListViewController(articleURLs: articleURLs, dataStore: dataStore, theme: theme)
        let title = WMFCommunityModule.topRead.title(languageCode: project.languageCode)
        listViewController.title = title
        listViewController.headerTitle = title
        listViewController.headerSubtitle = DateFormatter.wmf_long().string(from: date)
        navigationController?.pushViewController(listViewController, animated: true)
    }

    /// "More on this day", or a tap on an event: every event of the day, the screen the Explore
    /// card opens. After a tap on an event the list opens at that event.
    private var onThisDayLoadTask: Task<Void, Never>?

    private func pushCommunityOnThisDay(project: WMFProject, date: Date, event: (year: Int, text: String)?) {
        // A second tap while the list loads is ignored, so the list is pushed once.
        guard onThisDayLoadTask == nil else { return }
        // Gregorian like the data controller, so a device set to another calendar asks for the same day.
        let calendar = Calendar(identifier: .gregorian)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        onThisDayLoadTask = Task { [weak self] in
            defer { self?.onThisDayLoadTask = nil }
            do {
                let response = try await WMFOnThisDayDataController.shared.fetchOnThisDay(project: project, month: month, day: day)
                // The reader may have left Home while the list loaded. Then it is not pushed on
                // top of whatever they opened.
                guard let self, self.isOnScreenForCommunityOnThisDay else { return }
                let events = response.events.map { WMFFeedOnThisDayEvent(event: $0, languageVariantCode: project.languageVariantCode) }
                guard !events.isEmpty else { return }
                let midnightUTCDate: Date = (date as NSDate).wmf_midnightUTCDateFromLocal
                let onThisDayViewController = OnThisDayViewController(events: events, dataStore: self.dataStore, midnightUTCDate: midnightUTCDate, contentGroup: nil, theme: self.theme)
                if let event, let index = WMFHomeCommunityViewModel.onThisDayEventIndex(year: event.year, text: event.text, in: response.events) {
                    onThisDayViewController.initialEvent = events[index]
                }
                self.navigationController?.pushViewController(onThisDayViewController, animated: true)
            } catch {
                DDLogError("Failed to load On this day events: \(error)")
                // Same rule for the error: it is not shown over a screen the reader opened since.
                guard let self, self.isOnScreenForCommunityOnThisDay else { return }
                WMFToastManager.sharedInstance.showErrorAlert(error, sticky: false, dismissPreviousToasts: true)
            }
        }
    }

    /// True while Home is the screen the reader sees: on top of its navigation stack, with nothing
    /// presented over it.
    private var isOnScreenForCommunityOnThisDay: Bool {
        navigationController?.topViewController === self && presentedViewController == nil
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
        presentShareSheet(for: articleURL)
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
        presentYearInReviewAnnouncementIfNeeded()
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
        if tab == .forYou, #unavailable(iOS 26.0) {
            navController.setTransparentAppearance(false)
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = Theme.black.colors.chromeBackground
            appearance.shadowColor = .clear
            navController.navigationBar.standardAppearance = appearance
            navController.navigationBar.scrollEdgeAppearance = appearance
            navController.navigationBar.compactAppearance = appearance
            if #available(iOS 18.0, *) {
                navController.navigationBar.compactScrollEdgeAppearance = appearance
            }
        } else {
            navController.setTransparentAppearance(tab == .forYou)
        }
    }

    private func updateTabBarAppearance(for tab: WMFHomeViewModel.Tab) {
        guard #unavailable(iOS 26.0), let appViewController = tabBarController as? WMFAppViewController else { return }
        appViewController.applyTabBarTheme(tab == .forYou ? .black : theme)
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
    /// Opens the "Customize the home feed" screen from the For You empty state.
    ///
    /// This method pushes the screen. The coordinator adds a close button only to the deep-linked
    /// screens, so a modal root screen gives the reader no way to close it.
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
        vc.didOpenAppFromExternalLink = didOpenAppFromExternalLink
        vc.additionalSafeAreaInsets = UIEdgeInsets(top: 16, left: 0, bottom: 0, right: 0)
        vc.notificationsCenterPresentationDelegate = tabBarController as? NotificationsCenterPresentationDelegate
        vc.onEmbeddedEmptyStateChange = { [weak self] isEmpty in
            self?.viewModel.isEmbeddedCommunityFeedEmpty = isEmpty
        }
        vc.apply(theme: theme)
        _embeddedExploreViewController = vc
        return vc
    }

    /// Opens the feed settings from the Community empty state. Temporary: remove this method with the
    /// community feed rework.
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
