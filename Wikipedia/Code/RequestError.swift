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
    
    public var errorDescription: String? {
        let serverResponse = WMFLocalizedString("fetcher-error-unexpected-response", value: "The app received an unexpected response from the server. Please try again later.", comment: "Error shown to the user for unexpected server responses.")
    
        switch self {
        case .unexpectedResponse:
            return serverResponse
        case .http(let code):
            return serverResponse + " httpStatusCode: \(code)"
        default:
            return CommonStrings.genericErrorDescription
        }
    }
    
    public static func from(code: Int) -> RequestError {
        return .http(code)
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
        case .http(let statusCode):
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
