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

    @Published public private(set) var selection: WMFHomeFeedSeeFirst = .community
    @Published private(set) var communityCards: [WMFAppOnboardingPreviewCardViewModel] = []
    @Published private(set) var personalizedCards: [WMFAppOnboardingPreviewCardViewModel] = []
    @Published public private(set) var isPersonalizedAvailable: Bool = true
    @Published var isCommunityLoading: Bool = false
    @Published var isPersonalizedLoading: Bool = false

    private let dataController: WMFHomeDataController
    private let summaryDataController: WMFArticleSummaryDataControlling & Sendable
    private(set) var project: WMFProject
    private var communityTask: Task<Void, Never>?
    private var personalizedTask: Task<Void, Never>?
    private var warmUpTask: Task<Void, Never>?
    private var hasLoaded = false

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

    /// The personalized option can be chosen only once its data has resolved and confirmed
    /// availability — otherwise a fast user could persist a preference we can't honor.
    var isPersonalizedSelectable: Bool {
        return isPersonalizedAvailable && !isPersonalizedLoading
    }

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

    /// Starts the article downloads for the current interests while the user is still on the
    /// interests step. The data controller keeps the results in a short-lived cache, and the
    /// For You fetch in `loadIfNeeded()` reads from that cache. Because of this, the work runs
    /// during the selection, and the fetch after the Next tap is almost immediate. Repeated
    /// calls are cheap: each interest is downloaded one time.
    func interestsDidChange() {
        guard !hasLoaded else { return }
        warmUpTask = Task { [weak self] in
            guard let self else { return }
            await dataController.warmForYouArticles(project: project)
        }
    }

    /// Called when the user changes their primary app language during onboarding. The previews
    /// normally load after the languages step, but reload defensively if they already did.
    public func updateProject(_ newProject: WMFProject) {
        guard newProject != project else { return }
        project = newProject
        if hasLoaded {
            communityTask?.cancel()
            personalizedTask?.cancel()
            communityCards = []
            personalizedCards = []
            hasLoaded = false
            loadIfNeeded()
        }
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

    public func loadIfNeeded() {
        guard !hasLoaded else { return }
        hasLoaded = true
        isCommunityLoading = true
        isPersonalizedLoading = true

        // Day-cached (and prefetched at onboarding start), so the previews match the Home feed
        communityTask = Task { [weak self] in
            guard let self else { return }
            if let community = try? await dataController.fetchCommunity(project: project) {
                self.communityCards = self.buildCommunityCards(from: community)
            }
            self.isCommunityLoading = false
        }

        // Force fetch: the user just chose interests in the previous step, so any cached
        // For You response predates them. The forced fetch refreshes the shared cache,
        // keeping the Home feed consistent with this preview. It is fast: the article groups
        // were downloaded during the selection (see `interestsDidChange`).
        personalizedTask = Task { [weak self] in
            guard let self else { return }
            if let forYou = try? await dataController.fetchForYou(project: project, forceFetch: true) {
                let cards = Self.buildPersonalizedCards(from: forYou, summaryDataController: summaryDataController)
                // Hydrate descriptions before revealing the row, so cards appear fully formed
                await withTaskGroup(of: Void.self) { group in
                    for card in cards {
                        group.addTask { await card.loadSummaryIfNeeded() }
                    }
                }
                self.personalizedCards = cards
                // Start the image downloads now, not on card appearance. When the speculative
                // fetch already put the images in the cache, the cards render complete.
                for card in cards {
                    card.loadImageIfNeeded()
                }
                self.isPersonalizedAvailable = Self.personalizedIsAvailable(for: forYou)
                logImpression(!isPersonalizedAvailable)
            } else {
                self.personalizedCards = []
                self.isPersonalizedAvailable = !dataController.interestTopics().isEmpty
                logImpression(!isPersonalizedAvailable)
            }

            if !self.isPersonalizedAvailable && self.selection == .personalized {
                self.selection = .community
            }
            self.isPersonalizedLoading = false
        }
    }

    deinit {
        communityTask?.cancel()
        personalizedTask?.cancel()
        warmUpTask?.cancel()
    }

    // MARK: - Test hooks

    /// Lets a test wait until the warm-up is complete.
    func waitForWarmUp() async {
        await warmUpTask?.value
    }

    /// Lets a test wait until both preview rows are loaded.
    func waitForLoadTasks() async {
        await communityTask?.value
        await personalizedTask?.value
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

    /// The articles that the personalized row shows: one for each of the first three interest
    /// groups. Topic interests (with a topic pill) come first, then article interests.
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

    /// Personalized cards start from the metadata in the article itself, when the search response
    /// carried it. A summary fetch is then not necessary, and the card is complete immediately.
    /// Articles from local sources carry no metadata; those cards hydrate from the article summary.
    init(article: WMFForYouArticle, topicPill: String?, summaryDataController: WMFArticleSummaryDataControlling & Sendable = WMFArticleSummaryDataController.shared) {
        self.displayTitle = article.title.underscoresToSpaces
        self.description = article.description
        self.imageURL = article.thumbnailURL
        self.topicPill = topicPill
        self.summaryFetchInfo = (article.title, article.project)
        self.summaryDataController = summaryDataController
        self.didLoadSummary = article.description != nil || article.thumbnailURL != nil
    }

    /// Fetches the display title, description, and thumbnail URL from the article summary.
    /// Awaited before the personalized row is revealed, so its cards appear with their text in place.
    /// The title goes out in the display form. The summary cache uses the title string as its key,
    /// and both the onboarding warm-up and the For You cards use the display form.
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
