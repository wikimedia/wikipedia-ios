import Foundation
import WMFData

@objc public final class WMFNewArticleTabDidYouKnowViewModel: NSObject, ObservableObject {
    @Published public var isLoading: Bool = true
    @Published public var facts: [String]? = nil
    
    public let fromSourceDefault: String
    public let languageCode: String?
    public let dykLocalizedStrings: LocalizedStrings?
    
    public init(isLoading: Bool, facts: [String]? = nil, fromSourceDefault: String, languageCode: String?, dykLocalizedStrings: LocalizedStrings?) {
        self.isLoading = isLoading
        self.facts = facts
        self.fromSourceDefault = fromSourceDefault
        self.languageCode = languageCode
        self.dykLocalizedStrings = dykLocalizedStrings
    }

    public var dyk: String? {
        guard let randomElement = facts?.randomElement() else { return nil }
        let cleanedText = replaceEllipsesWithSpace(in: randomElement)

        guard let dykPrefix = dykLocalizedStrings?.dyk, !dykPrefix.isEmpty else {
            return cleanedText
        }

        let removeEllipses = replaceEllipsesWithSpace(in: randomElement)
        let combined = dykPrefix + " " + removeEllipses
        return combined
    }
    
    public var fromSource: String {
        dykLocalizedStrings?.fromSource ?? fromSourceDefault
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
    
    public struct LocalizedStrings {
        let dyk: String
        let fromSource: String
        
        public init(dyk: String, fromSource: String) {
            self.dyk = dyk
            self.fromSource = fromSource
        }
    }
}
