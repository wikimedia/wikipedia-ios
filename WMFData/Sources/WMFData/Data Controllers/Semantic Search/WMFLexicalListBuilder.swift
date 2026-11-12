import Foundation

/// Builds the lexical list that feeds the Team-Draft merge from the prefix and full text results, as proposed
/// in the stage 1 lexical list spec on mediawiki.org. It is a pure function of its inputs.
///
/// TODO: Confirm with Android, Research and Search, then hash out and move into the shared spec. Anything that
/// changes the list for the same inputs needs a new `lexicalVersion` and regenerated vectors.
public enum WMFLexicalListBuilder {

    public static let lexicalVersion = 1

    /// Full text results are added only when prefix search returns fewer results than this. Both apps request 30 on the first load.
    public static let fullTextThreshold = 30

    /// - Parameters:
    ///   - prefix: The prefix search results, in rank order.
    ///   - fullText: The full text search results in rank order, or nil if the request was not made or failed.
    ///   - fullTextThreshold: Full text is used only when `prefix` has fewer results than this.
    ///   - pageID: The duplicate key.
    public static func build<Item>(
        prefix: [Item],
        fullText: [Item]?,
        fullTextThreshold: Int = WMFLexicalListBuilder.fullTextThreshold,
        pageID: (Item) -> Int
    ) -> [Item] {
        var combined = prefix
        if let fullText, prefix.count < fullTextThreshold {
            combined += fullText
        }

        var seenPageIDs = Set<Int>()
        return combined.filter { seenPageIDs.insert(pageID($0)).inserted }
    }
}
