import Foundation
import UIKit
import SwiftUI
import WMFData
import WMFNativeLocalizations

// MARK: - Module types and visibility

public enum WMFForYouModule {
    case basedOnInterests
    case becauseYouRead
    case continueReading
}

/// A default argument runs in the context of the caller, which is not the main actor. This type
/// only carries three flags, thus it needs no isolation.
public nonisolated struct WMFForYouModuleVisibility {
    public var basedOnInterests: Bool
    public var becauseYouRead: Bool
    public var continueReading: Bool

    public init(basedOnInterests: Bool, becauseYouRead: Bool, continueReading: Bool) {
        self.basedOnInterests = basedOnInterests
        self.becauseYouRead = becauseYouRead
        self.continueReading = continueReading
    }

    public func isVisible(_ module: WMFForYouModule) -> Bool {
        switch module {
        case .basedOnInterests: return basedOnInterests
        case .becauseYouRead: return becauseYouRead
        case .continueReading: return continueReading
        }
    }
}

// MARK: - Header label

public struct WMFForYouHeaderLabel {
    public let symbol: WMFSFSymbolIcon?
    public let format: String
    public let highlight: String

    public init(symbol: WMFSFSymbolIcon? = nil, format: String, highlight: String) {
        self.symbol = symbol
        self.format = format
        self.highlight = highlight
    }

    public var accessibilityText: String {
        String.localizedStringWithFormat(format, highlight)
    }
}

// MARK: - View models

@MainActor
public final class WMFForYouViewModel: ObservableObject {

    @Published public var pages: [WMFForYouPageViewModel] = []
    @Published public var moduleVisibility: WMFForYouModuleVisibility
    @Published public var hiddenCardKeys: Set<String>

    public var onRefresh: (() async -> Void)?
    public var onHideModule: ((WMFForYouModule) -> Void)?
    public var onHideCard: ((WMFForYouArticleCardViewModel) -> Void)?
    public var onCustomizeInterests: (() -> Void)?
    public var onTapCard: ((WMFForYouArticleCardViewModel) -> Void)?
    public var onSaveCard: ((WMFForYouArticleCardViewModel) -> Void)?
    public var onShareCard: ((WMFForYouArticleCardViewModel) -> Void)?
    public var onUnsaveCard: ((WMFForYouArticleCardViewModel) -> Void)?
    public var onUserInteraction: (() -> Void)?

    /// Called with a card that the user really sees on the screen.
    public var onShowCard: ((WMFForYouArticleCardViewModel) -> Void)?

    public let emptyTitle = WMFLocalizedString("for-you-empty-title", value: "Nothing here yet", comment: "Title shown on the For You tab when there is no content to display.")
    public let emptySubtitle = WMFLocalizedString("for-you-empty-subtitle", value: "Add interests to get personalized article recommendations.", comment: "Subtitle shown on the For You tab empty state encouraging the user to add interests.")
    public let emptyButtonTitle = WMFLocalizedString("for-you-empty-button", value: "Choose your interests", comment: "Button on the For You empty state that opens the interests customization screen.")

    // MARK: - Position in the feed
    private(set) var lastViewedModuleID: UUID?
    private(set) var lastViewedCardKey: String?

    func rememberViewedModule(_ moduleID: UUID?) {
        lastViewedModuleID = moduleID
    }

    func rememberViewedCard(_ cardKey: String?) {
        lastViewedCardKey = cardKey
    }

    public init(
        response: WMFForYouResponse,
        moduleVisibility: WMFForYouModuleVisibility = WMFForYouModuleVisibility(basedOnInterests: true, becauseYouRead: true, continueReading: true),
        hiddenCardKeys: Set<String> = []
    ) {
        self.moduleVisibility = moduleVisibility
        self.hiddenCardKeys = hiddenCardKeys
        self.pages = Self.makePages(from: response)
    }

    // MARK: - Building the feed

    private static func makePages(from response: WMFForYouResponse) -> [WMFForYouPageViewModel] {
        var deduplicator = ArticleDeduplicator()

        let interestPages = makeInterestPages(from: response, deduplicator: &deduplicator)
        let becauseYouReadPages = makeBecauseYouReadPages(from: response, deduplicator: &deduplicator)
        let continueReadingPages = makeContinueReadingPages(from: response, deduplicator: &deduplicator)

        // The first few interest pages open the feed; the rest follow the other modules.
        let leadingInterestPages = Array(interestPages.prefix(maxLeadingInterestPages))
        let trailingInterestPages = Array(interestPages.dropFirst(maxLeadingInterestPages))

        return leadingInterestPages + becauseYouReadPages + continueReadingPages + trailingInterestPages
    }

    private static let maxLeadingInterestPages = 3

    /// Builds one page for each interest, and mixes the topics and the articles one after the other.
    private static func makeInterestPages(from response: WMFForYouResponse, deduplicator: inout ArticleDeduplicator) -> [WMFForYouPageViewModel] {
        let interestFormat = WMFLocalizedString("for-you-header-interest", value: "Because of your interest: %1$@", comment: "Header on a For You feed card explaining it was chosen from one of the user's interests. %1$@ is replaced with the interest name.")

        var topicPages: [WMFForYouPageViewModel] = []
        var articlePages: [WMFForYouPageViewModel] = []

        for topicArticles in response.interestTopicRandomArticles {
            let header = WMFForYouHeaderLabel(format: interestFormat, highlight: topicArticles.topic.displayName)
            topicPages.append(WMFForYouPageViewModel(module: .basedOnInterests, headerLabel: header, articles: deduplicator.removingDuplicates(from: topicArticles.articles)))
        }

        for relatedArticles in response.interestPageRelatedArticles {
            let header = WMFForYouHeaderLabel(format: interestFormat, highlight: relatedArticles.pageInterest.title.normalizedForDisplay)
            articlePages.append(WMFForYouPageViewModel(module: .basedOnInterests, headerLabel: header, articles: deduplicator.removingDuplicates(from: relatedArticles.articles)))
        }

        return interleaved(topicPages, articlePages)
    }

    /// Puts the pages of two lists one after the other.
    private static func interleaved(_ first: [WMFForYouPageViewModel], _ second: [WMFForYouPageViewModel]) -> [WMFForYouPageViewModel] {
        var pages: [WMFForYouPageViewModel] = []

        for index in 0..<max(first.count, second.count) {
            if index < first.count {
                pages.append(first[index])
            }
            if index < second.count {
                pages.append(second[index])
            }
        }

        return pages
    }

    private static func makeBecauseYouReadPages(from response: WMFForYouResponse, deduplicator: inout ArticleDeduplicator) -> [WMFForYouPageViewModel] {
        guard let becauseYouRead = response.becauseYouReadArticles else { return [] }

        let header = WMFForYouHeaderLabel(
            symbol: .clock,
            format: WMFLocalizedString("for-you-header-because-you-read", value: "Because you read: %1$@", comment: "Header on a For You feed card shown because the user recently read a related article. %1$@ is replaced with the article title."),
            highlight: becauseYouRead.recentlyRead.title.normalizedForDisplay
        )

        return [WMFForYouPageViewModel(module: .becauseYouRead, headerLabel: header, articles: deduplicator.removingDuplicates(from: becauseYouRead.articles))]
    }

    private static func makeContinueReadingPages(from response: WMFForYouResponse, deduplicator: inout ArticleDeduplicator) -> [WMFForYouPageViewModel] {
        guard let continueReading = response.continueReadingArticles else { return [] }

        var cards: [WMFForYouArticleCardViewModel] = []

        if let continueReadingArticle = continueReading.continueReadingArticle {
            let continueHeader = WMFForYouHeaderLabel(
                symbol: .newspaper,
                format: CommonStrings.continueReadingTitle,
                highlight: continueReadingArticle.title.normalizedForDisplay
            )
            cards.append(WMFForYouArticleCardViewModel(article: continueReadingArticle, headerLabel: continueHeader))
            deduplicator.markUsed(continueReadingArticle)
        }

        let savedFormat = WMFLocalizedString("for-you-header-saved-article", value: "From your reading list", comment: "Header on a For You feed card showing an article from the user's reading list.")
        let savedCards = deduplicator.removingDuplicates(from: continueReading.fromReadingListArticles).map { article in
            let header = WMFForYouHeaderLabel(symbol: .bookmarkFill, format: savedFormat, highlight: article.title.normalizedForDisplay)
            return WMFForYouArticleCardViewModel(article: article, headerLabel: header)
        }
        cards.append(contentsOf: savedCards)

        guard !cards.isEmpty else { return [] }
        return [WMFForYouPageViewModel(module: .continueReading, articleViewModels: cards)]
    }
}

/// Keeps an article from appearing more than once in the feed, whichever module it came from.
private struct ArticleDeduplicator {

    private var seenKeys: Set<String> = []

    mutating func removingDuplicates(from articles: [WMFForYouArticle]) -> [WMFForYouArticle] {
        articles.filter { seenKeys.insert(key(for: $0)).inserted }
    }

    mutating func markUsed(_ article: WMFForYouArticle) {
        seenKeys.insert(key(for: article))
    }

    private func key(for article: WMFForYouArticle) -> String {
        "\(article.project.id)_\(article.title)"
    }
}

@MainActor
public final class WMFForYouPageViewModel: ObservableObject, Identifiable {

    public let id = UUID()
    public let module: WMFForYouModule
    public let articleViewModels: [WMFForYouArticleCardViewModel]

    public init(module: WMFForYouModule, headerLabel: WMFForYouHeaderLabel, articles: [WMFForYouArticle]) {
        self.module = module
        self.articleViewModels = articles.map {
            WMFForYouArticleCardViewModel(article: $0, headerLabel: headerLabel)
        }
        Self.assignCardIndexes(to: articleViewModels)
    }

    public init(module: WMFForYouModule, articleViewModels: [WMFForYouArticleCardViewModel]) {
        self.module = module
        self.articleViewModels = articleViewModels
        Self.assignCardIndexes(to: articleViewModels)
    }

    /// Fixes each card's position in the carousel at build time. Both initialisers go through here
    /// so a card's design never depends on which other cards happen to be hidden.
    private static func assignCardIndexes(to cards: [WMFForYouArticleCardViewModel]) {
        for (index, card) in cards.enumerated() {
            card.cardIndex = index
        }
    }
}

@MainActor
public final class WMFForYouArticleCardViewModel: ObservableObject, Identifiable {

    public let id = UUID()
    public let headerLabel: WMFForYouHeaderLabel
    public let title: String
    public let project: WMFProject
    @Published public var description: String?
    @Published public var extract: String?
    @Published public var uiImage: UIImage?
    @Published public var sampledColor: Color?
    @Published public var isSaved: Bool = false

    /// Position of this card in its carousel, fixed once by `WMFForYouPageViewModel` when the page
    /// is built. The card design is chosen from this, so it must not follow the live filtered
    /// position - otherwise hiding one card re-styles every card after it.
    public fileprivate(set) var cardIndex: Int = 0

    public enum LoadState {
        case loading, loaded
    }
    @Published public var loadState: LoadState = .loading

    /// Whether this article has an image to show.
    public enum ImageAvailability {
        case unknown /// The summary has not arrived yet, so we do not know.
        case available
        case unavailable
    }
    @Published public var imageAvailability: ImageAvailability = .unknown

    public var accessibilityLabel: String {
        var parts: [String] = []
        if !headerLabel.format.isEmpty {
            parts.append(headerLabel.accessibilityText)
        }
        parts.append(title)
        if let extract, !extract.isEmpty {
            parts.append(extract)
        } else if let description, !description.isEmpty {
            parts.append(description)
        }
        return parts.joined(separator: ", ")
    }

    public func refreshSavedState(isSaved: Bool) {
        self.isSaved = isSaved
    }

    public func toggleSaved() {
        isSaved.toggle()
    }

    private var loadTask: Task<Void, Never>?

    public let cardUniqueKey: String

    // MARK: - Localized strings

    public var saveTitle: String {
        CommonStrings.shortSaveTitle
    }

    public var unsaveTitle: String {
        CommonStrings.shortUnsaveTitle
    }

    public var shareTitle: String {
        CommonStrings.shortShareTitle
    }

    public var hideCardTitle: String {
        WMFHomeLocalizedStrings.hideCard
    }

    public var hideModuleTitle: String {
        WMFHomeLocalizedStrings.hideModule
    }

    public let customizeInterestsTitle = WMFLocalizedString("for-you-menu-customize-interests", value: "Customize interests", comment: "Menu action to open the interests customization screen from a For You feed card.")

    public init(article: WMFForYouArticle, headerLabel: WMFForYouHeaderLabel) {
        self.headerLabel = headerLabel
        self.title = article.title.normalizedForDisplay
        self.project = article.project
        self.cardUniqueKey = "for_you_\(article.project.id)_\(article.title)"
    }

    /// Rewrites a Commons thumbnail URL to ask for a wider rendering.
    ///
    /// Thumbnail URLs carry their width as a path component - `.../640px-Example.jpg` - so the size
    /// is changed by swapping that number. Returns nil when the URL has no such component, which
    /// means it is already the original file and cannot be scaled up.
    private static func upsizedThumbnailURL(from thumbnailURL: URL) -> URL? {
        var urlString = thumbnailURL.absoluteString
        guard let range = urlString.range(of: #"/\d+px-"#, options: .regularExpression) else {
            return nil
        }
        urlString.replaceSubrange(range, with: "/\(ImageUtils.leadImageWidth())px-")
        return URL(string: urlString)
    }

    public func load() {
        guard loadTask == nil else { return }
        loadTask = Task { [weak self] in
            guard let self else { return }
            guard let summary = try? await WMFArticleSummaryDataController.shared.fetchArticleSummary(project: project, title: title) else {
                self.imageAvailability = .unavailable
                self.loadState = .loaded
                return
            }
            self.description = summary.description
            self.extract = summary.extract
            guard let thumbnailURL = summary.thumbnailURL else {
                self.imageAvailability = .unavailable
                self.loadState = .loaded
                return
            }

            // The article has an image, so let the card settle on its image design now. The image
            // itself arrives later, and only a failed download changes the design after this.
            self.imageAvailability = .available

            // Ask for a bigger rendering than the summary's thumbnail, which is far too small for
            // a full screen card. Falls back to the thumbnail if the larger one is unavailable:
            let data: Data
            if let largeURL = Self.upsizedThumbnailURL(from: thumbnailURL),
               let largeData = try? await WMFImageDataController.shared.fetchImageData(url: largeURL) {
                data = largeData
            } else if let originalData = try? await WMFImageDataController.shared.fetchImageData(url: thumbnailURL) {
                data = originalData
            } else {
                self.imageAvailability = .unavailable
                self.loadState = .loaded
                return
            }

            // Sample before showing anything, off the main actor: the pixel work is far too
            // expensive to run while the user is swiping.
            let color = await WMFImageColorSampler.shared.sampledColor(from: data)

            // The photograph, its colour and the loaded flag land in one update, so the card
            // appears complete. Showing the image first put it on screen against a black gradient
            // that then turned coloured, which reads as a flash. The card view fades the whole
            // change in off `loadState`.
            self.uiImage = UIImage(data: data)
            self.sampledColor = color
            self.loadState = .loaded
        }
    }

    deinit {
        loadTask?.cancel()
    }
}
