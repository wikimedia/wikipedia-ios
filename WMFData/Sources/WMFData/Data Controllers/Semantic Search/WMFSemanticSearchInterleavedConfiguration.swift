import Foundation

/// The numbers of the semantic search interleaved experiment's treatment arm. Only readers in this experiment
/// use them. Everyone else keeps the numbers of the regular search.
public enum WMFSemanticSearchInterleavedConfiguration {

    // MARK: - TODO
    //
    // TODO: EVERY NUMBER IN THIS ENUM IS PROVISIONAL. Double check each one with the PMs before this
    // ships:
    //
    // - listLength (10): how many results the merged list shows.
    // - semanticResultsLimit (10): how many results the semantic request asks for. Dive's sheet asks for 8.
    // - lexicalResultsLimit (10): how many results each lexical request (prefix and full text) asks for.
    //   The stage 1 lexical list builder (EF-1) uses the same 10 as its default for now.
    // - fullTextThreshold (10): full text only tops up a prefix list that returned fewer results than this.
    //   It equals the request limit, and the stage 1 builder (EF-1) uses 10 as its default for now.
    // - semanticTimeoutSeconds (5.0): how long the semantic request may take before the reader gets the
    //   lexical list. The value is still to be settled (US-4).
    //
    // The backend rebuilds the lexical list from the search IDs, so the lexical limit and the full text
    // threshold must match the stage 1 spec. They do for now, so `lexicalVersion` stays 1. When the numbers
    // are confirmed, check that the spec and these values still agree, and decide whether a change needs a
    // `lexicalVersion` bump.

    public static let listLength = 10
    public static let semanticResultsLimit = 10
    public static let lexicalResultsLimit = 10
    public static let fullTextThreshold = 10
    public static let semanticTimeoutSeconds = 5.0
}
