import WMF

/// Which request gave the results: the prefix search alone, or the full text search appended to it.
public enum WMFSearchType: String, Codable {
    case full
    case prefix
}

struct SearchResultsLoader {

    enum Failure: Error {
        case fetch(Error, WMFSearchType)
    }

    /// The results of a search. The full text rows come after the prefix rows, so the count of
    /// prefix rows says which request gave each row.
    struct Outcome {
        let results: WMFSearchResults
        let type: WMFSearchType
        let prefixResultCount: Int

        /// Which request gave the row at `index`.
        func type(ofRow index: Int) -> WMFSearchType {
            index < prefixResultCount ? .prefix : .full
        }
    }

    static let fullTextSearchThreshold = 12

    let fetcher: WMFSearchFetcher

    func fetchResults(for searchTerm: String, siteURL: URL, resultLimit: UInt = WMFMaxSearchResultLimit) async throws -> Outcome {
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
            return Outcome(results: prefixResults, type: .prefix, prefixResultCount: prefixCount)
        }

        try Task.checkCancellation()

        do {
            let fullTextResults = try await fetcher.fetchArticles(forSearchTerm: searchTerm, siteURL: siteURL, resultLimit: resultLimit, fullTextSearch: true, appendToPreviousResults: prefixResults)
            return Outcome(results: fullTextResults, type: .full, prefixResultCount: prefixCount)
        } catch let error as CancellationError {
            throw error
        } catch {
            guard prefixCount > 0 else {
                throw Failure.fetch(error, .full)
            }
            return Outcome(results: prefixResults, type: .prefix, prefixResultCount: prefixCount)
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
