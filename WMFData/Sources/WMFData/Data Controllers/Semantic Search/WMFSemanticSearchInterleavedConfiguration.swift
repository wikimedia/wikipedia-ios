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
    //   The stage 1 lexical list spec and both apps use 30 today.
    // - fullTextThreshold (10): full text only tops up a prefix list that returned fewer results than this.
    //   The stage 1 spec says 30 (threshold equal to the request limit). Main's loader uses 12 of 24.
    // - minimumQueryLength (3, 2 for Japanese): the length in graphemes from which a query is eligible for
    //   retrieval. The retrieval itself is not held back yet.
    // - semanticTimeoutSeconds (1.5): how long the semantic request may take before the reader gets the
    //   lexical list. The value is still to be settled (US-4).
    //
    // Open question: the backend rebuilds the lexical list from the search IDs, so a different limit or
    // threshold needs to be written into the shared spec. Decide whether it needs a `lexicalVersion` bump,
    // or only gets logged.

    public static let listLength = 10
    public static let semanticResultsLimit = 10
    public static let lexicalResultsLimit = 10
    public static let fullTextThreshold = 10
    public static let semanticTimeoutSeconds = 1.5

    public static func minimumQueryLength(languageCode: String) -> Int {
        languageCode == "ja" ? 2 : 3
    }
}
