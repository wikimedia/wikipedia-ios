import Foundation

public final class WMFNewArticleTabViewModel {

    let text: String
    public let title: String

    public init (text: String, title: String) {
        self.text = text
        self.title = title
    }
    
    public var dyk: String {
        replaceEllipsesWithSpace(in: "Did you know...that a <a href=\"https://en.wikipedia.org\">15-second commercial for a streaming service</a> has been blamed for causing arguments and domestic violence?")
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
