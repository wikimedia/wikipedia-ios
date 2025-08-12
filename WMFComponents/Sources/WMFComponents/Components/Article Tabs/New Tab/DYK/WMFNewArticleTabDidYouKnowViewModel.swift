import Foundation
import WMFData

@objc public final class WMFNewArticleTabDidYouKnowViewModel: NSObject, ObservableObject {
    @Published public var facts: [String]
    
    public let languageCode: String?
    public let dykLocalizedStrings: LocalizedStrings
    
    public init(facts: [String], languageCode: String?, dykLocalizedStrings: LocalizedStrings) {
        self.facts = facts
        self.languageCode = languageCode
        self.dykLocalizedStrings = dykLocalizedStrings
    }

    public var didYouKnowFact: String? {
        guard let randomElement = facts.randomElement() else { return nil }
        let dykPrefix = dykLocalizedStrings.didYouKnowString
        let removeEllipses = replaceEllipsesWithSpace(in: randomElement)
        let combined = dykPrefix + " " + removeEllipses
        return combined
    }
    
    public var fromSource: String {
        dykLocalizedStrings.fromSource
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
        let didYouKnowTitle: String
        let fromSource: String
        
        public init(didYouKnowTitle: String, fromSource: String) {
            self.didYouKnowTitle = didYouKnowTitle
            self.fromSource = fromSource
        }
    }
}
