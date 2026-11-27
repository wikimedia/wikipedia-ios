import UIKit
import WMF
import WMFComponents
import WMFData
import WMFNativeLocalizations
import WMFTestKitchen
import CocoaLumberjackSwift

@MainActor
final class HomeCoordinator: NSObject, TabRootCoordinator {

    let tab: WMFAppTabType = .main

    // The Home tab's navigation controller. Injected via `attach(navigationController:)` once the
    // Home view controller has been wrapped in its tab navigation controller.
    private var tabNavigationController: UINavigationController?
    var navigationController: UINavigationController {
        guard let tabNavigationController else {
            fatalError("HomeCoordinator.navigationController accessed before attach(navigationController:)")
        }
        return tabNavigationController
    }

    var theme: Theme
    let dataStore: MWKDataStore

    private(set) weak var homeViewController: HomeViewController?
    
    private var homeFeedInstrument: InstrumentImpl?
    private var homeFeedSettingsCoordinator: HomeFeedSettingsCoordinator?
    private var onThisDayLoadTask: Task<Void, Never>?

    init(theme: Theme, dataStore: MWKDataStore) {
        self.theme = theme
        self.dataStore = dataStore
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(handleEnableHomePhase2DidChange), name: WMFNSNotification.enableHomePhase2DidChange, object: nil)
    }

    /// Rebuilds the Home tab when the phase 2 flag is toggled so the Community segment swaps between
    /// the embedded legacy Explore feed and the new community feed without an app relaunch.
    @objc private func handleEnableHomePhase2DidChange() {
        guard tabNavigationController != nil else { return }
        start()
    }

    var rootViewController: UIViewController {
        homeViewController ?? makeHomeViewController()
    }

    func apply(theme: Theme) {
        self.theme = theme
    }

    func tabWasReselected() {
        homeViewController?.scrollSelectedFeedToTop()
    }

    func attach(navigationController: UINavigationController) {
        self.tabNavigationController = navigationController
    }

    @discardableResult
    func start() -> Bool {
        let vc = makeHomeViewController()
        navigationController.setViewControllers([vc], animated: false)
        return true
    }

    func makeHomeViewController() -> HomeViewController {
        let viewModel = WMFHomeViewModel()
        
        viewModel.logDidTapLanguagePicker = { [weak self, weak viewModel] languageCode in
            guard let self, let viewModel else { return }
            var actionContext: [String: String]? = nil
            if let languageCode {
                actionContext = ["lang_code": languageCode]
            }
            // Note: purposefully not leaning on homeFeedInstrument property here, as the deck doesn't specify that.
            TestKitchenAdapter.shared.client.getInstrument(name: "apps-home-feed").submitInteraction(action: "click", actionSource: "language_menu", elementId: "language_change", actionContext: actionContext, mediawikiDatabase: self.mediawikiDatabase(for: viewModel))
        }
        
        viewModel.logCardImpression = { [weak self, weak viewModel] module, cardIndex in
            guard let self, let viewModel else { return }
            self.homeFeedInstrument?.submitInteraction(action: "impression", actionSource: module, actionContext: ["index": cardIndex], mediawikiDatabase: self.mediawikiDatabase(for: viewModel))
        }

        viewModel.logCardDidTapShare = { [weak self, weak viewModel] module in
            guard let self, let viewModel else { return }
            self.homeFeedInstrument?.submitInteraction(action: "click", actionSource: module, actionSubtype: "feed_overflow", elementId: "article_share", mediawikiDatabase: self.mediawikiDatabase(for: viewModel))
        }

        viewModel.logCardDidSave = { [weak self, weak viewModel] card in
            guard let self, let viewModel else { return }
            self.homeFeedInstrument?.submitInteraction(action: "click", actionSource: card.module.loggingId, actionSubtype: "feed_overflow", elementId: "article_save", mediawikiDatabase: self.mediawikiDatabase(for: viewModel))
            let articleURL = card.project.siteURL?.wmf_URL(withTitle: card.title)
            ReadingListsFunnel.shared.logSave(category: .article, label: nil, articleURL: articleURL)
        }

        viewModel.logCardDidUnsave = { [weak self, weak viewModel] card in
            guard let self, let viewModel else { return }
            self.homeFeedInstrument?.submitInteraction(action: "click", actionSource: card.module.loggingId, actionSubtype: "feed_overflow", elementId: "article_unsave", mediawikiDatabase: self.mediawikiDatabase(for: viewModel))
            let articleURL = card.project.siteURL?.wmf_URL(withTitle: card.title)
            ReadingListsFunnel.shared.logUnsave(category: .article, label: nil, articleURL: articleURL)
        }

        viewModel.logCardDidTapHideCard = { [weak self, weak viewModel] module in
            guard let self, let viewModel else { return }
            self.homeFeedInstrument?.submitInteraction(action: "click", actionSource: module, actionSubtype: "feed_overflow", elementId: "card_hide", mediawikiDatabase: self.mediawikiDatabase(for: viewModel))
        }

        viewModel.logCardDidTapHideModule = { [weak self, weak viewModel] module in
            guard let self, let viewModel else { return }
            self.homeFeedInstrument?.submitInteraction(action: "click", actionSource: module, actionSubtype: "feed_overflow", elementId: "module_hide", mediawikiDatabase: self.mediawikiDatabase(for: viewModel))
        }

        viewModel.logDidTapCustomizeInterests = { [weak self, weak viewModel] module, elementId in
            guard let self, let viewModel else { return }
            self.homeFeedInstrument?.submitInteraction(action: "click", actionSource: module, actionSubtype: "feed_overflow", elementId: elementId, mediawikiDatabase: self.mediawikiDatabase(for: viewModel))
        }

        viewModel.logEmptyViewImpression = { [weak self, weak viewModel] in
            guard let self, let viewModel else { return }
            self.homeFeedInstrument?.submitInteraction(action: "impression", actionSource: "EmptyForYouCard", mediawikiDatabase: self.mediawikiDatabase(for: viewModel))
        }

        viewModel.logCardDidTapArticle = { [weak self, weak viewModel] module, articleTitle in
            guard let self, let viewModel else { return }
            let project = self.currentProject(forViewModel: viewModel)
            let pageData = TestKitchenAdapter.getPageData(title: articleTitle, project: project)
            self.homeFeedInstrument?.submitInteraction(action: "click", actionSource: module, elementId: "article_open", mediawikiDatabase: self.mediawikiDatabase(for: viewModel), pageData: pageData)
        }
        
        viewModel.logEndOfFeedImpression = { [weak self, weak viewModel] in
            guard let self, let viewModel else { return }
            // Per the data team, this impression ends the home_feed funnel: any event after it
            // must not carry the funnel. Submit first so this event keeps time_spent_ms, then stop.
            self.homeFeedInstrument?.submitInteraction(action: "impression", actionSource: WMFForYouEndOfFeedCardViewModel.loggingId, mediawikiDatabase: self.mediawikiDatabase(for: viewModel))
            self.homeFeedInstrument?.stopFunnel()
        }

        viewModel.logEndOfFeedDidTapCommunity = { [weak self, weak viewModel] in
            guard let self, let viewModel else { return }
            self.homeFeedInstrument?.submitInteraction(action: "click", actionSource: WMFForYouEndOfFeedCardViewModel.loggingId, elementId: "community_feed", mediawikiDatabase: self.mediawikiDatabase(for: viewModel))
        }

        // Before the view controller exists: its view loads the feed, which reads the saved state.
        configureFeedActions(for: viewModel)

        let vc = HomeViewController(dataStore: dataStore, theme: theme, viewModel: viewModel, homeCoordinator: self)
        vc.title = CommonStrings.homeTabTitle
        vc.tabBarItem.image = WMFSFSymbolIcon.for(symbol: .house)
        vc.tabBarItem.accessibilityIdentifier = AccessibilityIdentifiers.RootTab.homeButton
        vc.apply(theme: theme)

        homeViewController = vc
        return vc
    }
    
    // MARK: - Feed actions

    /// Connects the actions of both feeds to the screens they open. The view model calls these
    /// closures; the coordinator does the navigation, as for the other features of the app.
    private func configureFeedActions(for viewModel: WMFHomeViewModel) {
        viewModel.isArticleSaved = { [weak self] card in
            guard let self, let articleURL = Self.articleURL(for: card) else { return false }
            return self.dataStore.savedPageList.isAnyVariantSaved(articleURL)
        }
        viewModel.isCommunityArticleSaved = { [weak self] title, project in
            guard let self, let articleURL = Self.articleURL(title: title, project: project) else { return false }
            return self.dataStore.savedPageList.isAnyVariantSaved(articleURL)
        }

        // For You
        viewModel.didTapForYouCard = { [weak self] article in
            self?.openForYouArticle(article)
        }
        viewModel.didSaveForYouCard = { [weak self] article in
            guard let self, let articleURL = Self.articleURL(for: article) else { return }
            self.dataStore.savedPageList.addSavedPage(with: articleURL)
        }
        viewModel.didTapUnsaveForYouCard = { [weak self] article in
            guard let self, let articleURL = Self.articleURL(for: article) else { return }
            self.dataStore.savedPageList.removeEntry(with: articleURL)
        }
        viewModel.didShareForYouCard = { [weak self] article in
            guard let self, let articleURL = Self.articleURL(for: article) else { return }
            self.presentShareSheet(for: articleURL)
        }
        viewModel.didInteractWithForYouFeed = {
            // The reading list toast sits over the bottom of a card, so get it out of the way as
            // soon as the user swipes. Posting with no toast on screen is a no-op.
            NotificationCenter.default.post(name: NSNotification.dismissReadingListToast, object: nil)
        }

        // Community
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

        // Settings
        viewModel.didTapCustomizeInterests = { [weak self] in
            self?.presentInterestsSettings()
        }
        viewModel.didTapCustomizeHomeFeed = { [weak self] in
            self?.pushHomeFeedSettings()
        }
        // Both Community feeds offer "Customize Community feed": the embedded Explore feed from its
        // empty state, the native feed from each module's menu.
        viewModel.didTapCustomizeCommunityFeed = { [weak self] in
            self?.pushCommunityFeedSettings()
        }
    }

    // MARK: - Article URLs

    /// The article URL a For You card points at. Cards carry a `WMFProject` and a title, so the
    /// translation to a legacy article URL happens here on the app side.
    static func articleURL(for card: WMFForYouArticleCardViewModel) -> URL? {
        articleURL(title: card.title, project: card.project)
    }

    /// The article URL of an article in either feed, from its `WMFProject` and its database title.
    static func articleURL(title: String, project: WMFProject) -> URL? {
        guard let siteURL = project.siteURL,
              var articleURL = siteURL.wmf_URL(withTitle: title) else { return nil }
        articleURL.wmf_languageVariantCode = project.languageVariantCode
        return articleURL
    }

    // MARK: - Presenting

    /// Modal screens open from the Home view controller, as before the move, so that a check such
    /// as its `presentedViewController` still sees them.
    private var presenter: UIViewController? {
        homeViewController ?? tabNavigationController
    }

    /// The share sheet is a popover on iPad. The card menus give no source rect, so it is centered
    /// with no arrow.
    private func presentShareSheet(for articleURL: URL) {
        guard let presenter else { return }
        let activityVC = UIActivityViewController(activityItems: [articleURL], applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        presenter.present(activityVC, animated: true)
    }

    /// True while Home is the screen the reader sees: on top of its navigation stack, with nothing
    /// presented over it.
    private var isHomeOnScreen: Bool {
        guard let homeViewController, let tabNavigationController else { return false }
        return tabNavigationController.topViewController === homeViewController && homeViewController.presentedViewController == nil
    }

    // MARK: - For You actions

    private func openForYouArticle(_ article: WMFForYouArticleCardViewModel) {
        guard let tabNavigationController, let articleURL = Self.articleURL(for: article) else { return }
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
            navigationController: tabNavigationController,
            articleURL: articleURL,
            dataStore: dataStore,
            theme: theme,
            source: source,
            tabConfig: .appendArticleAndAssignCurrentTab
        )
        coordinator.start()
    }

    // MARK: - Community actions

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

    private func openCommunityArticle(_ articleURL: URL, module: WMFCommunityModule, tabConfig: ArticleTabConfig) {
        guard let tabNavigationController else { return }
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
            navigationController: tabNavigationController,
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
        guard let tabNavigationController, !articleURLs.isEmpty else { return }
        let listViewController = ArticleURLListViewController(articleURLs: articleURLs, dataStore: dataStore, theme: theme)
        let title = WMFCommunityModule.topRead.title(languageCode: project.languageCode)
        listViewController.title = title
        listViewController.headerTitle = title
        listViewController.headerSubtitle = DateFormatter.wmf_long().string(from: date)
        tabNavigationController.pushViewController(listViewController, animated: true)
    }

    /// "More on this day", or a tap on an event: every event of the day, the screen the Explore
    /// card opens. After a tap on an event the list opens at that event.
    private func pushCommunityOnThisDay(project: WMFProject, date: Date, event: (year: Int, text: String)?) {
        // The last tap wins. A tap while the list loads cancels the load of the earlier tap, so the
        // list opens once, at the event the reader tapped last.
        onThisDayLoadTask?.cancel()
        // Gregorian like the data controller, so a device set to another calendar asks for the same day.
        let calendar = Calendar(identifier: .gregorian)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        onThisDayLoadTask = Task { [weak self] in
            do {
                let response = try await WMFOnThisDayDataController.shared.fetchOnThisDay(project: project, month: month, day: day)
                // The reader may have left Home while the list loaded. Then it is not pushed on
                // top of whatever they opened.
                guard !Task.isCancelled, let self else { return }
                self.onThisDayLoadTask = nil
                guard self.isHomeOnScreen, let tabNavigationController = self.tabNavigationController else { return }
                let events = response.events.map { WMFFeedOnThisDayEvent(event: $0, languageVariantCode: project.languageVariantCode) }
                guard !events.isEmpty else { return }
                let midnightUTCDate: Date = (date as NSDate).wmf_midnightUTCDateFromLocal
                let onThisDayViewController = OnThisDayViewController(events: events, dataStore: self.dataStore, midnightUTCDate: midnightUTCDate, contentGroup: nil, theme: self.theme)
                if let event, let index = WMFHomeCommunityViewModel.onThisDayEventIndex(year: event.year, text: event.text, in: response.events) {
                    onThisDayViewController.initialEvent = events[index]
                }
                tabNavigationController.pushViewController(onThisDayViewController, animated: true)
            } catch {
                guard !Task.isCancelled, let self else { return }
                self.onThisDayLoadTask = nil
                DDLogError("Failed to load On this day events: \(error)")
                // Same rule for the error: it is not shown over a screen the reader opened since.
                guard self.isHomeOnScreen else { return }
                WMFToastManager.sharedInstance.showErrorAlert(error, sticky: false, dismissPreviousToasts: true)
            }
        }
    }

    /// Opens an In the news story with its linked articles, the screen the legacy Explore feed
    /// opens from its news card. Android opens the tapped story too.
    private func pushCommunityNewsStory(_ newsItem: WMFFeedNewsItem, project: WMFProject) {
        guard let tabNavigationController else { return }
        let story = WMFFeedNewsStory(newsItem: newsItem, languageVariantCode: project.languageVariantCode)
        let newsViewController = NewsViewController(stories: [story], dataStore: dataStore, contentGroup: nil, theme: theme)
        tabNavigationController.pushViewController(newsViewController, animated: true)
    }

    /// Opens the Picture of the day gallery from the native Community feed, the same way the legacy
    /// Explore feed opens it from its card.
    private func presentPictureOfTheDayGallery(date: Date) {
        let gallery = WMFPOTDImageGalleryViewController(dates: [date], theme: theme, overlayViewTopBarHidden: false)
        presenter?.present(gallery, animated: true)
    }

    // MARK: - Settings

    /// Opens the "Customize the home feed" screen from the For You empty state.
    ///
    /// This method pushes the screen. The settings coordinator adds a close button only to the
    /// deep-linked screens, so a modal root screen gives the reader no way to close it.
    private func pushHomeFeedSettings() {
        guard let tabNavigationController else { return }
        let coordinator = HomeFeedSettingsCoordinator(navigationController: tabNavigationController, theme: theme, initialView: .root, presentation: .push)
        homeFeedSettingsCoordinator = coordinator
        coordinator.start()
    }

    /// Opens the interests screen modally, from the "Customize interests" menu action on a card and
    /// from the button on the empty feed.
    private func presentInterestsSettings() {
        guard let tabNavigationController else { return }
        let instrument = TestKitchenAdapter.shared.client.getInstrument(name: "apps-home-feed").startFunnel(name: "feed_customize")
        let coordinator = HomeFeedSettingsCoordinator(navigationController: tabNavigationController, theme: theme, initialView: .interests(instrument), presentation: .modal)
        homeFeedSettingsCoordinator = coordinator
        coordinator.start()
    }

    /// Opens the feed settings from the Community empty state and the native feed's module menu.
    /// Temporary: remove this method with the community feed rework.
    private func pushCommunityFeedSettings() {
        guard let tabNavigationController else { return }
        let feedSettingsVC = ExploreFeedSettingsViewController()
        feedSettingsVC.dataStore = dataStore
        feedSettingsVC.apply(theme: theme)
        tabNavigationController.pushViewController(feedSettingsVC, animated: true)
    }

    // MARK: - Logging helpers

    private func currentProject(forViewModel: WMFHomeViewModel) -> WMFProject {
        let language = forViewModel.selectedLanguage
        return WMFProject.wikipedia(language ?? WMFDataEnvironment.current.primaryAppLanguage ?? WMFLanguage(languageCode: "en", languageVariantCode: nil))
    }
    
    private func mediawikiDatabase(for viewModel: WMFHomeViewModel) -> String {
        return WikimediaProject(wmfProject: currentProject(forViewModel: viewModel)).notificationsApiWikiIdentifier
    }
    
    func startFunnelIfNeeded() {
        
        guard homeFeedInstrument == nil else { return }
        
        self.homeFeedInstrument = TestKitchenAdapter.shared.client.getInstrument(name: "apps-home-feed").startFunnel(name: "home_feed")
    }
    
    func stopFunnelIfNeeded() {
        homeFeedInstrument?.stopFunnel()
        homeFeedInstrument = nil
    }

    // MARK: - One-time Home onboarding

    /// Set by `WMFAppViewController`, because the customization flow loads the main UI when it closes.
    var startFeedCustomization: (@MainActor @Sendable (InstrumentImpl) -> Void)?
    private var oneTimeOnboardingViewController: WMFOnboardingViewController?

    func presentOneTimeOnboardingIfNeeded(isExistingUser: Bool) {
        guard let tabBarController = tabNavigationController?.tabBarController,
              tabBarController.selectedIndex == tab.rawValue,
              navigationController.viewControllers.count == 1,
              tabBarController.presentedViewController == nil else { return }

        // Show the sheet only to a reader who saw the old onboarding, did not see the Home onboarding, and did not see this sheet.
        let hasSeenHomeOnboarding = WMFHomeDataController.shared.hasSeenUpdatedHomeOnboarding()
        let hasSeenOneTimeOnboarding = WMFHomeDataController.shared.hasSeenOneTimeOnboarding()

        guard isExistingUser && !hasSeenOneTimeOnboarding && !hasSeenHomeOnboarding else { return }

        let viewModel = WMFOnboardingViewModel(
            title: WMFLocalizedString(
                "one-time-onboarding-title",
                value: "Explore is now Home, with a new look",
                comment: "Title of the one-time onboarding sheet shown to existing users after the Explore tab is renamed to Home."
            ),
            cells: [
                WMFOnboardingViewModel.WMFOnboardingCellViewModel(
                    icon: WMFSFSymbolIcon.for(symbol: .house),
                    title: WMFLocalizedString(
                        "one-time-onboarding-feature-name-title",
                        value: "A new name",
                        comment: "Title of the 'A new name' feature item on the one-time onboarding sheet."
                    ),
                    subtitle: WMFLocalizedString(
                        "one-time-onboarding-feature-name-body",
                        value: "The Explore feed is now Home, in the same spot as before.",
                        comment: "Description of the 'A new name' feature item on the one-time onboarding sheet."
                    ),
                    tintBlue: true
                ),
                WMFOnboardingViewModel.WMFOnboardingCellViewModel(
                    icon: WMFSFSymbolIcon.for(symbol: .squareSplit),
                    title: WMFLocalizedString(
                        "one-time-onboarding-feature-feed-title",
                        value: "Your feed, two ways",
                        comment: "Title of the 'Your feed, two ways' feature item on the one-time onboarding sheet."
                    ),
                    subtitle: WMFLocalizedString(
                        "one-time-onboarding-feature-feed-body",
                        value: "Discover articles personalized to your interests in For You, or browse Wikipedia's best editorial content in Community.",
                        comment: "Description of the 'Your feed, two ways' feature item on the one-time onboarding sheet."
                    ),
                    tintBlue: true
                ),
                WMFOnboardingViewModel.WMFOnboardingCellViewModel(
                    icon: WMFSFSymbolIcon.for(symbol: .sliderHorizontal3),
                    title: WMFLocalizedString(
                        "one-time-onboarding-feature-control-title",
                        value: "Stay in control",
                        comment: "Title of the 'Stay in control' feature item on the one-time onboarding sheet."
                    ),
                    subtitle: WMFLocalizedString(
                        "one-time-onboarding-feature-control-body",
                        value: "Every recommendation tells you exactly why it's there. You can update your preferences anytime in Settings.",
                        comment: "Description of the 'Stay in control' feature item on the one-time onboarding sheet."
                    ),
                    tintBlue: true
                ),
                WMFOnboardingViewModel.WMFOnboardingCellViewModel(
                    icon: WMFSFSymbolIcon.for(symbol: .globeAmericas),
                    title: WMFLocalizedString(
                        "one-time-onboarding-feature-languages-title",
                        value: "Every language, fully personalized",
                        comment: "Title of the 'Every language, fully personalized' feature item on the one-time onboarding sheet."
                    ),
                    subtitle: WMFLocalizedString(
                        "one-time-onboarding-feature-languages-body",
                        value: "Reading in multiple languages? Each one gets its own experience. Just switch and your new feed is ready.",
                        comment: "Description of the 'Every language, fully personalized' feature item on the one-time onboarding sheet."
                    ),
                    tintBlue: true
                )
            ],
            primaryButtonTitle: WMFLocalizedString(
                "one-time-onboarding-customize-button",
                value: "Customize my feed",
                comment: "Primary button on the one-time onboarding sheet that opens the feed customization flow."
            ),
            secondaryButtonTitle: WMFLocalizedString(
                "one-time-onboarding-auto-setup-button",
                value: "Set it up for me",
                comment: "Secondary button on the one-time onboarding sheet that automatically configures the feed without customization."
            )
        )

        let onboardingVC = WMFOnboardingViewController(viewModel: viewModel)
        onboardingVC.modalPresentationStyle = .pageSheet
        onboardingVC.delegate = self
        oneTimeOnboardingViewController = onboardingVC

        DispatchQueue.main.async {
            tabBarController.present(onboardingVC, animated: true) {
                TestKitchenAdapter.shared.client.getInstrument(name: "apps-home-feed").submitInteraction(action: "impression", actionSource: "feed_announce")
                WMFHomeDataController.shared.setHasSeenOneTimeOnboarding(true)
            }
        }
    }

    func selectFeedChosenInOnboarding() {
        homeViewController?.viewModel.selectedTab = WMFHomeDataController.shared.seeFirstContent() == .personalized ? .forYou : .community
    }
}

// MARK: - WMFOnboardingViewDelegate (one-time Home onboarding)

extension HomeCoordinator: WMFOnboardingViewDelegate {

    func onboardingViewDidClickPrimaryButton() {
        
        let instrument = TestKitchenAdapter.shared.client.getInstrument(name: "apps-home-feed").startFunnel(name: "feed_customize")
        instrument.submitInteraction(action: "click", actionSource: "feed_announce", elementId: "customize_feed")
        
        oneTimeOnboardingViewController?.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            self.oneTimeOnboardingViewController = nil
            self.startFeedCustomization?(instrument)
        }
    }

    func onboardingViewDidClickSecondaryButton() {
        TestKitchenAdapter.shared.client.getInstrument(name: "apps-home-feed").submitInteraction(action: "click", actionSource: "feed_announce", elementId: "accept_default")
        
        WMFHomeDataController.shared.setSeeFirstContent(.community)
        if let homeViewModel = homeViewController?.viewModel {
            homeViewModel.selectedTab = .community
            homeViewModel.loadForYouFeedIfNeeded()
        }
        oneTimeOnboardingViewController?.dismiss(animated: true) { [weak self] in
            self?.oneTimeOnboardingViewController = nil
        }
    }
}
