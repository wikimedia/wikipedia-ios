import Foundation

/// MEP interface for the legacy schema available here:
/// https://github.com/wikimedia/schemas-event-secondary/blob/master/jsonschema/analytics/legacy/editattemptstep/current.yaml
public final class EditAttemptFunnel {
    static let shared = EditAttemptFunnel()
    
    private struct EventContainer: EventInterface {
        static let schema: EventPlatformClient.Schema = .editAttempt
        let event: Event
    }

    private struct Event: Codable {
        let action: EditAction
        let editing_session_id: String
        let app_install_id: String?
        let editor_interface: String
        let integration: String
        let is_anon: Bool
        let mw_version: String
        let platform: String
        let user_editcount: Int
        let user_id: Int
        let user_is_temp: Bool
        let version: Int
        let page_title: String?
        let page_ns: Int?
        let revision_id: Int?
    }

    private enum EditAction: String, Codable {
        case start = "init"
        case ready = "ready"
        case loaded = "loaded"
        case first = "firstChange"
        case saveIntent = "saveIntent"
        case saveAttempt = "saveAttempt"
        case saveSuccess = "saveSuccess"
        case saveFailure = "saveFailure"
        case abort = "abort"
    }
    
    private var isAnon: Bool {
        return !MWKDataStore.shared().authenticationManager.authStateIsPermanent
    }
    
    private var isTemp: Bool {
        return MWKDataStore.shared().authenticationManager.authStateIsTemporary
    }

    private func logEvent(pageURL: URL, action: EditAction, revisionId: Int? = nil) {
        let editorInterface = "wikitext"
        let integrationID = "app-ios"
        let platform = UIDevice.current.userInterfaceIdiom == .pad ? "tablet" : "phone"

        let userId = getUserID(pageURL: pageURL)
        
        let appInstallID = UserDefaults.standard.wmf_appInstallId

        let event = Event(action: action, editing_session_id: "", app_install_id: appInstallID, editor_interface: editorInterface, integration: integrationID, is_anon: isAnon, mw_version: "", platform: platform, user_editcount: 0, user_id: userId, user_is_temp: isTemp, version: 1, page_title: pageURL.wmf_title, page_ns: pageURL.namespace?.rawValue, revision_id: revisionId)
        
        let container = EventContainer(event: event)
        EventPlatformClient.shared.submit(stream: .editAttempt, event: container, needsMinimal: true)
    }

    func logInit(pageURL: URL) {
        logEvent(pageURL: pageURL, action: .start)
    }

    func logSaveIntent(pageURL: URL) {
        logEvent(pageURL: pageURL, action: .saveIntent)
    }

    func logSaveAttempt(pageURL: URL) {
        logEvent(pageURL: pageURL, action: .saveAttempt)
    }

    func logSaveSuccess(pageURL: URL, revisionId: Int?) {
        logEvent(pageURL: pageURL, action: .saveSuccess, revisionId: revisionId)
    }

    func logSaveFailure(pageURL: URL) {
        logEvent(pageURL: pageURL, action: .saveFailure)
    }

    func logAbort(pageURL: URL) {
        logEvent(pageURL: pageURL, action: .abort)
    }

    fileprivate func getUserID(pageURL: URL) -> Int {
        MWKDataStore.shared().authenticationManager.permanentUser(siteURL: pageURL)?.userID ?? 0
    }

}
