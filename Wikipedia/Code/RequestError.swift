import Foundation
import WMFNativeLocalizations

public enum RequestError: LocalizedError {
    case unknown
    case invalidParameters
    case unexpectedResponse
    case notModified
    case noNewData
    case unauthenticated
    case http(Int)
    /// HTTP 429. Distinct from `.http(429)` so callers can react to the server's
    /// `Retry-After` when it sent one; `httpStatusCode` reports 429 for both.
    case rateLimited(retryAfter: TimeInterval?)
    case api(String)

    public var errorDescription: String? {
        switch self {
        // .http and .rateLimited carry the same meaning as .unexpectedResponse from
        // the user's point of view — the server answered with something the app
        // can't use — so they share the message rather than falling back to the
        // generic one.
        case .unexpectedResponse, .http, .rateLimited:
            return WMFLocalizedString("fetcher-error-unexpected-response", value: "The app received an unexpected response from the server. Please try again later.", comment: "Error shown to the user for unexpected server responses.")
        default:
            return CommonStrings.genericErrorDescription
        }
    }

    public static let rateLimitedStatusCode = 429

    public var httpStatusCode: Int? {
        switch self {
        case .http(let code):
            return code
        case .rateLimited:
            return RequestError.rateLimitedStatusCode
        default:
            return nil
        }
    }

    /// The interval the server asked us to wait, when this error is a rate limit.
    public var retryAfterInterval: TimeInterval? {
        guard case .rateLimited(let retryAfter) = self else {
            return nil
        }
        return retryAfter
    }

    public static func from(code: Int, response: HTTPURLResponse? = nil) -> RequestError {
        guard code == rateLimitedStatusCode else {
            return .http(code)
        }
        return .rateLimited(retryAfter: response?.retryAfterInterval)
    }
    
    public static func from(_ apiError: [String: Any]?) -> RequestError? {
        guard
            let error = apiError?["error"] as? [String: Any],
            let code = error["code"] as? String
        else {
            return nil
        }
        return .api(code)
    }
}
