
import Foundation

fileprivate extension Dictionary where Key == String, Value == Any {
    
    func appendingAction(action: ArticleAsLivingDocFunnel.Action) -> [String: Any] {
        var mutableDict = self
        mutableDict["action"] = action.rawValue
        return mutableDict
    }
    
    func appendingPosition(position: Int) -> [String: Any] {
        var mutableDict = self
        mutableDict["position"] = "\(position)"
        return mutableDict
    }
    
    func appendingTypes(types: [ArticleAsLivingDocFunnel.EventType]) -> [String: Any] {
        var mutableDict = self
        let rawTypes = types.map { $0.rawValue }
        mutableDict["types"] = rawTypes
        return mutableDict
    }
}

public final class ArticleAsLivingDocFunnel: EventLoggingFunnel, EventLoggingStandardEventProviding {
    
    public static let shared = ArticleAsLivingDocFunnel()
    
    private override init() {
        super.init(schema: "MobileWikiAppiOSLivingDoc", version: 20471010)
    }
    
    public enum ArticleContentInsertEventDescriptionType: Int {
        case single
        case discussion
        case vandalism
        case multiple
    }
    
    fileprivate enum Action: String, Codable {
        case cardShow = "card_show"
        case cardEditor = "card_editor"
        case cardMore = "card_more"
        case cardChange = "card_change"
        case cardDiscuss = "card_discuss"
        case cardVandalism = "card_vandalism"
        case cardMultiple = "card_multiple"
        case recentChanges = "recent_changes"
        case recentHistoryTop = "recent_history_top"
        case recentHistoryEnd = "recent_history_end"
        case recentThankTry = "recent_thank_try"
        case recentThankSuccess = "recent_thank_success"
        case recentThankFail = "recent_thank_fail"
        case recentClose = "recent_close"
        case recentSwipe = "recent_swipe"
    }
    
    public enum EventType: String, Codable {
        case reference
        case discussion
        case charAdded = "char_added"
        case charDeleted = "char_deleted"
        case vandalism
        case smallChanges = "small_changes"
        case descChange = "desc_change"
    }
    
    var baseEvent: [String: Any] {
        return ["primary_language": primaryLanguage(), "is_anon": isAnon]
    }
    
    private func event(action: Action) -> [String: Any]  {
        
        return baseEvent
            .appendingAction(action: action)
    }
    
    private func event(action: Action, position: Int) -> [String: Any] {

        return baseEvent
            .appendingAction(action: action)
            .appendingPosition(position: position)
    }
    
    private func event(action: Action, position: Int, types: [EventType]) -> [String: Any] {
        
        return baseEvent
            .appendingAction(action: action)
            .appendingPosition(position: position)
            .appendingTypes(types: types)
    }
    
    public override func preprocessData(_ eventData: [AnyHashable: Any]) -> [AnyHashable: Any] {
        return wholeEvent(with: eventData)
    }
    
    public func logArticleContentInsertShown() {
        log(event(action: .cardShow))
    }
    
    public func logArticleContentInsertReadMoreUpdatesTapped() {
        log(event(action: .cardMore))
    }
    
    public func logArticleContentInsertEditorTapped() {
        log(event(action: .cardEditor))
    }
    
    public func logArticleContentInsertEventDescriptionTapped(descriptionType: ArticleContentInsertEventDescriptionType) {
        
        switch descriptionType {
        case .discussion:
            log(event(action: .cardDiscuss))
        case .multiple:
            log(event(action: .cardMultiple))
        case .single:
            log(event(action: .cardChange))
        case .vandalism:
            log(event(action: .cardVandalism))
        }
    }
    
    public func logModalViewChangesButtonTapped(position: Int, types: [EventType]) {
        log(event(action: .recentChanges, position: position, types: types))
    }
    
    public func logModalViewDiscussionButtonTapped(position: Int) {
        log(event(action: .recentChanges, position: position, types: [.discussion]))
    }
    
    public func logModalSmallEventsLinkTapped(position: Int) {
        log(event(action: .recentChanges, position: position, types: [.smallChanges]))
    }
    
    public func logModalThankTryButtonTapped(position: Int) {
        log(event(action: .recentThankTry, position: position))
    }
    
    public func logModalThankSuccess(position: Int) {
        log(event(action: .recentThankSuccess, position: position))
    }
    
    public func logModalThankFail(position: Int) {
        log(event(action: .recentThankFail, position: position))
    }
    
    public func logModalViewFullHistoryTopButtonTapped() {
        log(event(action: .recentHistoryTop))
    }
    
    public func logModalViewFullHistoryBottomButtonTapped() {
        log(event(action: .recentHistoryEnd))
    }
    
    public func logModalCloseButtonTapped() {
        log(event(action: .recentClose))
    }
    
    public func logModalSwipedToDismiss() {
        log(event(action: .recentSwipe))
    }
}
