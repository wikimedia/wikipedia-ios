import Foundation
import SwiftUI
import WMFData

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
        public let shareArticleTitle: String
        public let articleTapAccessibility: String

        public init(sectionTitle: String, openArticleTitle: String, shareArticleTitle: String, articleTapAccessibility: String) {
            self.sectionTitle = sectionTitle
            self.openArticleTitle = openArticleTitle
            self.shareArticleTitle = shareArticleTitle
            self.articleTapAccessibility = articleTapAccessibility
        }
    }

    public let localizedStrings: LocalizedStrings

    @Published public var articleItems: [WMFWhichCameFirstArticleItemViewModel]

    /// Called when the user taps or selects "Open" on an article card.
    public var didTapArticle: ((URL) -> Void)?

    /// Called when the user selects "Share" on an article card.
    public var didShareArticle: ((URL) -> Void)?

    public init(
        articleItems: [WMFWhichCameFirstArticleItemViewModel],
        localizedStrings: LocalizedStrings,
        didTapArticle: ((URL) -> Void)? = nil,
        didShareArticle: ((URL) -> Void)? = nil
    ) {
        self.articleItems = articleItems
        self.localizedStrings = localizedStrings
        self.didTapArticle = didTapArticle
        self.didShareArticle = didShareArticle
    }
}
