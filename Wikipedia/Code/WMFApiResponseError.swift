
enum WMFAPIResponseError : LocalizedError {
    
    case noResponseDictionary
    case dictionaryWithoutErrorInfo
    case dictionaryWithErrorInfo(String)
    
    var errorDescription: String? {
        switch self {
        case .dictionaryWithErrorInfo(let info):
            return info
        case .noResponseDictionary:
            return "Couldn't extract response dictionary"
        case .dictionaryWithoutErrorInfo:
            return "Couldn't extract 'errorInfo' from response dictionary"
        }
    }
}
