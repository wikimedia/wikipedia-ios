import Foundation

/// Builds the list that a treatment reader sees: the lexical list from the prefix and full text results, merged
/// with the semantic results. It works on page IDs, and the caller turns them into rows.
public enum WMFSemanticSearchInterleavedList {

    public enum Source: String, Sendable, Equatable {
        case lexicalPrefix
        case lexicalFullText
        case semantic
    }

    public struct Item: Sendable, Equatable {
        public let pageID: Int
        public let source: Source

        public init(pageID: Int, source: Source) {
            self.pageID = pageID
            self.source = source
        }
    }

    /// What the semantic request came back with.
    public enum SemanticResponse: Sendable, Equatable {
        /// The page IDs of the semantic results, in rank order. Can be empty.
        case results([Int])
        case timedOut
        case failed
        case rateLimited
    }

    public struct Result: Sendable {
        public let items: [Item]
        /// How the list came out. Both requests failing is no list at all, so it has no state.
        public let state: WMFSemanticSearchInterleaveState
        /// Nil when there were no semantic results to merge, and the list is the lexical list alone.
        public let merge: WMFInterleaveResult<Item>?
    }

    /// - Parameters:
    ///   - prefix: The page IDs of the prefix results, in rank order.
    ///   - fullText: The page IDs of the full text results, or nil if the request was not made or failed.
    ///   - semantic: What the semantic request came back with.
    ///   - seed: The seed of the merge.
    public static func build(prefix: [Int], fullText: [Int]?, semantic: SemanticResponse, seed: UInt64) -> Result {
        let lexical = WMFLexicalListBuilder.build(
            prefix: prefix.map { Item(pageID: $0, source: .lexicalPrefix) },
            fullText: fullText?.map { Item(pageID: $0, source: .lexicalFullText) },
            fullTextThreshold: WMFSemanticSearchInterleavedConfiguration.fullTextThreshold,
            pageID: { $0.pageID }
        )

        let semanticPageIDs: [Int]
        switch semantic {
        case .results(let pageIDs):
            semanticPageIDs = pageIDs
        case .timedOut:
            return lexicalOnly(lexical, state: .lexicalOnlyTimeout)
        case .failed:
            return lexicalOnly(lexical, state: .lexicalOnlyError)
        case .rateLimited:
            return lexicalOnly(lexical, state: .lexicalOnlyRateLimited)
        }

        let merge = WMFSearchResultsInterleaver.merge(
            lexical: lexical,
            semantic: semanticPageIDs.map { Item(pageID: $0, source: .semantic) },
            listLength: WMFSemanticSearchInterleavedConfiguration.listLength,
            seed: seed,
            pageID: { $0.pageID }
        )
        return Result(items: merge.slots.map(\.item), state: state(lexicalIsEmpty: lexical.isEmpty, semanticIsEmpty: semanticPageIDs.isEmpty), merge: merge)
    }

    private static func lexicalOnly(_ lexical: [Item], state: WMFSemanticSearchInterleaveState) -> Result {
        Result(items: Array(lexical.prefix(WMFSemanticSearchInterleavedConfiguration.listLength)), state: state, merge: nil)
    }

    /// The state of a list when the semantic request answered.
    private static func state(lexicalIsEmpty: Bool, semanticIsEmpty: Bool) -> WMFSemanticSearchInterleaveState {
        switch (lexicalIsEmpty, semanticIsEmpty) {
        case (false, false): return .full
        case (true, false): return .semanticOnly
        case (false, true): return .lexicalOnlyEmpty
        case (true, true): return WMFSemanticSearchInterleaveState.none
        }
    }
}
