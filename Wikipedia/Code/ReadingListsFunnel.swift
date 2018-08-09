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
        super.init(schema: "MobileWikiAppiOSReadingLists", version: 18280648)
    }
    
    private func event(category: EventLoggingCategory, label: EventLoggingLabel?, action: Action, measure: Int = 1, measureAge: Int? = nil, measurePosition: Int? = nil) -> Dictionary<String, Any> {
        let category = category.rawValue
        let action = action.rawValue
        
        var event: [String: Any] = ["category": category, "action": action, "measure": measure, "primary_language": primaryLanguage(), "is_anon": isAnon]
        if let label = label?.rawValue {
            event["label"] = label
        }
        if let measurePosition = measurePosition {
            event["measure_position"] = measurePosition
        }
        if let measureAge = measureAge {
            event["measure_age"] = measureAge
        }
        return event
    }
    
    override func preprocessData(_ eventData: [AnyHashable: Any]) -> [AnyHashable: Any] {
        return wholeEvent(with: eventData)
    }
    
    // - MARK: Article
    
    @objc public func logArticleSaveInCurrentArticle(_ articleURL: URL) {
        logSave(category: .article, label: .default, articleURL: articleURL)
    }
    
    @objc public func logArticleUnsaveInCurrentArticle(_ articleURL: URL) {
        logUnsave(category: .article, label: .default, articleURL: articleURL)
    }
    
    // - MARK: Read more
    
    @objc public func logArticleSaveInReadMore(_ articleURL: URL) {
        logSave(category: .article, label: .readMore, articleURL: articleURL)
    }
    
    @objc public func logArticleUnsaveInReadMore(_ articleURL: URL) {
        logUnsave(category: .article, label: .readMore, articleURL: articleURL)
    }
    
    // - MARK: Feed
    
    @objc public func logSaveInFeed(saveButton: SaveButton?, articleURL: URL, kind: WMFContentGroupKind, index: Int, date: Date) {
        logSave(category: .feed, label: saveButton?.eventLoggingLabel ?? .none, articleURL: articleURL, measureAge: daysSince(date), measurePosition: index)
    }
    
    @objc public func logUnsaveInFeed(saveButton: SaveButton?, articleURL: URL, kind: WMFContentGroupKind, index: Int, date: Date) {
        logUnsave(category: .feed, label: saveButton?.eventLoggingLabel, articleURL: articleURL, measureAge: daysSince(date), measurePosition: index)
    }
    
    public func logSaveInFeed(context: FeedFunnelContext?, articleURL: URL, index: Int?) {
        logSave(category: .feed, label: context?.label ?? .none, articleURL: articleURL, measureAge: daysSince(context?.midnightUTCDate), measurePosition: index)
    }
    
    public func logUnsaveInFeed(context: FeedFunnelContext?, articleURL: URL, index: Int?) {
        logUnsave(category: .feed, label: context?.label, articleURL: articleURL, measureAge: daysSince(context?.midnightUTCDate), measurePosition: index)
    }

    private func daysSince(_ date: Date?) -> Int? {
        let now = NSDate().wmf_midnightUTCDateFromLocal
        let daysSince = NSCalendar.wmf_gregorian().wmf_days(from: date, to: now)
        return daysSince
    }
    
    // - MARK: Places
    
    @objc public func logSaveInPlaces(_ articleURL: URL) {
        logSave(category: .places, articleURL: articleURL)
    }
    
    @objc public func logUnsaveInPlaces(_ articleURL: URL) {
        logUnsave(category: .places, articleURL: articleURL)
    }
    
    // - MARK: Generic article save & unsave actions
    
    private func logSave(category: EventLoggingCategory, label: EventLoggingLabel? = nil, measure: Int = 1, language: String?, measureAge: Int? = nil, measurePosition: Int? = nil) {
        log(event(category: category, label: label, action: .save, measure: measure, measureAge: measureAge, measurePosition: measurePosition), language: language)
    }
    
    private func logSave(category: EventLoggingCategory, label: EventLoggingLabel? = nil, measure: Int = 1, articleURL: URL, measureAge: Int? = nil, measurePosition: Int? = nil) {
        log(event(category: category, label: label, action: .save, measure: measure, measureAge: measureAge, measurePosition: measurePosition), language: articleURL.wmf_language)
    }
    
    @objc public func logSave(category: EventLoggingCategory, label: EventLoggingLabel?, articleURL: URL?) {
        log(event(category: category, label: label, action: .save, measure: 1), language: articleURL?.wmf_language)
    }
    
    @objc public func logUnsave(category: EventLoggingCategory, label: EventLoggingLabel?, articleURL: URL?) {
        log(event(category: category, label: label, action: .unsave, measure: 1), language: articleURL?.wmf_language)
    }
    
    private func logUnsave(category: EventLoggingCategory, label: EventLoggingLabel? = nil, measure: Int = 1, language: String?, measureAge: Int? = nil, measurePosition: Int? = nil) {
        log(event(category: category, label: label, action: .unsave, measure: measure, measureAge: measureAge, measurePosition: measurePosition), language: language)
    }
    
    private func logUnsave(category: EventLoggingCategory, label: EventLoggingLabel? = nil, measure: Int = 1, articleURL: URL, measureAge: Int? = nil, measurePosition: Int? = nil) {
        log(event(category: category, label: label, action: .unsave, measure: measure, measureAge: measureAge, measurePosition: measurePosition), language: articleURL.wmf_language)
    }

    public func logUnsave(category: EventLoggingCategory, label: EventLoggingLabel? = nil, measure: Int = 1, articleURL: URL, date: Date?, measurePosition: Int) {
        log(event(category: category, label: label, action: .unsave, measure: measure, measureAge: daysSince(date), measurePosition: measurePosition), language: articleURL.wmf_language)
    }

    public func logSave(category: EventLoggingCategory, label: EventLoggingLabel? = nil, measure: Int = 1, articleURL: URL, date: Date?, measurePosition: Int) {
        log(event(category: category, label: label, action: .save, measure: measure, measureAge: daysSince(date), measurePosition: measurePosition), language: articleURL.wmf_language)
    }
    
    // - MARK: Saved - default reading list
    
    public func logUnsaveInReadingList(articlesCount: Int = 1, language: String?) {
        logUnsave(category: .saved, label: .items, measure: articlesCount, language: language)
    }
    
    public func logReadStartIReadingList(_ articleURL: URL) {
        log(event(category: .saved, label: .items, action: .readStart), language: articleURL.wmf_language)
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
