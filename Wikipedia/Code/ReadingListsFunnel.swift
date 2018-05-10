import WMF

@objc(WMFReadingListsFunnel)
class ReadingListsFunnel: EventLoggingFunnel {
    private let schemaName = "MobileWikiAppiOSReadingLists"
    private let schemaRevision: Int32 = 17990228
    
    private lazy var sessionID: String = {
        return singleUseUUID()
    }()

    private enum Action: String {
        case save
        case unsave
        case createList = "createlist"
        case deleteList = "deletelist"
        case readStart = "read_start"
    }
    
    override init() {
        super.init(schema: schemaName, version: schemaRevision)
    }
    
    private func event(category: EventLoggingCategory, label: EventLoggingLabel?, action: Action, measure: Int = 1) -> Dictionary<String, Any> {
        guard category != .undefined else {
            assertionFailure("category cannot be undefined")
            return [:]
        }
        let isAnon = !WMFAuthenticationManager.sharedInstance.isLoggedIn
        let primaryLanguage = MWKLanguageLinkController.sharedInstance().appLanguage?.languageCode ?? "en"
        var event: [String: Any] = ["app_install_id": self.wmf_appInstallID(), "category": category.value, "action": action.rawValue, "measure": Double(measure), "primary_language": primaryLanguage, "is_anon": isAnon, "event_dt": String(describing: NSDate()), "session_id": sessionID]
        if let label = label {
            event["label"] = label.value
        }
        return event
    }
    
    // - MARK: Article
    
    @objc public func logArticleSaveInCurrentArticle() {
        logSave(category: .article, label: .current)
    }
    
    @objc public func logArticleUnsaveInCurrentArticle() {
        logUnsave(category: .article, label: .current)
    }
    
    // - MARK: Read more
    
    @objc public func logArticleSaveInReadMore() {
        logSave(category: .article, label: .readMore)
    }
    
    @objc public func logArticleUnsaveInReadMore() {
        logUnsave(category: .article, label: .readMore)
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
    
    // - MARK: Places
    
    func logArticleActionFromPlaces(_ wasArticleSaved: Bool) {
        log(event(category: .map, label: nil, action: wasArticleSaved ? .save : .unsave))
    }
    
    @objc public func logArticleActionFromFeedCard(contentGroupKind: WMFContentGroupKind, wasArticleSaved: Bool) {
        log(event(category: .feed, label: label(for: contentGroupKind), action: wasArticleSaved ? .save : .unsave))
    }
    
    // - MARK: ArticleCollectionViewController
    
    public func logArticleActionFromArticleCollection(with category: EventLoggingCategory, label: EventLoggingLabel?, wasArticleSaved: Bool) {
        log(event(category: category, label: label, action: wasArticleSaved ? .save : .unsave))
    }
}
