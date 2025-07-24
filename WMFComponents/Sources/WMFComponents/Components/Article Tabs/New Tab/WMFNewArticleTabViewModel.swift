import Foundation

public final class WMFNewArticleTabViewModel {

    let text: String
    public let title: String
    public let facts: [String]?

    public init (text: String, title: String, facts: [String]? = nil) {
        self.text = text
        self.title = title
        self.facts = facts
    }
    
    public var dyk: String? {
        guard facts != nil, let randomElement = facts?.randomElement() else { return nil }
        return replaceEllipsesWithSpace(in: randomElement)
    }

    private func replaceEllipsesWithSpace(in text: String) -> String {
        let ellipsisPattern = "(\\.\\.\\.|…)" // ellipses
        let spaceCollapsePattern = "\\s{2,}"  // excessive whitespace

        var result = text

        if let ellipsisRegex = try? NSRegularExpression(pattern: ellipsisPattern) {
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            result = ellipsisRegex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: " ")
        }

        if let spaceRegex = try? NSRegularExpression(pattern: spaceCollapsePattern) {
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            result = spaceRegex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: " ")
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
