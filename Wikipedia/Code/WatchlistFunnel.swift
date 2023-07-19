import Foundation
import WMF

final class WatchlistFunnel {
   
    static let shared = WatchlistFunnel()
    
    private enum Action: String, Codable {
        case openDiff = "open_diff"
        case diffUserMenu = "diff_user_menu"
        case diffUserMenuFrom = "diff_user_menu_from"
        case diffUserMenuTo = "diff_user_menu_to"
        case diffUserPage = "diff_user_page"
        case diffUserTalk = "diff_user_talk"
        case diffUserContribution = "diff_user_contribution"
        case diffNavPrevious = "diff_nav_previous"
        case diffNavNext = "diff_nav_next"
        case diffNavUndo = "diff_nav_undo"
        case diffNavThank = "diff_nav_thank"
        case diffUndo = "diff_undo"
        case diffUndoConfirm = "diff_undo_confirm"
        case diffThankSend = "diff_thank_send"
        case diffThankCancel = "diff_thank_cancel"
        case diffThankLogin = "diff_thank_login"
        case diffThankCreate = "diff_thank_create"
        case diffThankConfirm = "diff_thank_confirm"
        case diffOverHistory = "diff_over_history"
        case diffOverShare = "diff_over_share"
        case diffOverShareConfirm = "diff_over_share_confirm"
        case diffOverRollback = "diff_over_rollback"
        case diffRollback = "diff_rollback"
        case diffRollbackConfirm = "diff_rollback_confirm"
    }
    
    private struct Event: EventInterface {
        static let schema: EventPlatformClient.Schema = .watchlist
        let action: Action
        let wiki_id: String
    }
   
    private func logEvent(action: WatchlistFunnel.Action, project: WikimediaProject) {
        
        let wikiID = project.notificationsApiWikiIdentifier
        
        let event: WatchlistFunnel.Event = WatchlistFunnel.Event(action: action, wiki_id: wikiID)
        EventPlatformClient.shared.submit(stream: .watchlist, event: event)
    }
    
    func logDiffOpen(project: WikimediaProject?) {
        guard let project else {
            return
        }
        logEvent(action: .openDiff, project: project)
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
        logEvent(action: .diffUserMenuFrom, project: project)
    }
    
    func logDiffTapCompareToEditorName(project: WikimediaProject?) {
        guard let project else {
            return
        }
        logEvent(action: .diffUserMenuTo, project: project)
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
    
    func logDiffToolbarTapThank(project: WikimediaProject?) {
        guard let project else {
            return
        }
        logEvent(action: .diffNavThank, project: project)
    }
    
    func logDiffUndoAlertTapUndo(project: WikimediaProject?) {
        guard let project else {
            return
        }
        logEvent(action: .diffUndo, project: project)
    }
    
    func logDiffUndoDisplaySuccessToast(project: WikimediaProject?) {
        guard let project else {
            return
        }
        logEvent(action: .diffUndoConfirm, project: project)
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
    
    func logDiffThanksCreateAccount(project: WikimediaProject?) {
        guard let project else {
            return
        }
        logEvent(action: .diffThankCreate, project: project)
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
    
    func logDiffRollbackDisplaySuccessToast(project: WikimediaProject?) {
        guard let project else {
            return
        }
        logEvent(action: .diffRollbackConfirm, project: project)
    }
}
