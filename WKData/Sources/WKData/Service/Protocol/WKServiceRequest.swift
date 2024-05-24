import Foundation

public enum WKServiceRequestMethod: String {
    case GET
    case POST
    case PUT
    case DELETE
    case HEAD
}

public protocol WKServiceRequest {
    var url: URL? { get }
    var method: WKServiceRequestMethod { get }
    var languageVariantCode: String? { get }
    var parameters: [String: Any]? { get }
}
