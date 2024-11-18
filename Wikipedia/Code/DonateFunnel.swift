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
        case articleProfile = "article_profile"
        case exploreProfile = "explore_profile"
        case exploreOptOut = "explore_optout_profile"
        case wikiYiR = "wiki_yir"
    }
    
    private enum Action: String {
        case settingClick = "setting_click"
        case donateStartClick = "donate_start_click"
        case impression = "impression"
        case impressionSuppressed = "impression_suppressed_user_pref"
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
        case successToastProfile = "success_toast_profile"
        case articleReturnClick = "article_return_click"
        case returnClick = "return_click"
        case profileClick = "profile_click"
        case startClick = "start_click"
        case learnClick = "learn_click"
        case nextClick = "next_click"
        case continueClick = "continue_click"
        case donateStartClickYir = "donate_start_click_yir"
        case accountEngageClick = "account_engage_click"
        case rejectClick = "reject_click"
        case shareClick = "share_click"
        case feedbackSubmitClick = "feedback_submit_click"
        case feedbackSubmitted = "feedback_submitted"
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
    
    func logFundraisingCampaignModalImpression(project: WikimediaProject, metricsID: String) {
        logEvent(activeInterface: .articleBanner, action: .impression, actionData: ["campaign_id": metricsID], project: project)
    }
    
    func logFundraisingCampaignModalDidTapClose(project: WikimediaProject, metricsID: String) {
        logEvent(activeInterface: .articleBanner, action: .closeClick, actionData: ["campaign_id": metricsID], project: project)
    }
    
    func logFundraisingCampaignModalDidTapDonate(project: WikimediaProject, metricsID: String) {
        logEvent(activeInterface: .articleBanner, action: .donateClick, actionData: ["campaign_id": metricsID], project: project)
    }
    
    func logFundraisingCampaignModalDidTapMaybeLater(project: WikimediaProject, metricsID: String) {
        logEvent(activeInterface: .articleBanner, action: .laterClick, actionData: ["campaign_id": metricsID], project: project)
    }
    
    func logFundraisingCampaignModalDidTapAlreadyDonated(project: WikimediaProject, metricsID: String) {
        logEvent(activeInterface: .articleBanner, action: .alreadyDonatedClick, actionData: ["campaign_id": metricsID], project: project)
    }
    
    func logFundraisingCampaignModalDidTapDonorPolicy(project: WikimediaProject, metricsID: String) {
        logEvent(activeInterface: .articleBanner, action: .donorPolicyClick, actionData: ["campaign_id": metricsID], project: project)
    }
    
    func logArticleDidSeeReminderToast(project: WikimediaProject, metricsID: String) {
        logEvent(activeInterface: .article, action: .reminderToast, actionData: ["campaign_id": metricsID], project: project)
    }
    
    func logArticleDidTapDonateWithApplePay(project: WikimediaProject, metricsID: String) {
        logEvent(activeInterface: .articleBanner, action: .applePayClick, actionData: ["campaign_id": metricsID], project: project)
    }
    
    func logArticleDidTapOtherPaymentMethod(project: WikimediaProject, metricsID: String) {
        logEvent(activeInterface: .articleBanner, action: .webPayClick, actionData: ["campaign_id": metricsID], project: project)
    }
    
    func logArticleDidTapCancel(project: WikimediaProject, metricsID: String) {
        logEvent(activeInterface: .articleBanner, action: .cancelClick, actionData: ["campaign_id": metricsID], project: project)
    }
    
    func logDonateFormNativeApplePayImpression(project: WikimediaProject?, metricsID: String) {
        logEvent(activeInterface: .applePayInitiated, action: .impression, actionData: ["campaign_id": metricsID], project: project)
    }
    
    func logDonateFormNativeApplePayEntryError(project: WikimediaProject?, metricsID: String) {
        logEvent(activeInterface: .applePay, action: .entryError, actionData: ["campaign_id": metricsID], project: project)
    }
    
    func logDonateFormNativeApplePayDidTapAmountPresetButton(project: WikimediaProject?, metricsID: String) {
        logEvent(activeInterface: .applePay, action: .amountSelected, actionData: ["campaign_id": metricsID], project: project)
    }
    
    func logDonateFormNativeApplePayDidEnterAmountInTextfield(project: WikimediaProject?, metricsID: String) {
        logEvent(activeInterface: .applePay, action: .amountEntered, actionData: ["campaign_id": metricsID], project: project)
    }
    
    func logDonateFormNativeApplePayDidTapApplePayButton(transactionFeeIsSelected: Bool, recurringMonthlyIsSelected: Bool, emailOptInIsSelected: Bool?, project: WikimediaProject?, metricsID: String) {
        var actionData = ["add_transaction": String(transactionFeeIsSelected),
                          "recurring": String(recurringMonthlyIsSelected),
                          "campaign_id": metricsID]
        
        if let emailOptInIsSelected {
            actionData["email_subscribe"] = String(emailOptInIsSelected)
        }
        
        logEvent(activeInterface: .applePay, action: .donateConfirmClick, actionData: actionData, project: project)
    }
    
    func logDonateFormNativeApplePayDidTapProblemsDonatingLink(project: WikimediaProject?, metricsID: String) {
        logEvent(activeInterface: .applePay, action: .reportProblemClick, actionData: ["campaign_id": metricsID], project: project)
    }
    
    func logDonateFormNativeApplePayDidTapOtherWaysToGiveLink(project: WikimediaProject?, metricsID: String) {
        logEvent(activeInterface: .applePay, action: .otherGiveClick, actionData: ["campaign_id": metricsID], project: project)
    }
    
    func logDonateFormNativeApplePayDidTapFAQLink(project: WikimediaProject?, metricsID: String) {
        logEvent(activeInterface: .applePay, action: .faqClick, actionData: ["campaign_id": metricsID], project: project)
    }
    
    func logDonateFormNativeApplePayDidTapTaxInfoLink(project: WikimediaProject?, metricsID: String) {
        logEvent(activeInterface: .applePay, action: .taxInfoClick, actionData: ["campaign_id": metricsID], project: project)
    }
    
    func logDonateFormNativeApplePayDidAuthorizeApplePay(amount: Decimal, presetIsSelected: Bool, recurringMonthlyIsSelected: Bool, metricsID: String, donorEmail: String?, project: WikimediaProject?) {
        var actionData = ["preset_selected": String(presetIsSelected),
                          "donation_amount": (amount as NSNumber).stringValue,
                          "recurring": String(recurringMonthlyIsSelected),
                          "pay_method": "applepay",
                          "campaign_id": metricsID]

        if let donorEmail {
            actionData["email"] = donorEmail
        }
        
        logEvent(activeInterface: .applePayProcessed, action: .applePayUIConfirm, actionData: actionData, project: project)
    }
    
    func logDonateFormNativeApplePaySubmissionError(errorReason: String?, errorCode: String?, orderID: String?, project: WikimediaProject?, metricsID: String) {
        var actionData: [String: String] = ["campaign_id": metricsID]
        
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
    
    func logArticleCampaignDidSeeApplePayDonateSuccessToast(project: WikimediaProject, metricsID: String) {
        logEvent(activeInterface: .article, action: .successToastArticle, actionData: ["campaign_id": metricsID], project: project)
    }
    
    func logArticleProfileDidSeeApplePayDonateSuccessToast(project: WikimediaProject, metricsID: String) {
        logEvent(activeInterface: .articleProfile, action: .successToastProfile, actionData: ["campaign_id": metricsID], project: project)
    }
    
    func logExploreProfileDidSeeApplePayDonateSuccessToast(metricsID: String) {
        logEvent(activeInterface: .exploreProfile, action: .successToastProfile, actionData: ["campaign_id": metricsID])
    }
    
    func logExploreOptOutProfileDidSeeApplePayDonateSuccessToast(metricsID: String) {
        logEvent(activeInterface: .exploreOptOut, action: .successToastProfile, actionData: ["campaign_id": metricsID])
    }
    
    func logDonateFormInAppWebViewImpression(project: WikimediaProject?, metricsID: String) {
        logEvent(activeInterface: .webPayInitiated, action: .impression, actionData: ["campaign_id": metricsID], project: project)
    }
    
    func logDonateFormInAppWebViewThankYouImpression(project: WikimediaProject?, metricsID: String) {
        logEvent(activeInterface: .webPayProcessed, action: .impression, actionData: ["campaign_id": metricsID], project: project)
    }
    
    func logDonateFormInAppWebViewDidTapArticleReturnButton(project: WikimediaProject, metricsID: String) {
        logEvent(activeInterface: .webPayProcessed, action: .articleReturnClick, actionData: ["campaign_id": metricsID], project: project)
    }
    
    func logDonateFormInAppWebViewDidTapReturnButton(metricsID: String) {
        logEvent(activeInterface: .webPayProcessed, action: .returnClick, actionData: ["campaign_id": metricsID])
    }

    func logHiddenBanner(project: WikimediaProject, metricsID: String) {
        logEvent(activeInterface: .articleBanner, action: .impressionSuppressed, actionData: ["campaign_id": metricsID])
    }
    
    func logArticleProfile(project: WikimediaProject, metricsID: String) {
        logEvent(activeInterface: .articleProfile, action: .profileClick, actionData: ["campaign_id": metricsID], project: project)
    }
    
    func logArticleProfileDonate(project: WikimediaProject, metricsID: String) {
        logEvent(activeInterface: .articleProfile, action: .donateStartClick, actionData: ["campaign_id": metricsID], project: project)
    }
    
    func logExploreProfile(metricsID: String) {
        logEvent(activeInterface: .exploreProfile, action: .profileClick, actionData: ["campaign_id": metricsID])
    }
    
    func logExploreProfileDonate(metricsID: String) {
        logEvent(activeInterface: .exploreProfile, action: .donateStartClick, actionData: ["campaign_id": metricsID])
    }
    
    func logOptOutExploreProfileDonate(metricsID: String) {
        logEvent(activeInterface: .exploreOptOut, action: .donateStartClick, actionData: ["campaign_id": metricsID])
    }
    
    func logArticleProfileDonateCancel(project: WikimediaProject, metricsID: String) {
        logEvent(activeInterface: .articleProfile, action: .cancelClick, actionData: ["campaign_id": metricsID], project: project)
    }
    
    func logExploreProfileDonateCancel(metricsID: String) {
        logEvent(activeInterface: .exploreProfile, action: .cancelClick, actionData: ["campaign_id": metricsID])
    }
    
    func logExploreOptOutProfileDonateCancel(metricsID: String) {
        logEvent(activeInterface: .exploreOptOut, action: .cancelClick, actionData: ["campaign_id": metricsID])
    }
    
    func logExploreProfileDonateApplePay(metricsID: String) {
        logEvent(activeInterface: .exploreProfile, action: .applePayClick, actionData: ["campaign_id": metricsID])
    }
    
    func logArticleProfileDonateApplePay(project: WikimediaProject, metricsID: String) {
        logEvent(activeInterface: .articleProfile, action: .applePayClick, actionData: ["campaign_id": metricsID], project: project)
    }

    func logExploreOptOutProfileDonateApplePay(metricsID: String) {
        logEvent(activeInterface: .exploreOptOut, action: .applePayClick, actionData: ["campaign_id": metricsID])
    }
    
    func logExploreProfileDonateWebPay(metricsID: String) {
        logEvent(activeInterface: .exploreProfile, action: .webPayClick, actionData: ["campaign_id": metricsID])
    }
    
    func logArticleProfileDonateWebPay(project: WikimediaProject, metricsID: String) {
        logEvent(activeInterface: .articleProfile, action: .webPayClick, actionData: ["campaign_id": metricsID], project: project)
    }
    
    func logExploreOptOutProfileDonateWebPay(metricsID: String) {
        logEvent(activeInterface: .exploreOptOut, action: .applePayClick, actionData: ["campaign_id": metricsID])
    }
    
    @objc func logExploreOptOutProfileClick(metricsID: String) {
        logEvent(activeInterface: .exploreOptOut, action: . profileClick, actionData: ["campaign_id": metricsID])
    }
    
    // MARK: - Year In Review
    
    func logProfileDidTapYearInReview() {
        logEvent(activeInterface: .wikiYiR, action: .startClick, actionData: ["slide": "entry_b_profile"])
    }
    
    func logYearInReviewSlideImpression(slideLoggingID: String) {
        logEvent(activeInterface: .wikiYiR, action: .impression, actionData: ["slide": slideLoggingID])
    }
    
    func logYearInReviewDidTapDone(slideLoggingID: String) {
        logEvent(activeInterface: .wikiYiR, action: .closeClick, actionData: ["slide": slideLoggingID])
    }
    
    func logYearInReviewDidTapIntroContinue() {
        logEvent(activeInterface: .wikiYiR, action: .startClick, actionData: ["slide": "start"])
    }
    
    func logYearInReviewDidTapIntroLearnMore() {
        logEvent(activeInterface: .wikiYiR, action: .learnClick, actionData: ["slide": "start"])
    }
    
    func logYearInReviewDidTapNext(slideLoggingID: String) {
        logEvent(activeInterface: .wikiYiR, action: .nextClick, actionData: ["slide": slideLoggingID])
    }
    
    func logYearInReviewFeatureAnnouncementDidAppear() {
        logEvent(activeInterface: .wikiYiR, action: .impression, actionData: ["slide": "entry_a"])
    }
    
    func logYearInReviewFeatureAnnouncementDidTapContinue() {
        logEvent(activeInterface: .wikiYiR, action: .continueClick, actionData: ["slide": "entry_a"])
    }
    
    func logYearInReviewFeatureAnnouncementDidTapClose() {
        logEvent(activeInterface: .wikiYiR, action: .closeClick, actionData: ["slide": "entry_a"])
    }
    
    func logYearInReviewDidTapDonate(slideLoggingID: String, metricsID: String) {
        logEvent(activeInterface: .wikiYiR, action: .donateStartClickYir, actionData: [
            "slide": slideLoggingID,
            "campaign_id": metricsID])
    }

    func logYearInReviewLoginPromptDidAppear() {
        logEvent(activeInterface: .wikiYiR, action: .impression, actionData: ["slide": "new_account_engage"])
    }
    
    func logYearInReviewLoginPromptDidTapLogin() {
        logEvent(activeInterface: .wikiYiR, action: .accountEngageClick, actionData: ["slide": "new_account_engage"])
    }
    
    func logYearInReviewLoginPromptDidTapNoThanks() {
        logEvent(activeInterface: .wikiYiR, action: .rejectClick, actionData: ["slide": "new_account_engage"])
    }
    
    func logYearInReviewDidTapShare(slideLoggingID: String) {
        logEvent(activeInterface: .wikiYiR, action: .shareClick, actionData: ["slide": slideLoggingID])
    }
    
    func logYearInReviewSurveyDidAppear() {
        logEvent(activeInterface: .wikiYiR, action: .impression, actionData: ["slide": "feedback_choice"])
    }
    
    func logYearInReviewSurveyDidTapCancel() {
        logEvent(activeInterface: .wikiYiR, action: .closeClick, actionData: ["slide": "feedback_choice"])
    }
    
    func logYearInReviewSurveyDidSubmit(selected: [String], other: String?) {
        
        // strip "other", join by comma
        let selectedJoined = selected.filter { $0 != "other" }.joined(separator: ",")
        
        var actionData: [String: String] = [
            "slide": "feedback_choice",
            "feedback_select": selectedJoined
        ]

        if let other, !other.isEmpty {
            actionData["feedback_text"] = other
        }
        
        logEvent(activeInterface: .wikiYiR, action: .feedbackSubmitClick, actionData: actionData)
    }
    
    func logYearinReviewSurveySubmitSuccessToast() {
        logEvent(activeInterface: .wikiYiR, action: .feedbackSubmitted)
    }
    
    func logYearInReviewDonateSlideDidTapLearnMoreLink(slideLoggingID: String) {
        logEvent(activeInterface: .wikiYiR, action: .learnClick, actionData: ["slide": slideLoggingID])
    }
    
    func logYearInReviewDonateSlideLearnMoreWebViewDidAppear(slideLoggingID: String) {
        logEvent(activeInterface: .wikiYiR, action: .impression, actionData: ["slide": slideLoggingID])
    }
    
    func logYearInReviewDonateSlideLearnMoreWebViewDidTapDonateButton(metricsID: String) {
        logEvent(activeInterface: .wikiYiR, action: .donateStartClickYir, actionData: ["slide": "about_wikimedia",
                                                                                       "campaign_id": metricsID])
    }
    
    // Year in Review Donate flow events
    
    func logYearInReviewDidTapDonateCancel(metricsID: String) {
        logEvent(activeInterface: .wikiYiR, action: .cancelClick, actionData: ["campaign_id": metricsID])
    }
    
    func logYearInReviewDidTapDonateApplePay(metricsID: String) {
        logEvent(activeInterface: .wikiYiR, action: .applePayClick, actionData: ["campaign_id": metricsID])
    }
    
    func logYearInReviewDidTapDonateOtherPaymentMethod(metricsID: String) {
        logEvent(activeInterface: .wikiYiR, action: .webPayClick, actionData: ["campaign_id": metricsID])
    }
    
    func logYearInReviewDidSeeApplePayDonateSuccessToast(metricsID: String) {
        logEvent(activeInterface: .wikiYiR, action: .successToastProfile, actionData: ["campaign_id": metricsID])
    }
}
