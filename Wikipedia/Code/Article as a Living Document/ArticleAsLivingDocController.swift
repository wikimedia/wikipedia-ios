
import Foundation
import UIKit
import CocoaLumberjackSwift
import WMF

protocol ArticleAsLivingDocControllerDelegate: class {
    var articleURL: URL { get }
    var article: WMFArticle { get }
    var messagingController: ArticleWebMessagingController { get }
    var theme: Theme { get }
    var webView: WKWebView { get }
    var leadImageContainerView: UIView { get }
    func updateArticleMargins()
    var isInValidSurveyCampaignAndArticleList: Bool { get }
    var abTestsController: ABTestsController { get }
    func extendTimerForPresentingModal()
}

enum ArticleAsLivingDocSurveyLinkState {
    case notInExperiment
    case inExperimentLoadingEvents
    case inExperimentFailureLoadingEvents
    case inExperimentLoadedEventsDidNotSeeModal
    case inExperimentLoadedEventsDidSeeModal
}

@available(iOS 13.0, *)
class ArticleAsLivingDocController: NSObject {

    enum Errors: Error {
        case viewModelInstantiationFailure
    }
    
    typealias ArticleAsLivingDocConformingViewController = ArticleAsLivingDocControllerDelegate & UIViewController & HintPresenting & ArticleAsLivingDocViewControllerDelegate

    private weak var delegate: ArticleAsLivingDocConformingViewController?
    private(set) var surveyLinkState: ArticleAsLivingDocSurveyLinkState
    
    var _articleAsLivingDocViewModel: ArticleAsLivingDocViewModel?
    var articleAsLivingDocViewModel: ArticleAsLivingDocViewModel? {
        get {
            return _articleAsLivingDocViewModel
        }
        set {
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
                let oldLastUpdatedTimestamp = oldModel.lastUpdatedTimestamp
                _articleAsLivingDocViewModel = ArticleAsLivingDocViewModel(nextRvStartId: newValue.nextRvStartId, sha: oldModel.sha, sections: appendedSections, summaryText: newValue.summaryText, articleInsertHtmlSnippets: oldHtmlSnippets, lastUpdatedTimestamp: oldLastUpdatedTimestamp)
                articleAsLivingDocViewController?.appendSections(newValue.sections)
            } else {
                // should only be triggered via pull to refresh or fresh load. update everything
                _articleAsLivingDocViewModel = newValue
                //note, we aren't updating data source in VC here. So far we won't reach this situation where a refresh
                //is triggered while the events modal is still on screen, so not needed at this point.
            }
        }
    }
    var articleAsLivingDocEditMetrics: [NSNumber]?
    
    //making lazy to be able to limit just this property to 13+
    @available(iOS 13.0, *)
    lazy var articleAsLivingDocViewController: ArticleAsLivingDocViewController? = {
        return nil
    }()
    
    var shouldAttemptToShowArticleAsLivingDoc: Bool {
        
        guard let delegate = delegate,
              delegate.articleURL.host == Configuration.Domain.englishWikipedia,
              let view = delegate.view,
              view.effectiveUserInterfaceLayoutDirection == .leftToRight
               else {
            return false
        }
        
        let isInExperimentBucket: Bool
        if let bucket = delegate.abTestsController.bucketForExperiment(.articleAsLivingDoc) {
            isInExperimentBucket = bucket == .articleAsLivingDocTest
        } else {
            isInExperimentBucket = false
        }
        
        let shouldAttemptToShowArticleAsLivingDoc = articleTitleAndSiteURL() != nil && delegate.isInValidSurveyCampaignAndArticleList && isInExperimentBucket
        
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
    
    var injectingSkeleton = false
    var hasSkeleton = false
    var loadingArticleContent = true
    var isPullToRefreshing = false
    var failedLastInitialFetch = false

    private var currentFetchRvStartIds: [UInt] = []
    var isFetchingAdditionalPages: Bool {
        return !currentFetchRvStartIds.isEmpty
    }
    
    var hintController: HintController?

    required init(delegate: ArticleAsLivingDocConformingViewController) {
        self.delegate = delegate
        surveyLinkState = .notInExperiment
        
        super.init()
        
        if shouldAttemptToShowArticleAsLivingDoc {
            surveyLinkState = .inExperimentLoadingEvents
        }
    }
    
    func articleTitleAndSiteURL() -> (title: String, siteURL: URL)? {
        
        guard let delegate = delegate,
              let title = delegate.articleURL.wmf_title?.denormalizedPageTitle,
              let siteURL = delegate.articleURL.wmf_site else {
            return nil
        }
        
        return (title, siteURL)
    }
    
    func articleDidTriggerPullToRefresh() {
        articleAsLivingDocViewModel = nil
        isPullToRefreshing = true
    }
    
    func articleContentFinishedLoading() {
        self.loadingArticleContent = false
        let delay = self.isPullToRefreshing ? 0.0 : 0.3
        self.isPullToRefreshing = false
        if self.articleAsLivingDocViewModel != nil {
            self.configureForArticleAsLivingDocResult()
        } else {
            self.scheduleInjectArticleAsLivingDocSkeletonAfterDelay(delay)
        }
    }
    
    func articleContentWillBeginLoading(traitCollection: UITraitCollection, theme: Theme) {
        loadingArticleContent = true
        articleAsLivingDocViewModel = nil
        fetchInitialArticleAsLivingDoc(traitCollection: traitCollection, theme: theme)
    }
    
    func setupLeadImageView() {
        if (shouldAttemptToShowArticleAsLivingDoc) {
            toggleContentVisibilityExceptLeadImage(shouldHide: true)
        }
    }
    
    func scheduleInjectArticleAsLivingDocSkeletonAfterDelay(_ delay: TimeInterval) {
        
        guard shouldAttemptToShowArticleAsLivingDoc,
              articleAsLivingDocViewModel == nil else {
            return
        }
        
        if delay > 0 {
            perform(#selector(injectArticleAsLivingDocSkeletonIfNeeded), with: nil, afterDelay: delay)
        } else {
            injectArticleAsLivingDocSkeletonIfNeeded()
        }
    }
    
    @objc func injectArticleAsLivingDocSkeletonIfNeeded() {
        guard shouldAttemptToShowArticleAsLivingDoc,
              articleAsLivingDocViewModel == nil,
              let delegate = delegate else {
            return
        }
        
        injectingSkeleton = true
        delegate.messagingController.injectSkeletonArticleAsLivingDocContent { [weak self] (success) in
            
            guard let self = self else {
                return
            }
            
            let completion = {
                self.injectingSkeleton = false
                self.hasSkeleton = true
                self.toggleContentVisibilityExceptLeadImage(shouldHide: false)
                if self.articleAsLivingDocViewModel != nil {
                    self.injectArticleAsALivingDocument()
                } else if self.failedLastInitialFetch {
                    self.showError()
                }
            }
            
            if (success) {
                self.delegate?.updateArticleMargins()
                completion()
            } else {
                completion()
            }
        }
    }
    
    func fetchInitialArticleAsLivingDoc(traitCollection: UITraitCollection, theme: Theme) {
        
        // triggered via initial load or pull to refresh
        
        guard let articleTitleAndSiteURL = self.articleTitleAndSiteURL(),
              shouldAttemptToShowArticleAsLivingDoc,
              let delegate = delegate else {
            return
        }
        
        failedLastInitialFetch = false

        fetchArticleAsLivingDocViewModel(rvStartId: nil, title: articleTitleAndSiteURL.title, siteURL: articleTitleAndSiteURL.siteURL, traitCollection: traitCollection, theme: theme) { [weak self] (result) in
            
            guard let self = self else {
                return
            }
            
            defer {
                self.configureForArticleAsLivingDocResult()
            }
            switch result {
            case .success(let articleAsLivingDocViewModel):
                self.articleAsLivingDocViewModel = articleAsLivingDocViewModel
                self.surveyLinkState = .inExperimentLoadedEventsDidNotSeeModal
            case .failure(let error):
                if self.hasSkeleton {
                    self.showError()
                } else {
                    self.failedLastInitialFetch = true
                }
                self.surveyLinkState = .inExperimentFailureLoadingEvents
                DDLogDebug("Failure getting article as living doc view models: \(error)")
            }
        }
        
        fetchEditMetrics(for: articleTitleAndSiteURL.title, pageURL: delegate.articleURL) { [weak self] result in
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
    
    func showError() {
        delegate?.messagingController.removeArticleAsLivingDocContent()
        self.show(hintViewController: ArticleAsLivingDocHintViewController())
    }
    
    func configureForArticleAsLivingDocResult() {
        
        guard !loadingArticleContent else {
            return
        }
        
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(injectArticleAsLivingDocSkeletonIfNeeded), object: nil)
        
        guard !injectingSkeleton else {
            return
        }
        
        injectArticleAsALivingDocument()
    }
    
    
    private let userDefaultsKey = "article-as-living-doc-shas"
    func getPersistedShaForArticleKey(_ articleKey: String) -> String? {
        guard let shas = UserDefaults.standard.dictionary(forKey: userDefaultsKey),
              let sha = shas[articleKey] as? String else {
            return nil
        }
        
        return sha
    }
    
    func persistShaForArticleKey(_ articleKey: String, sha: String) {
        var shas = UserDefaults.standard.dictionary(forKey: userDefaultsKey) ?? [:]
        shas[articleKey] = sha
        UserDefaults.standard.setValue(shas, forKey: userDefaultsKey)
    }
    
    func injectArticleAsALivingDocument() {
        
        guard let delegate = delegate,
              let articleKey = delegate.article.key else {
            return
        }
        
        if let viewModel = articleAsLivingDocViewModel,
           shouldShowArticleAsLivingDoc {
            let htmlSnippets = viewModel.articleInsertHtmlSnippets
            let lastPersistedSha = getPersistedShaForArticleKey(articleKey)
            let shouldShowNewChangesBadge = viewModel.sha != nil ? lastPersistedSha != viewModel.sha : false
            let topBadgeType: ArticleWebMessagingController.TopBadgeType = shouldShowNewChangesBadge ? .newChanges : .lastUpdated
            let timestamp = viewModel.lastUpdatedTimestamp
            
            delegate.messagingController.injectArticleAsLivingDocContent(articleInsertHtmlSnippets: htmlSnippets, topBadgeType: topBadgeType, timestamp: timestamp) { [weak self, weak delegate] (success) in
                
                guard let self = self else {
                    return
                }
                
                if (success) {
                    self.hasSkeleton = false
                    delegate?.updateArticleMargins()
                }
                
                if let sha = viewModel.sha {
                    self.persistShaForArticleKey(articleKey, sha: sha)
                }
                
                self.toggleContentVisibilityExceptLeadImage(shouldHide: false)
            }
        } else if shouldAttemptToShowArticleAsLivingDoc {
            toggleContentVisibilityExceptLeadImage(shouldHide: false)
        }
    }
    
    func presentArticleAsLivingDoc(scrollToInitialIndexPath initialIndexPath: IndexPath? = nil) {
        
        guard let delegate = delegate else {
            return
        }
        
        if let _ = articleAsLivingDocViewModel {
            
            articleAsLivingDocViewController = ArticleAsLivingDocViewController(articleTitle: delegate.article.displayTitle, editMetrics: articleAsLivingDocEditMetrics, theme: delegate.theme, delegate: delegate, scrollToInitialIndexPath: initialIndexPath)
            articleAsLivingDocViewController?.apply(theme: delegate.theme)
            
            if let articleAsLivingDocViewController = articleAsLivingDocViewController {
                let navigationController = WMFThemeableNavigationController(rootViewController: articleAsLivingDocViewController, theme: delegate.theme)
                navigationController.modalPresentationStyle = .pageSheet
                navigationController.isNavigationBarHidden = true
                surveyLinkState = .inExperimentLoadedEventsDidSeeModal
                delegate.extendTimerForPresentingModal()
                delegate.present(navigationController, animated: true)
            }
        }
    }
    
    func toggleContentVisibilityExceptLeadImage(shouldHide: Bool) {
        //seems usually thanks to a margin update taking a little bit of time, pushing the
        //unhide out a little bit gives us a smoother experience
        
        guard let delegate = delegate else {
            return
        }
        
        let toggleBlock = { [weak delegate] in
            
            guard let delegate = delegate else {
                return
            }
            
            delegate.webView.scrollView.subviews.forEach { (view) in
                if view != delegate.leadImageContainerView {
                    view.isHidden = shouldHide
                }
            }
        }
        
        if !shouldHide {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
                toggleBlock()
            }
        } else {
            toggleBlock()
        }
        
    }
    
    func handleArticleAsLivingDocLinkForAnchor(_ anchor: String, articleURL: URL) {
        guard anchor.contains("significant-events") else {
            return
        }
        
        let splitItems = anchor.split(separator: "-")
        
        if splitItems.count == 4,
           splitItems[2] == "username",
           let userName = String(splitItems[3]).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed) {

            let href = "./User:\(userName)"
            guard let resolvedURL = articleURL.resolvingRelativeWikiHref(href) else {
                assertionFailure("Unable to read link as article as a living doc link.")
                return
            }
            
            ArticleAsLivingDocFunnel.shared.logArticleContentInsertEditorTapped()
            delegate?.navigate(to: resolvedURL)
            return
        }
        
        //example: anchor of "significant-events-1-2-3" means scroll to initial index path (item: 1, section: 2) and log ArticleContentInsertEventDescriptionType(rawValue: 3)
        guard splitItems.count == 5,
              let item = Int(splitItems[2]),
              let section = Int(splitItems[3]),
              let loggingDescriptionTypeRaw = Int(splitItems[4]),
              let loggingDescriptionType = ArticleAsLivingDocFunnel.ArticleContentInsertEventDescriptionType(rawValue: loggingDescriptionTypeRaw) else {
            
            ArticleAsLivingDocFunnel.shared.logArticleContentInsertReadMoreUpdatesTapped()
            presentArticleAsLivingDoc()
            return
        }

        ArticleAsLivingDocFunnel.shared.logArticleContentInsertEventDescriptionTapped(descriptionType: loggingDescriptionType)
        
        let indexPath = IndexPath(item: item, section: section)
        presentArticleAsLivingDoc(scrollToInitialIndexPath: indexPath)
    }
    
    private func show(hintViewController: HintViewController){
        
        guard let delegate = delegate else {
            return
        }
        
        let showHint = {
            self.hintController = HintController(hintViewController: hintViewController)
            self.hintController?.toggle(presenter: delegate, context: nil, theme: delegate.theme)
            self.hintController?.setHintHidden(false)
        }
        if let hintController = self.hintController {
            hintController.setHintHidden(true) {
                showHint()
            }
        } else {
            showHint()
        }
    }
    
    //MARK: Fetcher Methods
    private let fetcher = SignificantEventsFetcher()
    func fetchArticleAsLivingDocViewModel(rvStartId: UInt? = nil, title: String, siteURL: URL, traitCollection: UITraitCollection, theme: Theme, completion: @escaping ((Result<ArticleAsLivingDocViewModel, Error>) -> Void)) {
        fetcher.fetchSignificantEvents(rvStartId: rvStartId, title: title, siteURL: siteURL) { (result) in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            case .success(let significantEvents):
                if let viewModel = ArticleAsLivingDocViewModel(significantEvents: significantEvents, traitCollection: traitCollection, theme: theme) {
                    DispatchQueue.main.async {
                        completion(.success(viewModel))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(ArticleAsLivingDocController.Errors.viewModelInstantiationFailure))
                    }
                }
            }
        }
    }
    
    func fetchEditMetrics(for pageTitle: String, pageURL: URL, completion: @escaping (Result<[NSNumber], Error>) -> Void ) {
        fetcher.fetchEditMetrics(for: pageTitle, pageURL: pageURL) { (result) in
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    func fetchNextPage(nextRvStartId: UInt, traitCollection: UITraitCollection, theme: Theme) {

        guard let articleTitleAndSiteURL = self.articleTitleAndSiteURL(),
              shouldAttemptToShowArticleAsLivingDoc else {
            return
        }

        currentFetchRvStartIds.append(nextRvStartId)

        fetchArticleAsLivingDocViewModel(rvStartId: nextRvStartId, title: articleTitleAndSiteURL.title, siteURL: articleTitleAndSiteURL.siteURL, traitCollection: traitCollection, theme: theme) { [weak self] (result) in
            guard let self = self else {
                return
            }

            defer {
                self.currentFetchRvStartIds.removeAll(where: {$0 == nextRvStartId})
                if self.currentFetchRvStartIds.isEmpty {
                    self.articleAsLivingDocViewController?.collectionView.reloadData()
                }
            }

            switch result {
            case .failure(let error):
                DDLogDebug("Failure fetching next significant events page \(error)")
            case .success(let articleAsLivingDocViewModel):
                self.articleAsLivingDocViewModel = articleAsLivingDocViewModel
            }
        }
    }
}
