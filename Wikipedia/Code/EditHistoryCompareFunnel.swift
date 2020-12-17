
import Foundation

final class EditHistoryCompareFunnel: EventLoggingFunnel, EventLoggingStandardEventProviding {
    private enum Action: String, Codable {
        case showHistory = "show_history"
        case revisionView = "revision_view"
        case compare1
        case compare2
        case thankTry = "thank_try"
        case thankSuccess = "thank_success"
        case thankFail = "thank_fail"
    }
    
    
    private struct Event: EventInterface {
        static let schema: EventPlatformClient.Schema = .editHistoryCompare
        let action: Action
        let primary_language: String
        let is_anon: Bool
    }
    
    public static let shared = EditHistoryCompareFunnel()
    
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

    private func newLog(action: Action, domain: String?) {
        let event = Event(action: action, primary_language: primaryLanguage(), is_anon: isAnon.boolValue)
        EventPlatformClient.shared.submit(stream: .editHistoryCompare, event: event, domain: domain)
    }
    
    public func logShowHistory(articleURL: URL) {
        log(event(action: .showHistory), language: articleURL.wmf_language)
        newLog(action: .showHistory, domain: articleURL.wmf_site?.host)
    }

    /**
     * Log a revision view event.
     * - Parameter url: either a `siteURL` (when logging from `PageHistoryViewController`)
     *   or a `pageURL` (when logging from `DiffContainerViewController`)
     */
    public func logRevisionView(url: URL) {
        log(event(action: .revisionView), language: url.wmf_language)
        newLog(action: .revisionView, domain: url.wmf_site?.host)
    }
    
    public func logCompare1(articleURL: URL) {
        log(event(action: .compare1), language: articleURL.wmf_language)
        newLog(action: .compare1, domain: articleURL.wmf_site?.host)
    }
    
    public func logCompare2(articleURL: URL) {
        log(event(action: .compare2), language: articleURL.wmf_language)
        newLog(action: .compare2, domain: articleURL.wmf_site?.host)
    }

    public func logThankTry(siteURL: URL) {
        log(event(action: .thankTry), language: siteURL.wmf_language)
        newLog(action: .thankTry, domain: siteURL.host)
    }

    public func logThankSuccess(siteURL: URL) {
        log(event(action: .thankSuccess), language: siteURL.wmf_language)
        newLog(action: .thankSuccess, domain: siteURL.host)
    }

    public func logThankFail(siteURL: URL) {
        log(event(action: .thankFail), language: siteURL.wmf_language)
        newLog(action: .thankFail, domain: siteURL.host)
    }
}
