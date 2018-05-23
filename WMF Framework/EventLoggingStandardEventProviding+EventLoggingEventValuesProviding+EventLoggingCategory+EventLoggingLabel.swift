@objc public protocol EventLoggingEventValuesProviding {
    var eventLoggingCategory: EventLoggingCategory { get }
    var eventLoggingLabel: EventLoggingLabel { get }
}

public protocol EventLoggingStandardEventProviding {
    var standardEvent: Dictionary<String, Any> { get }
}

public extension EventLoggingStandardEventProviding where Self: EventLoggingFunnel {
    var standardEvent: Dictionary<String, Any> {
        let appInstallID = wmf_appInstallID()
        let timestamp = DateFormatter.wmf_iso8601Localized().string(from: Date())
        let sessionID = wmf_sessionID()
        return ["app_install_id": appInstallID, "session_id": sessionID, "event_dt": timestamp];
    }
    
    func wholeEvent(with event: Dictionary<AnyHashable, Any>) -> Dictionary<String, Any> {
        guard let event = event as? [String: Any] else {
            assertionFailure("Expected dictionary with keys of type String")
            return [:]
        }
        return standardEvent.merging(event, uniquingKeysWith: { (first, _) in first })
    }
}

@objc public enum EventLoggingCategory: Int {
    case feed
    case history
    case places
    case article
    case search
    case addToList
    case saved
    case login
    case setting
    case loginToSyncPopover
    case enableSyncPopover
    case unknown
    
    public var value: String {
        switch self {
        case .feed:
            return "feed"
        case .history:
            return "history"
        case .places:
            return "places"
        case .article:
            return "article"
        case .search:
            return "search"
        case .addToList:
            return "add_to_list"
        case .saved:
            return "saved"
        case .login:
            return "login"
        case .setting:
            return "setting"
        case .loginToSyncPopover:
            return "login_to_sync_popover"
        case .enableSyncPopover:
            return "enable_sync_popover"
        case .unknown:
            return "unknown"
        }
    }
}


@objc public enum EventLoggingLabel: Int {
    case featuredArticle
    case topRead
    case onThisDay
    case readMore
    case random
    case news
    case relatedPages
    case articleList
    case outLink
    case similarPage
    case items
    case lists
    case current
    case syncEducation
    case login
    case syncArticle
    case location
    case mainPage
    case none
    
    public var value: String? {
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
        case .relatedPages:
            return "related_pages" // because you read
        case .articleList:
            return "article_list"
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
        case .syncEducation:
            return "sync_education"
        case .login:
            return "login"
        case .syncArticle:
            return "sync_article" // Article storage and syncing settings screen
        case .location:
            return "location"
        case .mainPage:
            return "main_page"
        case .none:
            return nil
        }
    }
}
