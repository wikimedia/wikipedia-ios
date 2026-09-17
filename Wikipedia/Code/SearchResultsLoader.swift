import WMF

struct SearchResultsLoader {

    enum Failure: Error {
        case fetch(Error, WMFSearchType)
    }

    static let fullTextSearchThreshold = 12

    let fetcher: WMFSearchFetcher

    func fetchResults(for searchTerm: String, siteURL: URL, resultLimit: UInt = WMFMaxSearchResultLimit) async throws -> (results: WMFSearchResults, type: WMFSearchType) {
        let prefixResults: WMFSearchResults
        do {
            prefixResults = try await fetcher.fetchArticles(forSearchTerm: searchTerm, siteURL: siteURL, resultLimit: resultLimit)
        } catch let error as CancellationError {
            throw error
        } catch {
            throw Failure.fetch(error, .prefix)
        }

        let prefixCount = prefixResults.results?.count ?? 0
        guard prefixCount < Self.fullTextSearchThreshold else {
            return (prefixResults, .prefix)
        }

        try Task.checkCancellation()

        do {
            let fullTextResults = try await fetcher.fetchArticles(forSearchTerm: searchTerm, siteURL: siteURL, resultLimit: resultLimit, fullTextSearch: true, appendToPreviousResults: prefixResults)
            return (fullTextResults, .full)
        } catch let error as CancellationError {
            throw error
        } catch {
            guard prefixCount > 0 else {
                throw Failure.fetch(error, .full)
            }
            return (prefixResults, .prefix)
        }
    }
}

extension WMFSearchFetcher {
    func fetchArticles(forSearchTerm searchTerm: String, siteURL: URL, resultLimit: UInt, fullTextSearch: Bool = false, appendToPreviousResults previousResults: WMFSearchResults? = nil) async throws -> WMFSearchResults {
        try Task.checkCancellation()
        return try await withTaskCancellationHandler {
            do {
                return try await withCheckedThrowingContinuation { continuation in
                    fetchArticles(forSearchTerm: searchTerm, siteURL: siteURL, resultLimit: resultLimit, fullTextSearch: fullTextSearch, appendToPreviousResults: previousResults, failure: { error in
                        continuation.resume(throwing: error)
                    }, success: { results in
                        continuation.resume(returning: results)
                    })
                }
            } catch {
                guard !Task.isCancelled else {
                    throw CancellationError()
                }
                throw error
            }
        } onCancel: {
            cancelAllFetches()
        }
    }
}
