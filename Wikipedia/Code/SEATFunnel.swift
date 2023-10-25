import Foundation
import WMF

final class SEATFunnel: NSObject {
   
    @objc static let shared = SEATFunnel()
    
    private enum ActiveInterface: String {
        case suggestedEditsDialog = "suggested_edits_dialog"
        case seAddImageTextOnboarding = "se_add_image_text_onboarding"
        case seAddImageText = "se_add_image_text"
        case seAddImageFeedback = "se_add_image_feedback"
    }
    
    private enum Action: String {
        case enterClick = "enter_click"
        case continueClick = "continue_click"
        case learnClick = "learn_click"
        case learnImpression = "learn_impression"
        case readArticleClick = "read_article_click"
        case suggestStart = "suggest_start"
        case suggestSkip = "suggest_skip"
        case feedbackClick = "feedback_click"
        case imageDetailClick = "image_detail_click"
        case detailImpression = "detail_impression"
        case articleImpression = "article_impression"
        case textEnterStart = "text_enter_start"
        case examplesClick = "examples_click"
        case textEnterNext = "text_enter_next"
        case previewImpression = "preview_impression"
        case previewBack = "preview_back"
        case textEnterSubmit = "text_enter_submit"
        case editSuccessToast = "edit_success_toast"
        case policyClick = "policy_click"
        case cancelClick = "cancel_click"
        case feedbackToast = "feedback_toast"
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
    
    lazy var project: WikimediaProject? = {
        if let siteURL = MWKDataStore.shared().languageLinkController.appLanguage?.siteURL {
            return WikimediaProject(siteURL: siteURL)
        }
        
        return nil
    }()
   
    private func logEvent(activeInterface: ActiveInterface? = nil, action: Action? = nil, actionData: [String: String]? = nil) {
        
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
        
        let event: SEATFunnel.Event = SEATFunnel.Event(activeInterface: activeInterface?.rawValue, action: action?.rawValue, actionData: actionDataString, platform: "ios", wikiID: project?.notificationsApiWikiIdentifier)
        EventPlatformClient.shared.submit(stream: .suggestedEditsAltTextPrototype, event: event)
    }
    
    func logSettingsDidTapSEAT() {
        logEvent(activeInterface: .suggestedEditsDialog, action: .enterClick)
    }
    
    func logSEATOnboardingDidTapContinue() {
        logEvent(activeInterface: .seAddImageTextOnboarding, action: .continueClick)
    }
    
    func logSEATOnboardingDidTapLearnMore() {
        logEvent(activeInterface: .seAddImageTextOnboarding, action: .learnClick)
    }
    
    func logSEATOnboardingLearnMoreImpression() {
        logEvent(activeInterface: .seAddImageTextOnboarding, action: .learnImpression)
    }
    
    func logSEATTaskSelectionDidTapReadArticle(articleTitle: String, commonsFileName: String) {
        
        let actionData = baseActionData(articleTitle: articleTitle, commonsFileName: commonsFileName)
        logEvent(activeInterface: .seAddImageText, action: .readArticleClick, actionData: actionData)
    }
    
    func logSEATTaskSelectionDidTapSuggestButton(articleTitle: String, commonsFileName: String) {
        
        let actionData = baseActionData(articleTitle: articleTitle, commonsFileName: commonsFileName)
        logEvent(activeInterface: .seAddImageText, action: .suggestStart, actionData: actionData)
    }
    
    func logSEATTaskSelectionDidTapSkipButton(articleTitle: String, commonsFileName: String) {
        
        let actionData = baseActionData(articleTitle: articleTitle, commonsFileName: commonsFileName)
        logEvent(activeInterface: .seAddImageText, action: .suggestSkip, actionData: actionData)
    }
    
    func logSEATTaskSelectionDidTapMoreButtonLearnMore() {
        logEvent(activeInterface: .seAddImageText, action: .learnClick)
    }
    
    func logSEATTaskSelectionDidTapMoreButtonSendFeedback() {
        logEvent(activeInterface: .seAddImageText, action: .feedbackClick)
    }
    
    func logSEATTaskSelectionFeedbackAlertDidTapSendFeedback() {
        logEvent(activeInterface: .seAddImageFeedback, action: .feedbackClick)
    }
    
    func logSEATTaskSelectionFeedbackAlertDidTapPrivacyPolicy() {
        logEvent(activeInterface: .seAddImageFeedback, action: .policyClick)
    }
    
    func logSEATTaskSelectionFeedbackAlertDidTapCancel() {
        logEvent(activeInterface: .seAddImageFeedback, action: .cancelClick)
    }
    
    func logSEATTaskSelectionDidTapImageDetails(articleTitle: String, commonsFileName: String) {
        
        let actionData = baseActionData(articleTitle: articleTitle, commonsFileName: commonsFileName)
        logEvent(activeInterface: .seAddImageText, action: .imageDetailClick, actionData: actionData)
    }
    
    func logSEATTaskSelectionCommonsWebViewImpression(articleTitle: String, commonsFileName: String) {
        
        let actionData = baseActionData(articleTitle: articleTitle, commonsFileName: commonsFileName)
        logEvent(activeInterface: .seAddImageText, action: .detailImpression, actionData: actionData)
    }
    
    func logSEATTaskSelectionArticleViewImpression(articleTitle: String, commonsFileName: String) {
        
        let actionData = baseActionData(articleTitle: articleTitle, commonsFileName: commonsFileName)
        logEvent(activeInterface: .seAddImageText, action: .articleImpression, actionData: actionData)
    }
    
    func logSEATFormViewDidAppear(articleTitle: String, commonsFileName: String) {
        
        let actionData = baseActionData(articleTitle: articleTitle, commonsFileName: commonsFileName)
        logEvent(activeInterface: .seAddImageText, action: .textEnterStart, actionData: actionData)
    }
    
    func logSEATFormViewDidTapViewExamples(articleTitle: String, commonsFileName: String) {
        
        let actionData = baseActionData(articleTitle: articleTitle, commonsFileName: commonsFileName)
        logEvent(activeInterface: .seAddImageText, action: .examplesClick, actionData: actionData)
    }
    
    func logSEATFormViewDidTapNext(articleTitle: String, commonsFileName: String) {
        
        let actionData = baseActionData(articleTitle: articleTitle, commonsFileName: commonsFileName)
        logEvent(activeInterface: .seAddImageText, action: .textEnterNext, actionData: actionData)
    }
    
    func logSEATPreviewViewImpression(articleTitle: String, commonsFileName: String) {
        
        let actionData = baseActionData(articleTitle: articleTitle, commonsFileName: commonsFileName)
        logEvent(activeInterface: .seAddImageText, action: .previewImpression, actionData: actionData)
    }
    
    func logSEATPreviewViewDidTapBack(articleTitle: String, commonsFileName: String) {
        
        let actionData = baseActionData(articleTitle: articleTitle, commonsFileName: commonsFileName)
        logEvent(activeInterface: .seAddImageText, action: .previewBack, actionData: actionData)
    }
    
    func logSEATPreviewViewDidTapSubmit(articleTitle: String, commonsFileName: String) {
        
        let actionData = baseActionData(articleTitle: articleTitle, commonsFileName: commonsFileName)
        logEvent(activeInterface: .seAddImageText, action: .textEnterSubmit, actionData: actionData)
    }
    
    func logSEATPreviewViewDidDidTriggerSubmittedToast(articleTitle: String, commonsFileName: String, altText: String) {
        
        var actionData = baseActionData(articleTitle: articleTitle, commonsFileName: commonsFileName)
        actionData["alt_text"] = "'\(altText)'"
        
        logEvent(activeInterface: .seAddImageText, action: .editSuccessToast, actionData: actionData)
    }
    
    private func baseActionData(articleTitle: String, commonsFileName: String) -> [String : String] {
        var actionData: [String: String] = [:]
        actionData["source"] = articleTitle.replacingOccurrences(of: " ", with: "_")
        actionData["image"] = commonsFileName.replacingOccurrences(of: " ", with: "_")
        return actionData
    }
}
