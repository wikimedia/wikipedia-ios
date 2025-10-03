import UIKit
import WMFData

@MainActor
public final class WMFTabsOverviewRecommendationsViewModel: ObservableObject {

    public typealias ShareRecordAction = (CGRect?, HistoryItem) -> Void
    public typealias OnRecordTapAction = ((HistoryItem) -> Void)

    // MARK: - Inputs & outputs

    public let title: String
    public let openButtonTitle: String
    public let shareButtonTitle: String
    private(set) var articles: [HistoryRecord]

    @Published public private(set) var items: [HistoryItem] = []

    public var onTapArticle: OnRecordTapAction?
    public var shareRecordAction: ShareRecordAction?

    var geometryFrames: [String: CGRect] = [:]

    private let imageDataController = WMFImageDataController()

    // MARK: - Init

    public init(title: String, openButtonTitle: String, shareButtonTitle: String, articles: [HistoryRecord], onTapArticle: OnRecordTapAction?, shareRecordAction: ShareRecordAction? ) {
        self.title = title
        self.openButtonTitle = openButtonTitle
        self.shareButtonTitle = shareButtonTitle
        self.articles = articles
        self.onTapArticle = onTapArticle
        self.shareRecordAction = shareRecordAction
        self.items = Self.mapRecordsToItems(articles)
    }

    // MARK: - Public API

    public func loadImage(imageURLString: String?) async throws -> UIImage? {
        guard let imageURLString,
              let url = URL(string: imageURLString) else {
            return nil
        }
        let data = try await imageDataController.fetchImageData(url: url)
        return UIImage(data: data)
    }

    public func share(frame: CGRect?, item: HistoryItem) {
        shareRecordAction?(frame, item)
    }

    public func onTap(_ item: HistoryItem) {
        onTapArticle?(item)
    }

    // MARK: - Helpers

    private static func mapRecordsToItems(_ records: [HistoryRecord]) -> [HistoryItem] {
        records.map { dataItem in
            HistoryItem(
                id: String(dataItem.id),
                url: dataItem.articleURL,
                titleHtml: dataItem.title,
                description: dataItem.descriptionOrSnippet,
                shortDescription: dataItem.shortDescription,
                imageURLString: dataItem.imageURL,
                isSaved: dataItem.isSaved,
                snippet: dataItem.snippet,
                variant: dataItem.variant
            )
        }
    }
}
