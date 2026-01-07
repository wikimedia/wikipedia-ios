import Foundation
import WMFData
import WMF
import WMFComponents

final class NewArticleTabDataController {
    private let dataStore: MWKDataStore

    private var seenSeedKeys = Set<String>()
    private var seed: WMFArticle?
    private var related: [WMFArticle] = []

    init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
    }

    @MainActor
    private func obtainFeedImportContext() -> NSManagedObjectContext {
        dataStore.feedImportContext
    }
}

// MARK: - Extensions

fileprivate extension WMFArticle {
    func toHistoryRecord() -> HistoryRecord {
        let id = Int(truncating: self.pageID ?? NSNumber())
        let viewed = self.viewedDate ?? self.savedDate ?? Date()
        return HistoryRecord(
            id: id,
            title: self.displayTitle ?? self.displayTitleHTML,
            descriptionOrSnippet:self.capitalizedWikidataDescriptionOrSnippet,
            shortDescription: self.snippet,
            articleURL: self.url,
            imageURL: self.imageURLString,
            viewedDate: viewed,
            isSaved: self.isSaved,
            snippet: self.snippet,
            variant: self.variant
        )
    }
}
