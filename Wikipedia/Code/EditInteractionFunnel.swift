import Foundation
import WMFData

final class EditInteractionFunnel {
    
    static let shared = EditInteractionFunnel()
    
    enum ProblemSource: String {
        case editNoticeLink = "edit_notice_link"
        case blockedMessage = "blocked_message"
        case blockedMessageLink = "blocked_message_link"
        case protectedPage = "protected_page"
        case protectedPageLink = "protected_page_link"
        case abuseFilterBlocked = "abuse_filter_blocked"
        case abuseFilterWarned = "abuse_filter_warned"
        case serverError = "server_error"
        case connectionError = "connection_error"
        case needsCaptcha = "needs_captcha"
        case articleSelectFail = "article_select_fail"
    }
    
    private enum ActiveInterface: String {
        case articleOverflowMenu = "article_overflow_menu"
        case articleSection = "article_section"
        case articleSelect = "article_select"
        case talkOverflowMenu = "talk_overflow_menu"
        case articleEditingInterface = "article_editing_interface"
        case talkEditingInterface = "talk_editing_interface"
        case articleEditPreview = "article_edit_preview"
        case articleEditSummary = "article_edit_summary"
        case talkEditSummary = "talk_edit_summary"
        case activityEntry = "activity_entry"
        case activityTab = "activity_tab"
        case activityFeedback = "activity_feedback"
    }
    
    private enum Action: String {
        case editEntryClick = "edit_entry_click"
        case editDescription = "edit_description"
        case editIntro = "edit_intro"
        case editCancel = "edit_cancel"
        case keepEditing = "keep_editing"
        case editNext = "edit_next"
        case previewNext = "preview_next" // Note: used for article flow only
        case showPreview = "show_preview" // Note: used for talk flow only
        case saveAttempt = "save_attempt"
        case saveSuccess = "save_success"
        case saveFailure = "save_failure"
        case launch = "launch"
        case impression = "impression"
        case loginClick = "login_click"
        case viewClick = "view_click"
        case viewHistoryClick = "view_history_click"
        case viewSavedClick = "view_saved_click"
        case viewEditedClick = "view_edited_click"
        case feedbackImpression = "feedback_impression"
        case feedbackCloseClick = "feedback_close_click"
        case feedbackSubmitClick = "feedback_submit_click"
    }

    private struct Event: EventInterface {
        static let schema: EventPlatformClient.Schema = .appInteraction
        let activeInterface: String?
        let action: String?
        let actionData: String?
        let platform: String
        let wikiID: String?
        
        enum CodingKeys: String, CodingKey {
            case activeInterface = "active_interface"
            case action = "action"
            case actionData = "action_data"
            case platform = "platform"
            case wikiID = "wiki_id"
        }
    }
   
    private func logEvent(activeInterface: ActiveInterface?, action: Action, actionData: [String: String]? = nil, project: WikimediaProject) {
        
        var actionDataString: String? = nil
        if let actionData {
            actionDataString = ""
            for (key, value) in actionData {
                actionDataString?.append("\(key):\(value), ")
            }
            
            // remove last ", "
            if let finalActionDataString = actionDataString,
               finalActionDataString.count > 1 {
                actionDataString?.removeLast(2)
            }
        }
        
        let event: EditInteractionFunnel.Event = EditInteractionFunnel.Event(activeInterface: activeInterface?.rawValue, action: action.rawValue, actionData: actionDataString, platform: "ios", wikiID: project.notificationsApiWikiIdentifier)
        EventPlatformClient.shared.submit(stream: .editInteraction, event: event)
    }
    
    func logArticleDidTapEditSourceButton(project: WikimediaProject) {
        logEvent(activeInterface: .articleOverflowMenu, action: .editEntryClick, project: project)
    }
    
    func logTalkDidTapEditSourceButton(project: WikimediaProject) {
        logEvent(activeInterface: .talkOverflowMenu, action: .editEntryClick, project: project)
    }
    
    func logArticleDidTapEditSectionButton(project: WikimediaProject) {
        logEvent(activeInterface: .articleSection, action: .editEntryClick, project: project)
    }
    
    func logArticleConfirmDidTapEditArticleDescription(project: WikimediaProject) {
        logEvent(activeInterface: .articleSection, action: .editDescription, project: project)
    }
    
    func logArticleConfirmDidTapEditIntroduction(project: WikimediaProject) {
        logEvent(activeInterface: .articleSection, action: .editIntro, project: project)
    }
    
    func logArticleConfirmDidTapCancel(project: WikimediaProject) {
        logEvent(activeInterface: .articleSection, action: .editCancel, project: project)
    }
    
    func logArticleSelectDidTapEditContextMenu(project: WikimediaProject) {
        logEvent(activeInterface: .articleSelect, action: .editEntryClick, project: project)
    }
    
    func logArticleEditorDidTapClose(problemSource: ProblemSource?, project: WikimediaProject) {
        var actionData: [String: String]? = nil
        if let problemSource {
            actionData = ["abort_source": problemSource.rawValue]
        }
        logEvent(activeInterface: .articleEditingInterface, action: .editCancel, actionData: actionData, project: project)
    }
    
    func logArticleEditorDidTapPanelLink(problemSource: ProblemSource?, project: WikimediaProject) {
        var actionData: [String: String]? = nil
        if let problemSource {
            actionData = ["abort_source": problemSource.rawValue]
        }
        logEvent(activeInterface: .articleEditingInterface, action: .editCancel, actionData: actionData, project: project)
    }
    
    func logTalkEditorDidTapPanelLink(problemSource: ProblemSource?, project: WikimediaProject) {
        var actionData: [String: String]? = nil
        if let problemSource {
            actionData = ["abort_source": problemSource.rawValue]
        }
        logEvent(activeInterface: .talkEditingInterface, action: .editCancel, actionData: actionData, project: project)
    }
    
    func logArticleEditorConfirmDidTapDiscardEdit(problemSource: ProblemSource?, project: WikimediaProject) {
        var actionData: [String: String]? = nil
        if let problemSource {
            actionData = ["abort_source": problemSource.rawValue]
        }
        logEvent(activeInterface: .articleEditingInterface, action: .editCancel, actionData: actionData, project: project)
    }
    
    func logArticleEditorConfirmDidTapKeepEditing(project: WikimediaProject) {
        logEvent(activeInterface: .articleEditingInterface, action: .keepEditing, project: project)
    }
    
    func logTalkEditorDidTapClose(problemSource: ProblemSource?, project: WikimediaProject) {
        var actionData: [String: String]? = nil
        if let problemSource {
            actionData = ["abort_source": problemSource.rawValue]
        }
        
        logEvent(activeInterface: .talkEditingInterface, action: .editCancel, actionData: actionData, project: project)
    }
    
    func logTalkEditorConfirmDidTapDiscardEdit(problemSource: ProblemSource?, project: WikimediaProject) {
        var actionData: [String: String]? = nil
        if let problemSource {
            actionData = ["abort_source": problemSource.rawValue]
        }
        logEvent(activeInterface: .talkEditingInterface, action: .editCancel, actionData: actionData, project: project)
    }
    
    func logTalkEditorConfirmDidTapKeepEditing(project: WikimediaProject) {
        logEvent(activeInterface: .talkEditingInterface, action: .keepEditing, project: project)
    }
    
    func logArticleEditorDidTapNext(project: WikimediaProject) {
        logEvent(activeInterface: .articleEditingInterface, action: .editNext, project: project)
    }
    
    func logTalkEditorDidTapNext(project: WikimediaProject) {
        logEvent(activeInterface: .talkEditingInterface, action: .editNext, project: project)
    }
    
    func logArticlePreviewDidTapNext(project: WikimediaProject) {
        logEvent(activeInterface: .articleEditPreview, action: .previewNext, project: project)
    }
    
    func logArticleEditSummaryDidTapPublish(summaryAdded: Bool, minorEdit: Bool, watchlistAdded: Bool, project: WikimediaProject) {
        
        let actionData = ["summary_added": String(summaryAdded),
                          "minor_edit": String(minorEdit),
                          "watchlist_added": String(watchlistAdded)]
        
        logEvent(activeInterface: .articleEditSummary, action: .saveAttempt, actionData: actionData, project: project)
    }
    
    func logTalkEditSummaryDidTapPublish(summaryAdded: Bool, minorEdit: Bool, project: WikimediaProject) {
        
        let actionData = ["summary_added": String(summaryAdded),
                          "minor_edit": String(minorEdit)]
        
        logEvent(activeInterface: .talkEditSummary, action: .saveAttempt, actionData: actionData, project: project)
    }
    
    func logTalkEditSummaryDidTapPreview(project: WikimediaProject) {
        logEvent(activeInterface: .talkEditSummary, action: .showPreview, project: project)
    }
    
    func logArticlePublishSuccess(revisionID: Int, project: WikimediaProject) {
        let actionData = ["revision_id": String(revisionID)]
        logEvent(activeInterface: .articleEditingInterface, action: .saveSuccess, actionData: actionData, project: project)
    }
    
    func logTalkPublishSuccess(revisionID: Int, project: WikimediaProject) {
        let actionData = ["revision_id": String(revisionID)]
        logEvent(activeInterface: .talkEditingInterface, action: .saveSuccess, actionData: actionData, project: project)
    }
    
    func logArticlePublishFail(problemSource: ProblemSource?, project: WikimediaProject) {
        var actionData: [String: String]? = nil
        if let problemSource {
            actionData = ["fail_source": problemSource.rawValue]
        }
        
        logEvent(activeInterface: .articleEditSummary, action: .saveFailure, actionData: actionData, project: project)
    }
    
    func logTalkPublishFail(problemSource: ProblemSource?, project: WikimediaProject) {
        var actionData: [String: String]? = nil
        if let problemSource {
            actionData = ["fail_source": problemSource.rawValue]
        }
        
        logEvent(activeInterface: .talkEditSummary, action: .saveFailure, actionData: actionData, project: project)
    }
    
    func logArticleEditSummaryDidTapBlockedMessageLink(project: WikimediaProject) {
        let actionData = ["abort_source": ProblemSource.blockedMessageLink.rawValue]
        logEvent(activeInterface: .articleEditSummary, action: .editCancel, actionData: actionData, project: project)
    }
    
    func logTalkEditSummaryDidTapBlockedMessageLink(project: WikimediaProject) {
        let actionData = ["abort_source": ProblemSource.blockedMessageLink.rawValue]
        logEvent(activeInterface: .talkEditSummary, action: .editCancel, actionData: actionData, project: project)
    }
    
    // MARK: - Activity Tab Events
    
    func logActivityTabGroupAssignment(groupAssignment: Int, project: WikimediaProject) {

        let groupAssignmentString: String
        switch groupAssignment {
        case 0: groupAssignmentString = "activity_a"
        case 1: groupAssignmentString = "activity_b"
        case 2: groupAssignmentString = "activity_c"
        default: groupAssignmentString = "activity_a"
        }
        
        logEvent(activeInterface: nil, action: .launch, actionData:["group": groupAssignmentString], project: project)
    }
    
    func logActivityTabLoggedOutDidAppear(project: WikimediaProject) {
        logEvent(activeInterface: .activityEntry, action: .impression, actionData: nil, project: project)
    }
    
    func logActivityTabDidAppear(project: WikimediaProject) {
        logEvent(activeInterface: .activityTab, action: .impression, actionData: nil, project: project)
    }
    
    func logActivityTabLoggedOutDidTapLogin(project: WikimediaProject) {
        logEvent(activeInterface: .activityEntry, action: .loginClick, actionData: nil, project: project)
    }
    
    func logActivityTabLoggedOutDidTapViewReadingHistory(project: WikimediaProject) {
        logEvent(activeInterface: .activityEntry, action: .viewClick, actionData: nil, project: project)
    }
    
    func logActivityTabDidTapViewReadingHistory(project: WikimediaProject) {
        logEvent(activeInterface: .activityTab, action: .viewHistoryClick, actionData: nil, project: project)
    }
    
    func logActivityTabDidTapEditEmptyCapsule(project: WikimediaProject) {
        logEvent(activeInterface: .activityTab, action: .editEntryClick, actionData: nil, project: project)
    }
    
    func logActivityTabDidTapEditPopulatedCapsule(project: WikimediaProject) {
        logEvent(activeInterface: .activityTab, action: .viewEditedClick, actionData: nil, project: project)
    }
    
    func logActivityTabDidTapSavedCapsule(project: WikimediaProject) {
        logEvent(activeInterface: .activityTab, action: .viewSavedClick, actionData: nil, project: project)
    }
    
    func logActivityTabSurveyDidAppear(project: WikimediaProject) {
        logEvent(activeInterface: .activityFeedback, action: .feedbackImpression, actionData: nil, project: project)
    }
    
    func logActivityTabSurveyDidTapCancel(project: WikimediaProject) {
        logEvent(activeInterface: .activityFeedback, action: .feedbackCloseClick, actionData: nil, project: project)
    }
    
    func logActivityTabSurveyDidTapSubmit(options: [String], otherText: String?, project: WikimediaProject) {
        var actionData: [String: String] = [:]
        
        let trimmedOptions = options.filter { $0 != "other" }
        
        // todo: confirm commas don't get cut off
        let feedbackSelect = trimmedOptions.joined(separator: ",")
        actionData["feedback_select"] = feedbackSelect
        if let otherText,
           !otherText.isEmpty {
            actionData["feedback_text"] = otherText
        }
        logEvent(activeInterface: .activityFeedback, action: .feedbackSubmitClick, actionData: actionData, project: project)
    }
    
    func logActivityTabImageRecsPublishSuccess(revisionID: Int, project: WikimediaProject) {
        let actionData = ["revision_id": String(revisionID),
                          "image_add": String("true")]
        logEvent(activeInterface: .activityTab, action: .saveSuccess, actionData: actionData, project: project)
    }
}

