import Foundation

final class ImageRecommendationsFunnel: NSObject {
    
    @objc static let shared = ImageRecommendationsFunnel()
    
    private enum ActiveInterface: String {
        case onboardingStep1Dialog = "onboarding_step_1_dialog"
        case onboardingStep2Dialog = "onboarding_step_2_dialog"
        case onboardingStep3Dialog = "onboarding_step_3_dialog"
        case onboardingStep4Dialog = "onboarding_step_4_dialog"
        case onboardingStep5Dialog = "onboarding_step_5_dialog"
        case suggestedEditsDialog = "suggested_edits_dialog"
        case recommendedImageToolbar = "recommendedimagetoolbar"
        case imageDetailsDialog = "imagedetails_dialog"
        case captionEntry = "caption_entry"
        case captionPreview = "caption_preview"
        case editSummaryDialog = "editsummary_dialog"
        case rejectionDialog = "rejection_dialog"
        case noSuggestionsDialog = "no_suggestions_dialog"
        case exploreSettings = "explore_settings"
    }
    
    private enum Action: String {
        case startTooltips = "start_tooltips"
        case next = "next"
        case learnMore = "learn_more"
        case completeTooltips = "complete_tooltips"
        case addImageStart = "add_image_start"
        case impression = "impression"
        case suggestionAccept = "suggestion_accept"
        case suggestionReject = "suggestion_reject"
        case suggestionSkip = "suggestion_skip"
        case overflowLearnMore = "overflow_learn_more"
        case overflowTutorial = "overflow_learn_tutorial"
        case overflowReport = "overflow_learn_report"
        case imageDetailView = "image_detail_view"
        case viewCaptionHelp = "view_caption_help"
        case viewAltTextHelp = "view_alt_text_help"
        case advancedSettingOpen = "advanced_settting_open"
        case captionPreviewAccept = "caption_preview_accept"
        case back = "back"
        case viewEditHelp = "view_edit_help"
        case viewWatchlistHelp = "view_watchlist_help"
        case editSummarySave = "editsummary_save"
        case addWatchlist = "add_watchlist"
        case removeWatchlist = "remove_watchlist"
        case editSummarySuccess = "editsummary_success"
        case rejectCancel = "reject_cancel"
        case rejectSubmit = "reject_submit"
        case noSuggestionsBack = "nosuggestions_back"
        case enableSuggestedEdits = "enable_suggested_edits"
        case disableSuggestedEdits = "disable_suggested_edits"
        case saveFailure = "save_failure"
    }
    
    private struct Event: EventInterface {
        static let schema: EventPlatformClient.Schema = .imageRecommendation
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
    
    private func logEvent(activeInterface: ActiveInterface? = nil, action: Action? = nil, actionData: [String: String]? = nil, project: WikimediaProject? = nil) {
        
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
        
        let event: ImageRecommendationsFunnel.Event = ImageRecommendationsFunnel.Event(activeInterface: activeInterface?.rawValue, action: action?.rawValue, actionData: actionDataString, platform: "ios", wikiID: project?.notificationsApiWikiIdentifier)
        EventPlatformClient.shared.submit(stream: .imageRecommendation, event: event)
    }
    
    func logExploreDidTapFeatureAnnouncementPrimaryButton() {
        logEvent(activeInterface: .onboardingStep1Dialog, action: .startTooltips)
    }
    
    func logOnboardingDidTapContinue() {
        logEvent(activeInterface: .onboardingStep2Dialog, action: .next)
    }
    
    func logOnboardingDidTapLearnMore() {
        logEvent(activeInterface: .onboardingStep2Dialog, action: .learnMore)
    }
    
    func logTooltipDidTapFirstNext() {
        logEvent(activeInterface: .onboardingStep3Dialog, action: .next)
    }
    
    func logTooltipDidTapSecondNext() {
        logEvent(activeInterface: .onboardingStep4Dialog, action: .next)
    }
    
    func logTooltipDidTapThirdOk() {
        logEvent(activeInterface: .onboardingStep5Dialog, action: .completeTooltips)
    }
    
    func logExploreCardDidTapAddImage() {
        logEvent(activeInterface: .suggestedEditsDialog, action: .addImageStart)
    }
    
    func logBottomSheetDidAppear() {
        logEvent(activeInterface: .recommendedImageToolbar, action: .impression)
    }
    
    func logBottomSheetDidTapYes() {
        logEvent(activeInterface: .recommendedImageToolbar, action: .suggestionAccept)
    }
    
    func logBottomSheetDidTapNo() {
        logEvent(activeInterface: .recommendedImageToolbar, action: .suggestionReject)
    }
    
    func logBottomSheetDidTapNotSure() {
        logEvent(activeInterface: .recommendedImageToolbar, action: .suggestionSkip)
    }
    
    func logOverflowDidTapLearnMore() {
        logEvent(activeInterface: .recommendedImageToolbar, action: .overflowLearnMore)
    }
    
    func logOverflowDidTapTutorial() {
        logEvent(activeInterface: .recommendedImageToolbar, action: .overflowTutorial)
    }
    
    func logOverflowDidTapProblem() {
        logEvent(activeInterface: .recommendedImageToolbar, action: .overflowReport)
    }
    
    func logBottomSheetDidTapFileName() {
        logEvent(activeInterface: .recommendedImageToolbar, action: .imageDetailView)
    }
    
    func logCommonsWebViewDidAppear() {
        logEvent(activeInterface: .imageDetailsDialog, action: .impression)
    }
    
    func logAddImageDetailsDidAppear() {
        logEvent(activeInterface: .captionEntry, action: .impression)
    }
    
    func logAddImageDetailsDidTapFileName() {
        logEvent(activeInterface: .captionEntry, action: .imageDetailView)
    }
    
    func logAddImageDetailsDidTapCaptionLearnMore() {
        logEvent(activeInterface: .captionEntry, action: .viewCaptionHelp)
    }
    
    func logAddImageDetailsDidTapAltTextLearnMore() {
        logEvent(activeInterface: .captionEntry, action: .viewAltTextHelp)
    }
    
    func logAddImageDetailsDidTapAdvancedSettings() {
        logEvent(activeInterface: .captionEntry, action: .advancedSettingOpen)
    }
    
    func logPreviewDidTapBack() {
        logEvent(activeInterface: .captionPreview, action: .back)
    }
    
    func logPreviewDidTapNext() {
        logEvent(activeInterface: .captionPreview, action: .next)
    }
    
    func logSaveChangesDidAppear() {
        logEvent(activeInterface: .editSummaryDialog, action: .impression)
    }
    
    func logSaveChangesDidTapBack() {
        logEvent(activeInterface: .editSummaryDialog, action: .back)
    }
    
    func logSaveChangesDidTapMinorEditsLearnMore() {
        logEvent(activeInterface: .editSummaryDialog, action: .viewEditHelp)
    }
    
    func logSaveChangesDidTapWatchlistLearnMore() {
        logEvent(activeInterface: .editSummaryDialog, action: .viewWatchlistHelp)
    }
    
    func logSaveChangesDidTapPublish(minorEditEnabled: Bool, watchlistEnabled: Bool) {
        logEvent(activeInterface: .editSummaryDialog, action: .editSummarySave, actionData:
                    ["minor_edit": "\(minorEditEnabled)",
                     "watchlist_added": "\(watchlistEnabled)"]
        )
    }
    
    func logSaveChangesPublishSuccess(revisionID: Int, captionAdded: Bool, altTextAdded: Bool, summaryAdded: Bool) {
        // TODO: Time Spent, don't know how that should be tracked
        logEvent(activeInterface: .editSummaryDialog, action: .editSummarySave, actionData:
                    ["revision_id": "\(revisionID)",
                     "capion_add": "\(captionAdded)",
                     "alt_text_add": "\(altTextAdded)",
                     "summary_add": "\(summaryAdded)"]
        )
    }
    
    func logRejectSurveyDidAppear() {
        logEvent(activeInterface: .rejectionDialog, action: .impression)
    }
    
    func logRejectSurveyDidTapCancel() {
        logEvent(activeInterface: .rejectionDialog, action: .rejectCancel)
    }
    
    func logRejectSurveyDidTapSubmit(rejectionReasons: [String], otherReason: String?, fileName: String) {
        let rejectionReasonsJoined = rejectionReasons.joined(separator: ",")
        
        // TODO: Recommendation Source, don't know how we capture that.
        var actionData: [String: String] = [
            "rejection_reason": "\(rejectionReasonsJoined)",
            "filename": "\(fileName)"
        ]
        
        if let otherReason {
            actionData["rejection_text"] = otherReason
        }
        
        logEvent(activeInterface: .rejectionDialog, action: .rejectSubmit, actionData: actionData)
    }
    
    func logEmptyStateDidTapBack() {
        logEvent(activeInterface: .noSuggestionsDialog, action: .noSuggestionsBack)
    }
    
    func logSettingsDidEnableSuggestedEditsCard() {
        logEvent(activeInterface: .exploreSettings, action: .enableSuggestedEdits)
    }
    
    func logSettingsDidDisableSuggestedEditsCard() {
        logEvent(activeInterface: .exploreSettings, action: .disableSuggestedEdits)
    }
    
    func logSaveChangesPublishFail(abortSource: String) {
        logEvent(activeInterface: .editSummaryDialog, action: .saveFailure, actionData: ["abort_source": abortSource])
    }
}
