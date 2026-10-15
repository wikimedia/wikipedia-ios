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
        /// Where the next page of full text results starts, or nil when there are no more.
        let nextOffset: Int?
        /// The ids of the first page's requests. Later pages don't change them, as on Android.
        let searchIDs: SearchInstrumentation.LexicalSearchIDs

        /// The same outcome with its own copy of the results, so a page can append to it while
        /// the results shown stay untouched. Make it where the results are shown, before handing
        /// it to `fetchNextPage`.
        func copyingResults() -> Outcome? {
            guard let copy = results.copy() as? WMFSearchResults else {
                return nil
            }
            return Outcome(results: copy, type: type, prefixResultCount: prefixResultCount, nextOffset: nextOffset, searchIDs: searchIDs)
        }

        /// Which request gave the row at `index`.
        func type(ofRow index: Int) -> WMFSearchType {
            index < prefixResultCount ? .prefix : .full
        }
    }

    /// The first page asks for as many results as the Android app's first page (3 pages of 10).
    static let initialLimit: UInt = 30
    /// Fewer prefix results than this adds the full text results, as on Android.
    static let fullTextSearchThreshold = Int(initialLimit)
    /// Each later page asks for this many full text results, as on Android.
    static let pageLimit: UInt = 10
    /// The most pages fetched in a row when they only repeat rows already shown.
    static let maxPagesWithoutNewRows = 3

    let fetcher: WMFSearchFetcher

    func fetchResults(for searchTerm: String, siteURL: URL, resultLimit: UInt = Self.initialLimit) async throws -> Outcome {
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
            // As on Android, the next page is the full text search from its first result.
            return Outcome(results: prefixResults, type: .prefix, prefixResultCount: prefixCount, nextOffset: 0, searchIDs: prefixResults.lexicalSearchIDs)
        }

        try Task.checkCancellation()

        do {
            let fullTextResults = try await fetcher.fetchArticles(forSearchTerm: searchTerm, siteURL: siteURL, resultLimit: resultLimit, fullTextSearch: true, appendToPreviousResults: prefixResults)
            return Outcome(results: fullTextResults, type: .full, prefixResultCount: prefixCount, nextOffset: fullTextResults.nextOffset?.intValue, searchIDs: fullTextResults.lexicalSearchIDs)
        } catch let error as CancellationError {
            throw error
        } catch {
            guard prefixCount > 0 else {
                throw Failure.fetch(error, .full)
            }
            return Outcome(results: prefixResults, type: .prefix, prefixResultCount: prefixCount, nextOffset: nil, searchIDs: prefixResults.lexicalSearchIDs)
        }
    }

    /// Appends the next page of full text results to the results of `outcome`, which it changes, so
    /// pass an outcome from `copyingResults()`. Rows already shown are dropped, and a page that only
    /// repeats them is skipped for the one after it.
    func fetchNextPage(after outcome: Outcome, for searchTerm: String, siteURL: URL) async throws -> Outcome {
        guard var offset = outcome.nextOffset else {
            return outcome
        }

        let results = outcome.results
        let previousCount = results.results?.count ?? 0
        var nextOffset: Int?

        for _ in 0..<Self.maxPagesWithoutNewRows {
            let page: WMFSearchResults
            do {
                page = try await fetcher.fetchArticles(forSearchTerm: searchTerm, siteURL: siteURL, resultLimit: Self.pageLimit, fullTextSearch: true, offset: UInt(offset))
            } catch let error as CancellationError {
                throw error
            } catch {
                throw Failure.fetch(error, .full)
            }
            try Task.checkCancellation()

            results.mergeValuesForKeys(from: page)
            nextOffset = page.nextOffset?.intValue
            guard let next = nextOffset, (results.results?.count ?? 0) == previousCount else {
                break
            }
            offset = next
        }

        return Outcome(results: results, type: outcome.type, prefixResultCount: outcome.prefixResultCount, nextOffset: nextOffset, searchIDs: outcome.searchIDs)
    }
}

extension WMFSearchFetcher {
    func fetchArticles(forSearchTerm searchTerm: String, siteURL: URL, resultLimit: UInt, fullTextSearch: Bool = false, offset: UInt = 0, appendToPreviousResults previousResults: WMFSearchResults? = nil) async throws -> WMFSearchResults {
        try Task.checkCancellation()
        return try await withTaskCancellationHandler {
            do {
                return try await withCheckedThrowingContinuation { continuation in
                    fetchArticles(forSearchTerm: searchTerm, siteURL: siteURL, resultLimit: resultLimit, fullTextSearch: fullTextSearch, offset: offset, appendToPreviousResults: previousResults, failure: { error in
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
