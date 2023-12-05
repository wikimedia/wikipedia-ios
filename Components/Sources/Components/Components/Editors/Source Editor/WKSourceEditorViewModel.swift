import Foundation
import UIKit

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
    public var textAlignment: NSTextAlignment
    
    // MARK: - Public

    public init(configuration: Configuration,
                initialText: String,
                accessibilityIdentifiers: WKSourceEditorAccessibilityIdentifiers? = nil,
                localizedStrings: WKSourceEditorLocalizedStrings,
                isSyntaxHighlightingEnabled: Bool,
                textAlignment: NSTextAlignment) {
        self.configuration = configuration
        self.initialText = initialText
        WKSourceEditorAccessibilityIdentifiers.current = accessibilityIdentifiers
        WKSourceEditorLocalizedStrings.current = localizedStrings
        self.isSyntaxHighlightingEnabled = isSyntaxHighlightingEnabled
        self.textAlignment = textAlignment
    }
}
