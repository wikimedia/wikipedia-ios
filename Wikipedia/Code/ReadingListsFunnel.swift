import WMF

@objc(WMFReadingListsFunnel)
class ReadingListsFunnel: EventLoggingFunnel {
    private let schemaName = "MobileWikiAppiOSReadingLists" // TODO
    private let schemaRevision: Int32 = 0 // TODO

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
    
    private func event(category: EventLoggingCategory, label: EventLoggingLabel?, action: Action, measure: Int = 1) -> Dictionary<String, Any> {
        guard category != .undefined else {
            assertionFailure("category cannot be undefined")
            return [:]
        }
        var event: [String: Any] = ["category": category.value, "action": action.rawValue, "measure": Double(measure)]
        if let label = label {
            event["label"] = label.value
        }
        return event
    }
    
    // - MARK: Read more
    
    @objc public func logArticleActionFromReadMore(_ wasArticleSaved: Bool) {
        log(event(category: .article, label: .readMore, action: wasArticleSaved ? .save : .unsave))
    }
    
    // - MARK: Feed
    
    private func label(for contentGroupKind: WMFContentGroupKind) -> EventLoggingLabel? {
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
    
    public func logArticleActionFromArticleCollection(with category: EventLoggingCategory, label: EventLoggingLabel?, wasArticleSaved: Bool) {
        log(event(category: category, label: label, action: wasArticleSaved ? .save : .unsave))
    }
}
