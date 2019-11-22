import WebKit

class SinglePageWebViewController: ViewController {
    let url: URL
    
    required init(url: URL, theme: Theme) {
        self.url = url
        super.init()
        self.theme = theme
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var webViewConfiguration: WKWebViewConfiguration = {
        let config = WKWebViewConfiguration()
        config.applicationNameForUserAgent = "WikipediaApp"
        return config
    }()

    lazy var webView: WKWebView = {
        let webView = WKWebView(frame: UIScreen.main.bounds, configuration: webViewConfiguration)
        webView.navigationDelegate = self
        return webView
    }()
    
    lazy var fakeProgressController: FakeProgressController = {
        let fpc = FakeProgressController(progress: navigationBar, delegate: navigationBar)
        fpc.delay = 0
        return fpc
    }()
    
    override func viewDidLoad() {
        view.wmf_addSubviewWithConstraintsToEdges(webView)
        scrollView = webView.scrollView
        scrollView?.delegate = self
        super.viewDidLoad()
        fakeProgressController.start()
        webView.load(URLRequest(url: url))
        let safariItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(tappedAction(_:)))
        navigationItem.rightBarButtonItem = safariItem
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
    
    @objc func tappedAction(_ sender: UIButton) {
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: [TUSafariActivity()])
        
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = sender
            popover.sourceRect = sender.bounds
            popover.permittedArrowDirections = .down
        }
        
        present(activityViewController, animated: true)
    }
}

extension SinglePageWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard handleNavigation(with: navigationAction) else {
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
    
    @available(iOS 13.0, *)
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
