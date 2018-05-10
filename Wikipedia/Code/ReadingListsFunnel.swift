import WMF

protocol ReadingListsFunnelProvider {
    var readingListsFunnel: ReadingListsFunnel { get }
}

// https://meta.wikimedia.org/wiki/Schema:MobileWikiAppiOSReadingLists

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
        case .relatedPages:
            return .relatedPages
        default:
            return nil
        }
    }
    
    @objc public func logSaveInFeed(contentGroupKind: WMFContentGroupKind) {
        logSave(category: .feed, label: label(for: contentGroupKind))
    }
    
    @objc public func logUnsaveInFeed(contentGroupKind: WMFContentGroupKind) {
        logUnsave(category: .feed, label: label(for: contentGroupKind))
    }
    
    // - MARK: Places
    
    @objc public func logSaveInPlaces() {
        logSave(category: .map)
    }
    
    @objc public func logUnsaveInPlaces() {
        logUnsave(category: .map)
    }
    
    // - MARK: Generic article save & unsave actions
    
    public func logSave(category: EventLoggingCategory, label: EventLoggingLabel? = nil, measure: Int = 1) {
        log(event(category: category, label: label, action: .save, measure: measure))
    }
    
    public func logUnsave(category: EventLoggingCategory, label: EventLoggingLabel? = nil, measure: Int = 1) {
        log(event(category: category, label: label, action: .unsave, measure: measure))
    }
    
    // - MARK: Saved - default reading list
    
    public func logUnsaveInDefaultReadingList(articlesCount: Int = 1) { // TODO: confirm if we want to log unsaves in reading list detail
        logUnsave(category: .saved, label: .items, measure: articlesCount)
    }
    
    public func logReadStartInDefaultReadingList() {
        log(event(category: .saved, label: .items, action: .readStart))
    }
    
    // - MARK: Saved - reading lists
    
    public func logDeleteInReadingLists(readingListsCount: Int = 1) {
        log(event(category: .saved, label: .lists, action: .deleteList, measure: readingListsCount))
    }
    
    public func logCreateInReadingLists() {
        log(event(category: .saved, label: .lists, action: .createList))
    }
    
    // - MARK: Add articles to reading list
    
    public func logDeleteInAddToReadingList(readingListsCount: Int = 1) {
        log(event(category: .addToList, label: nil, action: .deleteList, measure: readingListsCount))
    }
    
    public func logCreateInAddToReadingList() {
        log(event(category: .addToList, label: nil, action: .createList))
    }
}
