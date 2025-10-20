import Foundation
import WMFData

@objc public final class WMFTabsOverviewDidYouKnowViewModel: NSObject, ObservableObject {
    @Published public var facts: [String]
    
    public let languageCode: String?
    public let dykLocalizedStrings: LocalizedStrings
    public let tappedLinkAction: (URL) -> Void
    
    public init(facts: [String], languageCode: String?, tappedLinkAction: @escaping (URL) -> Void, dykLocalizedStrings: LocalizedStrings) {
        self.facts = facts
        self.languageCode = languageCode
        self.tappedLinkAction = tappedLinkAction
        self.dykLocalizedStrings = dykLocalizedStrings
    }

    public var didYouKnowFact: String? {
        guard let randomElement = facts.randomElement() else { return nil }
        return removeBoldTags(in: randomElement)
    }
    
    public var fromSource: String {
        dykLocalizedStrings.fromSource
    }
    
    private func removeBoldTags(in text: String) -> String {
        let boldTagPattern = "(<b>|</b>)"
        var result = text

        if let regex = try? NSRegularExpression(pattern: boldTagPattern, options: .caseInsensitive) {
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "")
        }

        return result
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
