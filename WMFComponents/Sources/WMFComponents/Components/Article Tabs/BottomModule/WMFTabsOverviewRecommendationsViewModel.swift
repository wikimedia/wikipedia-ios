import UIKit
import WMFData

final public class WMFTabsOverviewRecommendationsViewModel {

    public typealias ShareRecordAction = (CGRect?, HistoryItem) -> Void
    public typealias OnRecordTapAction = ((HistoryItem) -> Void)

    let title: String
    let articles: [HistoryRecord]
    public var onTapArticle: OnRecordTapAction?
    public var shareRecordAction: ShareRecordAction?
    private let imageDataController = WMFImageDataController()

    public init(title: String, articles: [HistoryRecord], onTapArticle: OnRecordTapAction? = nil, shareRecordAction: ShareRecordAction? = nil) {
        self.title = title
        self.articles = articles
        self.onTapArticle = onTapArticle
        self.shareRecordAction = shareRecordAction
    }

    func getItems() -> [HistoryItem] {
        let items = articles.map { dataItem in
            HistoryItem(id: String(dataItem.id),
                        url: dataItem.articleURL,
                        titleHtml: dataItem.title,
                        description: dataItem.descriptionOrSnippet,
                        shortDescription: dataItem.shortDescription,
                        imageURLString: dataItem.imageURL,
                        isSaved: dataItem.isSaved,
                        snippet: dataItem.snippet,
                        variant: dataItem.variant)
        }
        return items
    }

    func loadImage(imageURLString: String?) async throws -> UIImage? {

        guard let imageURLString,
              let url = URL(string: imageURLString) else {
            return nil
        }

        let data = try await imageDataController.fetchImageData(url: url)
        return UIImage(data: data)
    }

    func share(frame: CGRect?, item: HistoryItem) {
        shareRecordAction?(frame, item)
    }

    func onTap(_ item: HistoryItem) {
        onTapArticle?(item)
    }

}
