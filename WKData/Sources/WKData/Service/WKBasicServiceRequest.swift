import Foundation

public struct WKBasicServiceRequest: WKServiceRequest {
    public let url: URL?
    public let method: WKServiceRequestMethod
    public let parameters: [String: Any]?
    public var bodyContentType: WKServiceRequestBodyContentType?

    internal init(url: URL? = nil, method: WKServiceRequestMethod, parameters: [String : Any]? = nil, bodyContentType: WKServiceRequestBodyContentType? = nil) {
        self.url = url
        self.method = method
        self.parameters = parameters
        self.bodyContentType = bodyContentType
    }
}
