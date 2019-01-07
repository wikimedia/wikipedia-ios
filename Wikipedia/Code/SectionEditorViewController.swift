@objc(WMFSectionEditorViewControllerDelegate)
protocol SectionEditorViewControllerDelegate: class {
    func sectionEditorDidFinishEditing(_ sectionEditor: SectionEditorViewController, withChanges didChange: Bool)
}

@objc(WMFSectionEditorViewController)
class SectionEditorViewController: UIViewController {
    @objc weak var delegate: SectionEditorViewControllerDelegate?

    @objc var section: MWKSection?

    private var webView: SectionEditorWebView!
    private var webViewCoverView: UIView?
    private var inputViewsController: SectionEditorInputViewsController!
    private var messagingController: SectionEditorWebViewMessagingController!

    private var theme = Theme.standard
    
    private var wikitext: String? {
        didSet {
            setWikitextToWebViewIfReady()
        }
    }
    
    private var isCodemirrorReady: Bool = false {
        didSet {
            setWikitextToWebViewIfReady()
        }
    }

    // MARK: - Bar buttons

    private class BarButtonItem: UIBarButtonItem, Themeable {
        var tintColorKeyPath: KeyPath<Theme, UIColor>?

        convenience init(title: String?, style: UIBarButtonItem.Style, target: Any?, action: Selector?, tintColorKeyPath: KeyPath<Theme, UIColor>) {
            self.init(title: title, style: style, target: target, action: action)
            self.tintColorKeyPath = tintColorKeyPath
        }

        convenience init(image: UIImage?, style: UIBarButtonItem.Style, target: Any?, action: Selector?, tintColorKeyPath: KeyPath<Theme, UIColor>) {
            let button = UIButton(type: .system)
            button.setImage(image, for: .normal)
            if let target = target, let action = action {
                button.addTarget(target, action: action, for: .touchUpInside)
            }
            self.init(customView: button)
            self.tintColorKeyPath = tintColorKeyPath
        }
        
        func apply(theme: Theme) {
            guard let tintColorKeyPath = tintColorKeyPath else {
                return
            }
            let newTintColor = theme[keyPath: tintColorKeyPath]
            if customView == nil {
                tintColor = newTintColor
            } else if let button = customView as? UIButton {
                button.tintColor = newTintColor
            }
        }
    }

    // TODO: Enable/disable
    private lazy var progressButton: BarButtonItem = {
        return BarButtonItem(title: CommonStrings.nextTitle, style: .done, target: self, action: #selector(progress(_:)), tintColorKeyPath: \Theme.colors.link)
    }()

    private lazy var redoButton: BarButtonItem = {
        return BarButtonItem(image: #imageLiteral(resourceName: "redo"), style: .plain, target: self, action: #selector(redo(_ :)), tintColorKeyPath: \Theme.colors.primaryText)
    }()

    private lazy var undoButton: BarButtonItem = {
        return BarButtonItem(image: #imageLiteral(resourceName: "undo"), style: .plain, target: self, action: #selector(undo(_ :)), tintColorKeyPath: \Theme.colors.primaryText)
    }()

    private lazy var separatorButton: BarButtonItem = {
        let button = BarButtonItem(image: #imageLiteral(resourceName: "separator"), style: .plain, target: nil, action: nil, tintColorKeyPath: \Theme.colors.chromeText)
        button.isEnabled = false
        return button
    }()

    // TODO
    private var changesMade: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadWikitext()

        configureNavigationButtonItems()
        configureWebView()

        apply(theme: theme)

        WMFAuthenticationManager.sharedInstance.loginWithSavedCredentials { (_) in }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func configureNavigationButtonItems() {
        let closeButton = BarButtonItem(image: #imageLiteral(resourceName: "close"), style: .plain, target: self, action: #selector(close(_ :)), tintColorKeyPath: \Theme.colors.chromeText)
        closeButton.accessibilityLabel = CommonStrings.closeButtonAccessibilityLabel

        navigationItem.leftBarButtonItem = closeButton

        navigationItem.rightBarButtonItems = [
            progressButton,
            UIBarButtonItem.wmf_barButtonItem(ofFixedWidth: 20),
            separatorButton,
            UIBarButtonItem.wmf_barButtonItem(ofFixedWidth: 20),
            redoButton,
            UIBarButtonItem.wmf_barButtonItem(ofFixedWidth: 20),
            undoButton
        ]

        progressButton.isEnabled = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        progressButton.isEnabled = changesMade
    }

    override func viewWillDisappear(_ animated: Bool) {
        progressButton.isEnabled = false
        UIMenuController.shared.menuItems = webView.originalMenuItems
        super.viewWillDisappear(animated)
    }

    private func configureWebView() {
        guard let language = section?.article?.url.wmf_language else {
            return
        }
        
        let configuration = WKWebViewConfiguration()
        let schemeHandler = WMFURLSchemeHandler.shared()
        configuration.setURLSchemeHandler(schemeHandler, forURLScheme: WMFURLSchemeHandlerScheme)
        
        let coverView = UIView()
        coverView.backgroundColor = theme.colors.paperBackground

        let contentController = WKUserContentController()
        messagingController = SectionEditorWebViewMessagingController()
        messagingController.textSelectionDelegate = self
        messagingController.buttonSelectionDelegate = self
        let setupUserScript = CodemirrorSetupUserScript(language: language, theme: theme) { [weak self] in
            self?.isCodemirrorReady = true
        }
        
        contentController.addUserScript(setupUserScript)
        contentController.add(setupUserScript, name: setupUserScript.messageHandlerName)
        
        contentController.add(messagingController, name: SectionEditorWebViewMessagingController.Message.Name.selectionChanged)
        contentController.add(messagingController, name: SectionEditorWebViewMessagingController.Message.Name.highlightTheseButtons)

        configuration.userContentController = contentController
        webView = SectionEditorWebView(frame: .zero, configuration: configuration)

        webView.navigationDelegate = self
        webView.wmf_addSubviewWithConstraintsToEdges(coverView)
        webViewCoverView = coverView

        inputViewsController = SectionEditorInputViewsController(webView: webView)
        webView.inputViewsSource = inputViewsController

        webView.translatesAutoresizingMaskIntoConstraints = false
        view.wmf_addSubviewWithConstraintsToEdges(webView)
        
        let url = schemeHandler.appSchemeURL(forRelativeFilePath: "mediawiki-extensions-CodeMirror/codemirror-index.html", fragment: "top")!
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: WKWebViewLoadAssetsHTMLRequestTimeout)
        webView.load(request)
    }

    private func setWikitextToWebViewIfReady() {
        assert(Thread.isMainThread)
        guard isCodemirrorReady, let wikitext = wikitext else {
            return
        }
        setWikitextToWebView(wikitext) { [weak self] (error) in
            if let error = error {
                assertionFailure(error.localizedDescription)
            } else {
                DispatchQueue.main.async {
                    self?.webViewCoverView?.removeFromSuperview()
                    self?.webView.focus()
                    // TODO: Remove
                    self?.progressButton.isEnabled = true
                }
            }
        }
    }
    
    func setWikitextToWebView(_ wikitext: String, completionHandler: ((Error?) -> Void)? = nil) {
        // Can use ES6 backticks ` now instead of 'wmf_stringBySanitizingForJavaScript' with apostrophes.
        // Doing so means we *only* have to escape backticks instead of apostrophes, quotes and line breaks.
        // (May consider switching other native-to-JS messaging to do same later.)
        let escapedWikitext = wikitext.replacingOccurrences(of: "`", with: "\\`", options: .literal, range: nil)
        webView.evaluateJavaScript("window.wmf.setWikitext(`\(escapedWikitext)`);") { (_, error) in
            guard let completionHandler = completionHandler else {
                return
            }
            completionHandler(error)
        }
    }
    
    @objc func getWikitext(completionHandler: ((Any?, Error?) -> Void)? = nil) {
        webView.evaluateJavaScript("window.wmf.getWikitext();", completionHandler: completionHandler)
    }

    private func loadWikitext() {
        guard let section = section else {
            assertionFailure("Section should be set by now")
            return
        }
        let message = WMFLocalizedString("wikitext-downloading", value: "Loading content...", comment: "Alert text shown when obtaining latest revision of the section being edited")
        WMFAlertManager.sharedInstance.showAlert(message, sticky: true, dismissPreviousAlerts: true)
        let manager = QueuesSingleton.sharedInstance()?.sectionWikiTextDownloadManager
        QueuesSingleton.sharedInstance()?.sectionWikiTextDownloadManager.wmf_cancelAllTasks {
            let _ = WikiTextSectionFetcher(andFetchWikiTextFor: section, with: manager, thenNotify: self)
        }
    }

    // MARK: - Navigation actions

    @objc private func close(_ sender: UIBarButtonItem) {
        delegate?.sectionEditorDidFinishEditing(self, withChanges: false)
    }

    @objc private func undo(_ sender: UIBarButtonItem) {
        webView.undo()
    }

    @objc private func redo(_ sender: UIBarButtonItem) {
        webView.redo()
    }

    @objc private func progress(_ sender: UIBarButtonItem) {
        if changesMade {
            getWikitext { (result, error) in
                if let error = error {
                    assertionFailure(error.localizedDescription)
                    return
                } else if let wikitext = result as? String {
                    guard let preview = PreviewAndSaveViewController.wmf_initialViewControllerFromClassStoryboard() else {
                        return
                    }
                    preview.section = self.section
                    preview.wikiText = wikitext
                    preview.delegate = self
                    // TODO: Set funnels
                    // TODO: Apply theme
                    self.navigationController?.pushViewController(preview, animated: true)
                }
            }
        } else {
            let message = WMFLocalizedString("wikitext-preview-changes-none", value: "No changes were made to be previewed.", comment: "Alert text shown if no changes were made to be previewed.")
            WMFAlertManager.sharedInstance.showAlert(message, sticky: false, dismissPreviousAlerts: true)
        }
    }

    // MARK: - Accessibility

    override func accessibilityPerformEscape() -> Bool {
        navigationController?.popViewController(animated: true)
        return true
    }
}

extension SectionEditorViewController: SectionEditorWebViewMessagingControllerTextSelectionDelegate {
    func sectionEditorWebViewMessagingControllerDidReceiveTextSelectionChangeMessage(_ sectionEditorWebViewMessagingController: SectionEditorWebViewMessagingController, isRangeSelected: Bool) {
        undoButton.isEnabled = false
        redoButton.isEnabled = false
        inputViewsController.textSelectionDidChange(isRangeSelected: isRangeSelected)
    }
}

extension SectionEditorViewController: SectionEditorWebViewMessagingControllerButtonSelectionDelegate {
    func sectionEditorWebViewMessagingControllerDidReceiveButtonSelectionChangeMessage(_ sectionEditorWebViewMessagingController: SectionEditorWebViewMessagingController, button: SectionEditorWebViewMessagingController.Button) {
        switch button.kind {
        case .undo:
            undoButton.isEnabled = true
        case .redo:
            redoButton.isEnabled = true
        default:
            break
        }
        inputViewsController.buttonSelectionDidChange(button: button)
    }
}

// MARK: - WKNavigationDelegate

extension SectionEditorViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    }
}

// MARK - PreviewAndSaveViewControllerDelegate

extension SectionEditorViewController: PreviewAndSaveViewControllerDelegate {
    func previewViewControllerDidSave(_ previewViewController: PreviewAndSaveViewController!) {
        delegate?.sectionEditorDidFinishEditing(self, withChanges: true)
    }
}

// MARK: - FetchFinishedDelegate

extension SectionEditorViewController: FetchFinishedDelegate {
    func fetchFinished(_ sender: Any!, fetchedData: Any!, status: FetchFinalStatus, error: Error!) {
        guard sender is WikiTextSectionFetcher else {
            return
        }
        switch status {
        case .FETCH_FINAL_STATUS_SUCCEEDED:
            let fetcher = sender as! WikiTextSectionFetcher
            guard
                let results = fetchedData as? [String: Any],
                let revision = results["revision"] as? String,
                let userInfo = results["userInfo"] as? [String: Any],
                let userID = userInfo["id"] as? NSNumber
            else {
                return
            }

            let editFunnel = EditFunnel(userId: userID.int32Value)
            editFunnel?.logStart()

            if let protectionStatus = fetcher.section.article?.protection,
               let allowedGroups = protectionStatus.allowedGroups(forAction: "edit") as? [String],
                allowedGroups.count > 0 {
                let message: String
                if allowedGroups.contains("autoconfirmed") {
                    message = WMFLocalizedString("page-protected-autoconfirmed", value: "This page has been semi-protected.", comment: "Brief description of Wikipedia 'autoconfirmed' protection level, shown when editing a page that is protected.")
                } else if allowedGroups.contains("sysop") {
                    message = WMFLocalizedString("page-protected-sysop", value: "This page has been fully protected.", comment: "Brief description of Wikipedia 'sysop' protection level, shown when editing a page that is protected.")
                } else {
                    message = WMFLocalizedString("page-protected-other", value: "This page has been protected to the following levels: %1$@", comment: "Brief description of Wikipedia unknown protection level, shown when editing a page that is protected. %1$@ will refer to a list of protection levels.")
                }
                WMFAlertManager.sharedInstance.showAlert(message, sticky: false, dismissPreviousAlerts: true)
            } else {
                WMFAlertManager.sharedInstance.dismissAlert()
            }
            DispatchQueue.main.async {
                self.wikitext = revision
            }
        case .FETCH_FINAL_STATUS_CANCELLED:
            fallthrough
        case .FETCH_FINAL_STATUS_FAILED:
            WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: true)
        }
    }
}

extension SectionEditorViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        webView.apply(theme: theme)
        for case let barButonItem as BarButtonItem in navigationItem.rightBarButtonItems ?? [] {
            barButonItem.apply(theme: theme)
        }
        for case let barButonItem as BarButtonItem in navigationItem.leftBarButtonItems ?? [] {
            barButonItem.apply(theme: theme)
        }
    }
}

// MARK: - Old localized strings

extension SectionEditorViewController {
    // WMFLocalizedStringWithDefaultValue(@"wikitext-download-success", nil, nil, @"Content loaded.", @"Alert text shown when latest revision of the section being edited has been retrieved")
    // WMFLocalizedStringWithDefaultValue(@"wikitext-downloading", nil, nil, @"Loading content...", @"Alert text shown when obtaining latest revision of the section being edited")
}
