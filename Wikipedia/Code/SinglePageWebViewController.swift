import WebKit
import CocoaLumberjackSwift
import WMF
import WMFComponents

class SinglePageWebViewController: ViewController {
    let url: URL
    let campaignArticleURL: URL?
    let campaignMetricsID: String?
    
    var doesUseSimpleNavigationBar: Bool {
        didSet {
            if doesUseSimpleNavigationBar {
                navigationItem.setRightBarButtonItems([], animated: false)
                navigationItem.titleView = nil
            }
        }
    }
    
    var campaignProject: WikimediaProject? {
        guard let campaignArticleURL else {
            return nil
        }
        
        return WikimediaProject(siteURL: campaignArticleURL)
    }

    var didReachThankyouPage = false

    required init(url: URL, theme: Theme, doesUseSimpleNavigationBar: Bool = false, campaignArticleURL: URL? = nil, campaignMetricsID: String? = nil) {
        self.url = url
        self.campaignArticleURL = campaignArticleURL
        self.campaignMetricsID = campaignMetricsID
        self.doesUseSimpleNavigationBar = doesUseSimpleNavigationBar
        super.init()
        self.theme = theme
        
        self.navigationItem.backButtonTitle = url.lastPathComponent
        self.navigationItem.backButtonDisplayMode = .generic
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
        config.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        return config
    }()

    private lazy var webView: WKWebView = {
        let webView = WKWebView(frame: UIScreen.main.bounds, configuration: webViewConfiguration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        return webView
    }()
    
    private lazy var fakeProgressController: FakeProgressController = {
        let fpc = FakeProgressController(progress: navigationBar, delegate: navigationBar)
        fpc.delay = 0
        return fpc
    }()

    private lazy var bottomView: UIView = {
        let contentView = UIView(frame: .zero)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = self.theme.colors.paperBackground
        return contentView
    }()

    private lazy var button: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Came from article
        if campaignProject != nil {
            button.setTitle(CommonStrings.returnToArticle, for: .normal)
        } else {
            button.setTitle(CommonStrings.returnButtonTitle, for: .normal)
        }
        
        button.backgroundColor = self.theme.colors.link
        button.titleLabel?.textColor = .white
        button.layer.cornerRadius = 8
        button.titleLabel?.font = WMFFont.for(.headline, compatibleWith: traitCollection)
        button.addTarget(self, action: #selector(didTapReturnButton), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        view.wmf_addSubviewWithConstraintsToEdges(webView)
        scrollView = webView.scrollView
        scrollView?.delegate = self

        if !doesUseSimpleNavigationBar {
            let safariItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(tappedAction(_:)))
            let searchItem = AppSearchBarButtonItem.newAppSearchBarButtonItem
            navigationItem.setRightBarButtonItems([searchItem, safariItem], animated: false)

            if url.isDonationURL {
                navigationBar.isInteractiveHidingEnabled = false
            }
            setupWButton()
        }

        copyCookiesFromSession()
        
        super.viewDidLoad()
    }
    
    private func copyCookiesFromSession() {
        let cookies = Session.sharedCookieStorage.cookies ?? []
        for cookie in cookies {
            webView.configuration.websiteDataStore.httpCookieStore
                .setCookie(cookie)
        }
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if url.isDonationURL {
            DonateFunnel.shared.logDonateFormInAppWebViewImpression(project: campaignProject)
        }
    }

    func setupBottomView() {
        webView.addSubview(bottomView)
        bottomView.addSubview(button)

        let bottom = bottomView.bottomAnchor.constraint(equalTo: webView.bottomAnchor)
        let leading = bottomView.leadingAnchor.constraint(equalTo: webView.leadingAnchor)
        let trailing = bottomView.trailingAnchor.constraint(equalTo: webView.trailingAnchor)
        let height = bottomView.heightAnchor.constraint(equalToConstant: 90)

        let buttonTop = button.topAnchor.constraint(equalTo: bottomView.topAnchor, constant: 12)
        let buttonLeading = button.leadingAnchor.constraint(equalTo: bottomView.leadingAnchor, constant: 12)
        let buttonTrailing = button.trailingAnchor.constraint(equalTo: bottomView.trailingAnchor, constant: -12)
        let buttonBottom = button.bottomAnchor.constraint(equalTo: bottomView.bottomAnchor, constant: -32)

        webView.addConstraints([bottom, leading, trailing, height, buttonTop, buttonLeading, buttonTrailing, buttonBottom])
    }

    var didHandleInitialNavigation = false
    func handleNavigation(with action: WKNavigationAction) -> Bool {
        guard didHandleInitialNavigation else {
            didHandleInitialNavigation = true
            return true
        }
        
        guard
            let relativeActionURL = action.request.url,
            let actionURL = URL(string: relativeActionURL.absoluteString, relativeTo: webView.url)?.absoluteURL else {
            return true
        }
        
        if action.navigationType == .linkActivated {
            let userInfo: [AnyHashable : Any] = [RoutingUserInfoKeys.source: RoutingUserInfoSourceValue.inAppWebView.rawValue]
            navigate(to: actionURL, userInfo: userInfo)
            return false
        } else if action.navigationType == .other,
                  actionURL.isThankYouDonationURL {
            didReachThankyouPage = true
            setupBottomView()
            DonateFunnel.shared.logDonateFormInAppWebViewThankYouImpression(project: campaignProject, metricsID: campaignMetricsID)
        }
        
        return true
    }
    
    @objc func tappedAction(_ sender: UIBarButtonItem) {
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: [TUSafariActivity()])
        
        if let popover = activityViewController.popoverPresentationController {
            popover.barButtonItem = sender
            popover.permittedArrowDirections = .any
        }

        activityViewController.excludedActivityTypes = [.addToReadingList]
        present(activityViewController, animated: true)
    }
    
    @objc func closeButtonTapped(_ sender: UIButton) {
        navigationController?.dismiss(animated: true)
    }

    @objc func didTapReturnButton() {
        if let project = campaignProject {
            DonateFunnel.shared.logDonateFormInAppWebViewDidTapArticleReturnButton(project: project)
        } else {
            DonateFunnel.shared.logDonateFormInAppWebViewDidTapReturnButton()
        }
        
        navigationController?.popViewController(animated: true)
    }

    override func viewDidDisappear(_ animated: Bool) {
        let project = self.campaignProject
        if didReachThankyouPage {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                
                WMFAlertManager.sharedInstance.showBottomAlertWithMessage(CommonStrings.donateThankTitle, subtitle: CommonStrings.donateThankSubtitle, image: UIImage.init(systemName: "heart.fill"), type: .custom, customTypeName: "donate-success", duration: -1, dismissPreviousAlerts: true)
                
                if let project {
                    DonateFunnel.shared.logArticleDidSeeApplePayDonateSuccessToast(project: project)
                } else {
                    DonateFunnel.shared.logSettingDidSeeApplePayDonateSuccessToast()
                }
            }
        }
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
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        guard handleNavigation(with: navigationAction) else {
            decisionHandler(.cancel, preferences)
            return
        }
        decisionHandler(.allow, preferences)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        DDLogWarn("Error loading single page - did fail provisional navigation: \(error)")
        WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: false, dismissPreviousAlerts: true)
        fakeProgressController.finish()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        DDLogWarn("Error loading single page: \(error)")
        WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: false, dismissPreviousAlerts: false)
        fakeProgressController.finish()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        fakeProgressController.finish()
    }
}

extension SinglePageWebViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let action1 = UIAlertAction(title: CommonStrings.okTitle, style: .default) { _ in
            completionHandler(true)
        }
        let action2 = UIAlertAction(title: CommonStrings.cancelActionTitle, style: .default) { _ in
            completionHandler(false)
        }
        alertController.addAction(action1)
        alertController.addAction(action2)
        
        present(alertController, animated: true)
    }
}
