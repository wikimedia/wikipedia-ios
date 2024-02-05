import UIKit
import Components
import WMF
import CocoaLumberjackSwift

protocol PageEditorViewControllerDelegate: AnyObject {
    func pageEditorDidCancelEditing(_ pageEditor: PageEditorViewController, navigateToURL url: URL?)
    func pageEditorDidFinishEditing(_ pageEditor: PageEditorViewController, result: Result<SectionEditorChanges, Error>)
}

final class PageEditorViewController: UIViewController {
    
    // MARK: - Nested Types
    
    enum EditFlow {
        case editorPreviewSave
        case editorSavePreview
    }
    
    private struct WikitextFetchResponse {
        let wikitext: String
        let userGroupLevelCanEdit: Bool
        let protectedPageError: MediaWikiAPIDisplayError?
        let blockedError: MediaWikiAPIDisplayError?
        let otherError: MediaWikiAPIDisplayError?
    }
    
    // MARK: - Properties
    
    private let pageURL: URL
    private let sectionID: Int?
    private let editFlow: EditFlow
    private let dataStore: MWKDataStore
    private weak var delegate: PageEditorViewControllerDelegate?
    private var theme: Theme
    
    private let wikitextFetcher: SectionFetcher
    private let editNoticesFetcher: EditNoticesFetcher
    private var editNoticesViewModel: EditNoticesViewModel? = nil
    
    private var sourceEditor: WKSourceEditorViewController!
    private var editorTopConstraint: NSLayoutConstraint!
    
    private var editConfirmationSavedData: EditSaveViewController.SaveData? = nil
    
    private lazy var focusNavigationView: FocusNavigationView = {
        return FocusNavigationView.wmf_viewFromClassNib()
    }()
    
    private lazy var navigationItemController: SectionEditorNavigationItemController = {
        let navigationItemController = SectionEditorNavigationItemController(navigationItem: navigationItem)
        navigationItemController.delegate = self
        return navigationItemController
    }()
    
    lazy var readingThemesControlsViewController: ReadingThemesControlsViewController = {
        return ReadingThemesControlsViewController.init(nibName: ReadingThemesControlsViewController.nibName, bundle: nil)
    }()
    
    private lazy var spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()
    
    // MARK: - Lifecycle
    
    init(pageURL: URL, sectionID: Int?, editFlow: EditFlow, dataStore: MWKDataStore, delegate: PageEditorViewControllerDelegate, theme: Theme) {
        self.pageURL = pageURL
        self.sectionID = sectionID
        self.wikitextFetcher = SectionFetcher(session: dataStore.session, configuration: dataStore.configuration)
        self.editNoticesFetcher = EditNoticesFetcher(session: dataStore.session, configuration: dataStore.configuration)
        self.dataStore = dataStore
        self.delegate = delegate
        self.theme = theme
        self.editFlow = editFlow
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setTextSizeInAppEnvironment()
        setupFocusNavigationView()
        setupNavigationItemController()
        setupSpinner()
        apply(theme: theme)
        
        loadContent()
    }
    
    // MARK: - Private Helpers
    
    private func setupFocusNavigationView() {

        let closeAccessibilityText = WMFLocalizedString("find-replace-header-close-accessibility", value: "Close find and replace", comment: "Accessibility label for closing the find and replace view.")
        let headerTitle = CommonStrings.findReplaceHeader
        
        focusNavigationView.configure(titleText: headerTitle, closeButtonAccessibilityText: closeAccessibilityText, traitCollection: traitCollection)
        
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
    
    private func setupNavigationItemController() {
        navigationItemController.progressButton.isEnabled = false
        navigationItemController.undoButton.isEnabled = false
        navigationItemController.redoButton.isEnabled = false
    }
    
    private func setupSpinner() {
        spinner.isHidden = true
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            view.safeAreaLayoutGuide.centerXAnchor.constraint(equalTo: spinner.centerXAnchor),
            view.safeAreaLayoutGuide.centerYAnchor.constraint(equalTo: spinner.centerYAnchor)
        ])
    }
    
    private func delayStartSpinner() {
        perform(#selector(startSpinner), with: nil, afterDelay: 1.0)
    }
    
    @objc private func startSpinner() {
        spinner.startAnimating()
    }
    
    private func stopSpinner() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(startSpinner), object: nil)
        spinner.stopAnimating()
    }
    
    private func loadContent() {
        
        delayStartSpinner()
        
        var editNoticesViewModel: EditNoticesViewModel?
        var wikitextFetchResponse: WikitextFetchResponse?
        var wikitextFetchError: Error?
        let group = DispatchGroup()
        
        group.enter()
        loadEditNotices { result in
            defer {
                group.leave()
            }
            
            switch result {
            case .success(let viewModel):
                editNoticesViewModel = viewModel
            case .failure:
                break
            }
        }
        
        group.enter()
        loadWikitext { result in
            defer {
                group.leave()
            }
            
            switch result {
            case .success(let response):
                wikitextFetchResponse = response
            case .failure(let error):
                wikitextFetchError = error
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            
            guard let self else {
                return
            }
            
            self.stopSpinner()
            
            if let wikitextFetchError {
                handleWikitextLoadFailure(error: wikitextFetchError)
                return
            }
            
            guard let wikitextFetchResponse else {
                handleWikitextLoadFailure(error: RequestError.unexpectedResponse)
                return
            }
            
            if let blockedError = wikitextFetchResponse.blockedError {
                presentBlockedError(error: blockedError)
            } else if let protectedPageError = wikitextFetchResponse.protectedPageError {
                presentProtectedPageWarning(error: protectedPageError)
            } else if let otherError = wikitextFetchResponse.otherError {
                WMFAlertManager.sharedInstance.showErrorAlertWithMessage(otherError.messageHtml.removingHTML, sticky: false, dismissPreviousAlerts: true)
            }
            
            if let editNoticesViewModel,
               !editNoticesViewModel.notices.isEmpty {
                self.editNoticesViewModel = editNoticesViewModel
                self.navigationItemController.addEditNoticesButton()
                self.navigationItemController.apply(theme: self.theme)
                self.presentEditNoticesIfNecessary(viewModel: editNoticesViewModel, blockedError: wikitextFetchResponse.blockedError, userGroupLevelCanEdit: wikitextFetchResponse.userGroupLevelCanEdit)
            }
            
            let needsReadOnly = (wikitextFetchResponse.blockedError != nil) || (wikitextFetchResponse.protectedPageError != nil && !wikitextFetchResponse.userGroupLevelCanEdit)
            self.addChildEditor(wikitext: wikitextFetchResponse.wikitext, needsReadOnly: needsReadOnly)
        }
    }
    
    private func loadEditNotices(completion: @escaping (Result<EditNoticesViewModel, Error>) -> Void) {
        editNoticesFetcher.fetchNotices(for: pageURL) { [weak self] (result) in
            DispatchQueue.main.async { [weak self] in
                switch result {
                case .success(let notices):
                    guard let siteURL = self?.pageURL.wmf_site else {
                        completion(.failure(RequestError.unexpectedResponse))
                        return
                    }
                          
                    let viewModel = EditNoticesViewModel(siteURL: siteURL, notices: notices)
                    completion(.success(viewModel))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func presentEditNoticesIfNecessary(viewModel: EditNoticesViewModel, blockedError: MediaWikiAPIDisplayError?, userGroupLevelCanEdit: Bool) {
        guard UserDefaults.standard.wmf_alwaysDisplayEditNotices && blockedError == nil && userGroupLevelCanEdit else {
            return
        }

        presentEditNoticesIfAvailable()
    }
    
    private func presentEditNoticesIfAvailable() {
        
        guard let editNoticesViewModel,
        !editNoticesViewModel.notices.isEmpty else {
            return
        }
        
        let editNoticesViewController = EditNoticesViewController(theme: theme, viewModel: editNoticesViewModel)
        editNoticesViewController.delegate = self
        present(editNoticesViewController, animated: true)
    }
    
    private func loadWikitext(completion: @escaping (Result<WikitextFetchResponse, Error>) -> Void) {
        wikitextFetcher.fetchSection(with: sectionID, articleURL: pageURL) {  [weak self] (result) in
            DispatchQueue.main.async { [weak self] in
                
                guard let self else {
                    return
                }
                
                self.stopSpinner()
                
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let response):
                    let userGroupLevelCanEdit = self.checkUserGroupLevelCanEdit(protection: response.protection, userInfo: response.userInfo?.groups ?? [])
                    var protectedPageError: MediaWikiAPIDisplayError?
                    var blockedError: MediaWikiAPIDisplayError?
                    var otherError: MediaWikiAPIDisplayError?
                    
                    if let apiError = response.apiError {
                        if apiError.code.contains("protectedpage") {
                            protectedPageError = apiError
                        } else if apiError.code.contains("block") {
                            blockedError = apiError
                        } else {
                            otherError = apiError
                        }
                    }
                    
                    completion(.success(WikitextFetchResponse(wikitext: response.wikitext, userGroupLevelCanEdit: userGroupLevelCanEdit, protectedPageError: protectedPageError, blockedError: blockedError, otherError: otherError)))
                }
            }
        }
    }
    
    private func handleWikitextLoadFailure(error: Error) {
        let nsError = error as NSError
        if nsError.wmf_isNetworkConnectionError() {
            
            if !UIAccessibility.isVoiceOverRunning {
                WMFAlertManager.sharedInstance.showErrorAlert(error, sticky: false, dismissPreviousAlerts: true)
            } else {
                UIAccessibility.post(notification: .announcement, argument: nsError.alertMessage())
            }
            
        } else {
            
            let alert = UIAlertController(title: CommonStrings.unexpectedErrorAlertTitle, message: nsError.alertMessage(), preferredStyle: .alert)
            let action = UIAlertAction(title: CommonStrings.okTitle, style: .default)
            alert.addAction(action)
            alert.overrideUserInterfaceStyle = theme.isDark ? .dark : .light
            present(alert, animated: true)
        }
    }
    
    private func checkUserGroupLevelCanEdit(protection: [SectionFetcher.Protection], userInfo: [String]) -> Bool {
        let findEditProtection = protection.map { $0.type == "edit"}
        let articleHasEditProtection = findEditProtection.first ?? false

        if articleHasEditProtection {
            let allowedGroups = protection.map { $0.level }

            guard !allowedGroups.isEmpty else {
                return true
            }

            let userGroups = userInfo.filter { allowedGroups.contains($0) }

            if !userGroups.isEmpty {
                return true
            } else {
                return false
            }
        } else {
            return true
        }
    }
    
    private func presentBlockedError(error: MediaWikiAPIDisplayError) {
        
        guard let currentTitle = pageURL.wmf_title else {
            return
        }
        
        wmf_showBlockedPanel(messageHtml: error.messageHtml, linkBaseURL: error.linkBaseURL, currentTitle: currentTitle, theme: theme)
    }
    
    private func presentProtectedPageWarning(error: MediaWikiAPIDisplayError) {
        guard let currentTitle = pageURL.wmf_title else {
            return
        }

        wmf_showBlockedPanel(messageHtml: error.messageHtml, linkBaseURL: error.linkBaseURL, currentTitle: currentTitle, theme: theme, image: UIImage(named: "warning-icon"))
    }
    
    private func addChildEditor(wikitext: String, needsReadOnly: Bool) {
        let localizedStrings = WKSourceEditorLocalizedStrings(
            keyboardTextFormattingTitle: CommonStrings.editorKeyboardTextFormattingTitle,
            keyboardParagraph: CommonStrings.editorKeyboardParagraphButton,
            keyboardHeading: CommonStrings.editorKeyboardHeadingButton,
            keyboardSubheading1: CommonStrings.editorKeyboardSubheading1Button,
            keyboardSubheading2: CommonStrings.editorKeyboardSubheading2Button,
            keyboardSubheading3: CommonStrings.editorKeyboardSubheading3Button,
            keyboardSubheading4: CommonStrings.editorKeyboardSubheading4Button,
            findAndReplaceTitle: CommonStrings.findReplaceHeader,
            replaceTypeSingle: CommonStrings.editorReplaceTypeSingle,
            replaceTypeAll: CommonStrings.editorReplaceTypeAll,
            replaceTextfieldPlaceholder: CommonStrings.editorReplaceTextfieldPlaceholder,
            replaceTypeContextMenuTitle: CommonStrings.findReplaceHeader,
            toolbarOpenTextFormatMenuButtonAccessibility: CommonStrings.editorToolbarButtonOpenTextFormatMenuAccessiblityLabel,
            toolbarReferenceButtonAccessibility: CommonStrings.editorToolbarButtonReferenceAccessiblityLabel,
            toolbarLinkButtonAccessibility: CommonStrings.editorToolbarButtonLinkAccessiblityLabel,
            toolbarTemplateButtonAccessibility: CommonStrings.editorToolbarButtonTemplateAccessiblityLabel,
            toolbarImageButtonAccessibility: CommonStrings.editorToolbarButtonImageAccessiblityLabel,
            toolbarFindButtonAccessibility: CommonStrings.editorToolbarButtonFindAccessiblityLabel,
            toolbarExpandButtonAccessibility: CommonStrings.editorToolbarShowMoreOptionsButtonAccessiblityLabel,
            toolbarListUnorderedButtonAccessibility: CommonStrings.editorToolbarButtonListUnorderedAccessiblityLabel,
            toolbarListOrderedButtonAccessibility: CommonStrings.editorToolbarButtonListOrderedAccessiblityLabel,
            toolbarIndentIncreaseButtonAccessibility: CommonStrings.editorToolbarButtonIndentIncreaseAccessiblityLabel,
            toolbarIndentDecreaseButtonAccessibility: CommonStrings.editorToolbarButtonIndentDecreaseAccessiblityLabel,
            toolbarCursorUpButtonAccessibility: CommonStrings.editorToolbarButtonCursorUpAccessiblityLabel,
            toolbarCursorDownButtonAccessibility: CommonStrings.editorToolbarButtonCursorDownAccessiblityLabel,
            toolbarCursorPreviousButtonAccessibility: CommonStrings.editorToolbarButtonCursorPreviousAccessiblityLabel,
            toolbarCursorNextButtonAccessibility: CommonStrings.editorToolbarButtonCursorNextAccessiblityLabel,
            toolbarBoldButtonAccessibility: CommonStrings.editorToolbarButtonBoldAccessiblityLabel,
            toolbarItalicsButtonAccessibility: CommonStrings.editorToolbarButtonItalicsAccessiblityLabel,
            keyboardCloseTextFormatMenuButtonAccessibility: CommonStrings.editorKeyboardButtonCloseTextFormatMenuAccessiblityLabel,
            keyboardBoldButtonAccessibility: CommonStrings.editorKeyboardButtonBoldAccessiblityLabel,
            keyboardItalicsButtonAccessibility: CommonStrings.editorKeyboardButtonItalicsAccessiblityLabel,
            keyboardUnderlineButtonAccessibility: CommonStrings.editorKeyboardButtonUnderlineAccessiblityLabel,
            keyboardStrikethroughButtonAccessibility: CommonStrings.editorKeyboardButtonStrikethroughAccessiblityLabel,
            keyboardReferenceButtonAccessibility: CommonStrings.editorKeyboardButtonReferenceAccessiblityLabel,
            keyboardLinkButtonAccessibility: CommonStrings.editorKeyboardButtonLinkAccessiblityLabel,
            keyboardListUnorderedButtonAccessibility: CommonStrings.editorKeyboardButtonListUnorderedAccessiblityLabel,
            keyboardListOrderedButtonAccessibility: CommonStrings.editorKeyboardButtonListOrderedAccessiblityLabel,
            keyboardIndentIncreaseButtonAccessibility: CommonStrings.editorKeyboardButtonIndentIncreaseAccessiblityLabel,
            keyboardIndentDecreaseButtonAccessibility: CommonStrings.editorKeyboardButtonIndentDecreaseAccessiblityLabel,
            keyboardSuperscriptButtonAccessibility: CommonStrings.editorKeyboardButtonSuperscriptAccessiblityLabel,
            keyboardSubscriptButtonAccessibility: CommonStrings.editorKeyboardButtonSubscriptAccessiblityLabel,
            keyboardTemplateButtonAccessibility: CommonStrings.editorKeyboardButtonTemplateAccessiblityLabel,
            keyboardCommentButtonAccessibility: CommonStrings.editorKeyboardButtonCommentAccessiblityLabel,
            wikitextEditorAccessibility: CommonStrings.editorWikitextTextviewAccessibilityLabel,
            findTextFieldAccessibility: CommonStrings.editorFindTextFieldAccessibilityLabel,
            findClearButtonAccessibility: CommonStrings.editorFindClearButtonAccessibilityLabel,
            findCurrentMatchInfoFormatAccessibility: CommonStrings.editorFindCurrentMatchInfoFormatAccessibilityLabel,
            findCurrentMatchInfoZeroResultsAccessibility: CommonStrings.editorFindCurrentMatchInfoZeroResultsAccessibilityLabel,
            findCloseButtonAccessibility: CommonStrings.editorFindCloseButtonAccessibilityLabel,
            findNextButtonAccessibility: CommonStrings.editorFindNextButtonAccessibilityLabel,
            findPreviousButtonAccessibility: CommonStrings.editorFindPreviousButtonAccessibilityLabel,
            replaceTextFieldAccessibility: CommonStrings.editorReplaceTextFieldAccessibilityLabel,
            replaceClearButtonAccessibility: CommonStrings.editorReplaceClearButtonAccessibilityLabel,
            replaceButtonAccessibilityFormat: CommonStrings.editorReplaceButtonFormatAccessibilityLabel,
            replaceTypeButtonAccessibilityFormat: CommonStrings.editorReplaceTypeButtonFormatAccessibilityLabel,
            replaceTypeSingleAccessibility: CommonStrings.editorReplaceTypeSingleAccessibility,
            replaceTypeAllAccessibility: CommonStrings.editorReplaceTypeAllAccessibility)

        let isSyntaxHighlightingEnabled = UserDefaults.standard.wmf_IsSyntaxHighlightingEnabled
        let textAlignment = MWKLanguageLinkController.isLanguageRTL(forContentLanguageCode: pageURL.wmf_contentLanguageCode) ? NSTextAlignment.right : NSTextAlignment.left
        let viewModel = WKSourceEditorViewModel(configuration: .full, initialText: wikitext, localizedStrings: localizedStrings, isSyntaxHighlightingEnabled: isSyntaxHighlightingEnabled, textAlignment: textAlignment, needsReadOnly: needsReadOnly)

        let sourceEditor = WKSourceEditorViewController(viewModel: viewModel, delegate: self)
        
        addChild(sourceEditor)
        sourceEditor.view.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(sourceEditor.view)
        
        let top = view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: sourceEditor.view.topAnchor)
        let bottom = view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: sourceEditor.view.bottomAnchor)
        let leading = view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: sourceEditor.view.leadingAnchor)
        let trailing = view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: sourceEditor.view.trailingAnchor)
        
        NSLayoutConstraint.activate([
            top,
            bottom,
            leading,
            trailing
        ])
        
        sourceEditor.didMove(toParent: self)
        self.sourceEditor = sourceEditor
        self.editorTopConstraint = top
    }
    
    private func showFocusNavigationView() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        editorTopConstraint.constant = -focusNavigationView.frame.height
        focusNavigationView.isHidden = false
        navigationItemController.progressButton.isEnabled = false
        navigationItemController.readingThemesControlsToolbarItem.isEnabled = false
    }
    
    private func hideFocusNavigationView() {
        editorTopConstraint.constant = 0
        focusNavigationView.isHidden = true
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItemController.progressButton.isEnabled = true
        navigationItemController.readingThemesControlsToolbarItem.isEnabled = true
    }
    
    private func setTextSizeInAppEnvironment() {
        let textSizeAdjustment =  WMFFontSizeMultiplier(rawValue: UserDefaults.standard.wmf_articleFontSizeMultiplier().intValue) ?? .large
        WKAppEnvironment.current.set(articleAndEditorTextSize: textSizeAdjustment.contentSizeCategory)
    }
    

    private func showDestructiveDismissAlert(sender: UIBarButtonItem, confirmCompletion: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: CommonStrings.editorExitConfirmationMessage, preferredStyle: .actionSheet)
        alert.overrideUserInterfaceStyle = theme.isDark ? .dark : .light
        let confirmClose = UIAlertAction(title: CommonStrings.discardEditActionTitle, style: .destructive) { _ in
            confirmCompletion()
        }
        alert.addAction(confirmClose)
        let keepEditing = UIAlertAction(title: CommonStrings.keepEditingActionTitle, style: .cancel)
        alert.addAction(keepEditing)
        if let popoverController = alert.popoverPresentationController {
            popoverController.barButtonItem = sender
        }
        present(alert, animated: true)
    }

    private func showEditPreview(editFlow: EditFlow) {
        let previewVC = EditPreviewViewController(articleURL: pageURL)
        previewVC.theme = theme
        previewVC.sectionID = sectionID
        previewVC.languageCode = pageURL.wmf_languageCode
        previewVC.wikitext = sourceEditor.editedWikitext
        previewVC.delegate = self
        switch editFlow {
        case .editorPreviewSave:
            previewVC.needsNextButton = true
            previewVC.needsSimplifiedFormatToast = false
        case .editorSavePreview:
            previewVC.needsNextButton = false
            previewVC.needsSimplifiedFormatToast = true
        }
        navigationController?.pushViewController(previewVC, animated: true)
    }
    
    private func showEditSave(editFlow: EditFlow) {
        guard let saveVC = EditSaveViewController.wmf_initialViewControllerFromClassStoryboard() else {
            return
        }

        saveVC.savedData = editConfirmationSavedData
        saveVC.dataStore = dataStore
        saveVC.articleURL = pageURL
        saveVC.sectionID = sectionID
        saveVC.languageCode = pageURL.wmf_languageCode
        saveVC.wikitext = sourceEditor.editedWikitext
        if case .editorSavePreview = editFlow {
            saveVC.needsWebPreviewButton = true
        }
        saveVC.delegate = self
        saveVC.theme = self.theme
        
        navigationController?.pushViewController(saveVC, animated: true)
    }
}

// MARK: - Themeable

extension PageEditorViewController: Themeable {
    func apply(theme: Theme) {
        guard isViewLoaded else {
            return
        }
        
        self.theme = theme
        navigationItemController.apply(theme: theme)
        focusNavigationView.apply(theme: theme)
        view.backgroundColor = theme.colors.paperBackground
        spinner.color = theme.isDark ? .white : .gray
    }
}

// MARK: - WKSourceEditorViewControllerDelegate

extension PageEditorViewController: WKSourceEditorViewControllerDelegate {
    func sourceEditorDidChangeUndoState(_ sourceEditorViewController: Components.WKSourceEditorViewController, canUndo: Bool, canRedo: Bool) {
        navigationItemController.undoButton.isEnabled = canUndo
        navigationItemController.redoButton.isEnabled = canRedo
    }
    
    func sourceEditorDidChangeText(_ sourceEditorViewController: Components.WKSourceEditorViewController, didChangeText: Bool) {
        navigationItemController.progressButton.isEnabled = didChangeText
    }
    
    func sourceEditorViewControllerDidTapFind(_ sourceEditorViewController: WKSourceEditorViewController) {
        showFocusNavigationView()
    }
    
    func sourceEditorViewControllerDidRemoveFindInputAccessoryView(_ sourceEditorViewController: Components.WKSourceEditorViewController) {
        hideFocusNavigationView()
    }
    
    func sourceEditorViewControllerDidTapLink(parameters: WKSourceEditorFormatterLinkWizardParameters) {
        guard let siteURL = pageURL.wmf_site else {
            return
        }
        
        if let editPageTitle = parameters.editPageTitle {
            guard let link = Link(page: editPageTitle, label: parameters.editPageLabel, exists: true) else {
                return
            }
            
            guard let editLinkViewController = EditLinkViewController(link: link, siteURL: pageURL.wmf_site, dataStore: dataStore) else {
                return
            }
            
            editLinkViewController.delegate = self
            let navigationController = WMFThemeableNavigationController(rootViewController: editLinkViewController, theme: self.theme)
            navigationController.isNavigationBarHidden = true
            present(navigationController, animated: true)
        }
        
        if let insertSearchTerm = parameters.insertSearchTerm {
            guard let link = Link(page: insertSearchTerm, label: nil, exists: false) else {
                return
            }
            
            let insertLinkViewController = InsertLinkViewController(link: link, siteURL: siteURL, dataStore: dataStore)
            insertLinkViewController.delegate = self
            let navigationController = WMFThemeableNavigationController(rootViewController: insertLinkViewController, theme: self.theme)
            present(navigationController, animated: true)
        }
    }
    
    func sourceEditorViewControllerDidTapImage() {
        let insertMediaViewController = InsertMediaViewController(articleTitle: pageURL.wmf_title, siteURL: pageURL.wmf_site)
        insertMediaViewController.delegate = self
        insertMediaViewController.apply(theme: theme)
        let navigationController = WMFThemeableNavigationController(rootViewController: insertMediaViewController, theme: theme)
        navigationController.isNavigationBarHidden = true
        present(navigationController, animated: true)
    }
}

// MARK: - PageEditorNavigationItemControllerDelegate

extension PageEditorViewController: SectionEditorNavigationItemControllerDelegate {
    func sectionEditorNavigationItemController(_ sectionEditorNavigationItemController: SectionEditorNavigationItemController, didTapProgressButton progressButton: UIBarButtonItem) {

        sourceEditor.removeFocus()
        
        switch editFlow {
        case .editorSavePreview:
            showEditSave(editFlow: editFlow)
        case .editorPreviewSave:
            showEditPreview(editFlow: editFlow)
        }
    }
    
    func sectionEditorNavigationItemController(_ sectionEditorNavigationItemController: SectionEditorNavigationItemController, didTapCloseButton closeButton: UIBarButtonItem) {
        
        let progressButton = navigationItemController.progressButton
        let closeButton = navigationItemController.closeButton
        if progressButton.isEnabled {
            showDestructiveDismissAlert(sender: closeButton) { [weak self] in
                guard let self else {
                    return
                }
                self.delegate?.pageEditorDidCancelEditing(self, navigateToURL: nil)
            }
        } else {
            delegate?.pageEditorDidCancelEditing(self, navigateToURL: nil)
        }
    }
    
    func sectionEditorNavigationItemController(_ sectionEditorNavigationItemController: SectionEditorNavigationItemController, didTapUndoButton undoButton: UIBarButtonItem) {
        sourceEditor.undo()
    }
    
    func sectionEditorNavigationItemController(_ sectionEditorNavigationItemController: SectionEditorNavigationItemController, didTapRedoButton redoButton: UIBarButtonItem) {
        sourceEditor.redo()
    }
    
    func sectionEditorNavigationItemController(_ sectionEditorNavigationItemController: SectionEditorNavigationItemController, didTapReadingThemesControlsButton readingThemesControlsButton: UIBarButtonItem) {
        sourceEditor.removeFocus()
        showReadingThemesControlsPopup(on: self, responder: self, theme: theme)
    }
    
    func sectionEditorNavigationItemController(_ sectionEditorNavigationItemController: SectionEditorNavigationItemController, didTapEditNoticesButton: UIBarButtonItem) {
        presentEditNoticesIfAvailable()
    }
}

// MARK: - FocusNavigationViewDelegate

extension PageEditorViewController: FocusNavigationViewDelegate {
    func focusNavigationViewDidTapClose(_ focusNavigationView: FocusNavigationView) {
        sourceEditor.closeFind()
        hideFocusNavigationView()
    }
}

// MARK: - ReadingThemesControlsResponding

extension PageEditorViewController: ReadingThemesControlsResponding {
    func updateWebViewTextSize(textSize: Int) {
        setTextSizeInAppEnvironment()
    }
    
    func toggleSyntaxHighlighting(_ controller: ReadingThemesControlsViewController) {
        sourceEditor.toggleSyntaxHighlighting()
    }
}

// MARK: - ReadingThemesControlsPresenting

extension PageEditorViewController: ReadingThemesControlsPresenting {
    var needsExtraTopSpacing: Bool {
        return true
    }
    
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

    }
}

// MARK: - EditLinkViewControllerDelegate

extension PageEditorViewController: EditLinkViewControllerDelegate {
    func editLinkViewController(_ editLinkViewController: EditLinkViewController, didTapCloseButton button: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    func editLinkViewController(_ editLinkViewController: EditLinkViewController, didFinishEditingLink displayText: String?, linkTarget: String) {
        dismiss(animated: true)
        sourceEditor.editLink(newPageTitle: linkTarget, newPageLabel: displayText)
    }
    
    func editLinkViewController(_ editLinkViewController: EditLinkViewController, didFailToExtractArticleTitleFromArticleURL articleURL: URL) {
        DDLogError("Failed to extract article title from \(pageURL)")
        dismiss(animated: true)
    }
    
    func editLinkViewControllerDidRemoveLink(_ editLinkViewController: EditLinkViewController) {
        dismiss(animated: true)
        sourceEditor.removeLink()
    }
}

// MARK: - InsertLinkViewControllerDelegate

extension PageEditorViewController: InsertLinkViewControllerDelegate {
    func insertLinkViewController(_ insertLinkViewController: InsertLinkViewController, didTapCloseButton button: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    func insertLinkViewController(_ insertLinkViewController: InsertLinkViewController, didInsertLinkFor page: String, withLabel label: String?) {
        sourceEditor.insertLink(pageTitle: page)
        dismiss(animated: true)
    }
}

// MARK: - InsertMediaViewControllerDelegate

extension PageEditorViewController: InsertMediaViewControllerDelegate {
    func insertMediaViewController(_ insertMediaViewController: InsertMediaViewController, didTapCloseButton button: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    func insertMediaViewController(_ insertMediaViewController: InsertMediaViewController, didPrepareWikitextToInsert wikitext: String) {
        sourceEditor.insertImage(wikitext: wikitext)
        dismiss(animated: true)
    }
}

// MARK: - EditPreviewViewControllerDelegate

extension PageEditorViewController: EditPreviewViewControllerDelegate {
    func editPreviewViewControllerDidTapNext(_ editPreviewViewController: EditPreviewViewController) {
        
        guard case .editorPreviewSave = editFlow else {
            assertionFailure("Edit preview should not have a Next button when using editorSavePreview flow.")
            return
        }
        
        showEditSave(editFlow: editFlow)
    }
}

// MARK: - EditSaveViewControllerDelegate

extension PageEditorViewController: EditSaveViewControllerDelegate {
    func editSaveViewControllerDidSave(_ editSaveViewController: EditSaveViewController, result: Result<SectionEditorChanges, Error>) {
        delegate?.pageEditorDidFinishEditing(self, result: result)
    }

    func editSaveViewControllerWillCancel(_ saveData: EditSaveViewController.SaveData) {
        editConfirmationSavedData = saveData
    }
    
    func editSaveViewControllerDidTapShowWebPreview() {
        guard case .editorSavePreview = editFlow else {
            assertionFailure("Invalid - web preview button should only be available when in editorSavePreview flow.")
            return
        }
        
        showEditPreview(editFlow: editFlow)
    }
}

// MARK: - EditSaveViewControllerDelegate

extension PageEditorViewController: EditNoticesViewControllerDelegate {
    func editNoticesControllerUserTapped(url: URL) {
        let progressButton = navigationItemController.progressButton
        let closeButton = navigationItemController.closeButton
        if progressButton.isEnabled {
            showDestructiveDismissAlert(sender: closeButton) { [weak self] in
                guard let self else {
                    return
                }
                self.delegate?.pageEditorDidCancelEditing(self, navigateToURL: url)
            }
        } else {
            delegate?.pageEditorDidCancelEditing(self, navigateToURL: url)
        }
    }
}

enum SourceEditorAccessibilityIdentifiers: String {
    case entryButton = "Source Editor Entry Button"
    case textView = "Source Editor TextView"
    case findButton = "Source Editor Find Button"
    case showMoreButton = "Source Editor Show More Button"
    case closeButton = "Source Editor Close Button"
    case formatTextButton = "Source Editor Format Text Button"
    case expandingToolbar = "Source Editor Expanding Toolbar"
    case highlightToolbar = "Source Editor Highlight Toolbar"
    case findToolbar = "Source Editor Find Toolbar"
    case inputView = "Source Editor Input View"
}
