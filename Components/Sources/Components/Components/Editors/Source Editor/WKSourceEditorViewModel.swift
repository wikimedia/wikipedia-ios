import Foundation

public class WKSourceEditorViewModel {
    
    // MARK: - Nested Types
    
    public enum Configuration: String {
        case short
        case full
    }
    
    // MARK: - Properties
    
    public let configuration: Configuration
    public let initialText: String
    public var isSyntaxHighlightingEnabled: Bool
    
    // MARK: - Public

    public init(configuration: Configuration,
                initialText: String,
                accessibilityIdentifiers: WKSourceEditorAccessibilityIdentifiers? = nil,
                localizedStrings: WKSourceEditorLocalizedStrings,
                isSyntaxHighlightingEnabled: Bool) {
        self.configuration = configuration
        self.initialText = initialText
        WKSourceEditorAccessibilityIdentifiers.current = accessibilityIdentifiers
        WKSourceEditorLocalizedStrings.current = localizedStrings
        self.isSyntaxHighlightingEnabled = isSyntaxHighlightingEnabled
    }
}
