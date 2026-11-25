import Foundation
import SwiftUI
import UIKit
import WMFData
import WMFNativeLocalizations

@MainActor
public final class WMFHomeViewModel: ObservableObject {

    public var didTapForYouCard: ((WMFForYouArticleCardViewModel) -> Void)?
    public var didSaveForYouCard: ((WMFForYouArticleCardViewModel) -> Void)?
    public var didTapUnsaveForYouCard: ((WMFForYouArticleCardViewModel) -> Void)?
    public var didShareForYouCard: ((WMFForYouArticleCardViewModel) -> Void)?
    public var isArticleSaved: ((WMFForYouArticleCardViewModel) -> Bool)?

    public var didInteractWithForYouFeed: (() -> Void)?

    public var didChangeTab: (@MainActor @Sendable (Tab) -> Void)?
    
    public var logDidTapLanguagePicker: (@MainActor @Sendable (String?) -> Void)?
    private var lastLoggedImpressionCardKey: String?
    public var logCardImpression: (@MainActor @Sendable (String, Int) -> Void)?
    public var logCardDidTapShare: (@MainActor @Sendable (String) -> Void)?
    public var logCardDidSave: (@MainActor @Sendable (WMFForYouArticleCardViewModel) -> Void)?
    public var logCardDidUnsave: (@MainActor @Sendable (WMFForYouArticleCardViewModel) -> Void)?
    public var logCardDidTapHideCard: (@MainActor @Sendable (String) -> Void)?
    public var logCardDidTapHideModule: (@MainActor @Sendable (String) -> Void)?
    public var logDidTapCustomizeInterests: (@MainActor @Sendable (String, String) -> Void)?
    public var logEmptyViewImpression: (@MainActor @Sendable () -> Void)?
    public var logCardDidTapArticle: (@MainActor @Sendable (String, String) -> Void)?
    public var logEndOfFeedImpression: (@MainActor @Sendable () -> Void)?
    public var logEndOfFeedDidTapCommunity: (@MainActor @Sendable () -> Void)?

    public enum Tab: Int, CaseIterable {
        case forYou
        case community
    }

    // Like Android, the Home header follows the feed's wiki language: the segment titles and the
    // language menu's settings row. The date above each day and the card menus follow the app.
    var feedLanguageCode: String? { selectedLanguage?.languageCode }

    var forYouTabTitle: String { CommonStrings.forYouTabTitle(languageCode: feedLanguageCode) }
    var communityTabTitle: String {
        WMFLocalizedString("home-community-tab-title", languageCode: feedLanguageCode, value: "Community", comment: "Title for the Community segment within the Home tab.")
    }
    var manageLanguagesTitle: String {
        WMFLocalizedString("home-manage-languages-title", languageCode: feedLanguageCode, value: "Manage languages", comment: "Title for the option at the bottom of the Home language menu, on the Community and For You segments. It opens the languages settings screen.")
    }
    var communityEmptyFeedSubtitle: String {
        let format = WMFLocalizedString("home-empty-community-feed-subtitle", languageCode: feedLanguageCode, value: "Turn on %1$@“Community”%2$@ modules to start seeing content curated by contributors across the Wikimedia movement.", comment: "Message shown on the Home tab's Community segment when the reader has turned off every Community module in settings. “Community” matches the segment name. %1$@ and %2$@ are opening and closing bold.")
        return String.localizedStringWithFormat(format, "<b>", "</b>")
    }

    let forYouErrorTitle = WMFLocalizedString("for-you-error-title", value: "No internet connection", comment: "Title shown on the For You tab when content cannot be loaded due to a network error.")
    let forYouErrorSubtitle = WMFLocalizedString("for-you-error-subtitle", value: "Connect to the Internet and try again.", comment: "Subtitle shown on the For You tab when content cannot be loaded due to a network error.")
    let forYouErrorRetryTitle = WMFLocalizedString("for-you-error-retry", value: "Try again", comment: "Button on the For You error state that retries loading the feed.")
    let communityLoadErrorTitle = WMFLocalizedString("home-community-error-title", value: "Could not load content", comment: "Title shown on the Home tab's Community segment, or at the bottom of its feed, when content cannot be loaded for a reason other than a missing internet connection.")

    /// The offline copy only when the reader is offline. Other failures, such as a server error or
    /// a response that cannot be read, would otherwise tell an online reader to connect.
    func communityErrorTitle(for error: Error?) -> String {
        guard let error, !Self.isOfflineError(error) else { return forYouErrorTitle }
        return communityLoadErrorTitle
    }

    func communityErrorSubtitle(for error: Error?) -> String {
        guard let error, !Self.isOfflineError(error) else { return forYouErrorSubtitle }
        return CommonStrings.genericErrorDescription
    }

    nonisolated static func isOfflineError(_ error: Error) -> Bool {
        let offlineCodes: Set<Int> = [
            URLError.notConnectedToInternet.rawValue,
            URLError.networkConnectionLost.rawValue,
            URLError.dataNotAllowed.rawValue
        ]
        var nsError: NSError? = error as NSError
        // Services can wrap the URL error, so follow the underlying errors too.
        while let current = nsError {
            if current.domain == NSURLErrorDomain, offlineCodes.contains(current.code) { return true }
            nsError = current.userInfo[NSUnderlyingErrorKey] as? NSError
        }
        return false
    }

    let forYouRefreshingAccessibilityLabel = WMFLocalizedString("for-you-refreshing-accessibility-label", value: "Loading new content", comment: "Accessibility label for the loading indicator shown while the For You feed refreshes after a pull to refresh.")

    @Published public var selectedTab: Tab = .community {
        didSet {
            guard selectedTab != oldValue else { return }
            didChangeTab?(selectedTab)
        }
    }
    @Published public var languages: [WMFLanguage]
    @Published public var selectedLanguage: WMFLanguage? {
        didSet {
            guard let newValue = selectedLanguage, newValue.id != oldValue?.id else { return }
            discardLoadedFeeds()
            loadCurrentTabFeedIfNeeded()
        }
    }
    @Published public var forYouViewModel: WMFForYouViewModel? {
        didSet {
            configureForYouViewModel()
            if forYouViewModel != nil {
                feedDay = Date()
            }
        }
    }
    @Published public var forYouFeedError: Error?
    @Published public var isLoadingForYou: Bool = false
    @Published public private(set) var isRefreshingForYou: Bool = false
    /// The days of the feed, newest first. Only `setCommunityFirstPage` replaces the first day and
    /// sets `feedDay`. Earlier days are only appended, so an append after midnight cannot hide the
    /// day change from `refreshFeedsIfDayChanged`.
    @Published public var communityPages: [WMFHomeCommunityViewModel] = [] {
        didSet {
            refreshCommunitySavedStates()
        }
    }
    /// Set when the first page fails and there is nothing to show. The tab then shows the error
    /// state instead of the feed.
    @Published public var communityFeedError: Error?
    /// Set when today cannot load but a stored earlier day is on screen, such as on the first
    /// launch of a day while offline. The feed stays, with a note and a retry above it.
    @Published public private(set) var communityTodayError: Error?
    @Published public var isLoadingCommunity: Bool = false
    @Published public var isLoadingCommunityPreviousPage: Bool = false
    /// Set when "See past community content" fails. The feed stays, and its footer offers a retry.
    @Published public private(set) var communityPreviousPageError: Error?

    /// The feed loads in flight. A language change or a refresh cancels them, so that a page of the
    /// previous language or of the previous feed never lands in the new one.
    private var forYouLoadTask: Task<Void, Never>?
    private var communityLoadTask: Task<Void, Never>?
    private var communityPreviousPageTask: Task<Void, Never>?
    @Published public var communityModuleVisibility: WMFCommunityModuleVisibility = WMFCommunityModuleVisibility(
        featuredArticle: true, topRead: true, inTheNews: true, onThisDay: true, pictureOfDay: true
    )

    @Published public var hiddenCardKeys: Set<String> = [] {
        didSet {
            forYouViewModel?.hiddenCardKeys = hiddenCardKeys
        }
    }

    @Published public private(set) var forYouScrollToTopRequestID: Int = 0
    @Published public private(set) var communityScrollToTopRequestID: Int = 0

    public func scrollSelectedFeedToTop() {
        switch selectedTab {
        case .forYou:
            forYouScrollToTopRequestID += 1
        case .community:
            communityScrollToTopRequestID += 1
        }
    }

    let dataController: WMFHomeDataController

    /// Holds the refresh indicator on for its minimum time. Kept so that a second refresh can stop it.
    private(set) var refreshIndicatorTask: Task<Void, Never>?

    private var feedDay: Date?

    public var didSelectLanguage: ((WMFLanguage) -> Void)?
    public var didTapEditLanguages: (() -> Void)?
    public var didTapCustomizeInterests: (() -> Void)?

    /// Opens the "Customize the home feed" screen from the For You empty state.
    public var didTapCustomizeHomeFeed: (@MainActor @Sendable () -> Void)?

    /// Temporary: when set (app-side), the Community tab hosts this legacy view controller instead of
    /// the native SwiftUI community feed, and the community feed fetch is skipped. Remove once the
    /// community feed rework ships.
    public var makeEmbeddedCommunityViewController: (() -> UIViewController)?

    /// True when all the Community cards are hidden and the embedded feed has nothing to show.
    @Published public var isEmbeddedCommunityFeedEmpty: Bool = false

    /// Acts on an article of a Community feed card: the featured article, a top read row or an On
    /// this day page. A tap opens it; the long-press menu and the Save button do the rest. The
    /// title is the database title from the feed response. The module tells the coordinator which
    /// article source to log, the way Android logs one per card type.
    public var didTapCommunityArticle: (@MainActor @Sendable (_ title: String, _ project: WMFProject, _ module: WMFCommunityModule, _ action: WMFCommunityArticleAction) -> Void)?

    func performCommunityArticleAction(_ action: WMFCommunityArticleAction, title: String, project: WMFProject, module: WMFCommunityModule) {
        didTapCommunityArticle?(title, project, module, action)
        switch action {
        case .save:
            savedCommunityArticleKeys.insert(Self.communityArticleKey(title: title, project: project))
        case .unsave:
            savedCommunityArticleKeys.remove(Self.communityArticleKey(title: title, project: project))
        case .open, .openInNewTab, .openInBackgroundTab, .share:
            break
        }
    }

    /// Answers whether the app has an article saved. Set by the coordinator, which owns the saved
    /// list. The feed asks it again whenever the screen comes back, like For You does.
    public var isCommunityArticleSaved: (@MainActor @Sendable (_ title: String, _ project: WMFProject) -> Bool)?

    /// The articles of the loaded Community pages that are saved, keyed by project and title.
    @Published private(set) var savedCommunityArticleKeys: Set<String> = []

    static func communityArticleKey(title: String, project: WMFProject) -> String {
        "\(project.id)|\(title)"
    }

    func isCommunityArticleSaved(title: String, project: WMFProject) -> Bool {
        savedCommunityArticleKeys.contains(Self.communityArticleKey(title: title, project: project))
    }

    public func refreshCommunitySavedStates() {
        guard let isCommunityArticleSaved else { return }
        var saved: Set<String> = []
        for page in communityPages {
            let articles = [page.featuredArticleItem].compactMap { $0 }
                + page.topReadItems
                + (page.onThisDayItems ?? []).flatMap(\.pages)
            for article in articles where isCommunityArticleSaved(article.title, page.project) {
                saved.insert(Self.communityArticleKey(title: article.title, project: page.project))
            }
        }
        if saved != savedCommunityArticleKeys {
            savedCommunityArticleKeys = saved
        }
    }

    /// Opens the day's full Top read list ("More top read").
    public var didTapCommunityTopReadList: (@MainActor @Sendable (_ titles: [String], _ project: WMFProject, _ date: Date) -> Void)?

    func openCommunityTopReadList(for page: WMFHomeCommunityViewModel) {
        didTapCommunityTopReadList?(page.allTopReadTitles, page.project, page.feedDate)
    }

    /// Opens every On this day event of the day ("More on this day"), or, after a tap on an event,
    /// the same list scrolled to that event. The event is given by its year and text.
    public var didTapCommunityOnThisDay: (@MainActor @Sendable (_ project: WMFProject, _ date: Date, _ event: (year: Int, text: String)?) -> Void)?

    func openCommunityOnThisDay(for page: WMFHomeCommunityViewModel, event: WMFHomeCommunityViewModel.OnThisDayItem?) {
        didTapCommunityOnThisDay?(page.project, page.feedDate, event.map { (year: $0.year, text: $0.text) })
    }

    /// Opens an In the news story with all its linked articles.
    public var didTapCommunityNewsStory: (@MainActor @Sendable (_ story: WMFFeedNewsItem, _ project: WMFProject) -> Void)?

    func openCommunityNewsStory(_ story: WMFFeedNewsItem, project: WMFProject) {
        didTapCommunityNewsStory?(story, project)
    }

    /// Opens the Picture of the day gallery for the date of the tapped card, like the legacy Explore
    /// feed and Android do.
    public var didTapCommunityPictureOfTheDay: (@MainActor @Sendable (_ date: Date) -> Void)?

    func openCommunityPictureOfTheDay(date: Date) {
        didTapCommunityPictureOfTheDay?(date)
    }

    /// Opens the Community feed settings from that empty state.
    public var didTapCustomizeCommunityFeed: (@MainActor @Sendable () -> Void)?
    // MARK: - For You view model configuration

    private func configureForYouViewModel() {
        guard let forYouViewModel else { return }

        refreshForYouModuleVisibility()
        forYouViewModel.hiddenCardKeys = hiddenCardKeys
        forYouViewModel.onRefresh = { [weak self] in await self?.refreshForYouFeed() }
        forYouViewModel.onHideModule = { [weak self] in
            self?.logCardDidTapHideModule?($0.module.loggingId)
            self?.hideForYouModule($0.module)
        }
        forYouViewModel.onHideCard = { [weak self] card in
            self?.logCardDidTapHideCard?(card.module.loggingId)
            self?.hideForYouCard(card)
        }
        forYouViewModel.onCustomizeInterests = { [weak self] source in
            switch source {
            case .card(let card):
                self?.logDidTapCustomizeInterests?(card.module.loggingId, "feed_customize")
                self?.didTapCustomizeInterests?()
            case .emptyFeed:
                // From the empty feed the reader can also turn on modules. Open the root screen.
                self?.logDidTapCustomizeInterests?("feed_empty", "customize_feed")
                self?.didTapCustomizeHomeFeed?()
            }
        }
        forYouViewModel.onTapCard = { [weak self] in
            self?.logCardDidTapArticle?($0.module.loggingId, $0.title)
            self?.didTapForYouCard?($0)
        }
        forYouViewModel.onSaveCard = { [weak self] in
            self?.logCardDidSave?($0)
            self?.didSaveForYouCard?($0)
        }
        forYouViewModel.onShareCard = { [weak self] in
            self?.logCardDidTapShare?($0.module.loggingId)
            self?.didShareForYouCard?($0)
        }
        forYouViewModel.onUnsaveCard = { [weak self] in
            self?.logCardDidUnsave?($0)
            self?.didTapUnsaveForYouCard?($0)
        }
        
        forYouViewModel.onEmptyViewAppearance = { [weak self] in
            self?.logEmptyViewImpression?()
        }
        forYouViewModel.endOfFeedViewModel.onTapAddInterests = { [weak self] in
            self?.logDidTapCustomizeInterests?(WMFForYouEndOfFeedCardViewModel.loggingId, "customize_feed")
            self?.didTapCustomizeInterests?()
        }
        forYouViewModel.endOfFeedViewModel.onTapCommunity = { [weak self] in
            self?.logEndOfFeedDidTapCommunity?()
            self?.selectedTab = .community
        }
        forYouViewModel.endOfFeedViewModel.onShow = { [weak self] in
            self?.logEndOfFeedImpression?()
        }
        
        forYouViewModel.onUserInteraction = { [weak self] in self?.didInteractWithForYouFeed?() }
        forYouViewModel.onShowCard = { [weak self] card in
            
            // checking lastLoggedImpressionCardKey prevents duplicate impression events
            guard card.cardUniqueKey != self?.lastLoggedImpressionCardKey else { return }
            self?.logCardImpression?(card.module.loggingId, card.cardIndex)
            self?.lastLoggedImpressionCardKey = card.cardUniqueKey
            
            // The user saw this card, thus the feed does not suggest the article again for some days.
            self?.dataController.recordSeenArticle(title: card.title, project: card.project)
        }
    }

    // MARK: - For You

    public func refreshForYouModuleVisibility() {
        forYouViewModel?.moduleVisibility = WMFForYouModuleVisibility(
            basedOnInterests: dataController.forYouBasedOnInterestsIsOn(),
            becauseYouRead: dataController.forYouBecauseYouReadIsOn(),
            continueReading: dataController.forYouContinueReadingIsOn()
        )
    }


    public func refreshSavedStates() {
        refreshSavedStates(where: { _ in true })
    }

    public func refreshSavedStates(where matches: (WMFForYouArticleCardViewModel) -> Bool) {
        refreshCommunitySavedStates()
        guard let isArticleSaved else { return }
        forYouViewModel?.pages.forEach { page in
            for card in page.articleViewModels where matches(card) {
                card.refreshSavedState(isSaved: isArticleSaved(card))
            }
        }
    }

    public func hideForYouModule(_ module: WMFForYouModule) {
        switch module {
        case .basedOnInterests:
            dataController.setForYouBasedOnInterestsIsOn(false)
        case .becauseYouRead:
            dataController.setForYouBecauseYouReadIsOn(false)
        case .continueReading:
            dataController.setForYouContinueReadingIsOn(false)
        }
        withAnimation {
            refreshForYouModuleVisibility()
        }
    }

    public func hideForYouCard(_ card: WMFForYouArticleCardViewModel) {
        hideCard(key: card.cardUniqueKey)
    }

    public func refreshForYouFeed(minimumIndicatorDuration: TimeInterval = 1) async {
        guard let language = selectedLanguage else { return }
        let project = WMFProject.wikipedia(language)

        refreshIndicatorTask?.cancel()
        isRefreshingForYou = true
        let start = Date()

        do {
            let response = try await dataController.fetchForYou(project: project, forceFetch: true)
            self.forYouViewModel = WMFForYouViewModel(response: response)
            self.forYouFeedError = nil
            self.refreshSavedStates()
        } catch {
            self.forYouFeedError = error
        }

        let remaining = minimumIndicatorDuration - Date().timeIntervalSince(start)
        refreshIndicatorTask = Task { [weak self] in
            if remaining > 0 {
                try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
            }
            self?.isRefreshingForYou = false
        }
    }

    public func loadCurrentTabFeedIfNeeded() {
        switch selectedTab {
        case .forYou:
            loadForYouFeedIfNeeded()
        case .community:
            loadCommunityFeedIfNeeded()
        }
    }

    // MARK: - Daily refresh

    public func refreshFeedsIfDayChanged(now: Date = Date()) {
        guard let feedDay, !Calendar.current.isDate(feedDay, inSameDayAs: now) else {
            loadCommunityTodayIfBehind(now: now)
            return
        }

        discardLoadedFeeds()
        loadCurrentTabFeedIfNeeded()
    }

    private func discardLoadedFeeds() {
        feedDay = nil

        forYouLoadTask?.cancel()
        forYouLoadTask = nil
        isLoadingForYou = false
        forYouViewModel = nil
        forYouFeedError = nil

        communityLoadTask?.cancel()
        communityLoadTask = nil
        isLoadingCommunity = false
        cancelCommunityPreviousPageLoad()
        communityPages = []
        communityFeedError = nil
        communityTodayError = nil
    }

    private func cancelCommunityPreviousPageLoad() {
        communityPreviousPageTask?.cancel()
        communityPreviousPageTask = nil
        isLoadingCommunityPreviousPage = false
        communityPreviousPageError = nil
    }

    public func loadForYouFeedIfNeeded() {
        guard forYouViewModel == nil, !isLoadingForYou else { return }
        forYouFeedError = nil
        isLoadingForYou = true
        hiddenCardKeys = Set(dataController.hiddenCardKeys())

        guard let language = selectedLanguage else {
            isLoadingForYou = false
            return
        }
        let project = WMFProject.wikipedia(language)
        forYouLoadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let response = try await self.dataController.fetchForYou(project: project)
                guard !Task.isCancelled else { return }
                self.forYouViewModel = WMFForYouViewModel(response: response)
                self.refreshSavedStates()
            } catch {
                guard !Task.isCancelled else { return }
                self.forYouFeedError = error
            }
            self.isLoadingForYou = false
        }
    }

    // MARK: - Community

    /// Pull to refresh. The feed starts over at today: the older days it had loaded are dropped.
    /// A failure keeps the feed that is on screen.
    public func refreshCommunityFeed() async {
        guard let language = selectedLanguage else { return }
        await loadCommunityToday(project: WMFProject.wikipedia(language), now: Date(), forceFetch: true)
    }

    /// Opens the feed. A page stored on an earlier launch shows first, with its own date, so the
    /// feed has content before any network answer, also offline. Today then replaces it.
    public func loadCommunityFeedIfNeeded(now: Date = Date()) {
        guard makeEmbeddedCommunityViewController == nil else { return }
        guard communityPages.isEmpty, !isLoadingCommunity else { return }
        guard let language = selectedLanguage else { return }
        let project = WMFProject.wikipedia(language)
        isLoadingCommunity = true
        communityFeedError = nil
        communityTodayError = nil
        refreshCommunityModuleVisibility()
        hiddenCardKeys = Set(dataController.hiddenCardKeys())
        communityLoadTask = Task { [weak self] in
            guard let self else { return }
            if let stored = await self.dataController.lastStoredCommunity(project: project),
               !Task.isCancelled, self.communityPages.isEmpty {
                self.setCommunityFirstPage(stored, project: project, now: now)
            }
            guard !Task.isCancelled else { return }
            await self.loadCommunityToday(project: project, now: now, forceFetch: false)
            guard !Task.isCancelled else { return }
            self.isLoadingCommunity = false
        }
    }

    /// Loads today when the feed shows an earlier day, for example a stored page after a failed
    /// load. Called when the app comes back to the foreground on the same day.
    private func loadCommunityTodayIfBehind(now: Date) {
        guard makeEmbeddedCommunityViewController == nil,
              !isLoadingCommunity,
              let first = communityPages.first,
              first.day < WMFFeedDay.today(now: now),
              let language = selectedLanguage else { return }
        let project = WMFProject.wikipedia(language)
        isLoadingCommunity = true
        communityLoadTask = Task { [weak self] in
            guard let self else { return }
            await self.loadCommunityToday(project: project, now: now, forceFetch: false)
            guard !Task.isCancelled else { return }
            self.isLoadingCommunity = false
        }
    }

    /// Fetches today and puts it at the top of the feed. Yesterday is fetched at the same time:
    /// a small wiki often has nothing yet for today, and then the feed shows yesterday without a
    /// second wait. The fetch of yesterday also serves the first "See past" tap.
    private func loadCommunityToday(project: WMFProject, now: Date, forceFetch: Bool) async {
        let today = WMFFeedDay.today(now: now)
        let dataController = self.dataController
        async let todayResponse = dataController.fetchCommunity(project: project, day: today, forceFetch: forceFetch)
        async let yesterdayResponse = try? dataController.fetchCommunity(project: project, day: today.adding(days: -1))

        do {
            let response = try await todayResponse
            guard !Task.isCancelled, isCurrentCommunityProject(project) else { return }
            setCommunityFirstPage(response, project: project, now: now)
            communityFeedError = nil
            communityTodayError = nil

            guard let first = communityPages.first, !hasCommunityContent(first), !isCommunityFeedEmpty else { return }
            let yesterday = await yesterdayResponse
            guard !Task.isCancelled, isCurrentCommunityProject(project) else { return }
            if let yesterday, let page = appendCommunityPageIfNext(yesterday, project: project), hasCommunityContent(page) {
                return
            }
            loadCommunityPreviousPage()
        } catch {
            guard !Task.isCancelled, isCurrentCommunityProject(project) else { return }
            if communityPages.isEmpty {
                communityFeedError = error
            } else if let first = communityPages.first, first.day < today {
                // A failed pull to refresh over today's feed says nothing, as before. Only an
                // earlier day on screen needs the note: the reader may not know it is not today.
                communityTodayError = error
            }
        }
    }

    /// Replaces the whole feed with one day. This is the only place that sets `feedDay` for
    /// Community, and it stops a "See past" load of the feed it replaces.
    private func setCommunityFirstPage(_ response: WMFCommunityResponse, project: WMFProject, now: Date) {
        cancelCommunityPreviousPageLoad()
        communityPages = [WMFHomeCommunityViewModel(response: response, project: project, now: now)]
        feedDay = now
    }

    /// Appends a day only when it is the day before the oldest day of the feed, in the same wiki.
    /// A day fetched for a feed that a refresh or a language change has replaced fails this
    /// check and is dropped, so a late answer cannot land in the wrong place.
    @discardableResult
    private func appendCommunityPageIfNext(_ response: WMFCommunityResponse, project: WMFProject) -> WMFHomeCommunityViewModel? {
        guard let oldest = communityPages.last,
              oldest.project == project,
              response.day == oldest.day.adding(days: -1) else { return nil }
        let page = WMFHomeCommunityViewModel(response: response, project: project)
        communityPages.append(page)
        return page
    }

    private func isCurrentCommunityProject(_ project: WMFProject) -> Bool {
        selectedLanguage.map { WMFProject.wikipedia($0) } == project
    }

    /// True when the native feed has loaded but every module is turned off in settings. The tab then
    /// shows the empty state, whose button opens those settings.
    ///
    /// Cards hidden from the menu do not count. A day whose cards are all hidden is left out of the
    /// feed, but the feed stays, so the reader can still pull to refresh and reach earlier days.
    /// The settings could not bring those cards back.
    var isCommunityFeedEmpty: Bool {
        !communityPages.isEmpty && WMFCommunityModule.allCases.allSatisfy { !communityModuleVisibility.isOn($0) }
    }

    public func refreshCommunityModuleVisibility() {
        communityModuleVisibility = WMFCommunityModuleVisibility(
            featuredArticle: dataController.communityFeaturedArticleIsOn(),
            topRead: dataController.communityTopReadIsOn(),
            inTheNews: dataController.communityInTheNewsIsOn(),
            onThisDay: dataController.communityOnThisDayIsOn(),
            pictureOfDay: dataController.communityPictureOfTheDayIsOn()
        )
    }

    /// Hides one card in either feed. The key identifies it in both.
    public func hideCard(key: String) {
        guard !hiddenCardKeys.contains(key) else { return }
        dataController.hideCard(key: key)
        withAnimation {
            _ = hiddenCardKeys.insert(key)
        }
    }

    public func hideModule(_ module: WMFCommunityModule) {
        withAnimation {
            switch module {
            case .featuredArticle:
                dataController.setCommunityFeaturedArticleIsOn(false)
                communityModuleVisibility.featuredArticle = false
            case .topRead:
                dataController.setCommunityTopReadIsOn(false)
                communityModuleVisibility.topRead = false
            case .inTheNews:
                dataController.setCommunityInTheNewsIsOn(false)
                communityModuleVisibility.inTheNews = false
            case .onThisDay:
                dataController.setCommunityOnThisDayIsOn(false)
                communityModuleVisibility.onThisDay = false
            case .pictureOfDay:
                dataController.setCommunityPictureOfTheDayIsOn(false)
                communityModuleVisibility.pictureOfDay = false
            }
        }
    }

    /// "See past community content": appends the day before the oldest day in the feed.
    /// How many days with nothing to show one "See past" tap, or the first load, may skip.
    static let maxEmptyCommunityDaysSkipped = 3

    /// True when the page has content for at least one module the reader has on. Hidden cards do
    /// not count: a day the reader emptied by hand stays, so the feed does not jump.
    func hasCommunityContent(_ page: WMFHomeCommunityViewModel) -> Bool {
        !page.visibleModules(visibility: communityModuleVisibility, hiddenCardKeys: []).isEmpty
    }

    public func loadCommunityPreviousPage() {
        guard !isLoadingCommunityPreviousPage,
              let oldest = communityPages.last,
              let language = selectedLanguage else { return }
        let project = WMFProject.wikipedia(language)
        isLoadingCommunityPreviousPage = true
        communityPreviousPageError = nil
        communityPreviousPageTask = Task { [weak self] in
            guard let self else { return }
            do {
                // A day with no content for any module that is on (a small wiki often has only
                // some of them) adds nothing to the feed, so the tap would seem to do nothing.
                // Such days are skipped, up to a limit, so a wiki with no feed content cannot
                // start an endless run of requests.
                var day = oldest.day.adding(days: -1)
                var emptyDaysSkipped = 0
                while true {
                    let response = try await self.dataController.fetchCommunity(project: project, day: day)
                    guard !Task.isCancelled else { return }
                    guard let page = self.appendCommunityPageIfNext(response, project: project),
                          !self.hasCommunityContent(page),
                          emptyDaysSkipped < Self.maxEmptyCommunityDaysSkipped else { break }
                    emptyDaysSkipped += 1
                    day = day.adding(days: -1)
                }
            } catch {
                guard !Task.isCancelled else { return }
                self.communityPreviousPageError = error
            }
            self.isLoadingCommunityPreviousPage = false
        }
    }

    // MARK: - Init

    public init(dataController: WMFHomeDataController = .shared, languages: [WMFLanguage] = [], selectedLanguage: WMFLanguage? = nil, didSelectLanguage: ((WMFLanguage) -> Void)? = nil, didTapEditLanguages: (() -> Void)? = nil) {
        self.dataController = dataController
        self.languages = languages
        self.selectedLanguage = selectedLanguage
        self.didSelectLanguage = didSelectLanguage
        self.didTapEditLanguages = didTapEditLanguages
        self.selectedTab = dataController.seeFirstContent() == .personalized ? .forYou : .community

        NotificationCenter.default.addObserver(self, selector: #selector(handleVisibilityChange), name: WMFNSNotification.communityModuleVisibilityDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleCoreDataStoreSetup), name: WMFNSNotification.coreDataStoreSetup, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleForYouVisibilityChange), name: WMFNSNotification.forYouModuleVisibilityDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleForYouInterestsDidChange), name: WMFNSNotification.forYouInterestsDidChange, object: nil)
    }

    // MARK: - Notification handlers

    @objc private func handleVisibilityChange() {
        refreshCommunityModuleVisibility()
    }

    @objc private func handleCoreDataStoreSetup() {
        loadCurrentTabFeedIfNeeded()
    }

    @objc private func handleForYouVisibilityChange() {
        refreshForYouModuleVisibility()
    }

    @objc private func handleForYouInterestsDidChange() {
        forYouViewModel = nil
        Task { await refreshForYouFeed() }
    }

    // MARK: - Helpers

    var languageButtonTitle: String {
        selectedLanguage?.languageCode.uppercased() ?? ""
    }

    /// The language menu only applies to feeds that follow the Home language selection. The embedded
    /// legacy Explore feed (phase 1 Community segment) manages languages through its own feed
    /// settings, so the picker is hidden while it is showing.
    var shouldShowLanguagePicker: Bool {
        guard selectedTab == .community else { return true }
        return makeEmbeddedCommunityViewController == nil
    }
}
