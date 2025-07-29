import Foundation

public final class WMFNewArticleTabViewModel: ObservableObject {
    @Published public var isLoading: Bool = true
    @Published public var facts: [String]? = nil

    public let text: String
    public let title: String
    public let fromSourceDefault: String
    public let languageCode: String?
    public let dykLocalizedStrings: DYKLocalizedStrings?

    public init(text: String, title: String, facts: [String]? = nil, languageCode: String? = nil, dykLocalizedStrings: DYKLocalizedStrings? = nil, fromSourceDefault: String) {
        self.text = text
        self.title = title
        self.facts = facts
        self.isLoading = facts == nil
        self.languageCode = languageCode
        self.dykLocalizedStrings = dykLocalizedStrings
        self.fromSourceDefault = fromSourceDefault
    }
    
    // MARK: - DYK

    public var dyk: String? {
        guard let randomElement = facts?.randomElement() else { return nil }
        let cleanedText = replaceEllipsesWithSpace(in: randomElement)

        guard let languageCode,
              let dykPrefix = dykLocalizedStrings?.dyk,
              !dykPrefix.isEmpty else {
            return cleanedText
        }

        let rewrittenHTML = replaceRelativeHrefs(in: randomElement, languageCode: languageCode)
        let removeEllipses = replaceEllipsesWithSpace(in: rewrittenHTML)
        let combined = dykPrefix + " " + removeEllipses
        return combined
    }

    private func replaceRelativeHrefs(in html: String, languageCode: String) -> String {
        let pattern = #"href="\./([^"]+)""#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return html
        }

        let nsrange = NSRange(html.startIndex..<html.endIndex, in: html)
        var result = html
        let matches = regex.matches(in: html, options: [], range: nsrange).reversed()

        for match in matches {
            guard match.numberOfRanges > 1,
                  let hrefRange = Range(match.range(at: 1), in: html) else {
                continue
            }

            let relativePath = html[hrefRange]
            let fullURL = "https://\(languageCode).wikipedia.org/wiki/\(relativePath)"
            let replacement = #"href="\#(fullURL)""#

            if let fullMatchRange = Range(match.range(at: 0), in: html) {
                result.replaceSubrange(fullMatchRange, with: replacement)
            }
        }

        return result
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
    
    public struct DYKLocalizedStrings {
        let dyk: String
        let fromSource: String
        
        public init(dyk: String, fromSource: String) {
            self.dyk = dyk
            self.fromSource = fromSource
        }
    }
}
