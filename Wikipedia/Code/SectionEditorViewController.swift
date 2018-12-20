@objc(WMFSectionEditorViewControllerDelegate)
protocol SectionEditorViewControllerDelegate: class {
    func sectionEditorDidFinishEditing(_ sectionEditor: SectionEditorViewController, withChanges didChange: Bool)
}

@objc(WMFSectionEditorViewController)
class SectionEditorViewController: UIViewController {
    @objc weak var delegate: SectionEditorViewControllerDelegate?
    @objc var section: MWKSection?
    private var webView: SectionEditorWebViewWithEditToolbar!

    private var theme = Theme.standard

    // MARK: - Bar buttons

    private class BarButtonItem: UIBarButtonItem, Themeable {
        var tintColorKeyPath: KeyPath<Theme, UIColor>?

        convenience init(title: String?, style: UIBarButtonItem.Style, target: Any?, action: Selector?, tintColorKeyPath: KeyPath<Theme, UIColor>) {
            self.init(title: title, style: style, target: target, action: action)
            self.tintColorKeyPath = tintColorKeyPath
        }

        convenience init(image: UIImage?, style: UIBarButtonItem.Style, target: Any?, action: Selector?, tintColorKeyPath: KeyPath<Theme, UIColor>) {
            self.init(image: image, style: style, target: target, action: action)
            self.tintColorKeyPath = tintColorKeyPath
        }
        
        func apply(theme: Theme) {
            guard let tintColorKeyPath = tintColorKeyPath else {
                return
            }
            tintColor = theme[keyPath: tintColorKeyPath]
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
        let button = BarButtonItem(image: #imageLiteral(resourceName: "separator"), style: .plain, target: nil, action: nil, tintColorKeyPath: \Theme.colors.primaryText)
        button.isEnabled = false
        return button
    }()

    // TODO
    private var changesMade: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationButtonItems()

        configureWebView()
        apply(theme: theme)

        WMFAuthenticationManager.sharedInstance.loginWithSavedCredentials { (_) in }

        NotificationCenter.default.addObserver(self, selector: #selector(buttonSelectionDidChange(_:)), name: Notification.Name.WMFSectionEditorButtonHighlightNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(textSelectionDidChange(_:)), name: Notification.Name.WMFSectionEditorSelectionChangedNotification, object: nil)
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
            separatorButton,
            redoButton,
            separatorButton,
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
        webView = SectionEditorWebViewWithEditToolbar(theme: self.theme)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
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

    // MARK: - Navigation actions

    @objc private func close(_ sender: UIBarButtonItem) {
        delegate?.sectionEditorDidFinishEditing(self, withChanges: false)
    }

    @objc private func undo(_ sender: UIBarButtonItem) {
        webView.undo(sender)
    }

    @objc private func redo(_ sender: UIBarButtonItem) {
        webView.redo(sender)
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

    // MARK: - Notifications

    @objc private func buttonSelectionDidChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo else {
            return
        }
        guard let message = userInfo[SectionEditorWebViewConfiguration.WMFSectionEditorSelectionChangedSelectedButton] as? ButtonNeedsToBeSelectedMessage else {
            return
        }
        switch message.type {
        case .undo:
            undoButton.isEnabled = true
        case .redo:
            redoButton.isEnabled = true
        default:
            return
        }
    }

    @objc private func textSelectionDidChange(_ notification: Notification) {
        undoButton.isEnabled = false
        redoButton.isEnabled = false
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
                        self.progressButton.isEnabled = true
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
