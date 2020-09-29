
import Foundation

extension ArticleViewController {
    var articleAsLivingDocViewModel: ArticleAsLivingDocViewModel? {
        get {
            return _articleAsLivingDocViewModel
        }
        set {
            if #available(iOS 13.0, *) {
                guard let newValue = newValue else {
                    //should only occur when resetting to nil shortly before a pull to refresh was triggered.
                    _articleAsLivingDocViewModel = nil
                    return
                }
                
                if let oldModel = _articleAsLivingDocViewModel {
                    // should only be triggered via paging.
                    // update everything except sha and htmlInsert and
                    // append sections instead of replace sections
                    let appendedSections = oldModel.sections + newValue.sections
                    let oldHtmlSnippets = oldModel.articleInsertHtmlSnippets
                    let oldNewChangesTimestamp = oldModel.newChangesTimestamp
                    let oldLastUpdatedTimestamp = oldModel.lastUpdatedTimestamp
                    _articleAsLivingDocViewModel = ArticleAsLivingDocViewModel(nextRvStartId: newValue.nextRvStartId, sha: oldModel.sha, sections: appendedSections, summaryText: newValue.summaryText, articleInsertHtmlSnippets: oldHtmlSnippets, newChangesTimestamp: oldNewChangesTimestamp, lastUpdatedTimestamp: oldLastUpdatedTimestamp)
                    articleAsLivingDocViewController?.appendSections(newValue.sections)
                    
                } else {
                    // should only be triggered via pull to refresh or fresh load. update everything
                    _articleAsLivingDocViewModel = newValue
                    //note, we aren't updating data source in VC here. So far we won't reach this situation where a refresh
                    //is triggered while the events modal is still on screen, so not needed at this point.
                }
            }
        }
    }
    
    var shouldAttemptToShowArticleAsLivingDoc: Bool {
        
        //todo: need A/B test logic (falls in test and visiting article in allowed list)
        let isDeviceRTL = view.effectiveUserInterfaceLayoutDirection == .rightToLeft
        let isENWikipediaArticle: Bool
        if let host = articleURL.host,
           host == Configuration.Domain.englishWikipedia {
            isENWikipediaArticle = true
        } else {
            isENWikipediaArticle = false
        }
        
        let shouldAttemptToShowArticleAsLivingDoc: Bool
        if let _ = articleTitleAndSiteURL(),
           !isDeviceRTL && isENWikipediaArticle {
            shouldAttemptToShowArticleAsLivingDoc = true
        } else {
            shouldAttemptToShowArticleAsLivingDoc = false
        }
        
        return shouldAttemptToShowArticleAsLivingDoc
    }
    
    var shouldShowArticleAsLivingDoc: Bool {
        if let articleAsLivingDocViewModel = articleAsLivingDocViewModel,
           articleAsLivingDocViewModel.sections.count > 0,
           shouldAttemptToShowArticleAsLivingDoc {
            return true
        }
        
        return false
    }
    
    func scheduleInjectArticleAsLivingDocSkeleton() {
        
        guard shouldAttemptToShowArticleAsLivingDoc,
              articleAsLivingDocViewModel == nil else {
            return
        }
        perform(#selector(injectArticleAsLivingDocSkeletonIfNeeded), with: nil, afterDelay: 0.5)
    }
    
    @objc func injectArticleAsLivingDocSkeletonIfNeeded() {
        guard shouldAttemptToShowArticleAsLivingDoc,
              articleAsLivingDocViewModel == nil else {
            return
        }
        
        injectingSkeleton = true
        messagingController.injectSkeletonArticleAsLivingDocContent { [weak self] (success) in
            
            guard let self = self else {
                return
            }
            
            let completion = {
                self.injectingSkeleton = false
                self.toggleContentVisibilityExceptLeadImage(shouldHide: false)
                if self.articleAsLivingDocViewModel != nil {
                    self.injectArticleAsALivingDocument {
                        //nothing for now
                    }
                }
            }
            
            if (success) {
                self.updateArticleMargins(completion: completion)
            } else {
                completion()
            }
        }
    }
    
    func fetchInitialArticleAsLivingDoc() {
        
        // triggered via initial load or pull to refresh
        
        guard let articleTitleAndSiteURL = self.articleTitleAndSiteURL(),
              shouldAttemptToShowArticleAsLivingDoc else {
            return
        }
        
        articleAsLivingDocController.fetchArticleAsLivingDocViewModel(rvStartId: nil, title: articleTitleAndSiteURL.title, siteURL: articleTitleAndSiteURL.siteURL) { (result) in
            defer {
                self.configureForArticleAsLivingDocResult()
            }
            switch result {
            case .success(let articleAsLivingDocViewModel):
                self.articleAsLivingDocViewModel = articleAsLivingDocViewModel
            case .failure(let error):
                DDLogDebug("Failure getting article as living doc view models: \(error)")
            }
        }
        
        //tonitodo: might want to consider dispatch group here, to confirm edit metrics are there before view configuration occurs
        articleAsLivingDocController.fetchEditMetrics(for: articleTitleAndSiteURL.title, pageURL: articleURL) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else {
                    return
                }
                switch result {
                case .failure(let error):
                    self.articleAsLivingDocEditMetrics = nil
                    DDLogDebug("Error fetching edit metrics for article as a living document: \(error)")
                case .success(let timeseriesOfEditCounts):
                    self.articleAsLivingDocEditMetrics = timeseriesOfEditCounts
                }
            }
        }
    }
    
    func configureForArticleAsLivingDocResult() {
        
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(injectArticleAsLivingDocSkeletonIfNeeded), object: nil)
        
        guard !injectingSkeleton else {
            return
        }
        
        injectArticleAsALivingDocument {
            self.toggleContentVisibilityExceptLeadImage(shouldHide: false)
        }
    }
    
    func injectArticleAsALivingDocument(completion: @escaping () -> Void) {
        if let viewModel = articleAsLivingDocViewModel,
           shouldShowArticleAsLivingDoc {
            let htmlSnippets = viewModel.articleInsertHtmlSnippets
            let shaKey = "significant-events-sha"
            let shouldShowNewChangesBadge = viewModel.sha != nil ? UserDefaults.standard.string(forKey: shaKey) != viewModel.sha : false
            let topBadgeType: ArticleWebMessagingController.TopBadgeType = shouldShowNewChangesBadge ? .newChanges : .lastUpdated
            let timestamp = shouldShowNewChangesBadge ? viewModel.newChangesTimestamp : viewModel.lastUpdatedTimestamp
            
            self.messagingController.injectArticleAsLivingDocContent(articleInsertHtmlSnippets: htmlSnippets, topBadgeType: topBadgeType, timestamp: timestamp) { (success) in
                UserDefaults.standard.setValue(viewModel.sha, forKey: shaKey)
                
                if (success) {
                    self.updateArticleMargins(completion: completion)
                } else {
                    completion()
                }
            }
        } else if self.shouldAttemptToShowArticleAsLivingDoc {
            self.toggleContentVisibilityExceptLeadImage(shouldHide: false)
        }
    }
    
    func presentArticleAsLivingDoc(scrollToInitialIndexPath initialIndexPath: IndexPath? = nil) {
        if #available(iOS 13.0, *) {
            if let _ = articleAsLivingDocViewModel {
                
                articleAsLivingDocViewController = ArticleAsLivingDocViewController(articleTitle: article.displayTitle, editMetrics: articleAsLivingDocEditMetrics, theme: theme, delegate: self, scrollToInitialIndexPath: initialIndexPath)
                articleAsLivingDocViewController?.apply(theme: theme)
                
                if let articleAsLivingDocViewController = articleAsLivingDocViewController {
                    let navigationController = WMFThemeableNavigationController(rootViewController: articleAsLivingDocViewController, theme: theme)
                    navigationController.modalPresentationStyle = .pageSheet
                    navigationController.isNavigationBarHidden = true
                    present(navigationController, animated: true)
                }
            }
        }
    }
    
    func toggleContentVisibilityExceptLeadImage(shouldHide: Bool) {
        webView.scrollView.subviews.forEach { (view) in
            if view != leadImageContainerView {
                view.isHidden = shouldHide
            }
        }
    }
    
    func handleArticleAsLivingDocLinkForAnchor(_ anchor: String) {
        guard anchor.contains("significant-events") else {
            return
        }
        
        let splitItems = anchor.split(separator: "-")
        guard splitItems.count == 4,
              let item = Int(splitItems[2]),
              let section = Int(splitItems[3]) else { //last two items are initialIndexPath to scroll to
            presentArticleAsLivingDoc()
            return
        }
        
        let indexPath = IndexPath(item: item, section: section)
        presentArticleAsLivingDoc(scrollToInitialIndexPath: indexPath)
    }
}

extension ArticleViewController: ArticleAsLivingDocViewControllerDelegate {
    func fetchNextPage(nextRvStartId: UInt) {
        if #available(iOS 13.0, *) {
            guard let articleTitleAndSiteURL = self.articleTitleAndSiteURL(),
                  shouldAttemptToShowArticleAsLivingDoc else {
                return
            }
            
            articleAsLivingDocController.fetchArticleAsLivingDocViewModel(rvStartId: nextRvStartId, title: articleTitleAndSiteURL.title, siteURL: articleTitleAndSiteURL.siteURL) { (result) in
                switch result {
                case .failure(let error):
                    DDLogDebug("Failure fetching next significant events page \(error)")
                case .success(let articleAsLivingDocViewModel):
                    self.articleAsLivingDocViewModel = articleAsLivingDocViewModel
                }
            }
        }
    }
}
