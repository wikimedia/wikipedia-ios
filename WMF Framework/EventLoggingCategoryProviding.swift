public protocol EventLoggingEventValuesProviding {
    var eventLoggingCategory: EventLoggingCategory { get }
    var eventLoggingLabel: EventLoggingLabel? { get }
}

@objc(WMFEventLoggingCategory)
public enum EventLoggingCategory: Int {
    case feed
    case history
    case map
    case article
    case search
    case addToList
    case saved
    case undefined
    
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
        default:
            return "undefined"
        }
    }
}


@objc(WMFEventLoggingLabel)
public enum EventLoggingLabel: Int {
    case featuredArticle
    case topRead
    case onThisDay
    case readMore
    case random
    case news
    case outLink
    case similarPage
    case items
    case lists
    case current
    
    public var value: String {
        switch self {
        case .featuredArticle:
            return "featured_article"
        case .topRead:
            return "top_read"
        case .onThisDay:
            return "on_this_day"
        case .readMore:
            return "read_more"
        case .random:
            return "random"
        case .news:
            return "news"
        case .outLink:
            return "out_link"
        case .similarPage:
            return "similar_page"
        case .items:
            return "items"
        case .lists:
            return "lists"
        case .current:
            return "default" // refers to the current article the user is reading, default is a reserved word
        }
    }
}
