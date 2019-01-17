@objc(WMFSectionEditorViewControllerDelegate)
protocol SectionEditorViewControllerDelegate: class {
    func sectionEditorDidFinishEditing(_ sectionEditor: SectionEditorViewController, withChanges didChange: Bool)
}

@objc(WMFSectionEditorViewController)
class SectionEditorViewController: UIViewController {
    @objc weak var delegate: SectionEditorViewControllerDelegate?

    @objc var section: MWKSection?

    private var webView: SectionEditorWebView!

    private var inputViewsController: SectionEditorInputViewsController!
    private var messagingController: SectionEditorWebViewMessagingController!
    private var menuItemsController: SectionEditorMenuItemsController!
    private var navigationItemController: SectionEditorNavigationItemController!

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

    // TODO
    private var changesMade: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadWikitext()

        navigationItemController = SectionEditorNavigationItemController(navigationItem: navigationItem)
        navigationItemController.delegate = self

        configureWebView()
        apply(theme: theme)

        WMFAuthenticationManager.sharedInstance.loginWithSavedCredentials { (_) in }
    
        webView.scrollView.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide), name: UIWindow.keyboardDidHideNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        UIMenuController.shared.menuItems = menuItemsController.originalMenuItems
        NotificationCenter.default.removeObserver(self, name: UIWindow.keyboardDidHideNotification, object: nil)
        super.viewWillDisappear(animated)
    }

    @objc func keyboardDidHide() {
        inputViewsController.textFormattingProvidingDidDismissKeyboard()
    }

    private func configureWebView() {
        guard let language = section?.article?.url.wmf_language else {
            return
        }
        
        let configuration = WKWebViewConfiguration()
        let schemeHandler = WMFURLSchemeHandler.shared()
        configuration.setURLSchemeHandler(schemeHandler, forURLScheme: WMFURLSchemeHandlerScheme)

        let contentController = WKUserContentController()
        messagingController = SectionEditorWebViewMessagingController()
        messagingController.textSelectionDelegate = self
        messagingController.buttonSelectionDelegate = self
        let setupUserScript = CodemirrorSetupUserScript(language: language, theme: theme) { [weak self] in
            self?.isCodemirrorReady = true
        }
        
        contentController.addUserScript(setupUserScript)
        contentController.add(setupUserScript, name: setupUserScript.messageHandlerName)
        
        contentController.add(messagingController, name: SectionEditorWebViewMessagingController.Message.Name.codeMirrorMessage)

        configuration.userContentController = contentController
        webView = SectionEditorWebView(frame: .zero, configuration: configuration)

        webView.navigationDelegate = self
        webView.isHidden = true // hidden until wikitext is set
        webView.scrollView.keyboardDismissMode = .interactive

        inputViewsController = SectionEditorInputViewsController(webView: webView, messagingController: messagingController)
        webView.inputViewsSource = inputViewsController

        webView.translatesAutoresizingMaskIntoConstraints = false
        view.wmf_addSubviewWithConstraintsToEdges(webView)
        
        let url = schemeHandler.appSchemeURL(forRelativeFilePath: "codemirror/codemirror-index.html", fragment: "top")!
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: WKWebViewLoadAssetsHTMLRequestTimeout)
        webView.load(request)

        messagingController.webView = webView

        menuItemsController = SectionEditorMenuItemsController(messagingController: messagingController)
        webView.menuItemsDataSource = menuItemsController
        webView.menuItemsDelegate = menuItemsController
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
                    self?.messagingController.focus()
                    self?.webView.isHidden = false
                }
            }
        }
    }
    
    func setWikitextToWebView(_ wikitext: String, completionHandler: ((Error?) -> Void)? = nil) {
        // Can use ES6 backticks ` now instead of 'wmf_stringBySanitizingForJavaScript' with apostrophes.
        // Doing so means we *only* have to escape backtick, '{', and '}'. Escaping '{' and '}' is needed for handling ES6 template literals.
        // Benefit vs. current 'wmf_stringBySanitizingForJavaScript' with apostrophes approach is no need to escape apostrophes, quotes and line breaks.
        // (May consider switching other native-to-JS messaging to do same later.)
        let escapedWikitext = wikitext.replacingOccurrences(of: "([{}\\`])", with: "\\\\$1", options: .regularExpression)

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

    // MARK: - Accessibility

    override func accessibilityPerformEscape() -> Bool {
        navigationController?.popViewController(animated: true)
        return true
    }
    
    // MARK: - Docking `inputAccessoryView` at bottom of screen when keyboard is hidden.

    override var inputAccessoryView: UIView? {
        // In conjunction with overriding `canBecomeFirstResponder` to be true, this override
        // allows `inputViewsController.inputAccessoryView` to dock at bottom of screen when
        // the keyboard is dismissed.
        return inputViewsController.inputAccessoryView
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
}

private var previousAdjustedContentInset = UIEdgeInsets.zero
extension SectionEditorViewController: UIScrollViewDelegate {
    public func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
        let newAdjustedContentInset = scrollView.adjustedContentInset
        guard newAdjustedContentInset != previousAdjustedContentInset else {
            return
        }
        previousAdjustedContentInset = newAdjustedContentInset
        messagingController.setAdjustedContentInset(newInset: newAdjustedContentInset)
    }
}

extension SectionEditorViewController: SectionEditorNavigationItemControllerDelegate {
    func sectionEditorNavigationItemController(_ sectionEditorNavigationItemController: SectionEditorNavigationItemController, didTapProgressButton progressButton: UIBarButtonItem) {
        if changesMade {
            messagingController.getWikitext { (result, error) in
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

    func sectionEditorNavigationItemController(_ sectionEditorNavigationItemController: SectionEditorNavigationItemController, didTapCloseButton closeButton: UIBarButtonItem) {
        delegate?.sectionEditorDidFinishEditing(self, withChanges: false)
    }

    func sectionEditorNavigationItemController(_ sectionEditorNavigationItemController: SectionEditorNavigationItemController, didTapUndoButton undoButton: UIBarButtonItem) {
        messagingController.undo()
    }

    func sectionEditorNavigationItemController(_ sectionEditorNavigationItemController: SectionEditorNavigationItemController, didTapRedoButton redoButton: UIBarButtonItem) {
        messagingController.redo()
    }
}

extension SectionEditorViewController: SectionEditorWebViewMessagingControllerTextSelectionDelegate {
    func sectionEditorWebViewMessagingControllerDidReceiveTextSelectionChangeMessage(_ sectionEditorWebViewMessagingController: SectionEditorWebViewMessagingController, isRangeSelected: Bool) {
        navigationItemController.textSelectionDidChange(isRangeSelected: isRangeSelected)
        inputViewsController.textSelectionDidChange(isRangeSelected: isRangeSelected)
    }
}

extension SectionEditorViewController: SectionEditorWebViewMessagingControllerButtonMessageDelegate {
    func sectionEditorWebViewMessagingControllerDidReceiveSelectButtonMessage(_ sectionEditorWebViewMessagingController: SectionEditorWebViewMessagingController, button: SectionEditorWebViewMessagingController.Button) {
        inputViewsController.buttonSelectionDidChange(button: button)
    }
    func sectionEditorWebViewMessagingControllerDidReceiveDisableButtonMessage(_ sectionEditorWebViewMessagingController: SectionEditorWebViewMessagingController, button: SectionEditorWebViewMessagingController.Button) {
        navigationItemController.disableButton(button: button)
        inputViewsController.disableButton(button: button)
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
        webView.scrollView.backgroundColor = theme.colors.paperBackground
        webView.backgroundColor = theme.colors.paperBackground
        inputViewsController.apply(theme: theme)
        navigationItemController.apply(theme: theme)
    }
}

// MARK: - Old localized strings

extension SectionEditorViewController {
    // WMFLocalizedStringWithDefaultValue(@"wikitext-download-success", nil, nil, @"Content loaded.", @"Alert text shown when latest revision of the section being edited has been retrieved")
    // WMFLocalizedStringWithDefaultValue(@"wikitext-downloading", nil, nil, @"Loading content...", @"Alert text shown when obtaining latest revision of the section being edited")
}
