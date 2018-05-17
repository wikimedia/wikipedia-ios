// https://meta.wikimedia.org/wiki/Schema:MobileWikiAppiOSReadingLists

@objc final class ReadingListsFunnel: EventLoggingFunnel, EventLoggingStandardEventProviding {
    @objc public static let shared = ReadingListsFunnel()
    
    private enum Action: String {
        case save
        case unsave
        case createList = "createlist"
        case deleteList = "deletelist"
        case readStart = "read_start"
    }
    
    private override init() {
        super.init(schema: "MobileWikiAppiOSReadingLists", version: 18047424)
    }
    
    private func event(category: EventLoggingCategory, label: EventLoggingLabel?, action: Action, measure: Int = 1) -> Dictionary<String, Any> {
        let category = category.rawValue
        let action = action.rawValue
        let measure = Double(measure)
        let isAnon = !WMFAuthenticationManager.sharedInstance.isLoggedIn
        let primaryLanguage = MWKLanguageLinkController.sharedInstance().appLanguage?.languageCode ?? "en"
        
        var event: [String: Any] = ["category": category, "action": action, "measure": measure, "primary_language": primaryLanguage, "is_anon": isAnon]
        if let label = label {
            event["label"] = label.rawValue
        }
        return event
    }
    
    override func preprocessData(_ eventData: [AnyHashable: Any]) -> [AnyHashable: Any] {
        return wholeEvent(with: eventData)
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
    
    @objc public func logSaveInFeed(saveButton: SaveButton?) {
        logSave(category: .feed, label: saveButton?.eventLoggingLabel)
    }
    
    @objc public func logUnsaveInFeed(saveButton: SaveButton?) {
        logUnsave(category: .feed, label: saveButton?.eventLoggingLabel)
    }
    
    @objc public func logSaveInFeed(contentGroup: WMFContentGroup?) {
        logSave(category: .feed, label: contentGroup?.eventLoggingLabel)
    }
    
    @objc public func logUnsaveInFeed(contentGroup: WMFContentGroup?) {
        logUnsave(category: .feed, label: contentGroup?.eventLoggingLabel)
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
    
    public func logUnsaveInReadingList(articlesCount: Int = 1) {
        logUnsave(category: .saved, label: .items, measure: articlesCount)
    }
    
    public func logReadStartIReadingList() {
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
