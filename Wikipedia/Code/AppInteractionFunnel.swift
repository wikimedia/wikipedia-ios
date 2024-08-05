import Foundation
import WMF

@objc(WMFDonateFunnel) final class DonateFunnel: NSObject {
   
    @objc static let shared = DonateFunnel()
    
    private enum ActiveInterface: String {
        case setting = "setting"
        case articleBanner = "article_banner"
        case article = "article"
        case applePayInitiated = "applepay_initiated"
        case applePay = "applepay"
        case applePayProcessed = "applepay_processed"
        case webPayInitiated = "webpay_initiated"
        case webPayProcessed = "webpay_processed"
    }
    
    private enum Action: String {
        case settingClick = "setting_click"
        case donateStartClick = "donate_start_click"
        case impression = "impression"
        case closeClick = "close_click"
        case donateClick = "donate_click"
        case laterClick = "later_click"
        case alreadyDonatedClick = "already_donated_click"
        case donorPolicyClick = "donor_policy_click"
        case reminderToast = "reminder_toast"
        case applePayClick = "applepay_click"
        case webPayClick = "webpay_click"
        case cancelClick = "cancel_click"
        case entryError = "entry_error"
        case amountSelected = "amount_selected"
        case amountEntered = "amount_entered"
        case donateConfirmClick = "donate_confirm_click"
        case reportProblemClick = "report_problem_click"
        case otherGiveClick = "other_give_click"
        case faqClick = "faq_click"
        case taxInfoClick = "taxinfo_click"
        case submissionError = "submission_error"
        case applePayUIConfirm = "applepay_ui_confirm"
        case successToastSetting = "success_toast_setting"
        case successToastArticle = "success_toast_article"
        case articleReturnClick = "article_return_click"
        case returnClick = "return_click"
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
        
        let event: DonateFunnel.Event = DonateFunnel.Event(activeInterface: activeInterface?.rawValue, action: action?.rawValue, actionData: actionDataString, platform: "ios", wikiID: project?.notificationsApiWikiIdentifier)
        EventPlatformClient.shared.submit(stream: .appDonorExperience, event: event)
    }
    
    func logSettingsDidTapSettingsIcon() {
        logEvent(activeInterface: .setting, action: .settingClick)
    }
    
    @objc func logSettingsDidTapDonateCell() {
        logEvent(activeInterface: .setting, action: .donateStartClick)
    }
    
    func logFundraisingCampaignModalImpression(project: WikimediaProject, metricsID: String?) {
        
        var actionData: [String: String]?
        if let metricsID {
            actionData = [:]
            actionData?["campaign_id"] = metricsID
        }
        
        logEvent(activeInterface: .articleBanner, action: .impression, actionData: actionData, project: project)
    }
    
    func logFundraisingCampaignModalDidTapClose(project: WikimediaProject, campaignID: String?) {
        var actionData: [String: String]?
        if let campaignID {
            actionData = [:]
            actionData?["campaign_id"] = campaignID
        }
        
        logEvent(activeInterface: .articleBanner, action: .closeClick, actionData: actionData, project: project)
    }
    
    func logFundraisingCampaignModalDidTapDonate(project: WikimediaProject, campaignID: String?) {
        var actionData: [String: String]?
        if let campaignID {
            actionData = ["campaign_id": campaignID]
        }
        
        logEvent(activeInterface: .articleBanner, action: .donateClick, actionData: actionData, project: project)
    }
    
    func logFundraisingCampaignModalDidTapMaybeLater(project: WikimediaProject, campaignID: String?) {
        var actionData: [String: String]?
        if let campaignID {
            actionData = ["campaign_id": campaignID]
        }
        
        logEvent(activeInterface: .articleBanner, action: .laterClick, actionData: actionData, project: project)
    }
    
    func logFundraisingCampaignModalDidTapAlreadyDonated(project: WikimediaProject, campaignID: String?) {
        var actionData: [String: String]?
        if let campaignID {
            actionData = ["campaign_id": campaignID]
        }
        
        logEvent(activeInterface: .articleBanner, action: .alreadyDonatedClick, actionData: actionData, project: project)
    }
    
    func logFundraisingCampaignModalDidTapDonorPolicy(project: WikimediaProject) {
        logEvent(activeInterface: .articleBanner, action: .donorPolicyClick, project: project)
    }
    
    func logArticleDidSeeReminderToast(project: WikimediaProject) {
        logEvent(activeInterface: .article, action: .reminderToast, project: project)
    }
    
    func logSettingDidTapApplePay() {
        logEvent(activeInterface: .setting, action: .applePayClick)
    }
    
    func logSettingDidTapOtherPaymentMethod() {
        logEvent(activeInterface: .setting, action: .webPayClick)
    }
    
    func logSettingDidTapCancel() {
        logEvent(activeInterface: .setting, action: .cancelClick)
    }
    
    func logArticleDidTapDonateWithApplePay(project: WikimediaProject) {
        logEvent(activeInterface: .articleBanner, action: .applePayClick, project: project)
    }
    
    func logArticleDidTapOtherPaymentMethod(project: WikimediaProject) {
        logEvent(activeInterface: .articleBanner, action: .webPayClick, project: project)
    }
    
    func logArticleDidTapCancel(project: WikimediaProject) {
        logEvent(activeInterface: .articleBanner, action: .cancelClick, project: project)
    }
    
    func logDonateFormNativeApplePayImpression(project: WikimediaProject?) {
        logEvent(activeInterface: .applePayInitiated, action: .impression, project: project)
    }
    
    func logDonateFormNativeApplePayEntryError(project: WikimediaProject?) {
        logEvent(activeInterface: .applePay, action: .entryError, project: project)
    }
    
    func logDonateFormNativeApplePayDidTapAmountPresetButton(project: WikimediaProject?) {
        logEvent(activeInterface: .applePay, action: .amountSelected, project: project)
    }
    
    func logDonateFormNativeApplePayDidEnterAmountInTextfield(project: WikimediaProject?) {
        logEvent(activeInterface: .applePay, action: .amountEntered, project: project)
    }
    
    func logDonateFormNativeApplePayDidTapApplePayButton(transactionFeeIsSelected: Bool, recurringMonthlyIsSelected: Bool, emailOptInIsSelected: Bool?, project: WikimediaProject?) {
        var actionData = ["add_transaction": String(transactionFeeIsSelected),
                          "recurring": String(recurringMonthlyIsSelected)]
        
        if let emailOptInIsSelected {
            actionData["email_subscribe"] = String(emailOptInIsSelected)
        }
        
        logEvent(activeInterface: .applePay, action: .donateConfirmClick, actionData: actionData, project: project)
    }
    
    func logDonateFormNativeApplePayDidTapProblemsDonatingLink(project: WikimediaProject?) {
        logEvent(activeInterface: .applePay, action: .reportProblemClick, project: project)
    }
    
    func logDonateFormNativeApplePayDidTapOtherWaysToGiveLink(project: WikimediaProject?) {
        logEvent(activeInterface: .applePay, action: .otherGiveClick, project: project)
    }
    
    func logDonateFormNativeApplePayDidTapFAQLink(project: WikimediaProject?) {
        logEvent(activeInterface: .applePay, action: .faqClick, project: project)
    }
    
    func logDonateFormNativeApplePayDidTapTaxInfoLink(project: WikimediaProject?) {
        logEvent(activeInterface: .applePay, action: .taxInfoClick, project: project)
    }
    
    func logDonateFormNativeApplePayDidAuthorizeApplePay(amount: Decimal, presetIsSelected: Bool, recurringMonthlyIsSelected: Bool, metricsID: String?, donorEmail: String?, project: WikimediaProject?) {
        var actionData = ["preset_selected": String(presetIsSelected),
                          "donation_amount": (amount as NSNumber).stringValue,
                          "recurring": String(recurringMonthlyIsSelected),
                          "pay_method": "applepay"]
        if let metricsID {
            actionData["campaign_id"] = metricsID
        }
        
        if let donorEmail {
            actionData["email"] = donorEmail
        }
        
        logEvent(activeInterface: .applePayProcessed, action: .applePayUIConfirm, actionData: actionData, project: project)
    }
    
    func logDonateFormNativeApplePaySubmissionError(errorReason: String?, errorCode: String?, orderID: String?, project: WikimediaProject?) {
        var actionData: [String: String] = [:]
        
        if let errorReason {
            actionData["error_reason"] = "'\(errorReason)'"
        }
        
        if let errorCode {
            actionData["error_code"] = errorCode
        }
        
        if let orderID {
            actionData["order_id"] = orderID
        }
        
        logEvent(activeInterface: .applePay, action: .submissionError, actionData: actionData, project: project)
    }
    
    func logSettingDidSeeApplePayDonateSuccessToast() {
        logEvent(activeInterface: .setting, action: .successToastSetting)
    }
    
    func logArticleDidSeeApplePayDonateSuccessToast(project: WikimediaProject) {
        logEvent(activeInterface: .article, action: .successToastArticle, project: project)
    }
    
    func logDonateFormInAppWebViewImpression(project: WikimediaProject?) {
        logEvent(activeInterface: .webPayInitiated, action: .impression, project: project)
    }
    
    func logDonateFormInAppWebViewThankYouImpression(project: WikimediaProject?, metricsID: String?) {
        var actionData: [String: String]?
        if let metricsID {
            actionData = [:]
            actionData?["campaign_id"] = metricsID
        }
        logEvent(activeInterface: .webPayProcessed, action: .impression, actionData: actionData, project: project)
    }
    
    func logDonateFormInAppWebViewDidTapArticleReturnButton(project: WikimediaProject) {
        logEvent(activeInterface: .webPayProcessed, action: .articleReturnClick, project: project)
    }
    
    func logDonateFormInAppWebViewDidTapReturnButton() {
        logEvent(activeInterface: .webPayProcessed, action: .returnClick)
    }
}
