@objc(WMFSectionEditorViewControllerDelegate)
protocol SectionEditorViewControllerDelegate: class {
    func sectionEditorDidFinishEditing(_ sectionEditor: SectionEditorViewController, withChanges didChange: Bool)
    func sectionEditorDidFinishLoadingWikitext(_ sectionEditor: SectionEditorViewController)
}

@objc(WMFSectionEditorViewController)
class SectionEditorViewController: UIViewController {
    @objc weak var delegate: SectionEditorViewControllerDelegate?
    
    @objc var section: MWKSection?
    @objc var selectedTextEditInfo: SelectedTextEditInfo?
    
    private var webView: SectionEditorWebView!
    private let sectionFetcher = WikiTextSectionFetcher()
    
    private var inputViewsController: SectionEditorInputViewsController!
    private var messagingController: SectionEditorWebViewMessagingController!
    private var menuItemsController: SectionEditorMenuItemsController!
    private var navigationItemController: SectionEditorNavigationItemController!
    
    lazy var readingThemesControlsViewController: ReadingThemesControlsViewController = {
        return ReadingThemesControlsViewController.init(nibName: ReadingThemesControlsViewController.nibName, bundle: nil)
    }()
    
    private lazy var focusNavigationView: FocusNavigationView = {
        return FocusNavigationView.wmf_viewFromClassNib()
    }()
    private var webViewTopConstraint: NSLayoutConstraint!
    
    private var theme = Theme.standard

    private var didFocusWebViewCompletion: (() -> Void)?
    
    private var needsSelectLastSelection: Bool = false
    
    @objc var editFunnel: EditFunnel?
    
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
    
    private let findAndReplaceHeaderTitle = WMFLocalizedString("find-replace-header", value: "Find and replace", comment: "Find and replace header title.")
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.messagingController  = SectionEditorWebViewMessagingController()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    init(messagingController: SectionEditorWebViewMessagingController = SectionEditorWebViewMessagingController()) {
        self.messagingController = messagingController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        
        setupFocusNavigationView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide), name: UIWindow.keyboardDidHideNotification, object: nil)
        selectLastSelectionIfNeeded()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        UIMenuController.shared.menuItems = menuItemsController.originalMenuItems
        NotificationCenter.default.removeObserver(self, name: UIWindow.keyboardDidHideNotification, object: nil)
        super.viewWillDisappear(animated)
    }
    
    @objc func keyboardDidHide() {
        inputViewsController.resetFormattingAndStyleSubmenus()
    }
    
    private func setupFocusNavigationView() {

        let closeAccessibilityText = WMFLocalizedString("find-replace-header-close-accessibility", value: "Close find and replace", comment: "Accessibility label for closing the find and replace view.")
        
        focusNavigationView.configure(titleText: findAndReplaceHeaderTitle, closeButtonAccessibilityText: closeAccessibilityText, traitCollection: traitCollection)
        
        focusNavigationView.isHidden = true
        focusNavigationView.delegate = self
        focusNavigationView.apply(theme: theme)
        
        focusNavigationView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(focusNavigationView)
        
        let leadingConstraint = view.leadingAnchor.constraint(equalTo: focusNavigationView.leadingAnchor)
        let trailingConstraint = view.trailingAnchor.constraint(equalTo: focusNavigationView.trailingAnchor)
        let topConstraint = view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: focusNavigationView.topAnchor)
        
        NSLayoutConstraint.activate([leadingConstraint, trailingConstraint, topConstraint])
    }
    
    private func showFocusNavigationView() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        webViewTopConstraint.constant = -focusNavigationView.frame.height
        focusNavigationView.isHidden = false
        
    }
    
    private func hideFocusNavigationView() {
        webViewTopConstraint.constant = 0
        focusNavigationView.isHidden = true
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    private func configureWebView() {
        guard let language = section?.article?.url.wmf_language else {
            return
        }
        
        let configuration = WKWebViewConfiguration()
        let schemeHandler = SchemeHandler.shared
        configuration.setURLSchemeHandler(schemeHandler, forURLScheme: schemeHandler.scheme)
        let textSizeAdjustment = UserDefaults.wmf.wmf_articleFontSizeMultiplier().intValue
        let contentController = WKUserContentController()

        messagingController.textSelectionDelegate = self
        messagingController.buttonSelectionDelegate = self
        messagingController.alertDelegate = self
        messagingController.scrollDelegate = self
        let languageInfo = MWLanguageInfo(forCode: language)
        let isSyntaxHighlighted = UserDefaults.wmf.wmf_IsSyntaxHighlightingEnabled
        let setupUserScript = CodemirrorSetupUserScript(language: language, direction: CodemirrorSetupUserScript.CodemirrorDirection(rawValue: languageInfo.dir) ?? .ltr, theme: theme, textSizeAdjustment: textSizeAdjustment, isSyntaxHighlighted: isSyntaxHighlighted) { [weak self] in
            self?.isCodemirrorReady = true
        }
        
        contentController.addUserScript(setupUserScript)
        contentController.add(setupUserScript, name: setupUserScript.messageHandlerName)
        
        contentController.add(messagingController, name: SectionEditorWebViewMessagingController.Message.Name.codeMirrorMessage)
        contentController.add(messagingController, name: SectionEditorWebViewMessagingController.Message.Name.codeMirrorSearchMessage)
        
        contentController.add(messagingController, name: SectionEditorWebViewMessagingController.Message.Name.smoothScrollToYOffsetMessage)
        contentController.add(messagingController, name: SectionEditorWebViewMessagingController.Message.Name.replaceAllCountMessage)
        
        configuration.userContentController = contentController
        webView = SectionEditorWebView(frame: .zero, configuration: configuration)
        
        webView.navigationDelegate = self
        webView.isHidden = true // hidden until wikitext is set
        webView.scrollView.keyboardDismissMode = .interactive
        
        inputViewsController = SectionEditorInputViewsController(webView: webView, messagingController: messagingController, findAndReplaceDisplayDelegate: self)
        
        webView.inputViewsSource = inputViewsController
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        
        let leadingConstraint = view.leadingAnchor.constraint(equalTo: webView.leadingAnchor)
        let trailingConstraint = view.trailingAnchor.constraint(equalTo: webView.trailingAnchor)
        webViewTopConstraint = view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: webView.topAnchor)
        let bottomConstraint = view.bottomAnchor.constraint(equalTo: webView.bottomAnchor)
        
        NSLayoutConstraint.activate([leadingConstraint, trailingConstraint, webViewTopConstraint, bottomConstraint])
        
        if let url = SchemeHandler.FileHandler.appSchemeURL(for: "codemirror/codemirror-index.html", fragment: "top") {
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: WKWebViewLoadAssetsHTMLRequestTimeout)
            webView.load(request)
            
            messagingController.webView = webView
            
            menuItemsController = SectionEditorMenuItemsController(messagingController: messagingController)
            webView.menuItemsDataSource = menuItemsController
            webView.menuItemsDelegate = menuItemsController
        }
    }

    @objc var shouldFocusWebView = true {
        didSet {
            guard shouldFocusWebView else {
                return
            }
            focusWebViewIfReady()
        }
    }

    private var didSetWikitextToWebView: Bool = false {
        didSet {
            guard shouldFocusWebView else {
                return
            }
            focusWebViewIfReady()
        }
    }
    
    private func selectLastSelectionIfNeeded() {
        
        guard isCodemirrorReady,
            shouldFocusWebView,
            didSetWikitextToWebView,
            needsSelectLastSelection,
            wikitext != nil else {
            return
        }
        
        messagingController.selectLastSelection()
        messagingController.focusWithoutScroll()
        needsSelectLastSelection = false
    }
    
    private func showCouldNotFindSelectionInWikitextAlert() {
        let alertTitle = WMFLocalizedString("edit-menu-item-could-not-find-selection-alert-title", value:"The text that you selected could not be located", comment:"Title for alert informing user their text selection could not be located in the article wikitext.")
        let alertMessage = WMFLocalizedString("edit-menu-item-could-not-find-selection-alert-message", value:"This might be because the text you selected is not editable (eg. article title or infobox titles) or the because of the length of the text that was highlighted", comment:"Description of possible reasons the user text selection could not be located in the article wikitext.")
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: CommonStrings.okTitle, style:.default, handler: nil))
        present(alert, animated: true, completion: nil)
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
                    self?.didSetWikitextToWebView = true
                    if let selectedTextEditInfo = self?.selectedTextEditInfo {
                        self?.messagingController.highlightAndScrollToText(for: selectedTextEditInfo){ [weak self] (error) in
                            if let _ = error {
                                self?.showCouldNotFindSelectionInWikitextAlert()
                            }
                        }
                    }
                }
            }
        }
    }

    private func focusWebViewIfReady() {
        guard didSetWikitextToWebView else {
            return
        }
        messagingController.focus()
        webView.isHidden = false
        dispatchOnMainQueueAfterDelayInSeconds(0.5) { [weak self] in
            
            guard let self = self else { return }
            
            self.delegate?.sectionEditorDidFinishLoadingWikitext(self)
            
            guard let didFocusWebViewCompletion = self.didFocusWebViewCompletion else {
                return
            }
            
            didFocusWebViewCompletion()
            self.didFocusWebViewCompletion = nil
        }
    }
    
    func setWikitextToWebView(_ wikitext: String, completionHandler: ((Error?) -> Void)? = nil) {
        messagingController.setWikitext(wikitext, completionHandler: completionHandler)
    }
    
    private func loadWikitext() {
        guard let section = section else {
            assertionFailure("Section should be set by now")
            return
        }
        if shouldFocusWebView {
            let message = WMFLocalizedString("wikitext-downloading", value: "Loading content...", comment: "Alert text shown when obtaining latest revision of the section being edited")
            WMFAlertManager.sharedInstance.showAlert(message, sticky: true, dismissPreviousAlerts: true)
        }
        sectionFetcher.fetch(section) { (result, error) in
            DispatchQueue.main.async {
                if let error = error {
                    self.didFocusWebViewCompletion = {
                        WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: true)
                    }
                    return
                }
                guard
                    let results = result as? [String: Any],
                    let revision = results["revision"] as? String
                    else {
                        return
                }
                
                self.editFunnel?.logStart(section.article?.url.wmf_language)

                if let protectionStatus = section.article?.protection,
                    let allowedGroups = protectionStatus.allowedGroups(forAction: "edit") as? [String],
                    !allowedGroups.isEmpty {
                    let message: String
                    if allowedGroups.contains("autoconfirmed") {
                        message = WMFLocalizedString("page-protected-autoconfirmed", value: "This page has been semi-protected.", comment: "Brief description of Wikipedia 'autoconfirmed' protection level, shown when editing a page that is protected.")
                    } else if allowedGroups.contains("sysop") {
                        message = WMFLocalizedString("page-protected-sysop", value: "This page has been fully protected.", comment: "Brief description of Wikipedia 'sysop' protection level, shown when editing a page that is protected.")
                    } else {
                        message = WMFLocalizedString("page-protected-other", value: "This page has been protected to the following levels: %1$@", comment: "Brief description of Wikipedia unknown protection level, shown when editing a page that is protected. %1$@ will refer to a list of protection levels.")
                    }
                    self.didFocusWebViewCompletion = {
                        WMFAlertManager.sharedInstance.showAlert(message, sticky: false, dismissPreviousAlerts: true)
                    }
                } else {
                    self.didFocusWebViewCompletion = {
                        WMFAlertManager.sharedInstance.dismissAlert()
                    }
                }
                
                self.wikitext = revision
            }
        }
    }
    
    // MARK: - Accessibility
    
    override func accessibilityPerformEscape() -> Bool {
        navigationController?.popViewController(animated: true)
        return true
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { (_) in
            self.inputViewsController.didTransitionToNewCollection()
            self.focusNavigationView.updateLayout(for: newCollection)
        }
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
        messagingController.getWikitext { [weak self] (result, error) in
            guard let self = self else { return }
            if let error = error {
                assertionFailure(error.localizedDescription)
                return
            } else if let wikitext = result {
                if wikitext != self.wikitext {
                    guard let vc = EditPreviewViewController.wmf_initialViewControllerFromClassStoryboard() else {
                        return
                    }
                    self.inputViewsController.resetFormattingAndStyleSubmenus()
                    self.needsSelectLastSelection = true
                    vc.theme = self.theme
                    vc.section = self.section
                    vc.wikitext = wikitext
                    vc.delegate = self
                    vc.funnel = self.editFunnel
                    self.navigationController?.pushViewController(vc, animated: true)
                } else {
                    let message = WMFLocalizedString("wikitext-preview-changes-none", value: "No changes were made to be previewed.", comment: "Alert text shown if no changes were made to be previewed.")
                    WMFAlertManager.sharedInstance.showAlert(message, sticky: false, dismissPreviousAlerts: true)
                }
            }
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
    
    func sectionEditorNavigationItemController(_ sectionEditorNavigationItemController: SectionEditorNavigationItemController, didTapReadingThemesControlsButton readingThemesControlsButton: UIBarButtonItem) {
        
        webView.resignFirstResponder()
        inputViewsController.suppressMenus = true
        
        showReadingThemesControlsPopup(on: self, responder: self, theme: theme)
    }
}

extension SectionEditorViewController: SectionEditorWebViewMessagingControllerTextSelectionDelegate {
    func sectionEditorWebViewMessagingControllerDidReceiveTextSelectionChangeMessage(_ sectionEditorWebViewMessagingController: SectionEditorWebViewMessagingController, isRangeSelected: Bool) {
        navigationItemController.textSelectionDidChange(isRangeSelected: isRangeSelected)
        inputViewsController.textSelectionDidChange(isRangeSelected: isRangeSelected)
    }
}

extension SectionEditorViewController: SectionEditorWebViewMessagingControllerButtonMessageDelegate {
    func sectionEditorWebViewMessagingControllerDidReceiveSelectButtonMessage(_ sectionEditorWebViewMessagingController: SectionEditorWebViewMessagingController, button: SectionEditorButton) {
        inputViewsController.buttonSelectionDidChange(button: button)
    }
    func sectionEditorWebViewMessagingControllerDidReceiveDisableButtonMessage(_ sectionEditorWebViewMessagingController: SectionEditorWebViewMessagingController, button: SectionEditorButton) {
        navigationItemController.disableButton(button: button)
        inputViewsController.disableButton(button: button)
    }
}

extension SectionEditorViewController: SectionEditorWebViewMessagingControllerAlertDelegate {
    func sectionEditorWebViewMessagingControllerDidReceiveReplaceAllMessage(_ sectionEditorWebViewMessagingController: SectionEditorWebViewMessagingController, replacedCount: Int) {
        
        let format =  WMFLocalizedString("replace-replace-all-results-count", value: "{{PLURAL:%1$d|%1$d item replaced|%1$d items replaced}}", comment: "Alert view label that tells the user how many instances they just replaced via \"Replace all\". %1$d is replaced with the number of instances that were replaced.")
        let alertText = String.localizedStringWithFormat(format, replacedCount)
        wmf_showAlertWithMessage(alertText)
    }
}

extension SectionEditorViewController: FindAndReplaceKeyboardBarDisplayDelegate {
    func keyboardBarDidHide(_ keyboardBar: FindAndReplaceKeyboardBar) {
        hideFocusNavigationView()
    }
    
    func keyboardBarDidShow(_ keyboardBar: FindAndReplaceKeyboardBar) {
        showFocusNavigationView()
    }
    
    func keyboardBarDidTapReplaceSwitch(_ keyboardBar: FindAndReplaceKeyboardBar) {
        
        let alertController = UIAlertController(title: findAndReplaceHeaderTitle, message: nil, preferredStyle: .actionSheet)
        let replaceAllActionTitle = WMFLocalizedString("action-replace-all", value: "Replace all", comment: "Title of the replace all action.")
        let replaceActionTitle = WMFLocalizedString("action-replace", value: "Replace", comment: "Title of the replace all action.")
        
        let replaceAction = UIAlertAction(title: replaceActionTitle, style: .default) { (_) in
            self.inputViewsController.updateReplaceType(type: .replaceSingle)
        }
        let replaceAllAction = UIAlertAction(title: replaceAllActionTitle, style: .default) { (_) in
            self.inputViewsController.updateReplaceType(type: .replaceAll)
        }
        let cancelAction = UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel, handler: nil)
        alertController.addAction(replaceAction)
        alertController.addAction(replaceAllAction)
        alertController.addAction(cancelAction)
        alertController.popoverPresentationController?.sourceView = keyboardBar.replaceSwitchButton
        alertController.popoverPresentationController?.sourceRect = keyboardBar.replaceSwitchButton.bounds
        
        present(alertController, animated: true, completion: nil)
    }
}


// MARK: - WKNavigationDelegate

extension SectionEditorViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    }
}

// MARK - EditSaveViewControllerDelegate

extension SectionEditorViewController: EditSaveViewControllerDelegate {
    func editSaveViewControllerDidSave(_ editSaveViewController: EditSaveViewController) {
        delegate?.sectionEditorDidFinishEditing(self, withChanges: true)
    }
}

// MARK - EditPreviewViewControllerDelegate

extension SectionEditorViewController: EditPreviewViewControllerDelegate {
    func editPreviewViewControllerDidTapNext(_ editPreviewViewController: EditPreviewViewController) {
        guard let vc = EditSaveViewController.wmf_initialViewControllerFromClassStoryboard() else {
            return
        }
        vc.section = self.section
        vc.wikitext = editPreviewViewController.wikitext
        vc.delegate = self
        vc.theme = self.theme
        vc.funnel = self.editFunnel
        self.navigationController?.pushViewController(vc, animated: true)
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
        messagingController.applyTheme(theme: theme)
        inputViewsController.apply(theme: theme)
        navigationItemController.apply(theme: theme)
        apply(presentationTheme: theme)
        focusNavigationView.apply(theme: theme)
    }
}

extension SectionEditorViewController: ReadingThemesControlsPresenting {
    
    var shouldPassthroughNavBar: Bool {
        return false
    }
    
    var showsSyntaxHighlighting: Bool {
        return true
    }
    
    var readingThemesControlsToolbarItem: UIBarButtonItem {
        return self.navigationItemController.readingThemesControlsToolbarItem
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        inputViewsController.suppressMenus = false
    }
}

extension SectionEditorViewController: ReadingThemesControlsResponding {
    func updateWebViewTextSize(textSize: Int) {
        messagingController.scaleBodyText(newSize: String(textSize))
    }
    
    func toggleSyntaxHighlighting(_ controller: ReadingThemesControlsViewController) {
        messagingController.toggleSyntaxColors()
    }
}

extension SectionEditorViewController: FocusNavigationViewDelegate {
    func focusNavigationViewDidTapClose(_ focusNavigationView: FocusNavigationView) {
        hideFocusNavigationView()
        inputViewsController.closeFindAndReplace()
    }
}

extension SectionEditorViewController: SectionEditorWebViewMessagingControllerScrollDelegate {
    func sectionEditorWebViewMessagingController(_ sectionEditorWebViewMessagingController: SectionEditorWebViewMessagingController, didReceiveScrollMessageWithNewContentOffset newContentOffset: CGPoint) {
        guard presentedViewController == nil else {
            return
        }
        webView.scrollView.setContentOffset(newContentOffset, animated: true)
    }
}

#if (TEST)
//MARK: Helpers for testing
extension SectionEditorViewController {
    func openFindAndReplaceForTesting() {
        inputViewsController.textFormattingProvidingDidTapFindInPage()
    }
    
    var webViewForTesting: WKWebView {
        return webView
    }
    
    var findAndReplaceViewForTesting: FindAndReplaceKeyboardBar? {
        return inputViewsController.findAndReplaceViewForTesting
    }
}
#endif
