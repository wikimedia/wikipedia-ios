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

    func fetchResults(for searchTerm: String, siteURL: URL, resultLimit: UInt = WMFMaxSearchResultLimit, fullTextSearchThreshold: Int = SearchResultsLoader.fullTextSearchThreshold) async throws -> Outcome {
        let prefixResults: WMFSearchResults
        do {
            prefixResults = try await fetcher.fetchArticles(forSearchTerm: searchTerm, siteURL: siteURL, resultLimit: resultLimit)
        } catch let error as CancellationError {
            throw error
        } catch {
            throw Failure.fetch(error, .prefix)
        }

        let prefixCount = prefixResults.results.count
        guard prefixCount < fullTextSearchThreshold else {
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
        let latency: WMFSemanticSearchInterleavedLatency
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
        let clock = ContinuousClock()
        let start = clock.now
        async let semanticFetch = fetchSemantic(for: searchTerm, project: project, forcedScenario: forcedScenario)

        var lexicalOutcome: SearchResultsLoader.Outcome?
        var lexicalError: Error?
        var lexicalMs: Int?
        switch forcedScenario {
        case .lexicalReturnsNothing, .bothReturnNothing:
            break
        case .bothFail:
            lexicalError = SearchResultsLoader.Failure.fetch(ForcedFailure(), .prefix)
        default:
            do {
                let lexicalStart = clock.now
                defer { lexicalMs = (clock.now - lexicalStart).milliseconds }
                lexicalOutcome = try await lexicalLoader.fetchResults(
                    for: searchTerm,
                    siteURL: siteURL,
                    resultLimit: UInt(WMFSemanticSearchInterleavedConfiguration.lexicalResultsLimit),
                    fullTextSearchThreshold: WMFSemanticSearchInterleavedConfiguration.fullTextThreshold)
            } catch let error as CancellationError {
                throw error
            } catch {
                lexicalError = error
            }
        }

        let (semantic, semanticMs) = await semanticFetch
        try Task.checkCancellation()

        // Both requests failing is no list: the existing error state shows.
        if let lexicalError, !semantic.isAnswered {
            throw lexicalError
        }

        let lexicalResults = lexicalOutcome?.results.results ?? []
        let prefixCount = lexicalOutcome?.prefixResultCount ?? 0
        let fullTextResults: [MWKSearchResult]? = lexicalOutcome?.type == .full ? Array(lexicalResults.dropFirst(prefixCount)) : nil

        let mergeStart = clock.now
        let list = WMFSemanticSearchInterleavedList.build(
            prefix: lexicalResults.prefix(prefixCount).map(\.articleID),
            fullText: fullTextResults?.map(\.articleID),
            semantic: semantic.response,
            seed: WMFSearchResultsInterleaver.newSeed())
        let mergeMs = (clock.now - mergeStart).milliseconds

        var semanticAnswered: WMFSemanticSearchResults?
        if case .answered(let answered) = semantic {
            semanticAnswered = answered
        }
        let semanticResults = semanticAnswered?.results ?? []

        let searchIDs = WMFSemanticSearchInterleavedIDs(
            prefix: lexicalOutcome?.results.prefixSearchID,
            fullText: lexicalOutcome?.results.fullTextSearchID,
            semantic: semanticAnswered?.searchID)
        let latency = WMFSemanticSearchInterleavedLatency(
            lexicalMs: lexicalMs,
            semanticMs: semanticAnswered == nil ? nil : semanticMs,
            mergeMs: mergeMs,
            totalMs: (clock.now - start).milliseconds)

        return Outcome(
            items: list.items,
            state: list.state,
            merge: list.merge,
            latency: latency,
            searchIDs: searchIDs,
            lexicalResultsByPageID: Dictionary(lexicalResults.map { ($0.articleID, $0) }, uniquingKeysWith: { first, _ in first }),
            semanticResultsByPageID: Dictionary(semanticResults.map { ($0.pageID, $0) }, uniquingKeysWith: { first, _ in first }),
            redirectMappings: lexicalOutcome?.results.redirectMappings ?? [])
    }

    /// A failure or a request that does not answer within the timeout gives the reader the lexical list alone.
    private func fetchSemantic(for searchTerm: String, project: WMFProject, forcedScenario: WMFSemanticSearchInterleavedDataController.ForcedRetrievalScenario?) async -> (SemanticFetch, Int) {
        let clock = ContinuousClock()
        let start = clock.now
        let fetch = await fetchSemanticResults(for: searchTerm, project: project, forcedScenario: forcedScenario)
        return (fetch, (clock.now - start).milliseconds)
    }

    private func fetchSemanticResults(for searchTerm: String, project: WMFProject, forcedScenario: WMFSemanticSearchInterleavedDataController.ForcedRetrievalScenario?) async -> SemanticFetch {
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
                    try await WMFSemanticSearchDataController.shared.fetchResults(query: searchTerm, project: project, limit: WMFSemanticSearchInterleavedConfiguration.semanticResultsLimit)
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

extension Duration {

    var milliseconds: Int {
        Int(components.seconds * 1000 + components.attoseconds / 1_000_000_000_000_000)
    }
}
