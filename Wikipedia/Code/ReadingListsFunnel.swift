@objc final class ReadingListsFunnel: NSObject {
    @objc public static let shared = ReadingListsFunnel()
    
    private enum Action: String, Codable {
        case save
        case unsave
        case createList = "createlist"
        case deleteList = "deletelist"
        case readStart = "read_start"
        case receiveStart = "receive_start"
        case receiveCancel = "receive_cancel"
        case receiveFinish = "receive_finish"
        case surveyShown = "survey_shown"
        case surveyClicked = "survey_clicked"
        case allArticlesTab = "all_articles_tab"
        case readingListsTab = "reading_lists_tab"
        case editButton = "edit_tab"
    }

    private struct Event: EventInterface {
        static var schema: EventPlatformClient.Schema = .readingLists
        let action: Action
        let category: EventCategoryMEP
        let label: EventLabelMEP?
        let measure: Int?
        let measure_position: Int?
        let measure_age: Int?
        let wiki_id: String?
    }

    private func logEvent(action: Action, category: EventCategoryMEP, label: EventLabelMEP?, measure: Int? = nil, measurePosition: Int? = nil, measureAge: Int? = nil, wiki_id: String? = nil) {
        let event = ReadingListsFunnel.Event(action: action, category: category, label: label, measure: measure, measure_position: measurePosition, measure_age: measureAge, wiki_id: wiki_id)
        EventPlatformClient.shared.submit(stream: .readingLists, event: event)
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
    
    public func logSaveInFeed(label: EventLabelMEP?, measureAge: Date, articleURL: URL, index: Int?) {
        logSave(category: .feed, label: label ?? .none, articleURL: articleURL, measureAge: daysSince(measureAge), measurePosition: index)
    }
    
    public func logUnsaveInFeed(label: EventLabelMEP?, measureAge: Date, articleURL: URL, index: Int?) {
        logUnsave(category: .feed, label: label ?? .none, articleURL: articleURL, measureAge: daysSince(measureAge), measurePosition: index)
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
    
    private func logSave(category: EventCategoryMEP, label: EventLabelMEP? = nil, measure: Int = 1, language: String?, measureAge: Int? = nil, measurePosition: Int? = nil) {
        logEvent(action: .save, category: category, label: label, measure: measure, measurePosition: measurePosition, measureAge: measureAge, wiki_id: language)
    }
    
    private func logSave(category: EventCategoryMEP, label: EventLabelMEP? = nil, measure: Int = 1, articleURL: URL, measureAge: Int? = nil, measurePosition: Int? = nil) {
        logEvent(action: .save, category: category, label: label, measure: measure, measurePosition: measurePosition, measureAge: measureAge, wiki_id: articleURL.wmf_languageCode)
    }
    
    public func logSave(category: EventCategoryMEP, label: EventLabelMEP?, articleURL: URL?) {
        logEvent(action: .save, category: category, label: label, measure: 1, wiki_id: articleURL?.wmf_languageCode)
    }
    
    public func logUnsave(category: EventCategoryMEP, label: EventLabelMEP?, articleURL: URL?) {
        logEvent(action: .unsave, category: category, label: label, measure: 1, wiki_id: articleURL?.wmf_languageCode)
    }
    
    private func logUnsave(category: EventCategoryMEP, label: EventLabelMEP? = nil, measure: Int = 1, wiki_id: String?, measureAge: Int? = nil, measurePosition: Int? = nil) {
        logEvent(action: .unsave, category: category, label: label, measure: measure, measurePosition: measurePosition, measureAge: measureAge, wiki_id: wiki_id)
    }
    
    private func logUnsave(category: EventCategoryMEP, label: EventLabelMEP? = nil, measure: Int = 1, articleURL: URL, measureAge: Int? = nil, measurePosition: Int? = nil) {
        logEvent(action: .unsave, category: category, label: label, measure: measure, measurePosition: measurePosition, measureAge: measureAge, wiki_id: articleURL.wmf_languageCode)
    }

    public func logUnsave(category: EventCategoryMEP, label: EventLabelMEP? = nil, measure: Int = 1, articleURL: URL, date: Date?, measurePosition: Int) {
        let measureAge = date == nil ? nil : daysSince(date)
        logEvent(action: .unsave, category: category, label: label, measure: measure, measurePosition: measurePosition, measureAge: measureAge, wiki_id: articleURL.wmf_languageCode)
    }

    public func logSave(category: EventCategoryMEP, label: EventLabelMEP? = nil, measure: Int = 1, articleURL: URL, date: Date?, measurePosition: Int) {
        let measureAge = date == nil ? nil : daysSince(date)
        logEvent(action: .save, category: category, label: label, measure: measure, measurePosition: measurePosition, measureAge: measureAge, wiki_id: articleURL.wmf_languageCode)
    }
    
    // - MARK: Saved - default reading list
    
    public func logUnsaveInReadingList(articlesCount: Int = 1, language: String?) {
        logUnsave(category: .saved, label: .items, measure: articlesCount, wiki_id: language)
    }
    
    public func logReadStartReadingList(_ articleURL: URL) {
        logEvent(action: .readStart, category: .saved, label: .items, measure: 1, wiki_id: articleURL.wmf_languageCode)
    }
    
    // - MARK: Saved - reading lists
    
    public func logDeleteInReadingLists(readingListsCount: Int = 1) {
        logEvent(action: .deleteList, category: .saved, label: .lists, measure: readingListsCount)
    }
    
    public func logCreateInReadingLists() {
        logEvent(action: .createList, category: .saved, label: .lists, measure: 1)
    }
    
    // - MARK: Add articles to reading list
    
    public func logDeleteInAddToReadingList(readingListsCount: Int = 1) {
        logEvent(action: .deleteList, category: .addToList, label: nil, measure: readingListsCount)
    }
    
    public func logCreateInAddToReadingList() {
        logEvent(action: .createList, category: .addToList, label: nil, measure: 1)
    }
    
    // - MARK: Import Shared Reading Lists
    
    public func logStartImport(articlesCount: Int) {
        logEvent(action: .receiveStart, category: .shared, label: nil, measure: articlesCount)
    }
    
    public func logCancelImport() {
        logEvent(action: .receiveCancel, category: .shared, label: nil)
    }
    
    public func logCompletedImport(articlesCount: Int) {
        logEvent(action: .receiveFinish, category: .shared, label: nil, measure: articlesCount)
    }
    
    public func logPresentedSurveyPrompt() {
        logEvent(action: .surveyShown, category: .shared, label: nil)
    }
    
    public func logTappedTakeSurvey() {
        logEvent(action: .surveyClicked, category: .shared, label: nil)
    }

    public func logTappedAllArticlesTab() {
        logEvent(action: .allArticlesTab, category: .saved, label: nil)
    }

    public func logTappedReadingListsTab() {
        logEvent(action: .readingListsTab, category: .saved, label: nil)
    }

    public func logTappedEditButton() {
        logEvent(action: .editButton, category: .saved, label: nil)
    }
}

