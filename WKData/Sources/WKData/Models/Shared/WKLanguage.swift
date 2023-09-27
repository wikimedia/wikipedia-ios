import Foundation

public struct WKLanguage: Equatable, Codable {
    public let languageCode: String
    public let languageVariantCode: String?
    
    public init(languageCode: String, languageVariantCode: String?) {
        self.languageCode = languageCode
        self.languageVariantCode = languageVariantCode
    }
}
