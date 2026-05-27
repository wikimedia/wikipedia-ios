import Foundation
import SwiftUI
import WMFData
import WMFNativeLocalizations

/// View model for a single article card shown in the post-game articles summary.
@MainActor
public final class WMFWhichCameFirstArticleItemViewModel: ObservableObject, Identifiable {

    public let id = UUID()

    /// The article title to display on the card.
    public let title: String

    /// The formatted date string for the event associated with this article.
    public let dateString: String

    /// The URL of the article on Wikipedia (used when the user taps the card).
    /// This must be supplied by the app-side coordinator because URL construction
    /// requires WMF framework extensions not available in WMFComponents.
    public let articleURL: URL?

    /// Thumbnail image data fetched asynchronously.
    @Published public var thumbnailImageData: Data?

    /// `true` when a thumbnail URL was provided, regardless of whether the image has loaded.
    public var hasThumbnailURL: Bool { thumbnailURL != nil }

    private let thumbnailURL: URL?
    private var imageTask: Task<Void, Never>?

    public init(title: String, date: Date, articleURL: URL?, thumbnailURL: URL?) {
        self.title = title
        self.dateString = DateFormatter.wmfMonthDayYearDateFormatter.string(from: date)
        self.articleURL = articleURL
        self.thumbnailURL = thumbnailURL

        if thumbnailURL != nil {
            loadImage()
        }
    }

    deinit {
        imageTask?.cancel()
    }

    private func loadImage() {
        imageTask?.cancel()
        imageTask = Task { [weak self] in
            guard let self, let url = self.thumbnailURL else { return }
            do {
                let data = try await WMFImageDataController.shared.fetchImageData(url: url)
                self.thumbnailImageData = data
            } catch {}
        }
    }
}

/// View model for the post-game article summary section shown after the user finishes
/// a Which Came First game. It exposes one card per unique article mentioned across
/// all questions.
///
/// Pass pre-built `WMFWhichCameFirstArticleItemViewModel` instances from the app-side
/// coordinator so that article URLs can be constructed using WMF framework helpers.
@MainActor
public final class WMFWhichCameFirstArticlesViewModel: ObservableObject {

    public struct LocalizedStrings {
        public let sectionTitle: String
        public let openArticleTitle: String
        public let openInNewTabTitle: String
        public let openInBackgroundTabTitle: String
        public let saveForLaterTitle: String
        public let shareArticleTitle: String
        public let articleTapAccessibility: String

        public init(
            sectionTitle: String = WMFLocalizedString("which-came-first-articles-section-title", value: "Articles from today's game", comment: "Section title for the article cards shown after completing the Which Came First game"),
            openArticleTitle: String = CommonStrings.articleTabsOpen,
            openInNewTabTitle: String = CommonStrings.articleTabsOpenInNewTab,
            openInBackgroundTabTitle: String = CommonStrings.articleTabsOpenInBackgroundTab,
            saveForLaterTitle: String = CommonStrings.saveTitle,
            shareArticleTitle: String = CommonStrings.shortShareTitle,
            articleTapAccessibility: String = CommonStrings.articleTabsOpen
        ) {
            self.sectionTitle = sectionTitle
            self.openArticleTitle = openArticleTitle
            self.openInNewTabTitle = openInNewTabTitle
            self.openInBackgroundTabTitle = openInBackgroundTabTitle
            self.saveForLaterTitle = saveForLaterTitle
            self.shareArticleTitle = shareArticleTitle
            self.articleTapAccessibility = articleTapAccessibility
        }
    }

    public let localizedStrings: LocalizedStrings

    @Published public var articleItems: [WMFWhichCameFirstArticleItemViewModel]

    public var didTapArticle: ((URL) -> Void)?
    public var didTapOpenInNewTab: ((URL) -> Void)?
    public var didTapOpenInBackgroundTab: ((URL) -> Void)?
    public var didSaveForLater: ((URL) -> Void)?
    public var didShareArticle: ((URL) -> Void)?

    public init(
        articleItems: [WMFWhichCameFirstArticleItemViewModel],
        localizedStrings: LocalizedStrings = LocalizedStrings()
    ) {
        self.articleItems = articleItems
        self.localizedStrings = localizedStrings
    }
}
