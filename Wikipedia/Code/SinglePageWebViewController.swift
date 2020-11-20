import WebKit
import CocoaLumberjackSwift

class SinglePageWebViewController: ViewController {
    let url: URL
    var doesUseSimpleNavigationBar: Bool {
        didSet {
            if doesUseSimpleNavigationBar {
                navigationItem.setRightBarButtonItems([], animated: false)
                navigationItem.titleView = nil
            }
        }
    }

    required init(url: URL, theme: Theme, doesUseSimpleNavigationBar: Bool = false) {
        self.url = url
        self.doesUseSimpleNavigationBar = doesUseSimpleNavigationBar
        super.init()
        self.theme = theme
        if #available(iOS 14.0, *) {
            self.navigationItem.backButtonTitle = url.lastPathComponent
            self.navigationItem.backButtonDisplayMode = .generic
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var webViewConfiguration: WKWebViewConfiguration = {
        let config = WKWebViewConfiguration()
        let controller = WKUserContentController()
        // hide mobile frontend header chrome
        let script = """
            let style = document.createElement('style')
            style.innerHTML = '.header-chrome { display: none; }'
            document.head.appendChild(style)
        """
        controller.addUserScript(PageUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        config.userContentController = controller
        config.applicationNameForUserAgent = "WikipediaApp"
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

        if !doesUseSimpleNavigationBar {
            let safariItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(tappedAction(_:)))
            let searchItem = AppSearchBarButtonItem.newAppSearchBarButtonItem
            navigationItem.setRightBarButtonItems([searchItem, safariItem], animated: false)

            setupWButton()
        }

        super.viewDidLoad()
    }
    
    private func fetch() {
        fakeProgressController.start()
        webView.load(URLRequest(url: url))
    }
    
    var fetched = false
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if navigationController?.viewControllers.first === self {
            let closeButton = UIBarButtonItem.wmf_buttonType(WMFButtonType.X, target: self, action: #selector(closeButtonTapped(_:)))
            navigationItem.leftBarButtonItem = closeButton
        }
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
    
    @objc func tappedAction(_ sender: UIBarButtonItem) {
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: [TUSafariActivity()])
        
        if let popover = activityViewController.popoverPresentationController {
            popover.barButtonItem = sender
            popover.permittedArrowDirections = .any
        }
        
        present(activityViewController, animated: true)
    }
    
    @objc func closeButtonTapped(_ sender: UIButton) {
        navigationController?.dismiss(animated: true)
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
