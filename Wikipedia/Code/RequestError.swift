public enum RequestError: Int, LocalizedError {
    case unknown
    case invalidParameters
    case unexpectedResponse
    case noNewData
    case timeout = 504
    
    public var errorDescription: String? {
        switch self {
        case .unexpectedResponse:
            return WMFLocalizedString("fetcher-error-unexpected-response", value: "The app received an unexpected response from the server. Please try again later.", comment: "Error shown to the user for unexpected server responses.")
        default:
            return CommonStrings.genericErrorDescription
        }
    }
    
    public static func from(code: Int) -> RequestError? {
        return self.init(rawValue: code)
    }
}
