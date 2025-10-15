import Foundation
import WMFData
import WMF
import WMFComponents

final class NewArticleTabDataController {
    private let dataStore: MWKDataStore
    private let relatedFetcher = RelatedSearchFetcher()
    private let dykFetcher = WMFFeedDidYouKnowFetcher()

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

    public func getRelatedArticles(for recordURLs: [URL?],maxTotal: Int) async throws -> [HistoryRecord] {

        let batches: [[HistoryRecord]] = try await withThrowingTaskGroup(of: [HistoryRecord].self) { group in
            for url in recordURLs {
                group.addTask { [weak self] in
                    guard let self else { return [] }
                    return try await self.relatedArticles(for: url, maxTotal: maxTotal)
                }
            }
            var out: [[HistoryRecord]] = []
            for try await batch in group { out.append(batch) }
            return out
        }

        var joinedResults = batches.flatMap { $0 }

        joinedResults.shuffle()

        if joinedResults.count > maxTotal {
            joinedResults.removeSubrange(maxTotal..<joinedResults.count)
        }

        return joinedResults
    }

    private func relatedArticles(for url: URL?, maxTotal: Int) async throws -> [HistoryRecord] {
        try await withCheckedThrowingContinuation { cont in
            relatedFetcher.fetchRelatedArticles(forArticleWithURL: url, limit: maxTotal) { error, summariesByKey in
                if let error {
                    cont.resume(throwing: error)
                    return
                }
                guard let summariesByKey, !summariesByKey.isEmpty else {
                    cont.resume(returning: [])
                    return
                }

                // take the first 3
                let top3Summaries = Array(summariesByKey)
                    .prefix(3)
                    .reduce(into: [WMFInMemoryURLKey: ArticleSummary]()) { result, pair in
                        result[pair.key] = pair.value
                    }

                Task {
                    let moc = await self.obtainFeedImportContext()
                    await moc.perform {
                        do {
                            let articlesByKey = try moc.wmf_createOrUpdateArticleSummmaries(
                                withSummaryResponses: top3Summaries
                            )
                            let orderedKeys = Array(top3Summaries.keys)
                            let relatedArticles: [WMFArticle] = orderedKeys.compactMap {
                                articlesByKey[$0]
                            }
                            let records = relatedArticles.map { $0.toHistoryRecord() }
                            cont.resume(returning: records)
                        } catch {
                            cont.resume(throwing: error)
                        }
                    }
                }
            }
        }
    }

    public func fetchDidYouKnowFacts(siteURL: URL) async throws -> [WMFDidYouKnow]? {
        try await withCheckedThrowingContinuation { cont in
            dykFetcher.fetchDidYouKnow(withSiteURL: siteURL) { error, facts in
                if let error { cont.resume(throwing: error) } else { cont.resume(returning: facts) }
            }
        }
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
