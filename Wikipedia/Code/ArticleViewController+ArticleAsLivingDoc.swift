import WMFComponents
import WMF
import CocoaLumberjackSwift
import WMFData

// MARK: Article As Living Doc Protocols
extension ArticleViewController: ArticleAsLivingDocViewControllerDelegate {
    func livingDocViewWillPush() {
        surveyTimerController?.livingDocViewWillPush(withState: state)
    }
    
    func livingDocViewWillAppear() {
        surveyTimerController?.livingDocViewWillAppear(withState: state)
    }
    
    var articleAsLivingDocViewModel: ArticleAsLivingDocViewModel? {
        return articleAsLivingDocController.articleAsLivingDocViewModel
    }
    
    func fetchNextPage(nextRvStartId: UInt, theme: Theme) {
        articleAsLivingDocController.fetchNextPage(nextRvStartId: nextRvStartId, traitCollection: traitCollection, theme: theme)
    }

    var isFetchingAdditionalPages: Bool {
        return articleAsLivingDocController.isFetchingAdditionalPages
    }
}

extension ArticleViewController: ArticleAsLivingDocControllerDelegate {
    var abTestsController: ABTestsController {
        return dataStore.abTestsController
    }
    
    var isInValidSurveyCampaignAndArticleList: Bool {
        surveyAnnouncementResult != nil
    }
    
    func extendTimerForPresentingModal() {
        surveyTimerController?.extendTimer()
    }
}

extension ArticleViewController: ArticleSurveyTimerControllerDelegate {
    var displayDelay: TimeInterval? {
        surveyAnnouncementResult?.displayDelay
    }
    
    var shouldAttemptToShowArticleAsLivingDoc: Bool {
        return articleAsLivingDocController.shouldAttemptToShowArticleAsLivingDoc
    }
    
    var userHasSeenSurveyPrompt: Bool {
        
        guard let identifier = surveyAnnouncementResult?.campaignIdentifier else {
            return false
        }
        
        return SurveyAnnouncementsController.shared.userHasSeenSurveyPrompt(forCampaignIdentifier: identifier)
    }
    
    var shouldShowArticleAsLivingDoc: Bool {
        return articleAsLivingDocController.shouldShowArticleAsLivingDoc
    }
    
    var livingDocSurveyLinkState: ArticleAsLivingDocSurveyLinkState {
        return articleAsLivingDocController.surveyLinkState
    }
    
    
}

extension ArticleViewController: UISheetPresentationControllerDelegate {
    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheetPresentationController: UISheetPresentationController) {
        
        guard altTextExperimentViewModel != nil else {
            return
        }
        
        let oldContentInset = webView.scrollView.contentInset
        
        if let selectedDetentIdentifier = sheetPresentationController.selectedDetentIdentifier {
            switch selectedDetentIdentifier {
            case .medium, .large:
                webView.scrollView.contentInset = UIEdgeInsets(top: oldContentInset.top, left: oldContentInset.left, bottom: view.bounds.height * 0.65, right: oldContentInset.right)
            default:
                logMinimized()
                webView.scrollView.contentInset = UIEdgeInsets(top: oldContentInset.top, left: oldContentInset.left, bottom: 75, right: oldContentInset.right)
            }
        }
    }
    
    private func logMinimized() {
        if let project = project {
            EditInteractionFunnel.shared.logAltTextInputDidMinimize(project: project)
        }
    }
}

extension ArticleViewController: WMFAltTextExperimentModalSheetLoggingDelegate {

    func didTriggerCharacterWarning() {
        if let project = project {
            EditInteractionFunnel.shared.logAltTextInputDidTriggerWarning(project: project)
        }
    }
    
    func didTapFileName() {
        if let project = project {
            EditInteractionFunnel.shared.logAltTextInputDidTapFileName(project: project)
        }
    }
    
    func didAppear() {
        if let project = project {
            EditInteractionFunnel.shared.logAltTextInputDidAppear(project: project)
        }
    }
    
    func didFocusTextView() {
        if let project = project {
            EditInteractionFunnel.shared.logAltTextInputDidFocus(project: project)
        }
    }
}

