import CocoaLumberjackSwift

protocol SectionEditorViewControllerDelegate: class {
    func sectionEditorDidCancelEditing(_ sectionEditor: SectionEditorViewController)
    func sectionEditorDidFinishEditing(_ sectionEditor: SectionEditorViewController, result: Result<SectionEditorChanges, Error>)
    func sectionEditorDidFinishLoadingWikitext(_ sectionEditor: SectionEditorViewController)
}

@objc(WMFSectionEditorViewController)
class SectionEditorViewController: ViewController {
    @objc public static let editWasPublished = NSNotification.Name(rawValue: "EditWasPublished")

    weak var delegate: SectionEditorViewControllerDelegate?
    
    private let sectionID: Int
    private let articleURL: URL
    private let language: String
    
    private var selectedTextEditInfo: SelectedTextEditInfo?
    private var dataStore: MWKDataStore

    private var webView: SectionEditorWebView!
    private let sectionFetcher = SectionFetcher()
    
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
    
    private var didFocusWebViewCompletion: (() -> Void)?
    
    private var needsSelectLastSelection: Bool = false
    
    @objc var editFunnel = EditFunnel.shared
    

    private var isInFindReplaceActionSheetMode = false
    
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
    
    struct ScriptMessageHandler {
        let handler: WKScriptMessageHandler
        let name: String
    }
    
    private var scriptMessageHandlers: [ScriptMessageHandler] = []
    
    private let findAndReplaceHeaderTitle = WMFLocalizedString("find-replace-header", value: "Find and replace", comment: "Find and replace header title.")
    
    init(articleURL: URL, sectionID: Int, messagingController: SectionEditorWebViewMessagingController? = nil, dataStore: MWKDataStore, selectedTextEditInfo: SelectedTextEditInfo? = nil, theme: Theme = Theme.standard) {
        self.articleURL = articleURL
        self.sectionID = sectionID
        self.dataStore = dataStore
        self.selectedTextEditInfo = selectedTextEditInfo
        self.messagingController = messagingController ?? SectionEditorWebViewMessagingController()
        language = articleURL.wmf_language ?? NSLocale.current.languageCode ?? "en"
        super.init(theme: theme)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        loadWikitext()
        
        navigationItemController = SectionEditorNavigationItemController(navigationItem: navigationItem)
        navigationItemController.delegate = self
        
        configureWebView()
        
        dataStore.authenticationManager.loginWithSavedCredentials { (_) in }
        
        webView.scrollView.delegate = self
        scrollView = webView.scrollView

        setupFocusNavigationView()
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        selectLastSelectionIfNeeded()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        UIMenuController.shared.menuItems = menuItemsController.originalMenuItems
        super.viewWillDisappear(animated)
    }
    
    deinit {
        removeScriptMessageHandlers()
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
    
    private func removeScriptMessageHandlers() {
        
        guard let userContentController = webView?.configuration.userContentController else {
            return
        }
        
        for handler in scriptMessageHandlers {
            userContentController.removeScriptMessageHandler(forName: handler.name)
        }
        
        scriptMessageHandlers.removeAll()
    }
    
    private func addScriptMessageHandlers(to contentController: WKUserContentController) {
        
        for handler in scriptMessageHandlers {
            contentController.add(handler.handler, name: handler.name)
        }
    }
    
    private func configureWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        let textSizeAdjustment = UserDefaults.standard.wmf_articleFontSizeMultiplier().intValue
        let contentController = WKUserContentController()

        messagingController.textSelectionDelegate = self
        messagingController.buttonSelectionDelegate = self
        messagingController.alertDelegate = self
        messagingController.scrollDelegate = self
        let layoutDirection = MWKLanguageLinkController.layoutDirection(forContentLanguageCode: language)
        let isSyntaxHighlighted = UserDefaults.standard.wmf_IsSyntaxHighlightingEnabled
        let setupUserScript = CodemirrorSetupUserScript(language: language, direction: CodemirrorSetupUserScript.CodemirrorDirection(rawValue: layoutDirection) ?? .ltr, theme: theme, textSizeAdjustment: textSizeAdjustment, isSyntaxHighlighted: isSyntaxHighlighted) { [weak self] in
            self?.isCodemirrorReady = true
        }
        
        contentController.addUserScript(setupUserScript)
        
        scriptMessageHandlers.append(ScriptMessageHandler(handler: setupUserScript, name: setupUserScript.messageHandlerName))

        scriptMessageHandlers.append(ScriptMessageHandler(handler: messagingController, name: SectionEditorWebViewMessagingController.Message.Name.codeMirrorMessage))
        
        scriptMessageHandlers.append(ScriptMessageHandler(handler: messagingController, name: SectionEditorWebViewMessagingController.Message.Name.codeMirrorSearchMessage))
        
        scriptMessageHandlers.append(ScriptMessageHandler(handler: messagingController, name: SectionEditorWebViewMessagingController.Message.Name.smoothScrollToYOffsetMessage))
        
        scriptMessageHandlers.append(ScriptMessageHandler(handler: messagingController, name: SectionEditorWebViewMessagingController.Message.Name.replaceAllCountMessage))

        scriptMessageHandlers.append(ScriptMessageHandler(handler: messagingController, name: SectionEditorWebViewMessagingController.Message.Name.didSetWikitextMessage))
        
        addScriptMessageHandlers(to: contentController)
        
        configuration.userContentController = contentController
        webView = SectionEditorWebView(frame: .zero, configuration: configuration)
        
        webView.navigationDelegate = self
        webView.isHidden = true // hidden until wikitext is set
        webView.scrollView.keyboardDismissMode = .interactive
        
        inputViewsController = SectionEditorInputViewsController(webView: webView, messagingController: messagingController, findAndReplaceDisplayDelegate: self)
        inputViewsController.delegate = self
        
        webView.inputViewsSource = inputViewsController
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        
        let leadingConstraint = view.leadingAnchor.constraint(equalTo: webView.leadingAnchor)
        let trailingConstraint = view.trailingAnchor.constraint(equalTo: webView.trailingAnchor)
        webViewTopConstraint = view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: webView.topAnchor)
        let bottomConstraint = view.bottomAnchor.constraint(equalTo: webView.bottomAnchor)
        
        NSLayoutConstraint.activate([leadingConstraint, trailingConstraint, webViewTopConstraint, bottomConstraint])
        let folderURL = Bundle.wmf.assetsFolderURL
        let fileURL = folderURL.appendingPathComponent("codemirror/codemirror-index.html")
        webView.loadFileURL(fileURL, allowingReadAccessTo: folderURL)
        
        messagingController.webView = webView
        
        menuItemsController = SectionEditorMenuItemsController(messagingController: messagingController)
        menuItemsController.delegate = self
        webView.menuItemsDataSource = menuItemsController
        webView.menuItemsDelegate = menuItemsController
    }

    @objc var shouldFocusWebView = true {
        didSet {
            guard shouldFocusWebView else {
                return
            }
            logSectionReadyToEdit()
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
        editFunnel.logSectionHighlightToEditError(language: language)
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
        webView.isHidden = false
        webView.becomeFirstResponder()
        messagingController.focus {
            assert(Thread.isMainThread)
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
        let isShowingStatusMessage = shouldFocusWebView
        if isShowingStatusMessage {
            let message = WMFLocalizedString("wikitext-downloading", value: "Loading content...", comment: "Alert text shown when obtaining latest revision of the section being edited")
            WMFAlertManager.sharedInstance.showAlert(message, sticky: true, dismissPreviousAlerts: true)
        }
        sectionFetcher.fetchSection(with: sectionID, articleURL: articleURL) { (result) in
            DispatchQueue.main.async {
                if isShowingStatusMessage {
                    WMFAlertManager.sharedInstance.dismissAlert()
                }
                switch result {
                case .failure(let error):
                    self.didFocusWebViewCompletion = {
                        WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: true)
                    }
                case .success(let response):
                    self.wikitext = response.wikitext
                    self.handle(protection: response.protection)
                }
            }
        }
    }
    
    private func handle(protection: [SectionFetcher.Protection]) {
        let allowedGroups = protection.map { $0.level }
        guard !allowedGroups.isEmpty else {
            return
        }
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
    }
    
    // MARK: - Accessibility
    
    override func accessibilityPerformEscape() -> Bool {
        delegate?.sectionEditorDidCancelEditing(self)
        return true
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { (_) in
            self.inputViewsController.didTransitionToNewCollection()
            self.focusNavigationView.updateLayout(for: newCollection)
        }
    }

    // MARK: Event logging

    private var loggedEditActions: NSMutableSet = []
    private func logSectionReadyToEdit() {
        guard !loggedEditActions.contains(EditFunnel.Action.ready) else {
            return
        }
        editFunnel.logSectionReadyToEdit(from: editFunnelSource, language: language)
        loggedEditActions.add(EditFunnel.Action.ready)
    }

    private var editFunnelSource: EditFunnelSource {
        return selectedTextEditInfo == nil ? .pencil : .highlight
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
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
    
    private var previousContentInset = UIEdgeInsets.zero
    override func scrollViewInsetsDidChange() {
        super.scrollViewInsetsDidChange()
        guard
            let newContentInset = scrollView?.contentInset,
            newContentInset != previousContentInset
        else {
            return
        }
        previousContentInset = newContentInset
        messagingController.setAdjustedContentInset(newInset: newContentInset)
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
                    let vc = EditPreviewViewController(articleURL: self.articleURL)
                    self.inputViewsController.resetFormattingAndStyleSubmenus()
                    self.needsSelectLastSelection = true
                    vc.theme = self.theme
                    vc.sectionID = self.sectionID
                    vc.language = self.language
                    vc.wikitext = wikitext
                    vc.delegate = self
                    vc.editFunnel = self.editFunnel
                    vc.loggedEditActions = self.loggedEditActions
                    vc.editFunnelSource = self.editFunnelSource
                    self.navigationController?.pushViewController(vc, animated: true)
                } else {
                    let message = WMFLocalizedString("wikitext-preview-changes-none", value: "No changes were made to be previewed.", comment: "Alert text shown if no changes were made to be previewed.")
                    WMFAlertManager.sharedInstance.showAlert(message, sticky: false, dismissPreviousAlerts: true)
                }
            }
        }
    }
    
    func sectionEditorNavigationItemController(_ sectionEditorNavigationItemController: SectionEditorNavigationItemController, didTapCloseButton closeButton: UIBarButtonItem) {
        delegate?.sectionEditorDidCancelEditing(self)
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
        if isRangeSelected {
            menuItemsController.setEditMenuItems()
        }
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
        
        isInFindReplaceActionSheetMode = true
        present(alertController, animated: true, completion: nil)
    }
}


// MARK: - WKNavigationDelegate

extension SectionEditorViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        DDLogError("Section editor did fail navigation with error: \(error)")
    }
}

// MARK - EditSaveViewControllerDelegate

extension SectionEditorViewController: EditSaveViewControllerDelegate {
    func editSaveViewControllerDidSave(_ editSaveViewController: EditSaveViewController, result: Result<SectionEditorChanges, Error>) {
        delegate?.sectionEditorDidFinishEditing(self, result: result)
    }
}

// MARK - EditPreviewViewControllerDelegate

extension SectionEditorViewController: EditPreviewViewControllerDelegate {
    func editPreviewViewControllerDidTapNext(_ editPreviewViewController: EditPreviewViewController) {
        guard let vc = EditSaveViewController.wmf_initialViewControllerFromClassStoryboard() else {
            return
        }
        vc.dataStore = dataStore
        vc.articleURL = self.articleURL
        vc.sectionID = self.sectionID
        vc.language = self.language
        vc.wikitext = editPreviewViewController.wikitext
        vc.delegate = self
        vc.theme = self.theme
        vc.editFunnel = self.editFunnel
        vc.editFunnelSource = editFunnelSource
        vc.loggedEditActions = loggedEditActions
        self.navigationController?.pushViewController(vc, animated: true)
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
        guard
            presentedViewController == nil,
            newContentOffset.x.isFinite,
            newContentOffset.y.isFinite
        else {
            return
        }
        self.webView.scrollView.setContentOffset(newContentOffset, animated: true)
    }
}

extension SectionEditorViewController: SectionEditorInputViewsControllerDelegate {
    func sectionEditorInputViewsControllerDidTapMediaInsert(_ sectionEditorInputViewsController: SectionEditorInputViewsController) {
        let insertMediaViewController = InsertMediaViewController(articleTitle: articleURL.wmf_title, siteURL: articleURL.wmf_site)
        insertMediaViewController.delegate = self
        insertMediaViewController.apply(theme: theme)
        let navigationController = WMFThemeableNavigationController(rootViewController: insertMediaViewController, theme: theme)
        navigationController.isNavigationBarHidden = true
        present(navigationController, animated: true)
    }

    func showLinkWizard() {
        messagingController.getLink { link in
            guard let link = link else {
                assertionFailure("Link button should be disabled")
                return
            }
            let siteURL = self.articleURL.wmf_site
            if link.exists {
                guard let editLinkViewController = EditLinkViewController(link: link, siteURL: siteURL, dataStore: self.dataStore) else {
                    return
                }
                editLinkViewController.delegate = self
                let navigationController = WMFThemeableNavigationController(rootViewController: editLinkViewController, theme: self.theme)
                navigationController.isNavigationBarHidden = true
                self.present(navigationController, animated: true)
            } else {
                let insertLinkViewController = InsertLinkViewController(link: link, siteURL: siteURL, dataStore: self.dataStore)
                insertLinkViewController.delegate = self
                let navigationController = WMFThemeableNavigationController(rootViewController: insertLinkViewController, theme: self.theme)
                self.present(navigationController, animated: true)
            }
        }
    }

    func sectionEditorInputViewsControllerDidTapLinkInsert(_ sectionEditorInputViewsController: SectionEditorInputViewsController) {
        showLinkWizard()
    }
}

extension SectionEditorViewController: SectionEditorMenuItemsControllerDelegate {
    func sectionEditorMenuItemsControllerDidTapLink(_ sectionEditorMenuItemsController: SectionEditorMenuItemsController) {
        showLinkWizard()
    }
}

extension SectionEditorViewController: EditLinkViewControllerDelegate {
    func editLinkViewController(_ editLinkViewController: EditLinkViewController, didTapCloseButton button: UIBarButtonItem) {
        dismiss(animated: true)
    }

    func editLinkViewController(_ editLinkViewController: EditLinkViewController, didFinishEditingLink displayText: String?, linkTarget: String) {
        messagingController.insertOrEditLink(page: linkTarget, label: displayText)
        dismiss(animated: true)
    }

    func editLinkViewControllerDidRemoveLink(_ editLinkViewController: EditLinkViewController) {
        messagingController.removeLink()
        dismiss(animated: true)
    }

    func editLinkViewController(_ editLinkViewController: EditLinkViewController, didFailToExtractArticleTitleFromArticleURL articleURL: URL) {
        dismiss(animated: true)
    }
}

extension SectionEditorViewController: InsertLinkViewControllerDelegate {
    func insertLinkViewController(_ insertLinkViewController: InsertLinkViewController, didTapCloseButton button: UIBarButtonItem) {
        dismiss(animated: true)
    }

    func insertLinkViewController(_ insertLinkViewController: InsertLinkViewController, didInsertLinkFor page: String, withLabel label: String?) {
        messagingController.insertOrEditLink(page: page, label: label)
        dismiss(animated: true)
    }
}

extension SectionEditorViewController: InsertMediaViewControllerDelegate {
    func insertMediaViewController(_ insertMediaViewController: InsertMediaViewController, didTapCloseButton button: UIBarButtonItem) {
        dismiss(animated: true)
    }

    func insertMediaViewController(_ insertMediaViewController: InsertMediaViewController, didPrepareWikitextToInsert wikitext: String) {
        dismiss(animated: true)
        messagingController.getLineInfo { lineInfo in
            guard let lineInfo = lineInfo else {
                self.messagingController.replaceSelection(text: wikitext)
                return
            }
            if !lineInfo.hasLineTokens && lineInfo.isAtLineEnd {
                self.messagingController.replaceSelection(text: wikitext)
            } else if lineInfo.isAtLineEnd {
                self.messagingController.newlineAndIndent()
                self.messagingController.replaceSelection(text: wikitext)
            } else if lineInfo.hasLineTokens {
                self.messagingController.newlineAndIndent()
                self.messagingController.replaceSelection(text: wikitext)
                self.messagingController.newlineAndIndent()
            } else {
                self.messagingController.replaceSelection(text: wikitext)
            }
        }
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
