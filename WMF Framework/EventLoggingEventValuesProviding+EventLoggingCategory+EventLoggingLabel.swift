public protocol EventLoggingEventValuesProviding {
    var eventLoggingCategory: EventLoggingCategory { get }
    var eventLoggingLabel: EventLoggingLabel? { get }
}

public enum EventLoggingCategory: String {
    case feed
    case history
    case map
    case article
    case search
    case addToList = "add_to_list"
    case saved
    case login
    case setting
    case loginToSyncPopover = "login_to_sync_popover"
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
}
