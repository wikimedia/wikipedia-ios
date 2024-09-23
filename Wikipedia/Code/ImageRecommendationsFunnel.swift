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
        case noSuggestionsDialog = "nosuggestions_dialog"
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
        case overflowTutorial = "overflow_tutorial"
        case overflowReport = "overflow_report"
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
        case warning = "warning"
    }
    
    private struct Event: EventInterface {
        static let schema: EventPlatformClient.Schema = .imageRecommendation
        let activeInterface: String?
        let action: String?
        let actionData: String?
        let wikiID: String?
        
        enum CodingKeys: String, CodingKey {
            case activeInterface = "active_interface"
            case action = "action"
            case actionData = "action_data"
            case wikiID = "wiki_id"
        }
    }
    
    // The Image Recommendations feature is displayed only for the app primary language, so this is a shortcut to get that value. If the business logic changes to include secondary language recommendations, we will need to inject project into each method based on which wiki the recommendation is on.
    
    private lazy var project: WikimediaProject? = {
        guard let appLanguage = MWKDataStore.shared().languageLinkController.appLanguage else {
            return nil
        }
        
        return WikimediaProject(siteURL: appLanguage.siteURL)
    }()
    
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
        
        let event: ImageRecommendationsFunnel.Event = ImageRecommendationsFunnel.Event(activeInterface: activeInterface?.rawValue, action: action?.rawValue, actionData: actionDataString, wikiID: project?.notificationsApiWikiIdentifier)
        EventPlatformClient.shared.submit(stream: .imageRecommendation, event: event)
    }
    
    func logExploreDidTapFeatureAnnouncementPrimaryButton() {
        logEvent(activeInterface: .onboardingStep1Dialog, action: .startTooltips, project: project)
    }
    
    func logOnboardingDidTapContinue() {
        logEvent(activeInterface: .onboardingStep2Dialog, action: .next, project: project)
    }
    
    func logOnboardingDidTapLearnMore() {
        logEvent(activeInterface: .onboardingStep2Dialog, action: .learnMore, project: project)
    }
    
    func logTooltipDidTapFirstNext() {
        logEvent(activeInterface: .onboardingStep3Dialog, action: .next, project: project)
    }
    
    func logTooltipDidTapSecondNext() {
        logEvent(activeInterface: .onboardingStep4Dialog, action: .next, project: project)
    }
    
    func logTooltipDidTapThirdOk() {
        logEvent(activeInterface: .onboardingStep5Dialog, action: .completeTooltips, project: project)
    }
    
    func logExploreCardDidTapAddImage() {
        logEvent(activeInterface: .suggestedEditsDialog, action: .addImageStart, project: project)
    }
    
    func logBottomSheetDidAppear() {
        logEvent(activeInterface: .recommendedImageToolbar, action: .impression, project: project)
    }
    
    func logBottomSheetDidTapYes() {
        logEvent(activeInterface: .recommendedImageToolbar, action: .suggestionAccept, project: project)
    }
    
    func logBottomSheetDidTapNo() {
        logEvent(activeInterface: .recommendedImageToolbar, action: .suggestionReject, project: project)
    }
    
    func logBottomSheetDidTapNotSure() {
        logEvent(activeInterface: .recommendedImageToolbar, action: .suggestionSkip, project: project)
    }
    
    func logOverflowDidTapLearnMore() {
        logEvent(activeInterface: .recommendedImageToolbar, action: .overflowLearnMore, project: project)
    }
    
    func logOverflowDidTapTutorial() {
        logEvent(activeInterface: .recommendedImageToolbar, action: .overflowTutorial, project: project)
    }
    
    func logOverflowDidTapProblem() {
        logEvent(activeInterface: .recommendedImageToolbar, action: .overflowReport, project: project)
    }
    
    func logBottomSheetDidTapFileName() {
        logEvent(activeInterface: .recommendedImageToolbar, action: .imageDetailView, project: project)
    }
    
    func logCommonsWebViewDidAppear() {
        logEvent(activeInterface: .imageDetailsDialog, action: .impression, project: project)
    }
    
    func logAddImageDetailsDidAppear() {
        logEvent(activeInterface: .captionEntry, action: .impression, project: project)
    }
    
    func logAddImageDetailsDidTapFileName() {
        logEvent(activeInterface: .captionEntry, action: .imageDetailView, project: project)
    }
    
    func logAddImageDetailsDidTapCaptionLearnMore() {
        logEvent(activeInterface: .captionEntry, action: .viewCaptionHelp, project: project)
    }
    
    func logAddImageDetailsDidTapAltTextLearnMore() {
        logEvent(activeInterface: .captionEntry, action: .viewAltTextHelp, project: project)
    }
    
    func logAddImageDetailsDidTapAdvancedSettings() {
        logEvent(activeInterface: .captionEntry, action: .advancedSettingOpen, project: project)
    }
    
    func logPreviewDidAppear() {
        logEvent(activeInterface: .captionPreview, action: .impression, project: project)
    }
    
    func logPreviewDidTapBack() {
        logEvent(activeInterface: .captionPreview, action: .back, project: project)
    }
    
    func logPreviewDidTapNext() {
        logEvent(activeInterface: .captionPreview, action: .captionPreviewAccept, project: project)
    }
    
    func logSaveChangesDidAppear() {
        logEvent(activeInterface: .editSummaryDialog, action: .impression, project: project)
    }
    
    func logSaveChangesDidTapBack() {
        logEvent(activeInterface: .editSummaryDialog, action: .back, project: project)
    }
    
    func logSaveChangesDidTapMinorEditsLearnMore() {
        logEvent(activeInterface: .editSummaryDialog, action: .viewEditHelp, project: project)
    }
    
    func logSaveChangesDidTapWatchlistLearnMore() {
        logEvent(activeInterface: .editSummaryDialog, action: .viewWatchlistHelp, project: project)
    }
    
    func logSaveChangesDidToggleWatchlist(isOn: Bool) {
        let action = isOn ? Action.addWatchlist : Action.removeWatchlist
        logEvent(activeInterface: .editSummaryDialog, action: action, project: project)
    }
    
    func logSaveChangesDidTapPublish(minorEditEnabled: Bool, watchlistEnabled: Bool) {
        let actionData: [String: String] =  ["minor_edit": "\(minorEditEnabled)", "watchlist_added": "\(watchlistEnabled)"]

        logEvent(activeInterface: .editSummaryDialog, action: .editSummarySave, actionData:actionData, project: project)
    }
    
    func logSaveChangesPublishSuccess(timeSpent: Int?, revisionID: Int, captionAdded: Bool, altTextAdded: Bool, summaryAdded: Bool) {
        var actionData = ["revision_id": "\(revisionID)",
                          "caption_add": "\(captionAdded)",
                          "alt_text_add": "\(altTextAdded)",
                          "summary_add": "\(summaryAdded)"]
        if let timeSpent {
            actionData["time_spent"] = String(timeSpent)
                              
        }
        logEvent(activeInterface: .editSummaryDialog, action: .editSummarySuccess, actionData: actionData, project: project)
    }
    
    func logRejectSurveyDidAppear() {
        logEvent(activeInterface: .rejectionDialog, action: .impression, project: project)
    }
    
    func logRejectSurveyDidTapCancel() {
        logEvent(activeInterface: .rejectionDialog, action: .rejectCancel, project: project)
    }
    
    func logRejectSurveyDidTapSubmit(rejectionReasons: [String], otherReason: String?, fileName: String, recommendationSource: String) {
        let rejectionReasonsJoined = rejectionReasons.joined(separator: ",")
        
        var actionData: [String: String] = [
            "rejection_reason": "\(rejectionReasonsJoined)",
            "filename": "\(fileName)",
            "recommendation_source": "\(recommendationSource)"
        ]
        
        if let otherReason {
            actionData["rejection_text"] = otherReason
        }
        
        logEvent(activeInterface: .rejectionDialog, action: .rejectSubmit, actionData: actionData, project: project)
    }
    
    func logEmptyStateDidAppear() {
        logEvent(activeInterface: .noSuggestionsDialog, action: .impression, project: project)
    }
    
    func logEmptyStateDidTapBack() {
        logEvent(activeInterface: .noSuggestionsDialog, action: .noSuggestionsBack, project: project)
    }
    
    func logSettingsToggleSuggestedEditsCard(isOn: Bool) {
        let action = isOn ? Action.enableSuggestedEdits : Action.disableSuggestedEdits
        logEvent(activeInterface: .exploreSettings, action: action, project: project)
    }
    
    func logSettingsDidDisableSuggestedEditsCard() {
        logEvent(activeInterface: .exploreSettings, action: .disableSuggestedEdits, project: project)
    }
    
    func logSaveChangesPublishFail(abortSource: String?) {
        var actionData: [String : String]?
        if let abortSource {
            actionData = ["abort_source": abortSource]
        }
        logEvent(activeInterface: .editSummaryDialog, action: .saveFailure, actionData: actionData, project: project)
    }

    func logDialogWarningMessageDidDisplay(fileName: String, recommendationSource: String) {
        
        let actionData: [String: String] = [
            "filename": "\(fileName)",
            "recommendation_source": "\(recommendationSource)"
        ]
        
        logEvent(activeInterface: .recommendedImageToolbar, action: .warning, actionData: actionData, project: project)
    }
}
