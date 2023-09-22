import Foundation

public enum WKServiceRequestMethod: String {
    case GET
    case POST
    case PUT
    case DELETE
    case HEAD
}

public enum WKServiceRequestBodyContentType {
    case form
    case json
}

public protocol WKServiceRequest {
    var url: URL? { get }
    var method: WKServiceRequestMethod { get }
    var parameters: [String: Any]? { get }
    var bodyContentType: WKServiceRequestBodyContentType? { get }
}
