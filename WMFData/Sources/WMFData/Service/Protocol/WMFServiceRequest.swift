import Foundation

public enum WMFServiceRequestMethod: String {
    case GET
    case POST
    case PUT
    case DELETE
    case HEAD
}

public protocol WMFServiceRequest {
    var url: URL? { get }
    var method: WMFServiceRequestMethod { get }
    var languageVariantCode: String? { get }
    var parameters: [String: Any]? { get }
}
