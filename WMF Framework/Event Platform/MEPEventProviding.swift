import Foundation

public enum EventCategoryMEP: String, Codable {
    case feed
    case feedDetail = "feed_detail"
    case history
    case places
    case search
    case addToList = "add_to_list"
    case saved
    case article
    case shared
    case login
    case setting
    case enableSyncPopover = "enable_sync_popover"
    case loginToSyncPopover = "login_to_sync_popover"
    case diff
    case unknown
}

public enum EventLabelMEP: String, Codable {
    case announcement = "announcement"
    case articleAnnouncement = "article_announcement"
    case featuredArticle = "featured_article"
    case topRead = "top_read"
    case readMore = "read_more"
    case onThisDay = "on_this_day"
    case random = "random"
    case news = "news"
    case relatedPages = "related_pages"
    case articleList = "article_list"
    case outLink = "out_link"
    case similarPage = "similar_page"
    case items = "items"
    case lists = "lists"
    case `default` = "default"
    case syncEducation = "sync_education"
    case login = "login"
    case syncArticle = "sync_article"
    case location = "location"
    case mainPage = "main_page"
    case continueReading = "continue_reading"
    case pictureOfTheDay = "picture_of_the_day"
}


public protocol MEPEventsProviding {
    var eventLoggingCategory: EventCategoryMEP { get }
    var eventLoggingLabel: EventLabelMEP? { get }
}
