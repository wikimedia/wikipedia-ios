import Foundation

public class ModernArticleSummaryController {
    let articleFetcher = ModernArticleFetcher()
    private let dataStore: MWKDataStore
    
    public init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
    }
    
    public func updateOrCreateArticleSummariesForArticles(withKeys articleKeys: [WMFInMemoryURLKey]) async throws -> [WMFInMemoryURLKey: WMFArticle] {
        let summaryResponses = try await articleFetcher.fetchArticleSummaryResponsesForArticles(withKeys: articleKeys)
        return try await processSummaryResponses(with: summaryResponses)
    }
    
    @MainActor
    private func processSummaryResponses(with summaryResponses: [WMFInMemoryURLKey: ArticleSummary]) throws -> [WMFInMemoryURLKey: WMFArticle] {
        return try dataStore.viewContext.wmf_createOrUpdateArticleSummmaries(withSummaryResponses: summaryResponses)
    }
}
