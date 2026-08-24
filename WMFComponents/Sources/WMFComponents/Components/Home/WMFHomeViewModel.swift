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

    public enum Tab: Int, CaseIterable {
        case forYou
        case community
    }

    let forYouTabTitle = CommonStrings.forYouTabTitle
    let communityTabTitle = WMFLocalizedString("home-community-tab-title", value: "Community", comment: "Title for the Community segment within the Home tab.")
    let editLanguagesTitle = WMFLocalizedString("home-edit-languages-title", value: "Add or edit languages", comment: "Title for the option at the bottom of the Home language menu that opens the languages settings screen.")
    
    let forYouErrorTitle = WMFLocalizedString("for-you-error-title", value: "No internet connection", comment: "Title shown on the For You tab when content cannot be loaded due to a network error.")
    let forYouErrorSubtitle = WMFLocalizedString("for-you-error-subtitle", value: "Connect to the Internet and try again.", comment: "Subtitle shown on the For You tab when content cannot be loaded due to a network error.")
    let forYouErrorRetryTitle = WMFLocalizedString("for-you-error-retry", value: "Try again", comment: "Button on the For You error state that retries loading the feed.")
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
    @Published public var communityPages: [WMFHomeCommunityViewModel] = [] {
        didSet {
            if !communityPages.isEmpty {
                feedDay = Date()
            }
        }
    }
    @Published public var communityFeedError: Error?
    @Published public var isLoadingCommunity: Bool = false
    @Published public var isLoadingCommunityPreviousPage: Bool = false
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

    /// Temporary: when set (app-side), the Community tab hosts this legacy view controller instead of
    /// the native SwiftUI community feed, and the community feed fetch is skipped. Remove once the
    /// community feed rework ships.
    public var makeEmbeddedCommunityViewController: (() -> UIViewController)?

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
            case .emptyFeed:
                self?.logDidTapCustomizeInterests?("feed_empty", "customize_feed")
            }
            self?.didTapCustomizeInterests?()
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
        guard let feedDay, !Calendar.current.isDate(feedDay, inSameDayAs: now) else { return }

        discardLoadedFeeds()
        loadCurrentTabFeedIfNeeded()
    }

    private func discardLoadedFeeds() {
        feedDay = nil
        forYouViewModel = nil
        forYouFeedError = nil
        communityPages = []
        communityFeedError = nil
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
        Task {
            do {
                let response = try await dataController.fetchForYou(project: project)
                self.forYouViewModel = WMFForYouViewModel(response: response)
                self.refreshSavedStates()
            } catch {
                self.forYouFeedError = error
            }
            self.isLoadingForYou = false
        }
    }

    // MARK: - Community

    public func refreshCommunityFeed() async {
        guard let language = selectedLanguage else { return }
        let project = WMFProject.wikipedia(language)
        do {
            let response = try await dataController.fetchCommunity(project: project, forceFetch: true)
            self.communityPages = [WMFHomeCommunityViewModel(response: response, project: project)]
        } catch {
            self.communityFeedError = error
        }
    }

    public func loadCommunityFeedIfNeeded() {
        guard makeEmbeddedCommunityViewController == nil else { return }
        guard communityPages.isEmpty, !isLoadingCommunity else { return }
        guard let language = selectedLanguage else { return }
        let project = WMFProject.wikipedia(language)
        isLoadingCommunity = true
        communityModuleVisibility = WMFCommunityModuleVisibility(
            featuredArticle: dataController.communityFeaturedArticleIsOn(),
            topRead: dataController.communityTopReadIsOn(),
            inTheNews: dataController.communityInTheNewsIsOn(),
            onThisDay: dataController.communityOnThisDayIsOn(),
            pictureOfDay: dataController.communityPictureOfTheDayIsOn()
        )
        hiddenCardKeys = Set(dataController.hiddenCardKeys())
        Task {
            do {
                let response = try await dataController.fetchCommunity(project: project)
                self.communityPages = [WMFHomeCommunityViewModel(response: response, project: project)]
            } catch {
                self.communityFeedError = error
            }
            self.isLoadingCommunity = false
        }
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

    public func loadCommunityPreviousPage() {
        guard !isLoadingCommunityPreviousPage else { return }
        guard let language = selectedLanguage else { return }
        let project = WMFProject.wikipedia(language)
        isLoadingCommunityPreviousPage = true
        Task {
            do {
                let response = try await dataController.fetchCommunityPreviousPage(project: project)
                self.communityPages.append(WMFHomeCommunityViewModel(response: response, project: project))
            } catch {
                self.communityFeedError = error
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
