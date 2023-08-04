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
        let editor_interface: String
        let integration: String
        let mw_version: String
        let platform: String
        let user_editcount: Int
        let user_id: Int
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

    private func logEvent(articleURL: URL, action: EditAction, revisionId: Int? = nil) {
        let editorInterface = "wikitext"
        let integrationID = "app-ios"
        let platform = UIDevice.current.userInterfaceIdiom == .pad ? "tablet" : "phone"

        let userId = getUserID(articleURL: articleURL)

        let event = Event(action: action, editing_session_id: "", editor_interface: editorInterface, integration: integrationID, mw_version: "", platform: platform, user_editcount: 0, user_id: userId, version: 1, page_title: articleURL.wmf_title, page_ns: articleURL.namespace?.rawValue, revision_id: revisionId)
        
        let container = EventContainer(event: event)
        EventPlatformClient.shared.submit(stream: .editAttempt, event: container, needsMinimal: true)
    }

    func logInit(articleURL: URL) {
        logEvent(articleURL: articleURL, action: .start)
    }

    func logSaveIntent(articleURL: URL) {
        logEvent(articleURL: articleURL, action: .saveIntent)
    }

    func logSaveAttempt(articleURL: URL) {
        logEvent(articleURL: articleURL, action: .saveAttempt)
    }

    func logSaveSuccess(articleURL: URL, revisionId: Int?) {
        logEvent(articleURL: articleURL, action: .saveSuccess, revisionId: revisionId)
    }

    func logSaveFailure(articleURL: URL) {
        logEvent(articleURL: articleURL, action: .saveFailure)
    }

    func logAbort(articleURL: URL) {
        logEvent(articleURL: articleURL, action: .abort)
    }

    fileprivate func getUserID(articleURL: URL) -> Int {
        let isAnon = !MWKDataStore.shared().authenticationManager.isLoggedIn

        if isAnon {
            return 0
        } else {
            var userId = 0
            MWKDataStore.shared().authenticationManager.getLoggedInUser(for: articleURL) { result in
                switch result {
                case .success(let user):
                    userId = user?.userID ?? 0
                default:
                    break
                }
            }
            return userId
        }
    }

}
