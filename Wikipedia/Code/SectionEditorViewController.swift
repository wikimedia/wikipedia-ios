@objc(WMFSectionEditorViewControllerDelegate)
protocol SectionEditorViewControllerDelegate: class {
    func sectionEditorDidFinishEditing(_ sectionEditor: SectionEditorViewController, withChanges didChange: Bool)
}

@objc(WMFSectionEditorViewController)
class SectionEditorViewController: UIViewController {
    @objc weak var delegate: SectionEditorViewControllerDelegate?
    @objc var section: MWKSection?
    private var webView: SectionEditorWebViewWithEditToolbar!
    private var webViewCover: UIView = UIView()
    private var rightButton: UIBarButtonItem?

    private var theme = Theme.standard

    private lazy var closeButton: UIBarButtonItem = {
        let button = UIBarButtonItem.wmf_buttonType(.X, target: self, action: #selector(close(_:)))
        button.accessibilityLabel = CommonStrings.accessibilityBackTitle
        return button
    }()

    private lazy var progressButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: CommonStrings.nextTitle, style: .done, target: self, action: #selector(progress(_:)))
        return button
    }()

    // TODO
    private var changesMade: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = closeButton
        navigationItem.rightBarButtonItem = progressButton
        enableProgressButton(false)

        configureWebView()
        view.wmf_addSubviewWithConstraintsToEdges(webViewCover)
        apply(theme: theme)

        WMFAuthenticationManager.sharedInstance.loginWithSavedCredentials { (_) in }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        enableProgressButton(changesMade)
    }

    override func viewWillDisappear(_ animated: Bool) {
        enableProgressButton(false)
        UIMenuController.shared.menuItems = webView.originalMenuItems
        super.viewWillDisappear(animated)
    }

    private func configureWebView() {
        webView = SectionEditorWebViewWithEditToolbar(theme: self.theme)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.config.eventDelegate = self
        view.wmf_addSubviewWithConstraintsToEdges(webView)
        webView.configureInputAccessoryViews()
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

    @objc private func close(_ sender: UIBarButtonItem) {
        delegate?.sectionEditorDidFinishEditing(self, withChanges: false)
    }

    @objc private func progress(_ sender: UIBarButtonItem) {
        if changesMade {
            webView.getWikitext { (result, error) in
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

    private func enableProgressButton(_ enabled: Bool) {
        progressButton.isEnabled = enabled
    }

    // MARK: - Accessibility

    override func accessibilityPerformEscape() -> Bool {
        navigationController?.popViewController(animated: true)
        return true
    }
}

// MARK: - WKNavigationDelegate

extension SectionEditorViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadWikitext()
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

            self.webView.setup(wikitext: revision) { (error) in
                if let error = error {
                    assertionFailure(error.localizedDescription)
                } else {
                    DispatchQueue.main.async {
                        self.webView.focus(self)
                        // TODO: Remove
                        self.enableProgressButton(true)
                    }
                }
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
        guard viewIfLoaded != nil else {
            self.theme = theme
            return
        }
        webViewCover.backgroundColor = theme.colors.paperBackground
        progressButton.tintColor = theme.colors.link
        view.backgroundColor = theme.colors.paperBackground
        webView.apply(theme: theme)
    }
}

// MARK: - Old localized strings

extension SectionEditorViewController {
    // WMFLocalizedStringWithDefaultValue(@"wikitext-download-success", nil, nil, @"Content loaded.", @"Alert text shown when latest revision of the section being edited has been retrieved")
    // WMFLocalizedStringWithDefaultValue(@"wikitext-downloading", nil, nil, @"Loading content...", @"Alert text shown when obtaining latest revision of the section being edited")
}

extension SectionEditorViewController: SectionEditorWebViewEventDelegate {
    func handleEvent(_ type: SectionEditorWebViewEventType, userInfo: [String : Any]) {
        switch type {
        case .atDocumentStart:
            let js =
            """
            var css = 'body, .CodeMirror { background: #\(theme.colors.paperBackground.wmf_hexString); }';
            var style = document.createElement('style');
            style.type = 'text/css';
            style.innerText = css;
            document.head.appendChild(style);
            """
            webView.evaluateJavaScript(js)
        case .atDocumentEnd:
            let js =
            """
            document.getElementById('codemirror-theme').setAttribute('href', 'codemirror-\(theme.codemirrorName).css');
            """
            webView.evaluateJavaScript(js) { (obj, error) in
                assert(error == nil)
                DispatchQueue.main.async {
                    self.webViewCover.removeFromSuperview()
                }
            }
        }
    }
}
