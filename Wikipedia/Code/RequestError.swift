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
        switch self {
        case .unexpectedResponse:
            return WMFLocalizedString("fetcher-error-unexpected-response", value: "The app received an unexpected response from the server. Please try again later.", comment: "Error shown to the user for unexpected server responses.")
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
