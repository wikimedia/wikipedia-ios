import Foundation

extension ArticleViewController {

    func showSurveyAnnouncementPanel(surveyAnnouncementResult: SurveyAnnouncementsController.SurveyAnnouncementResult, linkState: ArticleAsLivingDocSurveyLinkState) {
        let currentDate = Date()
        guard state == .loaded, let surveyEndTime = surveyAnnouncementResult.announcement.endTime, currentDate.isBefore(surveyEndTime),
              let googleFormattedArticleTitle = articleURL.wmf_title?.googleFormPercentEncodedPageTitle else {
            return
        }
        
        let didSeeModal: Bool
        let isInExperiment: Bool
        
        switch linkState {
        case .notInExperiment:
            didSeeModal = false
            isInExperiment = false
        case .inExperimentFailureLoadingEvents,
             .inExperimentLoadingEvents:
            assertionFailure("We should not be attempting to show a survey for a user that is still loading or has failed to load events.")
            return
        case .inExperimentLoadedEventsDidNotSeeModal:
            didSeeModal = false
            isInExperiment = true
        case .inExperimentLoadedEventsDidSeeModal:
            didSeeModal = true
            isInExperiment = true
        }
        
        let newActionURLString = surveyAnnouncementResult.actionURLString
            .replacingOccurrences(of: "{{articleTitle}}", with: googleFormattedArticleTitle)
            .replacingOccurrences(of: "{{didSeeModal}}", with: "\(didSeeModal)")
            .replacingOccurrences(of: "{{isInExperiment}}", with: "\(isInExperiment)")
        
        guard let actionURL = URL(string: newActionURLString) else {
            assertionFailure("Cannot show survey - failure generating actionURL.")
            return
        }
        
        var vcToPresentSurvey: UIViewController? = self
        if let presentedNavVC = presentedViewController as? UINavigationController,
           let livingDocVC = presentedNavVC.viewControllers.first as? ArticleAsLivingDocViewController {
            vcToPresentSurvey = presentedNavVC.viewControllers.count == 1 ? livingDocVC : nil
        }
        
        vcToPresentSurvey?.wmf_showAnnouncementPanel(announcement: surveyAnnouncementResult.announcement, style: .minimal, primaryButtonTapHandler: { (sender) in
            self.navigate(to: actionURL, useSafari: true)
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
