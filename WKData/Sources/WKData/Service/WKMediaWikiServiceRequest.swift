import Foundation

public struct WKMediaWikiServiceRequest: WKServiceRequest {
    
    public enum TokenType {
        case csrf
        case watch
        case rollback
    }

    public let url: URL?
    public let method: WKServiceRequestMethod
    public var languageVariantCode: String?
    public let tokenType: TokenType?
    public let parameters: [String: Any]?
    public let bodyContentType: WKServiceRequestBodyContentType?

    internal init(url: URL? = nil, method: WKServiceRequestMethod, languageVariantCode: String? = nil, tokenType: WKMediaWikiServiceRequest.TokenType? = nil, parameters: [String : Any]? = nil, bodyContentType: WKServiceRequestBodyContentType? = nil) {
        self.url = url
        self.method = method
        self.languageVariantCode = languageVariantCode
        self.tokenType = tokenType
        self.parameters = parameters
        self.bodyContentType = bodyContentType
    }
}
