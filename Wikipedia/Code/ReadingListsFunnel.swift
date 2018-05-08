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
        case none = "default"
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
    
    private func event(category: EventLoggingCategory, label: Label?, action: Action, measure: Int = 1) -> Dictionary<String, Any> {
        guard category != .unknown else {
            assertionFailure("category cannot be unknown")
            return [:]
        }
        var event: [String: Any] = ["category": category.value, "action": action.rawValue, "measure": Double(measure)]
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
    
    @objc public func logArticleUnsavedFromFeedCard(contentGroupKind: WMFContentGroupKind) {
        log(event(category: .feed, label: label(for: contentGroupKind), action: .unsave))
    }
    
    @objc public func logArticleSavedFromFeedCard(contentGroupKind: WMFContentGroupKind) {
        log(event(category: .feed, label: label(for: contentGroupKind), action: .save))
    }
}
