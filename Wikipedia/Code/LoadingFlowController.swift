
import Foundation
protocol LoadingFlowControllerTaskTrackingDelegate: class {
    func linkPushFetch(url: URL, successHandler: @escaping (LoadingFlowControllerArticle, URL) -> Void, errorHandler: @escaping (NSError, URL) -> Void) -> (cancellationKey: String, fetcher: Fetcher)?
}

class LoadingFlowController: UIViewController {
    
    let flowChild: WMFLoadingFlowControllerChildProtocol
    private let fetchDelegate: WMFLoadingFlowControllerFetchDelegate
    private let url: URL
    private let dataStore: MWKDataStore
    private var theme: Theme
    
    private let loadingAnimationViewController = LoadingAnimationViewController(nibName: "LoadingAnimationViewController", bundle: nil)
    
    init(dataStore: MWKDataStore, theme: Theme, fetchDelegate: WMFLoadingFlowControllerFetchDelegate, flowChild: WMFLoadingFlowControllerChildProtocol, url: URL) {
        self.dataStore = dataStore
        self.theme = theme
        self.fetchDelegate = fetchDelegate
        self.flowChild = flowChild
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }
    
    @objc init(articleViewController: WMFArticleViewController) {
        self.dataStore = articleViewController.dataStore
        self.theme = articleViewController.theme
        self.fetchDelegate = articleViewController
        self.flowChild = articleViewController
        self.url = articleViewController.articleURL
        
        super.init(nibName: nil, bundle: nil)
        articleViewController.loadingFlowController = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        apply(theme: theme)
        
        if let flowChild = flowChild as? UIViewController {
            wmf_add(childController: flowChild, andConstrainToEdgesOfContainerView: view)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return theme.preferredStatusBarStyle
    }
    
    @objc func tappedLink(url: URL) {
        
        if let taskTrackingDelegate = fetchDelegate as? LoadingFlowControllerTaskTrackingDelegate {
            let result = taskTrackingDelegate.linkPushFetch(url: url, successHandler: { [weak self] (article, url) in
                
                guard let self = self else { return }
                
                self.hideLoading()
                self.processSuccess(article: article, url: url)
            }) { [weak self] (error, url) in
                
                guard let self = self else { return }
                
                self.hideLoading()
                self.processFailure(error: error, url: url)
            }
            
            loadingAnimationViewController.cancelBlock = { [weak self] in
                
                self?.hideLoading()
                
                if let result = result {
                    result.fetcher.cancel(taskFor: result.cancellationKey)
                }
                
            }
            
            scheduleLoadingAnimation()
            return
        }
        
        let task = fetchDelegate.linkPushFetch(with: url, successHandler: { [weak self] (article, url) in
            
            guard let self = self else { return }
            
            self.hideLoading()
            self.processSuccess(article: article, url: url)
            
        }, errorHandler: { [weak self] (error) in
            
            guard let self = self else { return }
            
            self.hideLoading()
            self.processFailure(error: error as NSError, url: url)
            
        })
        
        loadingAnimationViewController.cancelBlock = { [weak self] in
            self?.hideLoading()
            task?.cancel()
        }
        
        scheduleLoadingAnimation()
    }
    
    private func scheduleLoadingAnimation() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(showLoading), object: nil)
        perform(#selector(showLoading), with: nil, afterDelay: 0.5)
    }
    
    @objc private func showLoading() {
        
        if let customAnimationContainer = flowChild.customNavAnimationHandler {
            customAnimationContainer.wmf_add(childController: loadingAnimationViewController, andConstrainToEdgesOfContainerView: customAnimationContainer.view)
        } else {
            wmf_add(childController: loadingAnimationViewController, andConstrainToEdgesOfContainerView: view)
        }
    }
    
    @objc private func hideLoading() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(showLoading), object: nil)
        loadingAnimationViewController.willMove(toParent: nil)
        loadingAnimationViewController.view.removeFromSuperview()
        loadingAnimationViewController.removeFromParent()
    }
    
    private func processSuccess(article: LoadingFlowControllerArticle, url: URL) {
        
        if flowChild.handleCustomSuccess(with: article, url: url) {
            return
        }
        
        switch article.namespace {
        case PageNamespace.main.rawValue:
            showArticleViewController(article: article, url: url)
        case PageNamespace.userTalk.rawValue:
            showTalkPage(url: url)
        default:
            showExternal(url: url)
        }
    }
    
    private func processFailure(error: NSError, url: URL) {
        
        if error.isCancelledError { //error came via cancelled fetch, no need to propogate to user
            return
        }
        
        if let cachedFallbackArticle = error.cachedFallbackArticle {
            
            if let cachedFallbackURL = cachedFallbackArticle.loadingFlowURL {
                switch cachedFallbackArticle.namespace {
                case PageNamespace.main.rawValue:
                    showArticleViewController(article: cachedFallbackArticle, url: cachedFallbackURL)
                    
                    if !error.wmf_isNetworkConnectionError() {
                        WMFAlertManager.sharedInstance.showErrorAlert(error, sticky: false, dismissPreviousAlerts: false)
                    }
                    
                case PageNamespace.userTalk.rawValue:
                    showTalkPage(url: cachedFallbackURL)
                default:
                    showExternal(url: cachedFallbackURL)
                    
                }
            } else {
                if !error.wmf_isNetworkConnectionError() {
                    WMFAlertManager.sharedInstance.showErrorAlert(error, sticky: false, dismissPreviousAlerts: false)
                }
            }
        } else if error.isUnexpectedResponseError || error.isInvalidParameterError {
            
            showExternal(url: url)
            
        } else {
            flowChild.showDefaultLinkFailureWithError(error)
        }
    }
    
    private func showExternal(url: URL) {
        
        if let customNavHandler = flowChild.customNavAnimationHandler {
            customNavHandler.wmf_openExternalUrl(url)
        } else {
            wmf_openExternalUrl(url)
        }
    }
    
    private func showArticleViewController(article: LoadingFlowControllerArticle, url: URL) {
        
        let articleVC = WMFArticleViewController(articleURL: url, dataStore: dataStore, theme: theme)
        let loadingFlowController = LoadingFlowController(dataStore: dataStore, theme: theme, fetchDelegate: articleVC, flowChild: articleVC, url: url)
        articleVC.loadingFlowController = loadingFlowController
        
        if let mwkArticle = article as? MWKArticle {
            articleVC.viewDidLoadCompletion = {
                articleVC.article = mwkArticle
                articleVC.kickoffProgressView()
                articleVC.articleDidLoad()
            }
            
            articleVC.skipFetchOnViewDidAppear = true
        }
        
        wmf_push(loadingFlowController, animated: true)
    }
    
    private func showTalkPage(url: URL) {
        
        guard let siteURL = url.wmf_site else {
            assertionFailure("Issue determining siteURL for talk page.")
            return
        }
        
        var title = url.lastPathComponent
        
        if let firstColon = title.range(of: ":") {
            title.removeSubrange(title.startIndex..<firstColon.upperBound)
        }
        
        let titleWithTalkPageNamespace = TalkPageType.user.titleWithCanonicalNamespacePrefix(title: title, siteURL: siteURL)

        let containerVC = TalkPageContainerViewController.containedTalkPageContainer(title: titleWithTalkPageNamespace, siteURL: siteURL, dataStore: dataStore, type: .user, theme: theme)
        self.navigationController?.pushViewController(containerVC, animated: true)
    }
}

//MARK: Themeable

extension LoadingFlowController: Themeable {
    
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        
        view.backgroundColor = theme.colors.paperBackground
        loadingAnimationViewController.apply(theme: theme)
        flowChild.apply(theme: theme)
        flowChild.customNavAnimationHandler?.apply(theme: theme)
        wmf_applyTheme(toEmptyView: theme)
    }
}

//MARK: ImageScaleTransitionProviding

extension LoadingFlowController: ImageScaleTransitionProviding {
    var imageScaleTransitionView: UIImageView? {
        if let imageScaleTransitioningChild = flowChild as? ImageScaleTransitionProviding {
            return imageScaleTransitioningChild.imageScaleTransitionView
        }
        
        return nil
    }
    
    func prepareViewsForIncomingImageScaleTransition(with imageView: UIImageView?) {
        if let imageScaleTransitioningChild = flowChild as? ImageScaleTransitionProviding {
            imageScaleTransitioningChild.prepareViewsForIncomingImageScaleTransition?(with: imageView)
        }
        
        return
    }
}


//MARK: Error Handling

private extension NSError {
    
    var cachedFallbackArticle: LoadingFlowControllerArticle? {
        if let cachedFallback = userInfo[WMFArticleFetcherErrorCachedFallbackArticleKey] as? LoadingFlowControllerArticle {
            return cachedFallback
        } else {
            return nil
        }
    }
    
    var isUnexpectedResponseError: Bool {
        return domain == Fetcher.unexpectedResponseError.domain && code == Fetcher.unexpectedResponseError.code
    }
    
    var isCancelledError: Bool {
        return domain == NSURLErrorDomain &&
        code == NSURLErrorCancelled
    }
    
    var isInvalidParameterError: Bool {
        return self == Fetcher.invalidParametersError
    }
}

//MARK: LoadingFlowControllerArticle

@objc protocol LoadingFlowControllerArticle {
    var namespace: Int { get }
    var loadingFlowURL: URL! { get }
}

extension MWKArticle: LoadingFlowControllerArticle {
    var namespace: Int {
        return ns
    }
    
    var loadingFlowURL: URL! {
        return url
    }
}

extension WMFArticle: LoadingFlowControllerArticle {
    public var namespace: Int {
        return pageNamespace?.rawValue ?? -1
    }
    
    var loadingFlowURL: URL! {
        return url
    }
}
