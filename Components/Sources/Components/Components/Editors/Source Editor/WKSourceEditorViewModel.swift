import Foundation
import UIKit
import WKData

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
    public let needsReadOnly: Bool
    public let onloadSelectRange: NSRange?
    public let linterResponse: WKSandboxDataController.LintAPIResponse?
    
    // MARK: - Public

    public init(configuration: Configuration,
                initialText: String,
                accessibilityIdentifiers: WKSourceEditorAccessibilityIdentifiers? = nil,
                localizedStrings: WKSourceEditorLocalizedStrings,
                isSyntaxHighlightingEnabled: Bool,
                textAlignment: NSTextAlignment,
                needsReadOnly: Bool,
                onloadSelectRange: NSRange?,
                linterResponse: WKSandboxDataController.LintAPIResponse?) {
        self.configuration = configuration
        self.initialText = initialText
        WKSourceEditorAccessibilityIdentifiers.current = accessibilityIdentifiers
        WKSourceEditorLocalizedStrings.current = localizedStrings
        self.isSyntaxHighlightingEnabled = isSyntaxHighlightingEnabled
        self.textAlignment = textAlignment
        self.needsReadOnly = needsReadOnly
        self.onloadSelectRange = onloadSelectRange
        self.linterResponse = linterResponse
    }
}
