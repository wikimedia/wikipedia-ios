import Foundation

/// Locates occurrences of search term in a `[TalkPageCellViewModel]` hierarchy
final class TalkPageFindInPageController {

    // MARK: - Nested Types

    struct SearchResult {

        enum Location {
            // Term was located within the topic's title for topic at associated index
            case topicTitle(topicIndex: Int)

            // Term was located within the topic's lead comment text for topic at associated index
            case topicLeadComment(topicIndex: Int)

            // The term was located within a topic's reply text, for topic and reply at associated indices
            case reply(topicIndex: Int, replyIndex: Int)
        }


        // Term user searched for
        let term: String

        // Location of result in topic/reply hierarchy
        var location: Location

        // Case insensitive range of term in raw HTML-removed text at result location
        var range: NSRange?

    }

    // MARK: - Public

    /// Search for occurrences of a text term in `[TalkPageCellViewModel]` hierarchy
    /// - Parameters:
    ///   - searchTerm: the term to locate, case insensitive
    ///   - topics: an ordered array of topics
    /// - Returns: An ordered array of SearchResult's indicating occurrences where the term was located
    func search(term searchTerm: String, in topics: [TalkPageCellViewModel]) -> [SearchResult] {
        var results: [SearchResult] = []

        for (topicIndex, topic) in topics.enumerated() {
            if topic.topicTitle.removingHTML.localizedCaseInsensitiveContains(searchTerm) {
                let bridgedText = NSString(string: topic.topicTitle.removingHTML)
                let rangeOfTerm = bridgedText.range(of: searchTerm, options: .caseInsensitive)
                let result = SearchResult(term: searchTerm, location: .topicTitle(topicIndex: topicIndex), range: rangeOfTerm)
                results.append(result)
            }

            if topic.leadComment.text.removingHTML.localizedCaseInsensitiveContains(searchTerm) {
                let bridgedText = NSString(string: topic.leadComment.text.removingHTML)
                let rangeOfTerm = bridgedText.range(of: searchTerm, options: .caseInsensitive)
                let result = SearchResult(term: searchTerm, location: .topicLeadComment(topicIndex: topicIndex), range: rangeOfTerm)
                results.append(result)
            }

            for (replyIndex, reply) in topic.replies.enumerated() {
                if reply.text.removingHTML.localizedCaseInsensitiveContains(searchTerm) {
                    let bridgedText = NSString(string: reply.text.removingHTML)
                    let rangeOfTerm = bridgedText.range(of: searchTerm, options: .caseInsensitive)
                    let result = SearchResult(term: searchTerm, location: .reply(topicIndex: topicIndex, replyIndex: replyIndex), range: rangeOfTerm)
                    results.append(result)
                }
            }
        }

        return results
    }

}
