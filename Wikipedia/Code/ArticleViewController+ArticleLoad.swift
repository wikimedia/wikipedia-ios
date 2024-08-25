import WMFComponents
import WMF
import CocoaLumberjackSwift
import WMFData

// MARK: - ArticleViewController + ArticleLoad
extension ArticleViewController {
    func loadIfNecessary() {
        guard state == .initial else {
            return
        }
        load()
    }
    
    func load() {
        state = .loading
        
        setupPageContentServiceJavaScriptInterface {
            let cachePolicy: WMFCachePolicy? = self.isRestoringState ? .foundation(.returnCacheDataElseLoad) : nil
            
            let revisionID = self.altTextExperimentViewModel != nil ? self.altTextExperimentViewModel?.lastRevisionID : nil
            
            self.loadPage(cachePolicy: cachePolicy, revisionID: revisionID)
        }
    }
    
    /// Waits for the article and article summary to finish loading (or re-loading) and performs post load actions
    internal func setupArticleLoadWaitGroup() {
        assert(Thread.isMainThread)

        guard articleLoadWaitGroup == nil else {
            return
        }
        
        articleLoadWaitGroup = DispatchGroup()
        articleLoadWaitGroup?.enter() // will leave on setup complete
        articleLoadWaitGroup?.notify(queue: DispatchQueue.main) { [weak self] in
            
            guard let self = self else {
                return
            }
            
            self.articleAsLivingDocController.articleContentFinishedLoading()
            
            if altTextExperimentViewModel != nil {
                self.setupForAltTextExperiment()
            } else {
                self.setupFooter()
            }
            
            self.shareIfNecessary()
            self.restoreScrollStateIfNecessary()
            self.articleLoadWaitGroup = nil
        }
    }

    private func setupForAltTextExperiment() {

        guard let altTextExperimentViewModel,
         altTextBottomSheetViewModel != nil else {
            return
        }
        
        let oldContentInset = webView.scrollView.contentInset
        webView.scrollView.contentInset = UIEdgeInsets(top: oldContentInset.top, left: oldContentInset.left, bottom: view.bounds.height * 0.65, right: oldContentInset.right)
        messagingController.hideEditPencils()
        messagingController.scrollToNewImage(filename: altTextExperimentViewModel.filename)
        
        presentAltTextModalSheet()
    }
    
    func presentAltTextModalSheet() {
        
        guard altTextExperimentViewModel != nil,
         let altTextBottomSheetViewModel else {
            return
        }

        let bottomSheetViewController = WMFAltTextExperimentModalSheetViewController(viewModel: altTextBottomSheetViewModel, delegate: self, loggingDelegate: self)
        
        if #available(iOS 16.0, *) {
            if let sheet = bottomSheetViewController.sheetPresentationController {
                sheet.delegate = self
                let customSmallId = UISheetPresentationController.Detent.Identifier("customSmall")
                let customSmallDetent = UISheetPresentationController.Detent.custom(identifier: customSmallId) { context in
                    return 44
                }
                sheet.detents = [customSmallDetent, .medium(), .large()]
                sheet.selectedDetentIdentifier = .medium
                sheet.largestUndimmedDetentIdentifier = .medium
                sheet.prefersGrabberVisible = true
            }
            bottomSheetViewController.isModalInPresentation = true
            self.altTextBottomSheetViewController = bottomSheetViewController
            
            present(bottomSheetViewController, animated: true) { [weak self] in
                self?.presentAltTextTooltipsIfNecessary(force: false)
            }
        }
    }
    
    internal func presentAltTextTooltipsIfNecessary(force: Bool = false) {
        guard let altTextExperimentViewModel,
              let bottomSheetViewController = altTextBottomSheetViewController,
              let tooltip1SourceView = view,
              let tooltip2SourceView = bottomSheetViewController.tooltip2SourceView,
              let tooltip2SourceRect = bottomSheetViewController.tooltip2SourceRect,
              let tooltip3SourceView = bottomSheetViewController.tooltip3SourceView,
              let tooltip3SourceRect = bottomSheetViewController.tooltip3SourceRect,
        let dataController = WMFAltTextDataController.shared else {
            return
        }

        if !force && dataController.hasPresentedOnboardingTooltips {
            return
        }
        
        let tooltip1SourceRect = CGRect(x: 30, y: navigationBar.frame.height + 30, width: 0, height: 0)

        let viewModel1 = WMFTooltipViewModel(localizedStrings: altTextExperimentViewModel.firstTooltipLocalizedStrings, buttonNeedsDisclosure: true, sourceView: tooltip1SourceView, sourceRect: tooltip1SourceRect, permittedArrowDirections: .up) { [weak self] in
            
            if let siteURL = self?.articleURL.wmf_site,
               let project = WikimediaProject(siteURL: siteURL) {
                EditInteractionFunnel.shared.logAltTextOnboardingDidTapNextOnFirstTooltip(project: project)
            }
        }

        
        let viewModel2 = WMFTooltipViewModel(localizedStrings: altTextExperimentViewModel.secondTooltipLocalizedStrings, buttonNeedsDisclosure: true, sourceView: tooltip2SourceView, sourceRect: tooltip2SourceRect, permittedArrowDirections: .down)

        let viewModel3 = WMFTooltipViewModel(localizedStrings: altTextExperimentViewModel.thirdTooltipLocalizedStrings, buttonNeedsDisclosure: false, sourceView: tooltip3SourceView, sourceRect: tooltip3SourceRect, permittedArrowDirections: .down) { [weak self] in
            
            if let siteURL = self?.articleURL.wmf_site,
               let project = WikimediaProject(siteURL: siteURL) {
                EditInteractionFunnel.shared.logAltTextOnboardingDidTapDoneOnLastTooltip(project: project)
            }
            
        }

        bottomSheetViewController.displayTooltips(tooltipViewModels: [viewModel1, viewModel2, viewModel3])

        if !force {
            dataController.hasPresentedOnboardingTooltips = true
        }
    }
    
    internal func loadSummary(oldState: ViewState) {
        guard let key = article.inMemoryKey else {
            return
        }
        
        var oldFeedPreview: WMFFeedArticlePreview?
        if isWidgetCachedFeaturedArticle {
            oldFeedPreview = article.feedArticlePreview()
        }
        
        articleLoadWaitGroup?.enter()
        let cachePolicy: URLRequest.CachePolicy? = oldState == .reloading ? .reloadRevalidatingCacheData : nil
        
        self.dataStore.articleSummaryController.updateOrCreateArticleSummaryForArticle(withKey: key, cachePolicy: cachePolicy) { (article, error) in
            defer {
                self.articleLoadWaitGroup?.leave()
                self.updateMenuItems()
            }
            guard let article = article else {
                return
            }
            self.article = article
            
            if let oldFeedPreview,
               let newFeedPreview = article.feedArticlePreview(),
            oldFeedPreview != newFeedPreview {
                SharedContainerCacheClearFeaturedArticleWrapper.clearOutFeaturedArticleWidgetCache()
                WidgetController.shared.reloadFeaturedArticleWidgetIfNecessary()
            }
            
            // Handle redirects
            guard let newKey = article.inMemoryKey, newKey != key, let newURL = article.url else {
                return
            }
            self.articleURL = newURL
            self.addToHistory()
        }
    }
    
    func loadPage(cachePolicy: WMFCachePolicy? = nil, revisionID: UInt64? = nil) {
        defer {
            callLoadCompletionIfNecessary()
        }
        
        guard var request = try? fetcher.mobileHTMLRequest(articleURL: articleURL, revisionID: revisionID, scheme: schemeHandler.scheme, cachePolicy: cachePolicy, isPageView: true) else {
            showGenericError()
            state = .error
            return
        }

        // Add the URL fragment to request, if the fragment exists
        if let articleFragment = URLComponents(url: articleURL, resolvingAgainstBaseURL: true)?.fragment,
           let url = request.url,
           var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            urlComponents.fragment = articleFragment
            request.url = urlComponents.url
        }
        
        articleAsLivingDocController.articleContentWillBeginLoading(traitCollection: traitCollection, theme: theme)

        webView.load(request)
    }
    
    func syncCachedResourcesIfNeeded() {
        guard let groupKey = articleURL.wmf_databaseKey else {
            return
        }
        
        fetcher.isCached(articleURL: articleURL) { [weak self] (isCached) in
            
            guard let self = self,
                isCached else {
                    return
            }
            
            self.cacheController.syncCachedResources(url: self.articleURL, groupKey: groupKey) { (result) in
                switch result {
                case .success(let itemKeys):
                    DDLogDebug("successfully synced \(itemKeys.count) resources")
                case .failure(let error):
                    DDLogError("failed to synced resources for \(groupKey): \(error)")
                }
            }
        }
    }
}
