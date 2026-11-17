import WMF
import WMFData

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

        let prefixCount = prefixResults.results.count
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

extension SearchResultsLoader {

    /// The prefix results and, when prefix returned fewer than `fullTextSearchThreshold`, the full text results, each as
    /// its request returned it. Unlike `fetchResults`, nothing is merged or de-duplicated by title, so each list is the one
    /// its search ID gives.
    struct RawOutcome {
        let prefix: WMFSearchResults
        let fullText: WMFSearchResults?
    }

    /// - Parameter includesExtracts: Asks for the lead section of each article, for the rows that show it.
    func fetchRawResults(for searchTerm: String, siteURL: URL, resultLimit: UInt, fullTextSearchThreshold: Int, includesExtracts: Bool = false) async throws -> RawOutcome {
        let prefixResults: WMFSearchResults
        do {
            prefixResults = try await fetcher.fetchArticles(forSearchTerm: searchTerm, siteURL: siteURL, resultLimit: resultLimit, includesExtracts: includesExtracts)
        } catch let error as CancellationError {
            throw error
        } catch {
            throw Failure.fetch(error, .prefix)
        }

        let prefixCount = prefixResults.results.count
        guard prefixCount < fullTextSearchThreshold else {
            return RawOutcome(prefix: prefixResults, fullText: nil)
        }

        try Task.checkCancellation()

        do {
            let fullTextResults = try await fetcher.fetchArticles(forSearchTerm: searchTerm, siteURL: siteURL, resultLimit: resultLimit, fullTextSearch: true, appendToPreviousResults: nil, includesExtracts: includesExtracts)
            return RawOutcome(prefix: prefixResults, fullText: fullTextResults)
        } catch let error as CancellationError {
            throw error
        } catch {
            guard prefixCount > 0 else {
                throw Failure.fetch(error, .full)
            }
            return RawOutcome(prefix: prefixResults, fullText: nil)
        }
    }
}

extension WMFSearchFetcher {
    func fetchArticles(forSearchTerm searchTerm: String, siteURL: URL, resultLimit: UInt, fullTextSearch: Bool = false, appendToPreviousResults previousResults: WMFSearchResults? = nil, includesExtracts: Bool = false) async throws -> WMFSearchResults {
        try Task.checkCancellation()
        return try await withTaskCancellationHandler {
            do {
                return try await withCheckedThrowingContinuation { continuation in
                    fetchArticles(forSearchTerm: searchTerm, siteURL: siteURL, resultLimit: resultLimit, fullTextSearch: fullTextSearch, appendToPreviousResults: previousResults, includesExtracts: includesExtracts, failure: { error in
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

/// The requests and the list of the treatment arm of the semantic search interleaved experiment. The
/// numbers are in `WMFSemanticSearchInterleavedConfiguration`.
struct SemanticSearchInterleavedLoader {

    struct Outcome {
        /// The list in display order.
        let items: [WMFSemanticSearchInterleavedList.Item]
        /// How the list came out.
        let state: WMFSemanticSearchInterleaveState
        /// Nil when the lexical list is the list alone, with no semantic results to merge.
        let merge: WMFInterleaveResult<WMFSemanticSearchInterleavedList.Item>?
        let searchIDs: WMFSemanticSearchInterleavedIDs
        let lexicalResultsByPageID: [Int: MWKSearchResult]
        let semanticResultsByPageID: [Int: WMFSemanticSearchResult]
        let redirectMappings: [MWKSearchRedirectMapping]
    }

    /// What the semantic request came back with, before it is reduced to page IDs.
    private enum SemanticFetch {
        case answered(WMFSemanticSearchResults)
        case timedOut
        case failed
        case rateLimited

        var isAnswered: Bool {
            if case .answered = self { return true }
            return false
        }

        var response: WMFSemanticSearchInterleavedList.SemanticResponse {
            switch self {
            case .answered(let results): return .results(results.results.map(\.pageID))
            case .timedOut: return .timedOut
            case .failed: return .failed
            case .rateLimited: return .rateLimited
            }
        }
    }

    private struct SemanticTimeout: Error {}

    /// Stands in for a lexical failure that developer settings forces.
    private struct ForcedFailure: Error {}

    let lexicalLoader: SearchResultsLoader

    /// - Parameter forcedScenario: What developer settings forces the two retrievers to do, so every
    ///   state can be reached. Nil for the real requests.
    func fetchResults(for searchTerm: String, siteURL: URL, project: WMFProject, forcedScenario: WMFSemanticSearchInterleavedDataController.ForcedRetrievalScenario? = nil) async throws -> Outcome {
        async let semanticFetch = Self.fetchSemantic(for: searchTerm, project: project, forcedScenario: forcedScenario)

        var rawLexical: SearchResultsLoader.RawOutcome?
        var lexicalError: Error?
        switch forcedScenario {
        case .lexicalReturnsNothing, .bothReturnNothing:
            break
        case .bothFail:
            lexicalError = SearchResultsLoader.Failure.fetch(ForcedFailure(), .prefix)
        default:
            do {
                rawLexical = try await lexicalLoader.fetchRawResults(
                    for: searchTerm,
                    siteURL: siteURL,
                    resultLimit: UInt(WMFSemanticSearchInterleavedConfiguration.lexicalResultsLimit),
                    fullTextSearchThreshold: WMFSemanticSearchInterleavedConfiguration.fullTextThreshold,
                    includesExtracts: true)
            } catch let error as CancellationError {
                throw error
            } catch {
                lexicalError = error
            }
        }

        let semantic = await semanticFetch
        try Task.checkCancellation()

        // Both requests failing is no list: the existing error state shows.
        if let lexicalError, !semantic.isAnswered {
            throw lexicalError
        }

        // The lists are the raw ones their search IDs give. The builder removes duplicates by page ID, so the
        // backend can rebuild the same list from the search IDs.
        let prefixResults = rawLexical?.prefix.results ?? []
        let fullTextResults = rawLexical?.fullText?.results
        let lexicalResults = prefixResults + (fullTextResults ?? [])

        let list = WMFSemanticSearchInterleavedList.build(
            prefix: prefixResults.map(\.articleID),
            fullText: fullTextResults?.map(\.articleID),
            semantic: semantic.response,
            seed: WMFSearchResultsInterleaver.newSeed())

        var semanticAnswered: WMFSemanticSearchResults?
        if case .answered(let answered) = semantic {
            semanticAnswered = answered
        }
        let semanticResults = semanticAnswered?.results ?? []

        var redirectMappings = rawLexical?.prefix.redirectMappings ?? []
        for mapping in rawLexical?.fullText?.redirectMappings ?? [] where !redirectMappings.contains(mapping) {
            redirectMappings.append(mapping)
        }

        return Outcome(
            items: list.items,
            state: list.state,
            merge: list.merge,
            searchIDs: WMFSemanticSearchInterleavedIDs(
                prefix: rawLexical?.prefix.prefixSearchID,
                fullText: rawLexical?.fullText?.fullTextSearchID,
                semantic: semanticAnswered?.searchID),
            lexicalResultsByPageID: Dictionary(lexicalResults.map { ($0.articleID, $0) }, uniquingKeysWith: { first, _ in first }),
            semanticResultsByPageID: Dictionary(semanticResults.map { ($0.pageID, $0) }, uniquingKeysWith: { first, _ in first }),
            redirectMappings: redirectMappings)
    }

    /// A failure or a request that does not answer within the timeout gives the reader the lexical list alone.
    /// Static, so the `async let` that runs it does not capture the loader, which holds non-Sendable lexical request types.
    private static func fetchSemantic(for searchTerm: String, project: WMFProject, forcedScenario: WMFSemanticSearchInterleavedDataController.ForcedRetrievalScenario?) async -> SemanticFetch {
        switch forcedScenario {
        case .semanticTimesOut:
            return .timedOut
        case .semanticFails, .bothFail:
            return .failed
        case .semanticRateLimited:
            return .rateLimited
        case .semanticReturnsNothing, .bothReturnNothing:
            return .answered(WMFSemanticSearchResults(results: []))
        default:
            break
        }

        do {
            let results = try await withThrowingTaskGroup(of: WMFSemanticSearchResults.self) { group in
                group.addTask {
                    try await WMFSemanticSearchDataController.shared.fetchResults(query: searchTerm, project: project, limit: WMFSemanticSearchInterleavedConfiguration.semanticResultsLimit, includesDescriptions: true)
                }
                group.addTask {
                    try await Task.sleep(for: .seconds(WMFSemanticSearchInterleavedConfiguration.semanticTimeoutSeconds))
                    throw SemanticTimeout()
                }
                defer { group.cancelAll() }
                guard let first = try await group.next() else {
                    throw SemanticTimeout()
                }
                return first
            }
            return .answered(results)
        } catch is SemanticTimeout {
            return .timedOut
        } catch WMFSemanticSearchDataController.SearchError.rateLimited {
            return .rateLimited
        } catch {
            return .failed
        }
    }
}
