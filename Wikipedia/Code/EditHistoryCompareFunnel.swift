
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

    private func newLog(_ action: Action, _ domain: String?) {
        /*
         * TODO: The following still need to be resolved before this
         * instrumentation upgrade can be called done:
         *   - Finalize stream name to what will be deployed in mediawiki-config/wmf-config
         *   - Finalize the schema (TBD in Gerrit patch to schemas/event/secondary repo)
         *   - Decide if this approach is preferable to explicit EPC.shared?.log()
         *     - PROS: less verbose; see logShowHistory() below for comparison
         *     - CONS: have to do this step to ensure that newLog isn't Optional
         */
        EPC.shared?.log(
            stream: "ios.edit_history_compare",
            schema: "/analytics/mobile_apps/ios/edit_history_compare/1.0.0",
            data: [
                "action": action.rawValue as NSCoding,
                "primary_language": self.primaryLanguage() as NSCoding,
                "is_anon": (self.isAnon == 1) as NSCoding
            ],
            domain: domain
        )
    }
    
    public func logShowHistory(articleURL: URL) {
        log(event(action: .showHistory), language: articleURL.wmf_language)

        // Approach 1
        EPC.shared?.log(
            stream: "ios.edit_history_compare",
            schema: "/analytics/mobile_apps/ios/edit_history_compare/1.0.0",
            data: [
                "action": Action.showHistory.rawValue as NSCoding,
                "primary_language": primaryLanguage() as NSCoding,
                "is_anon": (isAnon == 1) as NSCoding
            ],
            domain: articleURL.wmf_site?.absoluteString
        )

        // Approach 2
        newLog(.showHistory, articleURL.wmf_site?.absoluteString)
    }

    /**
     * Log a revision view event.
     * - Parameter url: either a `siteURL` (when logging from `PageHistoryViewController`)
     *   or a `pageURL` (when logging from `DiffContainerViewController`)
     */
    public func logRevisionView(url: URL) {
        log(event(action: .revisionView), language: url.wmf_language)

        newLog(.revisionView, url.wmf_site?.absoluteString)
    }
    
    public func logCompare1(articleURL: URL) {
        log(event(action: .compare1), language: articleURL.wmf_language)

        newLog(.compare1, articleURL.wmf_site?.absoluteString)
    }
    
    public func logCompare2(articleURL: URL) {
        log(event(action: .compare2), language: articleURL.wmf_language)

        newLog(Action.compare2, articleURL.wmf_site?.absoluteString)
    }

    public func logThankTry(siteURL: URL) {
        log(event(action: .thankTry), language: siteURL.wmf_language)

        newLog(Action.thankTry, siteURL.absoluteString)
    }

    public func logThankSuccess(siteURL: URL) {
        log(event(action: .thankSuccess), language: siteURL.wmf_language)

        newLog(Action.thankSuccess, siteURL.absoluteString)
    }

    public func logThankFail(siteURL: URL) {
        log(event(action: .thankFail), language: siteURL.wmf_language)

        newLog(Action.thankFail, siteURL.absoluteString)
    }
}
