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

        // Alt-Text-Experiment Items
        case altTextEditingOnboarding = "alt_text_editing_onboarding"
        case altTextEditingInterface = "alt_text_editing_interface"
        case altTextFeedbackInterface = "alt_text_feedback_interface"
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
        
        // Alt-Text-Experiment Items
        case groupAssignment = "group_assignment"
        case launchImpression = "launch_impression"
        case launchCloseClick = "launch_close_click"
        case addClick = "add_click"
        case doNotAddClick = "do_not_add_click"
        case addAltTextImpression = "add_alt_text_impression"
        case addAltTextInput = "add_alt_text_input"
        case altTextEditSuccess = "alt_text_edit_success"
        case minimizedImpression = "minimized_impression"
        case publishClick = "alt_text_publish_click"
        case characterWarning = "character_warning"
        case imageDetailViewClick = "image_detail_view_click"
        case imageTapImpression = "image_tap_impression"
        case imageDetailImpression = "image_detail_impression"
        case onboardImpression = "onboard_impression"
        case continueClick = "continue_click"
        case examplesClick = "examples_click"
        case tooltipStartClick = "tooltip_start_click"
        case tooltipDoneClick = "tooltip_done_click"
        case overflowLearnMore = "overflow_learn_more"
        case overflowTutorialClick = "overflow_tutorial_click"
        case overflowReportClick = "overflow_report_click"
        case feedbackYes = "feedback_yes_click"
        case feedbackNo = "feedback_no_click"
        case feedbackNeutral = "feedback_neutral_click"
        case feedbackUnsatisfied = "feedback_unsatisfied_click"
        case feedbackSatisfied = "feedback_satisfied_click"
        case feedbackToast = "feedback_submit_toast"
        case rejectSubmitClick = "reject_submit_click"
        case rejectSubmitSuccess = "reject_submit_success"
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
   
    private func logEvent(activeInterface: ActiveInterface, action: Action, actionData: [String: String]? = nil, project: WikimediaProject) {
        
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
        
        let event: EditInteractionFunnel.Event = EditInteractionFunnel.Event(activeInterface: activeInterface.rawValue, action: action.rawValue, actionData: actionDataString, platform: "ios", wikiID: project.notificationsApiWikiIdentifier)
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
    
    // MARK: Alt-Text-Experiment
    
    func logAltTextDidAssignImageRecsGroup(username: String, userEditCount: UInt64, articleTitle: String, image: String, registrationDate: String?, project: WikimediaProject) {
        guard let group = WMFAltTextDataController.shared?.assignedAltTextImageRecommendationsGroupForLogging() else {
            return
        }
        
        var actionData = ["article_title": articleTitle,
                          "image": image,
                          "username": username,
                          "event_user_revision_count": String(userEditCount)]
        
        if let registrationDate {
            actionData["user_create_date"] = registrationDate
        }
        
        switch group {
        case "A":
            actionData["exp_b_group"] = "a"
        case "B":
            actionData["exp_b_group"] = "b"
        default:
            assertionFailure("Unexpected experiment group")
        }
        
        logEvent(activeInterface: .altTextEditingOnboarding, action: .groupAssignment, actionData: actionData, project: project)
    }
    
    func logAltTextDidAssignArticleEditorGroup(username: String, userEditCount: UInt64, articleTitle: String, image: String, registrationDate: String?, project: WikimediaProject) {
        
        guard let group = WMFAltTextDataController.shared?.assignedAltTextArticleEditorGroupForLogging() else {
            return
        }
        
        var actionData = ["article_title": articleTitle,
                          "image": image,
                          "username": username,
                          "event_user_revision_count": String(userEditCount)]
        
        if let registrationDate {
            actionData["user_create_date"] = registrationDate
        }
        
        switch group {
        case "C":
            actionData["exp_c_group"] = "c"
        case "D":
            actionData["exp_c_group"] = "d"
        default:
            assertionFailure("Unexpected experiment group")
        }
        
        logEvent(activeInterface: .altTextEditingOnboarding, action: .groupAssignment, actionData: actionData, project: project)
    }
    
    func logAltTextPromptDidAppear(project: WikimediaProject) {
        logEvent(activeInterface: .altTextEditingOnboarding, action: .launchImpression, project: project)
    }
    
    func logAltTextPromptDidTapClose(project: WikimediaProject) {
        logEvent(activeInterface: .altTextEditingOnboarding, action: .launchCloseClick, project: project)
    }
    
    func logAltTextPromptDidTapAdd(project: WikimediaProject) {
        logEvent(activeInterface: .altTextEditingOnboarding, action: .addClick, project: project)
    }
    
    func logAltTextPromptDidTapDoNotAdd(project: WikimediaProject) {
        logEvent(activeInterface: .altTextEditingOnboarding, action: .doNotAddClick, project: project)
    }
    
    func logAltTextInputDidAppear(project: WikimediaProject) {
        logEvent(activeInterface: .altTextEditingInterface, action: .addAltTextImpression, project: project)
    }
    
    func logAltTextInputDidFocus(project: WikimediaProject) {
        logEvent(activeInterface: .altTextEditingInterface, action: .addAltTextInput, project: project)
    }
    
    func logAltTextInputDidMinimize(project: WikimediaProject) {
        logEvent(activeInterface: .altTextEditingInterface, action: .minimizedImpression, project: project)
    }
    
    func logAltTextDidTapPublish(project: WikimediaProject) {
        logEvent(activeInterface: .altTextEditingInterface, action: .publishClick, project: project)
    }

    func logAltTextInputDidTriggerWarning(project: WikimediaProject) {
        logEvent(activeInterface: .altTextEditingInterface, action: .characterWarning, project: project)
    }
    
    func logAltTextInputDidTapFileName(project: WikimediaProject) {
        logEvent(activeInterface: .altTextEditingInterface, action: .imageDetailViewClick, project: project)
    }
    
    func logAltTextInputDidTapImage(project: WikimediaProject) {
        logEvent(activeInterface: .altTextEditingInterface, action: .imageTapImpression, project: project)
    }

    func logAltTextDidPushCommonsView(project: WikimediaProject) {
        logEvent(activeInterface: .altTextEditingInterface, action: .imageDetailImpression, project: project)
    }

    func logAltTextDidSuccessfullyPostEdit(timeSpent: Int, revisionID: UInt64, altText: String, caption: String?, articleTitle: String, image: String, username: String, userEditCount: UInt64, registrationDate: String?, project: WikimediaProject) {
        
        var actionData = ["time_spent": String(timeSpent),
                          "revision_id": String(revisionID),
                          "alt_text": altText,
                          "article_title": articleTitle,
                          "image": image,
                          "username": username,
                          "event_user_revision_count": String(userEditCount)]
        
        if let registrationDate {
            actionData["user_create_date"] = registrationDate
        }
        
        if let caption {
            actionData["caption"] = caption
        }
        
        logEvent(activeInterface: .altTextEditingInterface, action: .altTextEditSuccess, actionData: actionData, project: project)
    }
    
    func logAltTextOnboardingDidAppear(project: WikimediaProject) {
        logEvent(activeInterface: .altTextEditingOnboarding, action: .onboardImpression, project: project)
    }
    
    func logAltTextOnboardingDidTapPrimaryButton(project: WikimediaProject) {
        logEvent(activeInterface: .altTextEditingOnboarding, action: .continueClick, project: project)
    }
    
    func logAltTextOnboardingDidTapSecondaryButton(project: WikimediaProject) {
        logEvent(activeInterface: .altTextEditingOnboarding, action: .examplesClick, project: project)
    }

    func logAltTextOnboardingDidTapNextOnFirstTooltip(project: WikimediaProject) {
        logEvent(activeInterface: .altTextEditingOnboarding, action: .tooltipStartClick, project: project)
    }
    
    func logAltTextOnboardingDidTapDoneOnLastTooltip(project: WikimediaProject) {
        logEvent(activeInterface: .altTextEditingOnboarding, action: .tooltipDoneClick, project: project)
    }
    
    func logAltTextEditingInterfaceOverflowLearnMore(project: WikimediaProject) {
        logEvent(activeInterface: .altTextEditingInterface, action: .overflowLearnMore, project: project)
    }

    func logAltTextEditingInterfaceOverflowTutorial(project: WikimediaProject) {
        logEvent(activeInterface: .altTextEditingInterface, action: .overflowTutorialClick, project: project)
    }
    
    func logAltTextEditingInterfaceOverflowReport(project: WikimediaProject) {
        logEvent(activeInterface: .altTextEditingInterface, action: .overflowReportClick, project: project)
   }

    func logAltTextFeedback(answer: Bool, project: WikimediaProject) {
        let action: Action = answer ? .feedbackYes : .feedbackNo
        logEvent(activeInterface: .altTextFeedbackInterface, action: action, project: project)
    }

    func logAltTextFeedbackSurveyNeutral(project: WikimediaProject) {
        logEvent(activeInterface: .altTextFeedbackInterface, action: .feedbackNeutral, project: project)
    }

    func logAltTextFeedbackSurveySatisfied(project: WikimediaProject) {
        logEvent(activeInterface: .altTextFeedbackInterface, action: .feedbackSatisfied, project: project)
    }

    func logAltTextFeedbackSurveyUnsatisfied(project: WikimediaProject) {
        logEvent(activeInterface: .altTextFeedbackInterface, action: .feedbackUnsatisfied, project: project)
    }

    func logAltTextFeedbackSurveyToastDisplayed(project: WikimediaProject) {
        logEvent(activeInterface: .altTextFeedbackInterface, action: .feedbackToast, project: project)
    }
    
    func logAltTextSurveyDidTapSubmit(project: WikimediaProject) {
        logEvent(activeInterface: .altTextEditingOnboarding, action: .rejectSubmitClick, project: project)
    }
    
    func logAltTextSurveyDidSubmit(rejectionReasons: [String], otherReason: String?, project: WikimediaProject) {
        let rejectionReasonsJoined = rejectionReasons.joined(separator: ",")
        
        var actionData: [String: String] = [
            "rejection_reason": "\(rejectionReasonsJoined)"
        ]
        
        if let otherReason {
            actionData["rejection_text"] = otherReason
        }
        
        logEvent(activeInterface: .altTextEditingOnboarding, action: .rejectSubmitSuccess, actionData: actionData, project: project)
    }
}

