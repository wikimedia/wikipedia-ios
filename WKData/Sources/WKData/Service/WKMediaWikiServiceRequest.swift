import Foundation

public struct WKMediaWikiServiceRequest: WKServiceRequest {
    public enum TokenType {
        case csrf
        case watch
        case rollback
    }

    public let url: URL?
    public let method: WKServiceRequestMethod
    public let tokenType: TokenType?
    public let parameters: [String: Any]?

    internal init(url: URL? = nil, method: WKServiceRequestMethod, tokenType: WKMediaWikiServiceRequest.TokenType? = nil, parameters: [String : Any]? = nil) {
        self.url = url
        self.method = method
        self.tokenType = tokenType
        self.parameters = parameters
    }
}
