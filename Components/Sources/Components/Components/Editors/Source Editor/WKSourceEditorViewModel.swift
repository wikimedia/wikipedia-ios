import Foundation

public class WKSourceEditorViewModel {
    
    // MARK: - Nested Types
    
    public enum Configuration: String {
        case short
        case full
    }
    
    // MARK: - Properties
    
    public var configuration: Configuration
    public let initialText: String
    
    // MARK: - Public

    public init(configuration: Configuration, initialText: String) {
        self.configuration = configuration
        self.initialText = initialText
    }
}
