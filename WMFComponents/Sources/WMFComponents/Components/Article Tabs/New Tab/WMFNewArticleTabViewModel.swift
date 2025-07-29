import Foundation

public final class WMFNewArticleTabViewModel: ObservableObject {
    @Published public var isLoading: Bool = true
    @Published public var facts: [String]? = nil

    public let text: String
    public let title: String
    public let fromSourceDefault: String
    public let languageCode: String?
    public let dykLocalizedStrings: DYKLocalizedStrings?
    public let tappedURLAction: (URL?) -> Void

    public init(text: String, title: String, facts: [String]? = nil, languageCode: String? = nil, dykLocalizedStrings: DYKLocalizedStrings? = nil, fromSourceDefault: String, tappedURLAction: @escaping (URL?) -> Void) {
        self.text = text
        self.title = title
        self.facts = facts
        self.isLoading = facts == nil
        self.languageCode = languageCode
        self.dykLocalizedStrings = dykLocalizedStrings
        self.fromSourceDefault = fromSourceDefault
        self.tappedURLAction = tappedURLAction
    }
    
    // MARK: - DYK

    public var dyk: String? {
        guard let randomElement = facts?.randomElement() else { return nil }
        
        return randomElement
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
