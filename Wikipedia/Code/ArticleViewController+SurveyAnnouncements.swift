import Foundation

extension ArticleViewController {

    func showSurveyAnnouncementPanel(surveyAnnouncementResult: SurveyAnnouncementsController.SurveyAnnouncementResult) {
        
        guard state == .loaded else {
            return
        }
        
        wmf_showAnnouncementPanel(announcement: surveyAnnouncementResult.announcement, style: .minimal, primaryButtonTapHandler: { (sender) in
            self.navigate(to: surveyAnnouncementResult.actionURL, useSafari: true)
            // dismiss handler is called
        }, secondaryButtonTapHandler: { (sender) in
            // dismiss handler is called
        }, footerLinkAction: { (url) in
             self.navigate(to: url, useSafari: true)
            // intentionally don't dismiss
        }, traceableDismissHandler: { lastAction in
            switch lastAction {
            case .tappedBackground, .tappedClose, .tappedSecondary:
                SurveyAnnouncementsController.shared.markSurveyAnnouncementAnswer(false, campaignIdentifier: surveyAnnouncementResult.campaignIdentifier)
            case .tappedPrimary:
                SurveyAnnouncementsController.shared.markSurveyAnnouncementAnswer(true, campaignIdentifier: surveyAnnouncementResult.campaignIdentifier)
            case .none:
                assertionFailure("Unexpected lastAction in Panel dismissHandler")
                break
            }
        }, theme: self.theme)
    }

}
