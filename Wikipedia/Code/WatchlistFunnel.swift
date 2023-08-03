import Foundation
import WMF

final class WatchlistFunnel {
   
    static let shared = WatchlistFunnel()
    
    private enum Action: String, Codable {
        case diffOpen = "diff_open"
        case diffUserMenu = "diff_user_menu"
        case diffUserMenuPrevious = "diff_user_menu_previous"
        case diffUserMenuDisplay = "diff_user_menu_display"
        case diffUserPage = "diff_user_page"
        case diffUserTalk = "diff_user_talk"
        case diffUserContribution = "diff_user_contribution"
        case diffNavPrevious = "diff_nav_previous"
        case diffNavNext = "diff_nav_next"
        case diffNavUndo = "diff_nav_undo"
        case diffUndo = "diff_undo"
        case diffUndoCancel = "diff_undo_cancel"
        case diffUndoConfirm = "diff_undo_confirm"
        case diffUndoSuccess = "diff_undo_success"
        case diffUndoFail = "diff_undo_fail"
        case diffNavThank = "diff_nav_thank"
        case diffThankSend = "diff_thank_send"
        case diffThankCancel = "diff_thank_cancel"
        case diffThankLogin = "diff_thank_login"
        case diffThankConfirm = "diff_thank_confirm"
        case diffOverHistory = "diff_over_history"
        case diffOverShare = "diff_over_share"
        case diffOverShareConfirm = "diff_over_share_confirm"
        case diffOverRollback = "diff_over_rollback"
        case diffRollback = "diff_rollback"
        case diffRollbackCancel = "diff_rollback_cancel"
        case diffRollbackConfirm = "diff_rollback_confirm"
        case diffRollbackSuccess = "diff_rollback_success"
        case diffRollbackFail = "diff_rollback_fail"
    }
    
    private struct ActionData: Codable {
        
        enum EditType: String, Codable {
            case undo
            case rollback
        }
        
        let revisionID: String?
        let editType: EditType?
        let errorReason: String?
        
        enum CodingKeys: String, CodingKey {
            case revisionID = "revision_id"
            case editType = "edit_type"
            case errorReason = "error_reason"
        }
    }
    
    private struct Event: EventInterface {
        static let schema: EventPlatformClient.Schema = .watchlist
        let action: Action
        let actionData: ActionData?
        let wikiID: String
        
        enum CodingKeys: String, CodingKey {
            case action = "action"
            case actionData = "action_data"
            case wikiID = "wiki_id"
        }
    }
   
    private func logEvent(action: WatchlistFunnel.Action, actionData: ActionData? = nil, project: WikimediaProject) {
        
        let wikiID = project.notificationsApiWikiIdentifier
        
        let event: WatchlistFunnel.Event = WatchlistFunnel.Event(action: action, actionData: actionData, wikiID: wikiID)
        EventPlatformClient.shared.submit(stream: .watchlist, event: event)
    }
    
    func logDiffOpen(project: WikimediaProject?) {
        guard let project else {
            return
        }
        logEvent(action: .diffOpen, project: project)
    }
    
    func logDiffTapSingleEditorName(project: WikimediaProject?) {
        guard let project else {
            return
        }
        logEvent(action: .diffUserMenu, project: project)
    }
    
    func logDiffTapCompareFromEditorName(project: WikimediaProject?) {
        guard let project else {
            return
        }
        logEvent(action: .diffUserMenuPrevious, project: project)
    }
    
    func logDiffTapCompareToEditorName(project: WikimediaProject?) {
        guard let project else {
            return
        }
        logEvent(action: .diffUserMenuDisplay, project: project)
    }
    
    func logDiffTapUserPage(project: WikimediaProject?) {
        guard let project else {
            return
        }
        logEvent(action: .diffUserPage, project: project)
    }
    
    func logDiffTapUserTalk(project: WikimediaProject?) {
        guard let project else {
            return
        }
        logEvent(action: .diffUserTalk, project: project)
    }
    
    func logDiffTapUserContributions(project: WikimediaProject?) {
        guard let project else {
            return
        }
        logEvent(action: .diffUserContribution, project: project)
    }
    
    func logDiffToolbarTapPrevious(project: WikimediaProject?) {
        guard let project else {
            return
        }
        logEvent(action: .diffNavPrevious, project: project)
    }
    
    func logDiffToolbarTapNext(project: WikimediaProject?) {
        guard let project else {
            return
        }
        logEvent(action: .diffNavNext, project: project)
    }
    
    func logDiffToolbarTapUndo(project: WikimediaProject?) {
        guard let project else {
            return
        }
        logEvent(action: .diffNavUndo, project: project)
    }
    
    func logDiffUndoAlertTapUndo(project: WikimediaProject?) {
        guard let project else {
            return
        }
        logEvent(action: .diffUndo, project: project)
    }
    
    func logDiffUndoAlertTapCancel(project: WikimediaProject?) {
        guard let project else {
            return
        }
        logEvent(action: .diffUndoCancel, project: project)
    }
    
    func logDiffUndoDisplaySuccessToast(project: WikimediaProject?) {
        guard let project else {
            return
        }
        logEvent(action: .diffUndoConfirm, project: project)
    }
    
    func logDiffUndoSuccess(revisionID: Int, project: WikimediaProject?) {
        guard let project else {
            return
        }
        logEvent(action: .diffUndoSuccess, actionData: ActionData(revisionID: String(revisionID), editType: .undo, errorReason: nil), project: project)
    }
    
    func logDiffUndoFail(errorReason: String, project: WikimediaProject?) {
        guard let project else {
            return
        }
        logEvent(action: .diffUndoFail, actionData: ActionData(revisionID: nil, editType: .undo, errorReason: errorReason), project: project)
    }

    func logDiffToolbarTapThank(project: WikimediaProject?) {
        guard let project else {
            return
        }
        logEvent(action: .diffNavThank, project: project)
    }
    
    func logDiffThanksAlertTapSend(project: WikimediaProject?) {
        guard let project else {
            return
        }
        logEvent(action: .diffThankSend, project: project)
    }
    
    func logDiffThanksAlertTapCancel(project: WikimediaProject?) {
        guard let project else {
            return
        }
        logEvent(action: .diffThankCancel, project: project)
    }
    
    func logDiffThanksLogin(project: WikimediaProject?) {
        guard let project else {
            return
        }
        logEvent(action: .diffThankLogin, project: project)
    }
    
    func logDiffThanksDisplaySuccessToast(project: WikimediaProject?) {
        guard let project else {
            return
        }
        logEvent(action: .diffThankConfirm, project: project)
    }
    
    func logDiffToolbarMoreTapArticleEditHistory(project: WikimediaProject?) {
        guard let project else {
            return
        }
        logEvent(action: .diffOverHistory, project: project)
    }
    
    func logDiffToolbarMoreTapShare(project: WikimediaProject?) {
        guard let project else {
            return
        }
        logEvent(action: .diffOverShare, project: project)
    }
    
    func logDiffShareSuccess(project: WikimediaProject?) {
        guard let project else {
            return
        }
        logEvent(action: .diffOverShareConfirm, project: project)
    }
    
    func logDiffToolbarMoreTapRollback(project: WikimediaProject?) {
        guard let project else {
            return
        }
        logEvent(action: .diffOverRollback, project: project)
    }
    
    func logDiffRollbackAlertTapRollback(project: WikimediaProject?) {
        guard let project else {
            return
        }
        logEvent(action: .diffRollback, project: project)
    }
    
    func logDiffRollbackAlertTapCancel(project: WikimediaProject?) {
        guard let project else {
            return
        }
        logEvent(action: .diffRollbackCancel, project: project)
    }
    
    func logDiffRollbackDisplaySuccessToast(project: WikimediaProject?) {
        guard let project else {
            return
        }
        logEvent(action: .diffRollbackConfirm, project: project)
    }
    
    func logDiffRollbackSuccess(revisionID: Int, project: WikimediaProject?) {
        guard let project else {
            return
        }
        logEvent(action: .diffRollbackSuccess, actionData: ActionData(revisionID: String(revisionID), editType: .rollback, errorReason: nil), project: project)
    }
    
    func logDiffRollbackFail(errorReason: String, project: WikimediaProject?) {
        guard let project else {
            return
        }
        logEvent(action: .diffRollbackFail, actionData: ActionData(revisionID: nil, editType: .rollback, errorReason: errorReason), project: project)
    }
}
