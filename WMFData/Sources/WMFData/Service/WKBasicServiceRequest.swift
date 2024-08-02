import Foundation

public struct WKBasicServiceRequest: WKServiceRequest {
    
    public enum ContentType {
        case form
        case json
    }

    public enum AcceptType {
        case json
        case none
    }
    
    public let url: URL?
    public let method: WKServiceRequestMethod
    public let languageVariantCode: String?
    public let parameters: [String: Any]?
    public var contentType: ContentType?
    public var acceptType: AcceptType

    internal init(url: URL? = nil, method: WKServiceRequestMethod, languageVariantCode: String? = nil, parameters: [String : Any]? = nil, contentType: ContentType? = nil, acceptType: AcceptType) {
        self.url = url
        self.method = method
        self.languageVariantCode = languageVariantCode
        self.parameters = parameters
        self.contentType = contentType
        self.acceptType = acceptType
    }
}
