import UIKit
import WMFNativeLocalizations
import WMFData

@MainActor
public final class WMFAppOnboardingFeedPreferenceViewModel: ObservableObject {

    // MARK: - Strings

    let title = WMFLocalizedString("app-onboarding-feed-preference-title", value: "What would you like to see first?", comment: "Title of the feed preference app onboarding screen, where users choose the content their feed opens on.")
    let communityOptionTitle = WMFLocalizedString("app-onboarding-feed-preference-community-option", value: "Community-related content", comment: "Title of the community content option on the feed preference app onboarding screen.")
    let personalizedOptionTitle = WMFLocalizedString("app-onboarding-feed-preference-personalized-option", value: "Personalized content", comment: "Title of the personalized content option on the feed preference app onboarding screen.")
    let personalizedDisabledExplanation = WMFLocalizedString("app-onboarding-feed-preference-personalized-disabled", value: "You need to add interests to see personalized content suggestions. You can do this in the previous steps or later in Settings.", comment: "Explanation shown on the feed preference app onboarding screen when the personalized content option is unavailable because the user has no interests and no reading history.")
    private let pictureOfTheDayTitle = WMFLocalizedString("app-onboarding-feed-preference-picture-of-the-day", value: "Picture of the day", comment: "Title of the Picture of the Day sample card on the feed preference app onboarding screen.")
    private let inTheNewsTitle = WMFLocalizedString("app-onboarding-feed-preference-in-the-news", value: "In the news", comment: "Title of the In the News sample card on the feed preference app onboarding screen.")

    /// Localized in the *wiki's* language (not the app UI's): it's matched against the story
    /// HTML, which comes from that wiki. Used to find the article a story marks as pictured.
    private var picturedText: String {
        return WMFLocalizedString("pictured", languageCode: project.languageCode, value: "pictured", comment: "Indicates the person or item is pictured (as in a news story).")
    }

    // MARK: - State

    /// The state of one preview row. Every flag the view and the events read comes from this,
    /// so a reset is one assignment and the flags cannot disagree.
    enum PreviewState {
        /// No load started yet, or a reset (new interests or language) discarded the previews.
        case idle
        case loading(Task<Void, Never>)
        /// `isAvailable` is false when the reader has no interests to personalize from.
        /// The community row is always available.
        case loaded(cards: [WMFAppOnboardingPreviewCardViewModel], isAvailable: Bool)

        var isIdle: Bool {
            if case .idle = self { return true }
            return false
        }

        var task: Task<Void, Never>? {
            if case .loading(let task) = self { return task }
            return nil
        }

        var cards: [WMFAppOnboardingPreviewCardViewModel]? {
            if case .loaded(let cards, _) = self { return cards }
            return nil
        }

        var isAvailable: Bool? {
            if case .loaded(_, let isAvailable) = self { return isAvailable }
            return nil
        }
    }

    @Published public private(set) var selection: WMFHomeFeedSeeFirst = .community

    // Internal, not private: tests set a loaded state directly.
    @Published var communityState: PreviewState = .idle {
        didSet { Self.cancelTask(of: oldValue, replacedBy: communityState) }
    }

    @Published var personalizedState: PreviewState = .idle {
        didSet {
            Self.cancelTask(of: oldValue, replacedBy: personalizedState)
            // Every path that makes the option unavailable (a reset for new interests, a load
            // that finds none) moves the choice back to the default here, so none can skip it.
            if selection == .personalized && !isPersonalizedSelectable {
                selection = .community
            }
        }
    }

    /// The community cards, or nil until they are loaded. The pager builds this page before it
    /// is shown, so a reader who swipes to it sees spinners, not empty rows.
    var communityCards: [WMFAppOnboardingPreviewCardViewModel]? {
        return communityState.cards
    }

    var personalizedCards: [WMFAppOnboardingPreviewCardViewModel] {
        return personalizedState.cards ?? []
    }

    /// Whether the reader has interests to personalize from, or nil until the personalized
    /// previews for their current interests are loaded.
    public var isPersonalizedAvailable: Bool? {
        return personalizedState.isAvailable
    }

    /// The personalized option can be chosen only once its data has resolved and confirmed
    /// availability — otherwise a fast user could persist a preference we can't honor.
    var isPersonalizedSelectable: Bool {
        return isPersonalizedAvailable == true
    }

    private let dataController: WMFHomeDataController
    private let summaryDataController: WMFArticleSummaryDataControlling & Sendable
    private(set) var project: WMFProject
    private var warmUpTask: Task<Void, Never>?
    /// The step is on screen and waits for the personalized load to log its impression.
    private var isImpressionPending = false

    // MARK: - App-side actions
    let logImpression: (Bool) -> Void
    let logDidTapCommunity: () -> Void
    let logDidTapPersonalized: () -> Void

    public init(
        dataController: WMFHomeDataController = WMFHomeDataController.shared,
        summaryDataController: WMFArticleSummaryDataControlling & Sendable = WMFArticleSummaryDataController.shared,
        project: WMFProject,
        logImpression: @escaping (Bool) -> Void,
        logDidTapCommunity: @escaping () -> Void,
        logDidTapPersonalized: @escaping () -> Void) {
        self.dataController = dataController
        self.summaryDataController = summaryDataController
        self.project = project
        self.logImpression = logImpression
        self.logDidTapCommunity = logDidTapCommunity
        self.logDidTapPersonalized = logDidTapPersonalized
    }

    // MARK: - Intents

    func select(_ newSelection: WMFHomeFeedSeeFirst) {
        guard newSelection != .personalized || isPersonalizedSelectable else { return }
        switch newSelection {
        case .community:
            logDidTapCommunity()
        case .personalized:
            logDidTapPersonalized()
        }
        selection = newSelection
    }

    /// Skipping onboarding applies the default preference regardless of the current selection.
    public func resetSelectionToDefault() {
        selection = .community
    }

    func interestsDidChange(topics: [WMFArticleTopic], selectedArticleTitles: [String]) {
        // The user swiped back from this step and changed their interests: the personalized
        // previews are stale. Reload them the next time this step is shown. The community
        // previews do not depend on interests.
        personalizedState = .idle
        warmUpTask = Task { [weak self] in
            guard let self else { return }
            await dataController.warmForYouArticles(project: project, topics: topics, pageTitles: selectedArticleTitles)
        }
    }

    /// Called when the user changes their primary app language during onboarding. The previews
    /// normally load after the languages step, but reload defensively if they already did.
    public func updateProject(_ newProject: WMFProject) {
        guard newProject != project else { return }
        project = newProject
        if !communityState.isIdle || !personalizedState.isIdle {
            communityState = .idle
            personalizedState = .idle
            loadIfNeeded()
        }
    }

    /// A reset cancels the load in progress, so it cannot overwrite the new state when it finishes.
    private static func cancelTask(of oldState: PreviewState, replacedBy newState: PreviewState) {
        guard newState.isIdle else { return }
        oldState.task?.cancel()
    }

    /// Warms the feed the user chose, so the Home feed renders immediately after onboarding.
    /// Both fetches are day-cached (and prefetched earlier in the flow), so this is usually fast.
    func loadSelectedFeed() async {
        switch selection {
        case .community:
            _ = try? await dataController.fetchCommunity(project: project)
        case .personalized:
            _ = try? await dataController.fetchForYou(project: project)
        }
    }

    /// Called each time the step is shown. The impression says whether the personalized option
    /// is available, so it waits for the personalized load. When that load is already done (the
    /// user swiped back and forth), log it now.
    func didShow() {
        if let isPersonalizedAvailable {
            logImpression(!isPersonalizedAvailable)
        } else {
            isImpressionPending = true
            loadIfNeeded()
        }
    }

    /// Called when the reader leaves the step: a swipe, Next or Skip. A load that finishes after
    /// this must not log an impression for a step that is not on screen.
    func didLeave() {
        isImpressionPending = false
    }

    private func logPendingImpression() {
        guard isImpressionPending, let isPersonalizedAvailable else { return }
        isImpressionPending = false
        logImpression(!isPersonalizedAvailable)
    }

    public func loadIfNeeded() {
        loadCommunityIfNeeded()
        loadPersonalizedIfNeeded()
    }

    private func loadCommunityIfNeeded() {
        guard communityState.isIdle else { return }

        // Day-cached (and prefetched at onboarding start), so the previews match the Home feed
        communityState = .loading(Task { [weak self] in
            guard let self else { return }
            let community = try? await dataController.fetchCommunity(project: project)
            // A reset (new language) cancels this task and starts a new load.
            guard !Task.isCancelled else { return }
            let cards = community.map { self.buildCommunityCards(from: $0) } ?? []
            self.communityState = .loaded(cards: cards, isAvailable: true)
        })
    }

    private func loadPersonalizedIfNeeded() {
        guard personalizedState.isIdle else { return }

        personalizedState = .loading(Task { [weak self] in
            guard let self else { return }
            let forYou = try? await dataController.fetchForYou(project: project, forceFetch: true)
            guard !Task.isCancelled else { return }
            if let forYou {
                let cards = Self.buildPersonalizedCards(from: forYou, summaryDataController: summaryDataController)
                // Hydrate descriptions before revealing the row, so cards appear fully formed
                await withTaskGroup(of: Void.self) { group in
                    for card in cards {
                        group.addTask { await card.loadSummaryIfNeeded() }
                    }
                }
                guard !Task.isCancelled else { return }
                self.personalizedState = .loaded(cards: cards, isAvailable: Self.personalizedIsAvailable(for: forYou))
                // Start the image downloads now, not on card appearance. When the speculative
                // fetch already put the images in the cache, the cards render complete.
                for card in cards {
                    card.loadImageIfNeeded()
                }
            } else {
                self.personalizedState = .loaded(cards: [], isAvailable: !dataController.interestTopics().isEmpty)
            }
            self.logPendingImpression()
        })
    }

    // The preview loads are not cancelled here: deinit cannot read the main actor-isolated
    // states. A load holds self while it runs, and one that has not started finds self gone.
    deinit {
        warmUpTask?.cancel()
    }

    // MARK: - Test hooks

    /// Lets a test wait until the warm-up is complete.
    func waitForWarmUp() async {
        await warmUpTask?.value
    }

    /// Lets a test wait until both preview rows are loaded.
    func waitForLoadTasks() async {
        await communityState.task?.value
        await personalizedState.task?.value
    }

    // MARK: - Card building (internal for unit testing)

    func buildCommunityCards(from response: WMFCommunityResponse) -> [WMFAppOnboardingPreviewCardViewModel] {
        var cards: [WMFAppOnboardingPreviewCardViewModel] = []

        if let featured = response.feedResponse.todaysFeaturedArticle {
            cards.append(WMFAppOnboardingPreviewCardViewModel(
                displayTitle: featured.displayTitle ?? featured.normalizedTitle ?? featured.title ?? "",
                description: featured.description,
                imageURLString: featured.thumbnail?.source,
                topicPill: nil
            ))
        }

        if let pictureOfDay = response.feedResponse.image {
            cards.append(WMFAppOnboardingPreviewCardViewModel(
                displayTitle: pictureOfTheDayTitle,
                description: pictureOfDay.description?.text,
                imageURLString: pictureOfDay.thumbnail?.source ?? pictureOfDay.image?.source,
                topicPill: nil
            ))
        }

        if let news = response.feedResponse.news?.first {
            // Same rule as the explore feed: the story's "pictured" article when there is one,
            // otherwise the first link that actually has a thumbnail.
            let featured = news.featuredArticle(picturedText: picturedText)
            cards.append(WMFAppOnboardingPreviewCardViewModel(
                displayTitle: inTheNewsTitle,
                description: news.story.map(Self.strippingHTMLTags),
                imageURLString: featured?.thumbnail?.source,
                topicPill: nil
            ))
        }

        return cards
    }

    struct PersonalizedPreviewSelection {
        let article: WMFForYouArticle
        let topicPill: String?
    }

    static func personalizedPreviewSelections(from response: WMFForYouResponse) -> [PersonalizedPreviewSelection] {
        var selections: [PersonalizedPreviewSelection] = []

        for group in response.interestTopicRandomArticles where selections.count < 3 {
            guard let article = group.articles.first else { continue }
            selections.append(PersonalizedPreviewSelection(article: article, topicPill: group.topic.displayName))
        }
        for group in response.interestPageRelatedArticles where selections.count < 3 {
            guard let article = group.articles.first ?? Optional(group.pageInterest) else { continue }
            selections.append(PersonalizedPreviewSelection(article: article, topicPill: nil))
        }

        // Deliberately no reading-history fallback: the preview must show what the user just
        // chose. Articles derived from reading history read as random here, so with no
        // interests the step shows its explanation text instead (see isPersonalizedAvailable).
        return selections
    }

    static func buildPersonalizedCards(from response: WMFForYouResponse, summaryDataController: WMFArticleSummaryDataControlling & Sendable = WMFArticleSummaryDataController.shared) -> [WMFAppOnboardingPreviewCardViewModel] {
        personalizedPreviewSelections(from: response).map {
            WMFAppOnboardingPreviewCardViewModel(article: $0.article, topicPill: $0.topicPill, summaryDataController: summaryDataController)
        }
    }


    static func personalizedIsAvailable(for response: WMFForYouResponse) -> Bool {
        return !response.interestTopicRandomArticles.isEmpty || !response.interestPageRelatedArticles.isEmpty
    }

    static func strippingHTMLTags(_ html: String) -> String {
        return html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}

/// A non-interactive sample article card shown on the feed preference onboarding step.
@MainActor
final class WMFAppOnboardingPreviewCardViewModel: ObservableObject, Identifiable {

    let id = UUID()
    let topicPill: String?

    @Published var displayTitle: String
    @Published var description: String?
    @Published var uiImage: UIImage?

    private var imageURL: URL?
    private let summaryFetchInfo: (title: String, project: WMFProject)?
    private let summaryDataController: (WMFArticleSummaryDataControlling & Sendable)?
    private var didLoadSummary = false
    private var imageTask: Task<Void, Never>?

    /// Community cards arrive with all content up front.
    init(displayTitle: String, description: String?, imageURLString: String?, topicPill: String?) {
        self.displayTitle = displayTitle
        self.description = description
        self.imageURL = imageURLString.flatMap { URL(string: $0) }
        self.topicPill = topicPill
        self.summaryFetchInfo = nil
        self.summaryDataController = nil
    }

    init(article: WMFForYouArticle, topicPill: String?, summaryDataController: WMFArticleSummaryDataControlling & Sendable = WMFArticleSummaryDataController.shared) {
        self.displayTitle = article.title.underscoresToSpaces
        self.description = article.description
        self.imageURL = article.thumbnailURL
        self.topicPill = topicPill
        self.summaryFetchInfo = (article.title, article.project)
        self.summaryDataController = summaryDataController
        self.didLoadSummary = article.description != nil || article.thumbnailURL != nil
    }

    func loadSummaryIfNeeded() async {
        guard !didLoadSummary, let info = summaryFetchInfo, let summaryDataController else { return }
        didLoadSummary = true
        guard let summary = try? await summaryDataController.fetchArticleSummary(project: info.project, title: info.title.normalizedForDisplay) else { return }
        displayTitle = summary.displayTitle
        description = summary.description
        imageURL = summary.thumbnailURL
    }

    /// Fetches the thumbnail image; images load progressively as cards appear.
    func loadImageIfNeeded() {
        guard uiImage == nil, imageTask == nil, let url = imageURL else { return }
        imageTask = Task { [weak self] in
            guard let self else { return }
            guard let data = try? await WMFImageDataController.shared.fetchImageData(url: url),
                  !Task.isCancelled else { return }
            self.uiImage = UIImage(data: data)
        }
    }

    deinit {
        imageTask?.cancel()
    }
}
