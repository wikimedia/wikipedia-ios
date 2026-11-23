import Foundation

// TODO: Still to be settled. The `interleave_state` values come from US-4. `lexical_only_empty` is provisional.

/// How the list came out, as US-4 defines it. Only `full` lists count toward preference credit.
/// The control arm has no state: it shows today's list with no semantic request.
public enum WMFSemanticSearchInterleaveState: String, Sendable, Equatable, CaseIterable {
    /// Both retrievers answered and the lists were merged.
    case full
    /// The semantic request did not arrive within the timeout; the list is lexical only.
    case lexicalOnlyTimeout = "lexical_only_timeout"
    /// The semantic request failed or the backend was unavailable; the list is lexical only.
    case lexicalOnlyError = "lexical_only_error"
    /// The semantic request was rate limited; the list is lexical only.
    case lexicalOnlyRateLimited = "lexical_only_rate_limited"
    /// Semantic returned nothing and lexical returned results; the list is lexical only.
    /// Provisional: US-4 names no state for this case. Not a preference unit, since it has no
    /// semantic results. Still to be confirmed.
    case lexicalOnlyEmpty = "lexical_only_empty"
    /// Lexical returned nothing and semantic returned results.
    case semanticOnly = "semantic_only"
    /// Both returned nothing: the existing empty state shows.
    case none
}

/// The search IDs from the response headers of the three requests. Analytics looks them up to
/// rebuild the lists the merge worked with.
public struct WMFSemanticSearchInterleavedIDs: Sendable, Equatable {
    public let prefix: String?
    public let fullText: String?
    public let semantic: String?

    public init(prefix: String?, fullText: String?, semantic: String?) {
        self.prefix = prefix
        self.fullText = fullText
        self.semantic = semantic
    }
}
