import Foundation
import WMF

struct ImportedReadingList: Codable {
    let name: String?
    let description: String?
    let list: [String: [Int]]
}

enum ImportReadingListError: Error {
    case failureDecodingPayload
    case failureFetchingPageURLs
    case failureFetchingArticleObjects
    case missingDataStore
    case missingArticles
}

/// Turns the payload of a shared reading list link into saved article objects.
///
/// The payload is a base64 JSON object. See https://phabricator.wikimedia.org/T316822#8366987:
///
///     { "list": { "en": [59874, 31883], "ru": [24868] } }
@MainActor
final class ReadingListImporter {

    private let encodedPageIDs: String
    private let dataStore: MWKDataStore?
    private let pageIDsFetcher = PageIDToURLFetcher()
    private let articleFetcher = ArticleFetcher()

    init(encodedPageIDs: String, dataStore: MWKDataStore?) {
        self.encodedPageIDs = encodedPageIDs
        self.dataStore = dataStore
    }

    func importArticles() async throws -> [WMFArticle] {
        guard let importedReadingList = decodedReadingList() else {
            throw ImportReadingListError.failureDecodingPayload
        }

        let pageIDCount = importedReadingList.list.values.reduce(0) { $0 + $1.count }
        ReadingListsFunnel.shared.logStartImport(articlesCount: pageIDCount)

        let pageURLs = try await fetchPageURLs(for: importedReadingList)
        return try await fetchArticles(for: pageURLs)
    }

    // MARK: - Steps

    private func decodedReadingList() -> ImportedReadingList? {
        guard let data = Data(base64Encoded: encodedPageIDs) else {
            return nil
        }
        return try? JSONDecoder().decode(ImportedReadingList.self, from: data)
    }

    private func fetchPageURLs(for importedReadingList: ImportedReadingList) async throws -> [URL] {
        var pageIDsBySiteURL: [URL: [Int]] = [:]
        for (languageCode, pageIDs) in importedReadingList.list {
            if let siteURL = NSURL.wmf_URL(withDefaultSiteAndLanguageCode: languageCode) {
                pageIDsBySiteURL[siteURL] = pageIDs
            }
        }

        let pageURLs = try await withThrowingTaskGroup(of: [URL].self) { group in
            for (siteURL, pageIDs) in pageIDsBySiteURL {
                group.addTask { [pageIDsFetcher] in
                    try await pageIDsFetcher.fetchPageURLs(siteURL, pageIDs: pageIDs)
                }
            }
            var pageURLs: [URL] = []
            for try await sitePageURLs in group {
                pageURLs.append(contentsOf: sitePageURLs)
            }
            return pageURLs
        }

        guard !pageURLs.isEmpty else {
            throw ImportReadingListError.failureFetchingPageURLs
        }
        return pageURLs
    }

    private func fetchArticles(for pageURLs: [URL]) async throws -> [WMFArticle] {
        guard let dataStore else {
            throw ImportReadingListError.missingDataStore
        }

        let keys = pageURLs.compactMap { $0.wmf_inMemoryKey }
        let summaryResponses = await articleFetcher.fetchArticleSummaryResponsesForArticles(withKeys: keys)
        let articlesByKey = try dataStore.viewContext.wmf_createOrUpdateArticleSummmaries(withSummaryResponses: summaryResponses)
        let articles = Array(articlesByKey.values)

        guard !articles.isEmpty else {
            throw ImportReadingListError.failureFetchingArticleObjects
        }
        return articles
    }
}

// MARK: - Async wrappers

private extension PageIDToURLFetcher {
    func fetchPageURLs(_ siteURL: URL, pageIDs: [Int]) async throws -> [URL] {
        try await withCheckedThrowingContinuation { continuation in
            fetchPageURLs(siteURL, pageIDs: pageIDs) { error in
                continuation.resume(throwing: error)
            } success: { pageURLs in
                continuation.resume(returning: pageURLs)
            }
        }
    }
}

private extension ArticleFetcher {
    func fetchArticleSummaryResponsesForArticles(withKeys keys: [WMFInMemoryURLKey]) async -> [WMFInMemoryURLKey: ArticleSummary] {
        await withCheckedContinuation { continuation in
            fetchArticleSummaryResponsesForArticles(withKeys: keys) { summaryResponses in
                continuation.resume(returning: summaryResponses)
            }
        }
    }
}
