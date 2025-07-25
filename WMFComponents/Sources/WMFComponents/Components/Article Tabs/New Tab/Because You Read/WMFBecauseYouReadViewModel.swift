import WMFData
import Foundation

public struct WMFBecauseYouReadViewModel {

    let becauseYouReadText: String
    let seedArticle: HistoryRecord
    let relatedArticles: [HistoryRecord]

    public init(becauseYouReadText: String, seedArticle: HistoryRecord, relatedArticles: [HistoryRecord]) {
        self.becauseYouReadText = becauseYouReadText
        self.seedArticle = seedArticle
        self.relatedArticles = relatedArticles
    }

    public func loadItems() -> [HistoryItem] {
        var related: [HistoryItem] = []
        for item in relatedArticles {
            let historyItem = HistoryItem(id: String(item.id), url: item.articleURL, titleHtml: item.title, description: item.descriptionOrSnippet, shortDescription: item.shortDescription, imageURL: getURL(item.imageURL), isSaved: item.isSaved, snippet: item.snippet, variant: item.variant)
            related.append(historyItem)

        }
        return related
    }

    public func getSeedArticle() -> HistoryItem {
        let historyItem = HistoryItem(id: String(seedArticle.id), url: seedArticle.articleURL, titleHtml: seedArticle.title, description: seedArticle.descriptionOrSnippet, shortDescription: seedArticle.descriptionOrSnippet, imageURL: getURL(seedArticle.imageURL), isSaved: seedArticle.isSaved, snippet: seedArticle.descriptionOrSnippet, variant: seedArticle.variant)
        return historyItem
    }

    private func getURL(_ string: String?) -> URL? {
        guard let string else { return nil }
        return URL(string: string)
    }

}
