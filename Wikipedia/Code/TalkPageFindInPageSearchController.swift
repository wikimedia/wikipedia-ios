import Foundation

/// Locates occurrences of search term in a `[TalkPageCellViewModel]` hierarchy
final class TalkPageFindInPageSearchController {

    // MARK: - Nested Types

    struct SearchResult {

        enum Location {
            // Term was located within the topic's title for topic at associated index
            case topicTitle(topicIndex: Int, topicIdentifier: ObjectIdentifier)

            // Term was located within the topic's lead comment text for topic at associated index
            case topicLeadComment(topicIndex: Int, replyIdentifier: ObjectIdentifier)

            // Term was located within topic's other content text for topic at associated index
            case topicOtherContent(topicIndex: Int)

            // The term was located within a topic's reply text, for topic and reply at associated indices
            case reply(topicIndex: Int, topicIdentifier: ObjectIdentifier, replyIndex: Int, replyIdentifier: ObjectIdentifier)
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
                let rangesOfTerm = bridgedText.ranges(of: searchTerm)
                for range in rangesOfTerm {
                    let result = SearchResult(term: searchTerm, location: .topicTitle(topicIndex: topicIndex, topicIdentifier: topic.id), range: range)
                    results.append(result)
                }
            }

            if let leadComment = topic.leadComment,
               leadComment.text.removingHTML.localizedCaseInsensitiveContains(searchTerm) {
                let bridgedText = NSString(string: leadComment.text.removingHTML)
                let rangesOfTerm = bridgedText.ranges(of: searchTerm)
                for range in rangesOfTerm {
                    let result = SearchResult(term: searchTerm, location: .topicLeadComment(topicIndex: topicIndex, replyIdentifier: leadComment.id), range: range)
                    results.append(result)
                }
            } else if let otherContent = topic.otherContent,
               otherContent.removingHTML.localizedCaseInsensitiveContains(searchTerm) {
                let bridgedText = NSString(string: otherContent.removingHTML)
                let rangesOfTerm = bridgedText.ranges(of: searchTerm)
                
                for range in rangesOfTerm {
                    let result = SearchResult(term: searchTerm, location: .topicOtherContent(topicIndex: topicIndex), range: range)
                    results.append(result)
                }
            }

            for (replyIndex, reply) in topic.replies.enumerated() {
                if reply.text.removingHTML.localizedCaseInsensitiveContains(searchTerm) {
                    let bridgedText = NSString(string: reply.text.removingHTML)
                    let rangesOfTerm = bridgedText.ranges(of: searchTerm)
                    for range in rangesOfTerm {
                        let result = SearchResult(term: searchTerm, location: .reply(topicIndex: topicIndex, topicIdentifier: topic.id, replyIndex: replyIndex, replyIdentifier: reply.id), range: range)
                        results.append(result)
                    }
                }
            }
        }

        return results
    }

}
