import WMFComponents
import WMF
import CocoaLumberjackSwift
import WMFData

// MARK: - ArticleViewController + Loading
extension ArticleViewController {
    override func viewDidLoad() {
        setup()
        super.viewDidLoad()
        
        if altTextExperimentViewModel == nil {
            setupToolbar() // setup toolbar needs to be after super.viewDidLoad because the superview owns the toolbar
        }
        
        loadWatchStatusAndUpdateToolbar()
        setupForStateRestorationIfNecessary()
        surveyTimerController?.timerFireBlock = { [weak self] in
            guard let self = self,
                  let result = self.surveyAnnouncementResult else {
                return
            }
            
            self.showSurveyAnnouncementPanel(surveyAnnouncementResult: result, linkState: self.articleAsLivingDocController.surveyLinkState)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: false)
        super.viewWillAppear(animated)
        tableOfContentsController.setup(with: traitCollection)
        toolbarController.update()
        loadIfNecessary()
        startSignificantlyViewedTimer()
        surveyTimerController?.viewWillAppear(withState: state)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        /// When jumping back to an article via long pressing back button (on iOS 14 or above), W button disappears. Couldn't find cause. It disappears between `viewWillAppear` and `viewDidAppear`, as setting this on the `viewWillAppear`doesn't fix the problem. If we can find source of this bad behavior, we can remove this next line.
        
        if altTextExperimentViewModel == nil {
            setupWButton()
        }

        if isReturningFromFAQ {
            isReturningFromFAQ = false
            needsAltTextExperimentSheet = true
            presentAltTextModalSheet()
        }

        if didTapPreview {
            presentAltTextModalSheet()
            didTapPreview = false
        }
        
        if didTapAltTextFileName {
            presentAltTextModalSheet()
            didTapAltTextFileName = false
        }
        
        if didTapAltTextGalleryInfoButton {
            presentAltTextModalSheet()
            didTapAltTextGalleryInfoButton = false
        }

        guard isFirstAppearance else {
            return
        }
        showAnnouncementIfNeeded()
        isFirstAppearance = false
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        tableOfContentsController.update(with: traitCollection)
        toolbarController.update()
    }
    
    override func wmf_removePeekableChildViewControllers() {
        super.wmf_removePeekableChildViewControllers()
        addToHistory()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cancelWIconPopoverDisplay()
        saveArticleScrollPosition()
        stopSignificantlyViewedTimer()
        surveyTimerController?.viewWillDisappear(withState: state)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if altTextExperimentViewModel != nil {
            return .portrait
        }
        
        return super.supportedInterfaceOrientations
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        if altTextExperimentViewModel != nil {
            return .portrait
        }
        
        return super.preferredInterfaceOrientationForPresentation
    }
}

