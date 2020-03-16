
import Foundation

final class EditHistoryCompareFunnel: EventLoggingFunnel, EventLoggingStandardEventProviding {
    public static let shared = EditHistoryCompareFunnel()
    
    private enum Action: String {
        case showHistory = "show_history"
        case revisionView = "revision_view"
        case compare1
        case compare2
        case thankTry = "thank_try"
        case thankSuccess = "thank_success"
        case thankFail = "thank_fail"
    }
    
    private override init() {
        super.init(schema: "MobileWikiAppiOSEditHistoryCompare", version: 19795952)
    }
    
    private func event(action: Action) -> Dictionary<String, Any> {
        
        let event: [String: Any] = ["action": action.rawValue, "primary_language": primaryLanguage(), "is_anon": isAnon]
        
        return event
    }
    
    override func preprocessData(_ eventData: [AnyHashable: Any]) -> [AnyHashable: Any] {
        return wholeEvent(with: eventData)
    }
    
    public func logShowHistory(articleURL: URL) {
        log(event(action: .showHistory), language: articleURL.wmf_language)
    }
    
    public func logRevisionView(language: String?) {
        log(event(action: .revisionView), language: language)
    }
    
    public func logCompare1(articleURL: URL) {
        log(event(action: .compare1), language: articleURL.wmf_language)
    }
    
    public func logCompare2(articleURL: URL) {
        log(event(action: .compare2), language: articleURL.wmf_language)
    }
    
    public func logThankTry(language: String?) {
        log(event(action: .thankTry), language: language)
    }
    
    public func logThankSuccess(language: String?) {
        log(event(action: .thankSuccess), language: language)
    }
    
    public func logThankFail(language: String?) {
        log(event(action: .thankFail), language: language)
    }
}
