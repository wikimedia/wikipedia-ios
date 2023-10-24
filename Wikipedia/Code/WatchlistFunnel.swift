import Foundation
import WMF

final class WatchlistFunnel {
   
    static let shared = WatchlistFunnel()
    
    private enum Action: String, Codable {
        case onboardWatchlist = "onboard_watchlist"
        case continueOnboard = "continue_onboard"
        case learnOnboard = "learn_onboard"
        case openWatchlistAccount = "open_watchlist_account"
        case openWatchlistArticle = "open_watchlist_article"
        case openWatchlistDiff = "open_watchlist_diff"
        case watchlistLoaded = "watchlist_loaded"
        case watchlistEmptyState = "watchlist_emptystate"
        case watchlistEmptyStateFilters = "watchlist_emptystate_filters"
        case watchlistSearch = "watchlist_search"
        case watchlistModifyFilters = "watchlist_modify_filters"
        case openUserMenu = "open_user_menu"
        case openUserPage = "open_user_page"
        case openUserTalk = "open_user_talk"
        case openUserContributions = "open_user_contributions"
        case openUserThank = "open_user_thank"
        case userThankSend = "user_thank_send"
        case userThankCancel = "user_thank_cancel"
        case userThankConfirm = "user_thank_confirm"
        case openFilterSettings = "open_filter_settings"
        case saveFilterSettings = "save_filter_settings"
        case addWatchlistItem = "add_watchlist_item"
        case addExpiryPrompt = "add_expiry_prompt"
        case expiryPerm = "expiry_perm"
        case expiry1week = "expiry_1week"
        case expiry1month = "expiry_1month"
        case expiry3month = "expiry_3month"
        case expiry6month = "expiry_6month"
        case expiry1year = "expiry_1year"
        case expiryCancel = "expiry_cancel"
        case expiryConfirm = "expiry_confirm"
        case unwatchItem = "unwatch_item"
        case unwatchConfirm = "unwatch_confirm"
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
        case diffOverWatch = "diff_over_watch"
        case diffOverExpiryPrompt = "diff_over_expiry_prompt"
        case diffExpiryConfirm = "diff_expiry_confirm"
        case diffOverUnwatchItem = "diff_over_unwatch_item"
        case diffOverUnwatchConfirm = "diff_over_unwatch_confirm"
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
    
    struct FilterEnabledList: Codable {
        
        enum Latest: String, Codable {
            case notLatest = "not_latest"
            case latest = "latest"
        }
        
        enum Activity: String, Codable {
            case all
            case seen
            case unseen
        }
        
        enum Automated: String, Codable {
            case all = "all"
            case bot = "bot"
            case nonBot = "non_bot"
        }
        
        enum Significance: String, Codable {
            case all = "all"
            case minor = "minor"
            case nonMinor = "non_minor"
        }
        
        enum UserRegistration: String, Codable {
            case all = "all"
            case unregistered = "unreg"
            case registered = "reg"
        }
        
        enum TypeChange: String, Codable {
            case pageEdits = "page_edits"
            case pageCreations = "page_creations"
            case categoryChanges = "cat_changes"
            case wikidataEdits = "wikidata_edits"
            case logActions = "log_actions"
        }
        
        enum Projects: String, Codable {
            case commons
            case wikidata
            case both
        }
        
        let projects: Projects?
        let wikis: [String]
        let latest: Latest
        let activity: Activity
        let automated: Automated
        let significance: Significance
        let userRegistration: UserRegistration
        let typeChange: [TypeChange]
        
        enum CodingKeys: String, CodingKey {
            case projects = "projects"
            case wikis = "wikis"
            case latest = "latest"
            case activity = "activity"
            case automated = "automated"
            case significance = "significance"
            case userRegistration = "user_reg"
            case typeChange = "type_change"
        }
    }
    
    private struct Event: EventInterface {
        static let schema: EventPlatformClient.Schema = .watchlist
        let action: Action
        let actionData: ActionData?
        let itemCount: Int?
        let filterEnabledList: FilterEnabledList?
        let wikiID: String?
        
        enum CodingKeys: String, CodingKey {
            case action = "action"
            case actionData = "action_data"
            case itemCount = "itemcount"
            case filterEnabledList = "filter_enabled_list"
            case wikiID = "wiki_id"
        }
    }
   
    private func logEvent(action: WatchlistFunnel.Action, actionData: ActionData? = nil, itemCount: Int? = nil, filterEnabledList: FilterEnabledList? = nil, project: WikimediaProject? = nil) {
        
        let wikiID = project?.notificationsApiWikiIdentifier
        
        let event: WatchlistFunnel.Event = WatchlistFunnel.Event(action: action, actionData: actionData, itemCount: itemCount, filterEnabledList: filterEnabledList, wikiID: wikiID)
        EventPlatformClient.shared.submit(stream: .watchlist, event: event)
    }
    
    func logWatchlistOnboardingAppearance() {
        logEvent(action: .onboardWatchlist)
    }
    
    func logWatchlistOnboardingTapContinue() {
        logEvent(action: .continueOnboard)
    }
    
    func logWatchlistOnboardingTapLearnMore() {
        logEvent(action: .learnOnboard)
    }
    
    func logOpenWatchlistFromAccount() {
        logEvent(action: .openWatchlistAccount)
    }
    
    func logOpenWatchlistFromArticleAddedToast(project: WikimediaProject) {
        logEvent(action: .openWatchlistArticle, project: project)
    }
    
    func logOpenWatchlistFromDiffAddedToast(project: WikimediaProject) {
        logEvent(action: .openWatchlistDiff, project: project)
    }
    
    func logWatchlistLoaded(itemCount: Int) {
        logEvent(action: .watchlistLoaded, itemCount: itemCount)
    }
    
    func logWatchlistSawEmptyStateNoFilters() {
        logEvent(action: .watchlistEmptyState)
    }
    
    func logWatchlistSawEmptyStateWithFilters() {
        logEvent(action: .watchlistEmptyStateFilters)
    }
    
    func logWatchlistEmptyStateTapSearch() {
        logEvent(action: .watchlistSearch)
    }
    
    func logWatchlistEmptyStateTapModifyFilters() {
        logEvent(action: .watchlistModifyFilters)
    }
    
    func logTapUserMenu(project: WikimediaProject) {
        logEvent(action: .openUserMenu, project: project)
    }
    
    func logTapUserPage(project: WikimediaProject) {
        logEvent(action: .openUserPage, project: project)
    }
    
    func logTapUserTalk(project: WikimediaProject) {
        logEvent(action: .openUserTalk, project: project)
    }
    
    func logTapUserContributions(project: WikimediaProject) {
        logEvent(action: .openUserContributions, project: project)
    }
    
    func logTapUserThank(project: WikimediaProject) {
        logEvent(action: .openUserThank, project: project)
    }
    
    func logThanksTapSend(project: WikimediaProject) {
        logEvent(action: .userThankSend, project: project)
    }
    
    func logThanksTapCancel(project: WikimediaProject) {
        logEvent(action: .userThankCancel, project: project)
    }
    
    func logThanksDisplaySuccessToast(project: WikimediaProject) {
        logEvent(action: .userThankConfirm, project: project)
    }
    
    func logOpenFilterSettings() {
        logEvent(action: .openFilterSettings)
    }
    
    func logSaveFilterSettings(filterEnabledList: FilterEnabledList) {
        logEvent(action: .saveFilterSettings, filterEnabledList: filterEnabledList)
    }
    
    func logAddToWatchlist(project: WikimediaProject) {
        logEvent(action: .addWatchlistItem, project: project)
    }
    
    func logPresentExpiryChoiceActionSheet(project: WikimediaProject) {
        logEvent(action: .addExpiryPrompt, project: project)
    }
    
    func logExpiryTapPermanent(project: WikimediaProject) {
        logEvent(action: .expiryPerm, project: project)
    }
    
    func logExpiryTapOneWeek(project: WikimediaProject) {
        logEvent(action: .expiry1week, project: project)
    }
    
    func logExpiryTapOneMonth(project: WikimediaProject) {
        logEvent(action: .expiry1month, project: project)
    }
    
    func logExpiryTapThreeMonths(project: WikimediaProject) {
        logEvent(action: .expiry3month, project: project)
    }
    
    func logExpiryTapSixMonths(project: WikimediaProject) {
        logEvent(action: .expiry6month, project: project)
    }
    
    func logExpiryTapOneYear(project: WikimediaProject) {
        logEvent(action: .expiry1year, project: project)
    }
    
    func logExpiryCancel(project: WikimediaProject) {
        logEvent(action: .expiryCancel, project: project)
    }
    
    func logAddToWatchlistDisplaySuccessToast(project: WikimediaProject) {
        logEvent(action: .expiryConfirm, project: project)
    }
    
    func logRemoveWatchlistItem(project: WikimediaProject) {
        logEvent(action: .unwatchItem, project: project)
    }
    
    func logRemoveWatchlistItemDisplaySuccessToast(project: WikimediaProject) {
        logEvent(action: .unwatchConfirm, project: project)
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
    
    func logAddToWatchlistFromDiff(project: WikimediaProject) {
        logEvent(action: .diffOverWatch, project: project)
    }
    
    func logPresentExpiryChoiceActionSheetFromDiff(project: WikimediaProject) {
        logEvent(action: .diffOverExpiryPrompt, project: project)
    }
    
    func logAddToWatchlistDisplaySuccessToastFromDiff(project: WikimediaProject) {
        logEvent(action: .diffExpiryConfirm, project: project)
    }
    
    func logRemoveWatchlistItemFromDiff(project: WikimediaProject) {
        logEvent(action: .diffOverUnwatchItem, project: project)
    }
    
    func logRemoveWatchlistItemDisplaySuccessToastFromDiff(project: WikimediaProject) {
        logEvent(action: .diffOverUnwatchConfirm, project: project)
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
