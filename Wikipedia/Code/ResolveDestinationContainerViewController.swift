
import Foundation
import SafariServices

@objc protocol DestinationContainerArticle {
    var namespace: Int { get }
    var destinationContainerURL: URL! { get }
}

protocol ResolveDestinationContainerDelegateError: Error {
    var cachedFallbackArticle: DestinationContainerArticle? { get }
    var isUnexpectedResponseError: Bool { get }
}

extension NSError: ResolveDestinationContainerDelegateError {
    
    var cachedFallbackArticle: DestinationContainerArticle? {
        if let cachedFallback = userInfo[WMFArticleFetcherErrorCachedFallbackArticleKey] as? DestinationContainerArticle {
            return cachedFallback
        } else {
            return nil
        }
    }
    
    var isUnexpectedResponseError: Bool {
        return domain == Fetcher.unexpectedResponseError.domain && code == Fetcher.unexpectedResponseError.code
    }
}

@objc protocol ResolveDestinationContainerDelegate: class {
    func loadEmbedFetch(url: URL, successHandler: @escaping (DestinationContainerArticle, URL) -> Void, errorHandler: @escaping (NSError) -> Void) -> URLSessionTask?
    func linkPushFetch(url: URL, successHandler: @escaping (DestinationContainerArticle, URL) -> Void, errorHandler: @escaping (NSError) -> Void) -> URLSessionTask?
    var reachabilityNotifier: ReachabilityNotifier? { get }
    func handleCustomSuccess(article: DestinationContainerArticle, url: URL) -> Bool
    func showDefaultEmbedFailure(error: NSError, container: ResolveDestinationContainerViewController)
    func showDefaultLinkFailure(error: NSError)
    var resolveDestinationContainerVC: ResolveDestinationContainerViewController? { get }
    @objc optional var customAnimationContainerViewController: UIViewController? { get }
}

protocol ResolveDestinationContainerTaskTrackingDelegate: ResolveDestinationContainerDelegate {
    func linkPushFetch(url: URL, successHandler: @escaping (DestinationContainerArticle, URL) -> Void, errorHandler: @escaping (NSError, URL) -> Void) -> (String, Fetcher)?
}

class ResolveDestinationContainerViewController: UIViewController {
    
    enum ProcessSource {
        case loadEmbed
        case linkPush
    }
    
    //intentionally not weak. we want to keep this in memory while we determine if we want to embed it or not.
    private var delegate: ResolveDestinationContainerDelegate?
    private let url: URL
    private let embedOnLoad: Bool
    private let dataStore: MWKDataStore
    private let theme: Theme
    
    private let loadingAnimationViewController = LoadingAnimationViewController(nibName: "LoadingAnimationViewController", bundle: nil)
    
    @objc init(dataStore: MWKDataStore, theme: Theme, delegate: ResolveDestinationContainerDelegate, url: URL, embedOnAppearance: Bool) {
        self.dataStore = dataStore
        self.theme = theme
        self.delegate = delegate
        self.url = url
        self.embedOnLoad = embedOnAppearance
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        apply(theme: theme)
        
        if (embedOnLoad) {
            let task = delegate?.loadEmbedFetch(url: url, successHandler: { [weak self] (article, url) in
                
                guard let self = self else { return }
                
                self.hideLoading()
                self.processSuccess(article: article, url: url, source: .loadEmbed)
            }) { [weak self] (error) in
                
                guard let self = self else { return }
                
                self.hideLoading()
                self.processFailure(error: error, source: .loadEmbed, url: self.url)
            }
            
            loadingAnimationViewController.cancelBlock = { [weak self] in
                self?.hideLoading()
                task?.cancel()
                self?.navigationController?.popViewController(animated: true)
            }
            
            scheduleLoadingAnimation()
        }
    }
    
    @objc func tappedLink(url: URL) {
        
        if let taskTrackingDelegate = delegate as? ResolveDestinationContainerTaskTrackingDelegate {
            let result = taskTrackingDelegate.linkPushFetch(url: url, successHandler: { [weak self] (article, url) in
                
                guard let self = self else { return }
                
                self.hideLoading()
                self.processSuccess(article: article, url: url, source: .linkPush)
            }) { [weak self] (error, url) in
                
                guard let self = self else { return }
                
                self.hideLoading()
                self.processFailure(error: error, source: .linkPush, url: url)
            }
            
            loadingAnimationViewController.cancelBlock = { [weak self] in
                
                self?.hideLoading()
                
                //todo: named tuple items
                if let result = result {
                    result.1.cancel(taskFor: result.0)
                }
                
            }
            
            scheduleLoadingAnimation()
            return
        }
        
        let task = delegate?.linkPushFetch(url: url, successHandler: { [weak self] (article, url) in
            
            guard let self = self else { return }
            
            self.hideLoading()
            self.processSuccess(article: article, url: url, source: .linkPush)
            
        }, errorHandler: { [weak self] (error) in
            
            guard let self = self else { return }
            
            self.hideLoading()
            self.processFailure(error: error, source: .linkPush, url: url)
            
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
        
        if let customContainer = delegate?.customAnimationContainerViewController as? UIViewController {
            customContainer.wmf_add(childController: loadingAnimationViewController, andConstrainToEdgesOfContainerView: customContainer.view)
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
    
    private func processSuccess(article: DestinationContainerArticle, url: URL, source: ProcessSource) {
        
        if let delegate = delegate,
            delegate.handleCustomSuccess(article: article, url: url) {
            return
        }
        
        switch article.namespace {
        case PageNamespace.main.rawValue:
            showArticleViewController(containerArticle: article, url: url, source: source)
        case PageNamespace.userTalk.rawValue:
            showTalkPage(containerArticle: article, url: url, source: source)
        default:
            showExternal(url: url, source: source)
        }
    }
    
    private func processFailure(error: NSError, source: ProcessSource, url: URL) {
        
        if error.domain == NSURLErrorDomain &&
            error.code == NSURLErrorCancelled { //error came via cancelled fetch, no need to propogate to user
            return
        }
        
        if let cachedFallbackArticle = error.cachedFallbackArticle {
            
            if let cachedFallbackURL = cachedFallbackArticle.destinationContainerURL {
                switch cachedFallbackArticle.namespace {
                case PageNamespace.main.rawValue:
                    showArticleViewController(containerArticle: cachedFallbackArticle, url: cachedFallbackURL, source: source)
                    
                    if !error.wmf_isNetworkConnectionError() {
                        WMFAlertManager.sharedInstance.showErrorAlert(error, sticky: false, dismissPreviousAlerts: false)
                    }
                    
                case PageNamespace.userTalk.rawValue:
                    showTalkPage(containerArticle: cachedFallbackArticle, url: cachedFallbackURL, source: source)
                default:
                    showExternal(url: cachedFallbackURL, source: source)
                    
                }
            } else {
                if !error.wmf_isNetworkConnectionError() {
                    WMFAlertManager.sharedInstance.showErrorAlert(error, sticky: false, dismissPreviousAlerts: false)
                }
            }
        } else if error.isUnexpectedResponseError {
            
            showExternal(url: url, source: source)
            
        } else {
            
            switch source {
            case .loadEmbed:
                delegate?.showDefaultEmbedFailure(error: error, container: self)

                if error.wmf_isNetworkConnectionError() {
                    delegate?.reachabilityNotifier?.start()
                }
            case .linkPush:
                delegate?.showDefaultLinkFailure(error: error)
            }
            
        }
    }
    
    private func showExternal(url: URL, source: ProcessSource) {
        
        switch source {
        case .loadEmbed:
            let safariVC = SFSafariViewController(url: url)
            safariVC.delegate = self
            wmf_add(childController: safariVC, andConstrainToEdgesOfContainerView: view)
        case .linkPush:
            if let customContainer = delegate?.customAnimationContainerViewController as? UIViewController {
                customContainer.wmf_openExternalUrl(url)
            } else {
                wmf_openExternalUrl(url)
            }
        }
    }
    
    private func showArticleViewController(containerArticle: DestinationContainerArticle, url: URL, source: ProcessSource) {

        switch source {
        case .loadEmbed:
            if let articleVC = delegate as? WMFArticleViewController,
                let mwkArticle = containerArticle as? MWKArticle {
                articleVC.skipFetchOnViewDidAppear = true
                wmf_add(childController: articleVC, andConstrainToEdgesOfContainerView: view)
                articleVC.article = mwkArticle
                articleVC.kickoffProgressView()
            } else {
                assertionFailure("Issue pushing article view controller")
            }
        case .linkPush:
            
            //todo: fix the as!
            let articleVC = WMFArticleViewController(articleURL: url, dataStore: dataStore, theme: theme)
            let resolveDestinationVC = ResolveDestinationContainerViewController(dataStore: dataStore, theme: theme, delegate: articleVC as! ResolveDestinationContainerDelegate, url: url, embedOnAppearance: true)
            articleVC.resolveDestinationContainerVC = resolveDestinationVC
            
            if let mwkArticle = containerArticle as? MWKArticle {
                articleVC.viewDidLoadCompletion = {
                    articleVC.article = mwkArticle
                }
                
                articleVC.skipFetchOnViewDidAppear = true
            }
            
            wmf_push(resolveDestinationVC, animated: true)
        }
    }
    
    private func showTalkPage(containerArticle: DestinationContainerArticle, url: URL, source: ProcessSource) {
        
        guard let siteURL = url.wmf_site else {
            assertionFailure("Issue determining siteURL for talk page.")
            return
        }
        
        var title = url.lastPathComponent
        
        if let firstColon = title.range(of: ":") {
            title.removeSubrange(title.startIndex..<firstColon.upperBound)
        }
        
        let titleWithTalkPageNamespace = TalkPageType.user.titleWithCanonicalNamespacePrefix(title: title, siteURL: siteURL)
        
        switch source {
        case .loadEmbed:
            let talkPageVC = TalkPageContainerViewController(title: titleWithTalkPageNamespace, siteURL: siteURL, type: .user, dataStore: dataStore)
            wmf_add(childController: talkPageVC, andConstrainToEdgesOfContainerView: view)
        case .linkPush:
            let containerVC = TalkPageContainerViewController.containedTalkPageContainer(title: titleWithTalkPageNamespace, siteURL: siteURL, dataStore: dataStore, type: .user, theme: theme)
            self.navigationController?.pushViewController(containerVC, animated: true)
        }
    }
}

extension ResolveDestinationContainerViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension MWKArticle: DestinationContainerArticle {
    var destinationContainerURL: URL! {
        return self.url
    }
    
    var namespace: Int {
        return ns
    }
    
    
}

extension ResolveDestinationContainerViewController: Themeable {
    func apply(theme: Theme) {
        view.backgroundColor = theme.colors.paperBackground
        loadingAnimationViewController.theme = theme
    }
}
