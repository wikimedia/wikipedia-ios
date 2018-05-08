@objc(WMFReadingListsFunnel)
class ReadingListsFunnel: EventLoggingFunnel {
    private let schemaName = "MobileWikiAppiOSReadingLists" // TODO
    private let schemaRevision: Int32 = 0 // TODO

    private enum Category: String {
        case feed
        case history
        case map
        case article
        case search
        case addToList = "add_to_list"
        case saved
    }

    private enum Label: String {
        case featuredArticle = "featured_article"
        case topRead = "top_read"
        case onThisDay = "on_this_day"
        case readMore = "read_more"
        case outLink
        case similarPage
        case items
        case lists
    }

    private enum Action: String {
        case save
        case unsave
        case createList
        case deleteLiss
        case readStart
    }
    
    override init() {
        super.init(schema: schemaName, version: schemaRevision)
    }
    
    private func event(category: Category, label: Label?, action: Action, measure: Int = 1) -> Dictionary<String, Any> {
        var event: [String: Any] = ["category": category.rawValue, "action": action.rawValue, "measure": Double(measure)]
        if let label = label {
            event["label"] = label.rawValue
        }
        return event
    }
    
    // - MARK: Read more
    
    @objc public func logArticleSavedFromReadMore() {
        log(event(category: .article, label: .readMore, action: .save))
    }
    
    @objc public func logArticleUnsavedFromReadMore() {
        log(event(category: .article, label: .readMore, action: .unsave))
    }
    
    // - MARK: Feed
    
    @objc public func logArticleUnsavedFromFeedCard(withLabelValue value: String) {
        log(event(category: .feed, label: Label(rawValue: value), action: .unsave))
    }
    
    @objc public func logArticleSavedFromFeedCard(withLabelValue value: String) {
        log(event(category: .feed, label: Label(rawValue: value), action: .save))
    }
}
