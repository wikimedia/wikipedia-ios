import WMFNativeLocalizations
public enum RequestError: LocalizedError {
    case unknown
    case invalidParameters
    case unexpectedResponse
    case notModified
    case noNewData
    case unauthenticated
    case http(Int)
    case api(String)
    /// 429 or 503. The server asks the client to wait. `retryAfter` comes from the Retry-After header.
    case serverBusy(statusCode: Int, retryAfter: TimeInterval?)
    
    public var errorDescription: String? {
        let serverResponse = WMFLocalizedString("fetcher-error-unexpected-response", value: "The app received an unexpected response from the server. Please try again later.", comment: "Error shown to the user for unexpected server responses.")
    
        switch self {
        case .unexpectedResponse:
            return serverResponse
        case .http(let code), .serverBusy(let code, _):
            return serverResponse + " httpStatusCode: \(code)"
        default:
            return CommonStrings.genericErrorDescription
        }
    }
    
    public static func from(code: Int) -> RequestError {
        return .http(code)
    }

    /// Maps a non-2xx response to an error. 429 and 503 keep the Retry-After value.
    public static func from(response: HTTPURLResponse) -> RequestError {
        switch response.statusCode {
        case 429, 503:
            return .serverBusy(statusCode: response.statusCode, retryAfter: response.wmf_retryAfterInterval)
        default:
            return .http(response.statusCode)
        }
    }

    /// True when the server asks the client to wait (429 or 503).
    public var isServerBusy: Bool {
        switch self {
        case .serverBusy:
            return true
        case .http(let code):
            return code == 429 || code == 503
        default:
            return false
        }
    }

    /// Seconds the server asked the client to wait, if it said so.
    public var retryAfter: TimeInterval? {
        if case .serverBusy(_, let retryAfter) = self {
            return retryAfter
        }
        return nil
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

extension RequestError: CustomNSError {

    public var errorCode: Int {
        switch self {
        case .http(let statusCode), .serverBusy(let statusCode, _):
            return statusCode
        case .api:
            return 1
        case .unknown:
            return 2
        case .invalidParameters:
            return 3
        case .unexpectedResponse:
            return 4
        case .notModified:
            return 5
        case .noNewData:
            return 6
        case .unauthenticated:
            return 7
        }
    }

    public var errorUserInfo: [String: Any] {
        guard let errorDescription else {
            return [:]
        }
        return [NSLocalizedDescriptionKey: errorDescription]
    }
}

public extension HTTPURLResponse {
    /// Seconds to wait, from the Retry-After header. Accepts delay-seconds or an HTTP-date. Nil when absent or unreadable.
    var wmf_retryAfterInterval: TimeInterval? {
        guard let rawValue = value(forHTTPHeaderField: "Retry-After")?.trimmingCharacters(in: .whitespacesAndNewlines), !rawValue.isEmpty else {
            return nil
        }
        if let seconds = TimeInterval(rawValue) {
            return Self.wmf_clampedRetryAfter(seconds)
        }
        guard let date = DateFormatter.wmf_httpDateFormatter().date(from: rawValue) else {
            return nil
        }
        return Self.wmf_clampedRetryAfter(date.timeIntervalSinceNow)
    }

    /// Longest wait the app accepts from a Retry-After header.
    static let wmf_maximumRetryAfterInterval: TimeInterval = 24 * 60 * 60

    /// Non-finite values are ignored; the rest is kept between 0 and one day, so the value is safe to convert to Int and to schedule.
    static func wmf_clampedRetryAfter(_ seconds: TimeInterval) -> TimeInterval? {
        guard seconds.isFinite else {
            return nil
        }
        return min(max(0, seconds), wmf_maximumRetryAfterInterval)
    }
}
