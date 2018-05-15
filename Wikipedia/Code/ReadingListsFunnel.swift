protocol ReadingListsFunnelProvider {
    var readingListsFunnel: ReadingListsFunnel { get }
}

// https://meta.wikimedia.org/wiki/Schema:MobileWikiAppiOSReadingLists

@objc class ReadingListsFunnel: EventLoggingFunnel {
    private enum Action: String {
        case save
        case unsave
        case createList = "createlist"
        case deleteList = "deletelist"
        case readStart = "read_start"
    }
    
    override init() {
        super.init(schema: "MobileWikiAppiOSReadingLists", version: 18047424)
    }
    
    private func event(category: EventLoggingCategory, label: EventLoggingLabel?, action: Action, measure: Int = 1) -> Dictionary<String, Any> {
        guard category != .undefined else {
            assertionFailure("category cannot be undefined")
            return [:]
        }
        let appInstallID = wmf_appInstallID()
        let category = category.rawValue
        let action = action.rawValue
        let measure = Double(measure)
        let isAnon = !WMFAuthenticationManager.sharedInstance.isLoggedIn
        let timestamp = DateFormatter.wmf_iso8601().string(from: Date())
        let primaryLanguage = MWKLanguageLinkController.sharedInstance().appLanguage?.languageCode ?? "en"
        let sessionID = wmf_sessionID()
        
        var event: [String: Any] = ["app_install_id": appInstallID, "category": category, "action": action, "measure": measure, "primary_language": primaryLanguage, "is_anon": isAnon, "event_dt": timestamp, "session_id": sessionID]
        if let label = label {
            event["label"] = label.rawValue
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
    
    @objc public func logSaveInFeed(contentGroupKind: WMFContentGroupKind) {
        logSave(category: .feed, label: contentGroupKind.eventLoggingLabel)
    }
    
    @objc public func logUnsaveInFeed(contentGroupKind: WMFContentGroupKind) {
        logUnsave(category: .feed, label: contentGroupKind.eventLoggingLabel)
    }
    
    // - MARK: Places
    
    @objc public func logSaveInPlaces() {
        logSave(category: .places)
    }
    
    @objc public func logUnsaveInPlaces() {
        logUnsave(category: .places)
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
    
    public func logCreateInAddToReadingList() { // TODO: confirm if we want to log if user attempts to create or only if they succed
        log(event(category: .addToList, label: nil, action: .createList))
    }
}
