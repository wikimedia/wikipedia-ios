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

        let combined = dykPrefix + " " + cleanedText
        let sanitized = sanitizeMalformedHrefs(in: combined)
        print("Sanitized: \(sanitized)")
        return transformWikiLinks(in: sanitized, languageCode: languageCode)
    }
    
    // Clean out the ellipses, any massive spaces, and anything else that might make the URL not work
    private func transformWikiLinks(in html: String, languageCode: String) -> String {
        let pattern = "<a[^>]+href=[\"']\\./([^\"'>]+)[\"']"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return html
        }

        let nsRange = NSRange(html.startIndex..<html.endIndex, in: html)
        var resultHTML = html

        var urlSafeCharacters = CharacterSet.urlPathAllowed
        urlSafeCharacters.remove(charactersIn: "\"'")

        regex.matches(in: html, options: [], range: nsRange).reversed().forEach { match in
            guard let pageTitleRange = Range(match.range(at: 1), in: resultHTML) else { return }

            let pageTitle = String(resultHTML[pageTitleRange])

            guard let encodedTitle = pageTitle.addingPercentEncoding(withAllowedCharacters: urlSafeCharacters) else { return }

            let url = "https://\(languageCode).wikipedia.org/wiki/\(encodedTitle)"

            if let fullRange = Range(match.range(at: 0), in: resultHTML) {
                let newHref = "<a href=\"\(url)\""
                resultHTML.replaceSubrange(fullRange, with: newHref)
            }
        }

        return resultHTML
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
    
    private func sanitizeMalformedHrefs(in html: String) -> String {
        let pattern = #"href="((?:https://|\.\/)en\.wikipedia\.org/wiki/[^"]*)""#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return html
        }

        let nsRange = NSRange(html.startIndex..<html.endIndex, in: html)
        var resultHTML = html

        regex.matches(in: html, options: [], range: nsRange).reversed().forEach { match in
            guard let range = Range(match.range(at: 1), in: resultHTML) else { return }
            let originalURL = String(resultHTML[range])

            let baseURL: String
            let path: String

            if originalURL.hasPrefix("https://en.wikipedia.org") {
                baseURL = "https://en.wikipedia.org"
                path = String(originalURL.dropFirst(baseURL.count))
            } else if originalURL.hasPrefix("./") {
                baseURL = "./"
                path = String(originalURL.dropFirst(2))
            } else {
                return
            }
            guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else { return }

            let sanitizedURL = baseURL + encodedPath
            resultHTML.replaceSubrange(range, with: sanitizedURL)
        }

        return resultHTML
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
