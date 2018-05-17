public protocol EventLoggingEventValuesProviding {
    var eventLoggingCategory: EventLoggingCategory { get }
    var eventLoggingLabel: EventLoggingLabel? { get }
}

public protocol EventLoggingStandardEventProviding {
    var standardEvent: Dictionary<String, Any> { get }
}

public extension EventLoggingStandardEventProviding where Self: EventLoggingFunnel {
    var standardEvent: Dictionary<String, Any> {
        let appInstallID = wmf_appInstallID()
        let timestamp = DateFormatter.wmf_iso8601().string(from: Date())
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

public enum EventLoggingCategory: String {
    case feed
    case history
    case places
    case article
    case search
    case addToList = "add_to_list"
    case saved
    case login
    case setting
    case loginToSyncPopover = "login_to_sync_popover"
    case enableSyncPopover = "enable_sync_popover"
    case undefined
}


public enum EventLoggingLabel: String {
    case featuredArticle = "featured_article"
    case topRead = "top_read"
    case onThisDay = "on_this_day"
    case readMore = "read_more"
    case random
    case news
    case relatedPages = "related_pages" // because you read
    case articleList = "article_list"
    case outLink = "out_link"
    case similarPage = "similar_page"
    case items
    case lists
    case current = "default" // refers to the current article the user is reading, default is a reserved word
    case syncEducation = "sync_education"
    case login
    case syncArticle = "sync_article" // Article storage and syncing settings screen
    case location
}
