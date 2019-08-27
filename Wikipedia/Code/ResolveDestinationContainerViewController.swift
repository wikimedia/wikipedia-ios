
import Foundation
import SafariServices

protocol DestinationContainerArticle {
    var namespace: Int { get }
    var url: URL { get }
}

protocol DestinationContainerDelegateError: Error {
    var cachedFallbackArticle: DestinationContainerArticle? { get }
    var isUnexpectedResponseError: Bool { get }
}

extension NSError: DestinationContainerDelegateError {
    
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

protocol DestinationContainerDelegate: class {
    func loadEmbedFetch(url: URL, success: (DestinationContainerArticle?, URL?) -> Void, error: (NSError?) -> Void) -> URLSessionTask
    func linkPushFetch(url: URL, success: (DestinationContainerArticle?, URL?) -> Void, error: (NSError?) -> Void) -> URLSessionTask
    func viewController(for containerArticle: DestinationContainerArticle) -> UIViewController
    var reachabilityNotifier: ReachabilityNotifier? { get }
    func showDefaultEmbedFailure(error: NSError)
    func showDefaultLinkFailure(error: NSError)
}

class ResolveDestinationContainerViewController: UIViewController {
    
    enum ProcessSource {
        case loadEmbed
        case linkPush
    }
    
    private weak var delegate: DestinationContainerDelegate?
    private let url: URL
    private let embedOnLoad: Bool
    private let dataStore: MWKDataStore
    private let theme: Theme
    
    init(dataStore: MWKDataStore, theme: Theme, delegate: DestinationContainerDelegate, url: URL, embedOnAppearance: Bool) {
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
        
        if (embedOnLoad) {
            delegate?.loadEmbedFetch(url: url, success: { [weak self] (article, url) in
                
                guard let self = self else { return }
                
                guard let article = article,
                    let url = url else {
                        assertionFailure("Missing article or url or both")
                        return
                }
                
                self.processSuccess(article: article, url: url, source: .loadEmbed)
            }) { [weak self] (error) in
                
                guard let self = self else { return }
                
                guard let error = error else {
                    assertionFailure("Missing Error object")
                    return
                }
                
                self.processFailure(error: error, source: .loadEmbed, originalURL: url)
            }
        }
    }
    
    private func processSuccess(article: DestinationContainerArticle, url: URL, source: ProcessSource) {
        
        switch article.namespace {
        case PageNamespace.main.rawValue:
            showArticleViewController(containerArticle: article, url: url, source: source)
        case PageNamespace.userTalk.rawValue:
            showTalkPage(containerArticle: article, url: url, source: source)
        default:
            showExternal(url: url, source: source)
        }
    }
    
    private func processFailure(error: NSError, source: ProcessSource, originalURL: URL) {
        
        if let cachedFallbackArticle = error.cachedFallbackArticle {
            
            let cachedFallbackURL = cachedFallbackArticle.url
            
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
            
        } else if error.isUnexpectedResponseError {
            
            showExternal(url: url, source: source)
            
        } else {
            
            switch source {
            case .loadEmbed:
                //articleVC's
                delegate?.showDefaultEmbedFailure(error: error)
                
                //articleVC will be:
                //                    wmf_showEmptyView(of: WMFEmptyViewType.articleDidNotLoad, theme: theme, frame: view.bounds)
                //                    WMFAlertManager.sharedInstance.showErrorAlert(error, sticky: false, dismissPreviousAlerts: false)
                //container?.embed(self)?

                
                if error.wmf_isNetworkConnectionError() {
                    delegate?.reachabilityNotifier?.start()
                }
            case .linkPush:
                delegate?.showDefaultLinkFailure(error: error)
                //articleVC will be:
                //                    WMFAlertManager.sharedInstance.showErrorAlert(error, sticky: false, dismissPreviousAlerts: false)
                //talk page container will be:
                //self.viewState = .linkFailure(loadingViewController: loadingViewController, error: error)
            }
            //
            
        }
        
        
    }
    
    private func showExternal(url: URL, source: ProcessSource) {
        
        switch source {
        case .loadEmbed:
            let safariVC = SFSafariViewController(url: url)
            safariVC.delegate = self
            wmf_add(childController: safariVC, andConstrainToEdgesOfContainerView: view)
        case .linkPush:
            wmf_openExternalUrl(url)
        }
    }
    
    private func showArticleViewController(containerArticle: DestinationContainerArticle, url: URL, source: ProcessSource) {
        
        //not necessarily this, coming from talk page will be article summary
        guard let mwkArticle = containerArticle as? MWKArticle else {
            assertionFailure("Unexpected article type")
            return
        }
        
        let articleVC = WMFArticleViewController(articleURL: url, dataStore: dataStore, theme: theme)
        articleVC.skipFetchOnViewDidAppear = true
        articleVC.article = mwkArticle
        
        switch source {
        case .loadEmbed:
            wmf_add(childController: articleVC, andConstrainToEdgesOfContainerView: view)
        case .linkPush:
            //todo: actually we should be pushing another container with a prepopulated article VC. if it's not an mwkArticle (might be article summary from talk page) push a non-prepopulated article VC.
            wmf_push(articleVC, animated: true)
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
        
        let talkPageVC = TalkPageContainerViewController(title: titleWithTalkPageNamespace, siteURL: siteURL, type: .user, dataStore: dataStore)
        
        switch source {
        case .loadEmbed:
            wmf_add(childController: talkPageVC, andConstrainToEdgesOfContainerView: view)
        case .linkPush:
            //todo: actually we should be pushing another container with a pre-embedded talk page vc
            self.navigationController?.pushViewController(talkPageVC, animated: true)
        }
    }
}

extension ResolveDestinationContainerViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        self.navigationController?.popViewController(animated: true)
    }
}
