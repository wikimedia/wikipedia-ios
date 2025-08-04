import WMFData
import Foundation
import UIKit

@objc public class WMFBecauseYouReadViewModel: NSObject {

    public typealias OnRecordTapAction = ((HistoryItem) -> Void)

    let becauseYouReadTitle: String
    let openButtonTitle: String
    let seedArticle: HistoryRecord
    let relatedArticles: [HistoryRecord]

    public var onTapArticle: OnRecordTapAction?

    private let imageDataController = WMFImageDataController()

    public init(becauseYouReadTitle: String, openButtonTitle: String, seedArticle: HistoryRecord, relatedArticles: [HistoryRecord]) {
        self.becauseYouReadTitle = becauseYouReadTitle
        self.openButtonTitle = openButtonTitle
        self.seedArticle = seedArticle
        self.relatedArticles = relatedArticles
    }

    public func loadItems() -> [HistoryItem] {
        var related: [HistoryItem] = []
        for item in relatedArticles {
            let historyItem = HistoryItem(id: String(item.id), url: item.articleURL, titleHtml: item.title, description: item.descriptionOrSnippet, shortDescription: item.shortDescription, imageURLString: item.imageURL, isSaved: item.isSaved, snippet: item.snippet, variant: item.variant)
            related.append(historyItem)
        }
        return related
    }

    public func getSeedArticle() -> HistoryItem {
        let historyItem = HistoryItem(id: String(seedArticle.id), url: seedArticle.articleURL, titleHtml: seedArticle.title, description: seedArticle.descriptionOrSnippet, shortDescription: seedArticle.descriptionOrSnippet, imageURLString: seedArticle.imageURL, isSaved: seedArticle.isSaved, snippet: seedArticle.descriptionOrSnippet, variant: seedArticle.variant)
        return historyItem
    }

    func onTap(_ item: HistoryItem) {
        onTapArticle?(item)
    }

    func loadImage(imageURLString: String?) async throws -> UIImage? {

        guard let imageURLString,
              let url = URL(string: imageURLString) else {
            return nil
        }

        let data = try await imageDataController.fetchImageData(url: url)
        return UIImage(data: data)
    }

}
