import WMF

@objc(WMFReadingListsFunnel)
class ReadingListsFunnel: EventLoggingFunnel {
    private let schemaName = "MobileWikiAppiOSReadingLists" // TODO
    private let schemaRevision: Int32 = 0 // TODO

    private enum Label: String {
        case featuredArticle = "featured_article"
        case topRead = "top_read"
        case onThisDay = "on_this_day"
        case readMore = "read_more"
        case random
        case news
        case outLink
        case similarPage
        case items
        case lists
        case standard = "default"
    }

    private enum Action: String {
        case save
        case unsave
        case createList
        case deleteList
        case readStart
    }
    
    override init() {
        super.init(schema: schemaName, version: schemaRevision)
    }
    
    private func event(category: EventLoggingCategory, label: Label?, action: Action, measure: Int = 1) -> Dictionary<String, Any> {
        var event: [String: Any] = ["category": category.value, "action": action.rawValue, "measure": Double(measure)]
        if let label = label {
            event["label"] = label.rawValue
        }
        return event
    }
    
    // - MARK: Read more
    
    @objc public func logArticleActionFromReadMore(_ wasArticleSaved: Bool) {
        log(event(category: .article, label: .readMore, action: wasArticleSaved ? .save : .unsave))
    }
    
    // - MARK: Feed
    
    private func label(for contentGroupKind: WMFContentGroupKind) -> Label? {
        switch contentGroupKind {
        case .featuredArticle:
            return .featuredArticle
        case .topRead:
            return .topRead
        case .onThisDay:
            return .onThisDay
        case .random:
            return .random
        case .news:
            return .news
        default:
            return nil
        }
    }
    
    @objc public func logArticleActionFromFeedCard(contentGroupKind: WMFContentGroupKind, wasArticleSaved: Bool) {
        log(event(category: .feed, label: label(for: contentGroupKind), action: wasArticleSaved ? .save : .unsave))
    }
    
    // - MARK: ArticleCollectionViewController
    
    @objc public func logArticleActionFromArticleCollection(with eventLoggingCategory: EventLoggingCategory, wasArticleSaved: Bool) {
        log(event(category: eventLoggingCategory, label: .standard, action: wasArticleSaved ? .save : .unsave))
    }
}
