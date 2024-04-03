import Foundation

public struct WKMediaWikiServiceRequest: WKServiceRequest {
    
    public enum TokenType {
        case csrf
        case watch
        case rollback
    }
    
    public enum Backend {
        case mediaWiki // https://www.mediawiki.org/wiki/API:Main_page
        case mediaWikiREST // https://www.mediawiki.org/wiki/API:REST_API
    }

    public let url: URL?
    public let method: WKServiceRequestMethod
    public let backend: Backend
    public var languageVariantCode: String?
    public let tokenType: TokenType?
    public let parameters: [String: Any]?

    internal init(url: URL? = nil, method: WKServiceRequestMethod, backend: Backend, languageVariantCode: String? = nil, tokenType: WKMediaWikiServiceRequest.TokenType? = nil, parameters: [String : Any]? = nil) {
        self.url = url
        self.method = method
        self.backend = backend
        self.languageVariantCode = languageVariantCode
        self.tokenType = tokenType
        self.parameters = parameters
    }
}
