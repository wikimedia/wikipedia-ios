@objc(WMFSectionEditorViewControllerDelegate)
protocol SectionEditorViewControllerDelegate: class {
    func sectionEditorDidFinishEditing(_ sectionEditor: SectionEditorViewController, withChanges didChange: Bool)
}

@objc(WMFSectionEditorViewController)
class SectionEditorViewController: UIViewController {
    @objc weak var delegate: SectionEditorViewControllerDelegate?
    @objc var section: MWKSection?
    private var webView: SectionEditorWebView!

    private var unmodifiedWikiText: String?
    private var viewKeyboardRect = CGRect.null
    private var rightButton: UIBarButtonItem?

    private var theme = Theme.standard

    private lazy var closeButton: UIBarButtonItem = {
        let button = UIBarButtonItem.wmf_buttonType(.X, target: self, action: #selector(close(_:)))
        button.accessibilityLabel = CommonStrings.accessibilityBackTitle
        return button
    }()

    private lazy var progressButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: CommonStrings.nextTitle, style: .plain, target: self, action: #selector(progress(_:)))
        return button
    }()

    private var changesMade: Bool {
        guard let unmodifiedWikiText = unmodifiedWikiText else {
            return false
        }
        return true
        //return !(unmodifiedWikiText == textView.text)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = closeButton
        navigationItem.rightBarButtonItem = progressButton
        enableProgressButton(false)

        configureWebView()

        apply(theme: theme)

        WMFAuthenticationManager.sharedInstance.loginWithSavedCredentials { (_) in }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        registerForKeyboardNotifications()
        enableProgressButton(changesMade)
    }

    override func viewWillDisappear(_ animated: Bool) {
        enableProgressButton(false)
        UIMenuController.shared.menuItems = webView.originalMenuItems
        super.viewWillDisappear(animated)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func configureWebView() {
        webView = SectionEditorWebView()
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
                    // set funnels
                    // apply theme
                    self.navigationController?.pushViewController(preview, animated: true)
                }
            }
        } else {
            let message = WMFLocalizedString("wikitext-preview-changes-none", value: "No changes were made to be previewed", comment: "Alert text shown if no changes were made to be previewed.")
            WMFAlertManager.sharedInstance.showAlert(message, sticky: false, dismissPreviousAlerts: true)
        }
    }

    private func enableProgressButton(_ enabled: Bool) {
        progressButton.isEnabled = enabled
    }

    private func scrollTextViewSoCursorNotUnderKeyboard(_ textView: UITextView) {
        guard
            !viewKeyboardRect.isNull,
            let textPosition = textView.selectedTextRange?.start
        else {
            return
        }

        let cursorRectInTextView = textView.caretRect(for: textPosition)
        let cursorRectInView = textView.convert(cursorRectInTextView, to: view)

        guard viewKeyboardRect.intersects(cursorRectInView) else {
            return
        }

        // Margin here is the amount the cursor will be scrolled above the top of the keyboard.
        let margin: CGFloat = -20
        let newCursorRect = cursorRectInTextView.insetBy(dx: 0, dy: margin)

        textView.scrollRectToVisible(newCursorRect, animated: true)
    }

    // MARK: - Keyboard

    // Ensure the edit text view can scroll whatever text it is displaying all the
    // way so the bottom of the text can be scrolled to the top of the screen.
    // More info here:
    // https://developer.apple.com/library/ios/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/KeyboardManagement/KeyboardManagement.html

    private func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardDidShow(_ notification: NSNotification) {
        guard let info = notification.userInfo else {
            return
        }

        guard let keyboardFrameEnd = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }

        let windowKeyboardRect = keyboardFrameEnd.cgRectValue
        guard let viewKeyboardRect = view.window?.convert(windowKeyboardRect, to: view) else {
            return
        }

        self.viewKeyboardRect = viewKeyboardRect

        // This makes it so you can always scroll to the bottom of the text view's text
        // even if the keyboard is onscreen.
        let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: viewKeyboardRect.size.height, right: 0)
        setTextViewContentInset(contentInset)

        // Mark the text view as needing a layout update so the inset changes above will
        // be taken in to account when the cursor is scrolled onscreen.
        webView.setNeedsLayout()
        webView.layoutIfNeeded()

        // Scroll cursor onscreen if needed.
        //scrollTextViewSoCursorNotUnderKeyboard(textView)
    }

    @objc private func keyboardWillHide(_ notification: NSNotification) {
        setTextViewContentInset(UIEdgeInsets.zero)
    }

    private func setTextViewContentInset(_ contentInset: UIEdgeInsets) {
        webView.scrollView.contentInset = contentInset
        webView.scrollView.scrollIndicatorInsets = contentInset

        viewKeyboardRect = CGRect.null
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

            unmodifiedWikiText = revision

            self.webView.setup(wikitext: revision, useRichEditor: true) { (error) in
                if let error = error {
                    assertionFailure(error.localizedDescription)
                } else {
                    DispatchQueue.main.async {
                        self.webView.becomeFirstResponder()
                        self.enableProgressButton(self.changesMade)
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
    }
}
