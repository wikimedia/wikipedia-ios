import Foundation
import WMFNativeLocalizations

@MainActor
public final class WMFSemanticSearchEntryPointViewModel: ObservableObject {

    public typealias Action = @MainActor @Sendable (String) -> Void

    @Published public private(set) var query: String
    public let languageCode: String
    public let showsTryItNow: Bool

    private let tapAction: Action
    private let infoAction: Action
    private let hideAction: Action

    private(set) lazy var betaLabel = CommonStrings.betaLabel(languageCode: languageCode)
    private(set) lazy var description = WMFLocalizedString("search-semantic-entry-point-description", languageCode: languageCode, value: "Search within articles and jump straight to the relevant passage", comment: "Explanatory text of the semantic search entry point shown above the search suggestions.")
    private(set) lazy var tryItNowTitle = WMFLocalizedString("search-semantic-entry-point-try-it-now", languageCode: languageCode, value: "Try it now", comment: "Call to action shown in the semantic search entry point above the search suggestions until the reader uses it for the first time.")
    private(set) lazy var infoAccessibilityLabel = WMFLocalizedString("search-semantic-entry-point-info-accessibility-label", languageCode: languageCode, value: "About searching within articles", comment: "Accessibility label of the info button in the semantic search entry point shown above the search suggestions.")
    private(set) lazy var hideAccessibilityLabel = WMFLocalizedString("search-semantic-entry-point-hide-accessibility-label", languageCode: languageCode, value: "Hide searching within articles", comment: "Accessibility label of the button that hides the semantic search entry point shown above the search suggestions.")
    private(set) lazy var accessibilityHint = WMFLocalizedString("search-semantic-entry-point-accessibility-hint", languageCode: languageCode, value: "Searches within articles for your query", comment: "Accessibility hint of the semantic search entry point shown above the search suggestions. Read by VoiceOver after the label to explain what happens on activation.")

    public init(
        query: String,
        languageCode: String,
        showsTryItNow: Bool,
        tapAction: @escaping Action,
        infoAction: @escaping Action,
        hideAction: @escaping Action
    ) {
        self.query = query
        self.languageCode = languageCode
        self.showsTryItNow = showsTryItNow
        self.tapAction = tapAction
        self.infoAction = infoAction
        self.hideAction = hideAction
    }

    public func update(query: String) {
        self.query = query
    }

    func tap() {
        tapAction(query)
    }

    func showInfo() {
        infoAction(query)
    }

    func hide() {
        hideAction(query)
    }
}
