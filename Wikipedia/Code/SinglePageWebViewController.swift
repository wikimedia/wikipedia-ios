@preconcurrency import WebKit
import CocoaLumberjackSwift
import WMF
import WMFComponents
import WMFData

class SinglePageWebViewController: ViewController {
    
    final class WebViewDonateConfig {
        weak var donateCoordinatorDelegate: DonateCoordinatorDelegate?
        weak var donateLoggingDelegate: WMFDonateLoggingDelegate?
        let donateCompleteButtonTitle: String
        
        internal init(donateCoordinatorDelegate: (any DonateCoordinatorDelegate)?, donateLoggingDelegate: (any WMFDonateLoggingDelegate)?, donateCompleteButtonTitle: String) {
            self.donateCoordinatorDelegate = donateCoordinatorDelegate
            self.donateLoggingDelegate = donateLoggingDelegate
            self.donateCompleteButtonTitle = donateCompleteButtonTitle
        }
    }
    
    let url: URL
    private let donateConfig: WebViewDonateConfig?

    private let donateDataController = WMFDonateDataController()

    var doesUseSimpleNavigationBar: Bool {
        didSet {
            if doesUseSimpleNavigationBar {
                navigationItem.setRightBarButtonItems([], animated: false)
                navigationItem.titleView = nil
            }
        }
    }

    var didReachThankyouPage = false

    required init(url: URL, theme: Theme, doesUseSimpleNavigationBar: Bool = false, donateConfig: WebViewDonateConfig? = nil) {
        self.url = url
        self.doesUseSimpleNavigationBar = doesUseSimpleNavigationBar
        self.donateConfig = donateConfig
        super.init()
        self.theme = theme
        
        self.navigationItem.backButtonTitle = url.lastPathComponent
        self.navigationItem.backButtonDisplayMode = .generic
        hidesBottomBarWhenPushed = true
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

    private lazy var donationCompleteButtonContainer: UIView = {
        let contentView = UIView(frame: .zero)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = self.theme.colors.paperBackground
        return contentView
    }()

    private lazy var donationCompleteButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(donateConfig?.donateCompleteButtonTitle, for: .normal)
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
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        if navigationController?.viewControllers.first === self {
            let closeButton = UIBarButtonItem.wmf_buttonType(WMFButtonType.X, target: self, action: #selector(closeButtonTapped(_:)))
            navigationItem.leftBarButtonItem = closeButton
        }
        
        super.viewWillAppear(animated)

        guard !fetched else {
            return
        }
        fetched = true
        fetch()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if url.isDonationURL {
            donateConfig?.donateLoggingDelegate?.handleDonateLoggingAction(.webViewFormDidAppear)
        }
    }
    
    public override var preferredContentSize: CGSize {
        get {
            return CGSize(width: 1400, height: 1400)
        } set {
            super.preferredContentSize = newValue
        }
    }

    func setupDonationCompleteView() {
        webView.addSubview(donationCompleteButtonContainer)
        donationCompleteButtonContainer.addSubview(donationCompleteButton)

        let bottom = donationCompleteButtonContainer.bottomAnchor.constraint(equalTo: webView.bottomAnchor)
        let leading = donationCompleteButtonContainer.leadingAnchor.constraint(equalTo: webView.leadingAnchor)
        let trailing = donationCompleteButtonContainer.trailingAnchor.constraint(equalTo: webView.trailingAnchor)
        let height = donationCompleteButtonContainer.heightAnchor.constraint(equalToConstant: 90)

        let buttonTop = donationCompleteButton.topAnchor.constraint(equalTo: donationCompleteButtonContainer.topAnchor, constant: 12)
        let buttonLeading = donationCompleteButton.leadingAnchor.constraint(equalTo: donationCompleteButtonContainer.leadingAnchor, constant: 12)
        let buttonTrailing = donationCompleteButton.trailingAnchor.constraint(equalTo: donationCompleteButtonContainer.trailingAnchor, constant: -12)
        let buttonBottom = donationCompleteButton.bottomAnchor.constraint(equalTo: donationCompleteButtonContainer.bottomAnchor, constant: -32)

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
            let parsedDonationInfo = parseThankYouURL(actionURL)
            saveDonationToLocalHistory(donationInfo: parsedDonationInfo, dataController: donateDataController)
            setupDonationCompleteView()
            donateConfig?.donateLoggingDelegate?.handleDonateLoggingAction(.webViewFormThankYouPageDidAppear)
        }
        
        return true
    }

    func parseThankYouURL(_ url: URL) -> DonationInfo? {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        let queryItems = urlComponents.queryItems ?? []
        let queryDict = Dictionary(uniqueKeysWithValues: queryItems.compactMap { item in
            (item.name, item.value)
        })

        guard let amount = queryDict["amount"],
              let country = queryDict["country"],
              let currency = queryDict["currency"] else {
            return nil
        }

        let isRecurring = queryDict["recurring"] == "true" || queryDict.keys.contains("recurring") && queryDict["recurring"] == nil

        let donationInfo = DonationInfo(amount: amount, country: country, currency: currency, isRecurring: isRecurring)

        return donationInfo
    }

    private func saveDonationToLocalHistory(donationInfo: DonationInfo?, dataController: WMFDonateDataController) {
        guard let donationInfo,
        let decimalAmount = Decimal(string: donationInfo.amount ?? String()),
                let currency = donationInfo.currency else {
            return
        }

        let donationType: WMFDonateLocalHistory.DonationType = donationInfo.isRecurring ? .recurring : .oneTime

        dataController.saveLocalDonationHistory(type: donationType, amount: decimalAmount, currencyCode: currency, isNative: false)
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
        donateConfig?.donateLoggingDelegate?.handleDonateLoggingAction(.webViewFormThankYouDidTapReturn)
        donateConfig?.donateCoordinatorDelegate?.handleDonateAction(.webViewFormThankYouDidTapReturn)
    }

    override func viewDidDisappear(_ animated: Bool) {
        if didReachThankyouPage {
            donateConfig?.donateLoggingDelegate?.handleDonateLoggingAction(.webViewFormThankYouDidDisappear)
            donateConfig?.donateCoordinatorDelegate?.handleDonateAction(.webViewFormThankYouDidDisappear)
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

        // Avoid displaying "Plug-in handled load" noise to users.
        if (error as NSError).isPluginHandledLoadError {
            fakeProgressController.finish()
            return
        }

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

private extension NSError {
  var isPluginHandledLoadError: Bool {
      domain == "WebKitErrorDomain" && code == 204
  }
}

struct DonationInfo {
    let amount: String?
    let country: String?
    let currency: String?
    let isRecurring: Bool
}
