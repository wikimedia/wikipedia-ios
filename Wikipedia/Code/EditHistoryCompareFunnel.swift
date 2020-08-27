
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

    private func newLog(action: Action, domain: String?) {
        /*
         * TODO: The following still need to be resolved before this
         * instrumentation upgrade can be called done:
         *   - Finalize stream name to what will be deployed in mediawiki-config/wmf-config
         *   - Finalize the schema (TBD in Gerrit patch to schemas/event/secondary repo)
         */
        EPC.shared?.log(
            stream: "ios.edit_history_compare",
            schema: "/analytics/mobile_apps/ios_edit_history_compare/1.0.0",
            data: [
                "action": action.rawValue as NSCoding,
                "primary_language": self.primaryLanguage() as NSCoding,
                "is_anon": self.isAnon as NSCoding
            ],
            domain: domain
        )
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
