import UIKit
import WMF
import CocoaLumberjackSwift

class TalkPageWebViewController: ViewController {
    let introText: String
    let talkPageTitle: String
    let siteURL: URL
    var finalURL: URL?

    required init(introText: String, talkPageTitle: String, siteURL: URL, theme: Theme) {
        self.introText = introText
        self.talkPageTitle = talkPageTitle
        self.siteURL = siteURL
        
        var finalComponents = URLComponents(url: siteURL, resolvingAgainstBaseURL: false)
        finalComponents?.path = "/wiki/\(talkPageTitle.denormalizedPageTitle ?? "")"
        let queryItem = URLQueryItem(name: "useformat", value: "desktop")
        finalComponents?.queryItems = [queryItem]
        self.finalURL = finalComponents?.url
        
        super.init()
        self.theme = theme
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var webViewConfiguration: WKWebViewConfiguration = {
        let config = WKWebViewConfiguration()
        let controller = WKUserContentController()
        let script = """
            document.body.innerHTML = `
        \(self.introText.sanitizedForJavaScriptTemplateLiterals)
        `;
        """
        controller.addUserScript(PageUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        config.userContentController = controller
        return config
    }()

    private lazy var webView: WKWebView = {
        let webView = WKWebView(frame: UIScreen.main.bounds, configuration: webViewConfiguration)
        webView.navigationDelegate = self
        return webView
    }()
    
    private lazy var fakeProgressController: FakeProgressController = {
        let fpc = FakeProgressController(progress: navigationBar, delegate: navigationBar)
        fpc.delay = 0
        return fpc
    }()
    
    override func viewDidLoad() {
        view.wmf_addSubviewWithConstraintsToEdges(webView)
        scrollView = webView.scrollView
        scrollView?.delegate = self

        super.viewDidLoad()
    }
    
    private func fetch() {
        
        guard let finalURL = finalURL else {
            return
        }
        
        fakeProgressController.start()
        //https://en.wikipedia.org/w/index.php?title=Talk:Cat&mobileaction=toggle_view_desktop
        webView.load(URLRequest(url: finalURL))
    }
    
    var fetched = false
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard !fetched else {
            return
        }
        fetched = true
        fetch()
    }
    
    var didHandleInitialNavigation = false
    func handleNavigation(with action: WKNavigationAction) -> Bool {
        guard didHandleInitialNavigation else {
            didHandleInitialNavigation = true
            return true
        }
        
        guard
            action.navigationType == .linkActivated, // allow redirects and other navigation types
            let relativeActionURL = action.request.url,
            let actionURL = URL(string: relativeActionURL.absoluteString, relativeTo: webView.url)?.absoluteURL
        else {
            return true
        }
    
        navigate(to: actionURL)
        return false
    }
}

extension TalkPageWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard handleNavigation(with: navigationAction) else {
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        guard handleNavigation(with: navigationAction) else {
            decisionHandler(.cancel, preferences)
            return
        }
        decisionHandler(.allow, preferences)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        DDLogError("Error loading single page: \(error)")
        WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: false, dismissPreviousAlerts: false)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        fakeProgressController.finish()
    }
}
