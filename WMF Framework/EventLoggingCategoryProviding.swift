@objc(WMFEventLoggingCategoryProviding)
public protocol EventLoggingCategoryProviding {
    var eventLoggingCategory: EventLoggingCategory { get }
}

@objc(WMFEventLoggingCategoryProviding)
public enum EventLoggingCategory: Int {
    case feed
    case history
    case map
    case article
    case search
    case addToList
    case saved
    case unknown
    
    public var value: String {
        switch self {
        case .feed:
            return "feed"
        case .history:
            return "history"
        case .map:
            return "map"
        case .article:
            return "article"
        case .search:
            return "search"
        case .addToList:
            return "add_to_list"
        case .saved:
            return "saved"
        case .unknown:
            return "unknown"
        }
    }
}
