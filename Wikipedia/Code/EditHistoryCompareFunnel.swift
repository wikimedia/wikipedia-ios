import Foundation

final class EditHistoryCompareFunnel {
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
    }
    
    public static let shared = EditHistoryCompareFunnel()
    
    private func logEvent(action: Action, domain: String?) {
        let event = Event(action: action)
        EventPlatformClient.shared.submit(stream: .editHistoryCompare, event: event, domain: domain)
    }
    
    public func logShowHistory(articleURL: URL) {
        logEvent(action: .showHistory, domain: articleURL.wmf_site?.host)
    }

    /**
     * Log a revision view event.
     * - Parameter url: either a `siteURL` (when logging from `PageHistoryViewController`)
     *   or a `pageURL` (when logging from `DiffContainerViewController`)
     */
    public func logRevisionView(url: URL) {
        logEvent(action: .revisionView, domain: url.wmf_site?.host)
    }
    
    public func logCompare1(articleURL: URL) {
        logEvent(action: .compare1, domain: articleURL.wmf_site?.host)
    }
    
    public func logCompare2(articleURL: URL) {
        logEvent(action: .compare2, domain: articleURL.wmf_site?.host)
    }

    public func logThankTry(siteURL: URL) {
        logEvent(action: .thankTry, domain: siteURL.host)
    }

    public func logThankSuccess(siteURL: URL) {
        logEvent(action: .thankSuccess, domain: siteURL.host)
    }

    public func logThankFail(siteURL: URL) {
        logEvent(action: .thankFail, domain: siteURL.host)
    }
}
