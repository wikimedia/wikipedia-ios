
import Foundation

extension ArticleViewController {
    
    func startSurveyAnnouncementTimer() {
        
        guard let surveyAnnouncementResult = surveyAnnouncementResult else {
            return
        }
        
        surveyAnnouncementTimer = Timer.scheduledTimer(withTimeInterval: surveyAnnouncementResult.displayDelay, repeats: false, block: { [weak self] (timer) in
            
            guard let self = self else {
                return
            }
            
            self.showSurveyAnnouncementPanel(surveyAnnouncementResult: surveyAnnouncementResult)
            
            self.stopSurveyAnnouncementTimer()
        })
    }
    
    private func showSurveyAnnouncementPanel(surveyAnnouncementResult: SurveyAnnouncementsController.SurveyAnnouncementResult) {
        
        guard state == .loaded else {
            return
        }
        
        wmf_showAnnouncementPanel(announcement: surveyAnnouncementResult.announcement, primaryButtonTapHandler: { (sender) in
            self.navigate(to: surveyAnnouncementResult.actionURL, useSafari: true)
            SurveyAnnouncementsController.shared.markSurveyAnnouncementAnswer(true, campaignIdentifier: surveyAnnouncementResult.campaignIdentifier)
            // dismiss handler is called
        }, secondaryButtonTapHandler: { (sender) in
            // dismiss handler is called
            SurveyAnnouncementsController.shared.markSurveyAnnouncementAnswer(false, campaignIdentifier: surveyAnnouncementResult.campaignIdentifier)
        }, footerLinkAction: { (url) in
             self.navigate(to: url, useSafari: true)
            // intentionally don't dismiss
        }, dismissHandler: {
            //no-op
        }, theme: self.theme)
    }
    
    func stopSurveyAnnouncementTimer() {
        surveyAnnouncementTimer?.invalidate()
        surveyAnnouncementTimer = nil
    }
}
