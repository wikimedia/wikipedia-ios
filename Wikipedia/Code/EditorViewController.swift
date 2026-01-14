import UIKit
import SwiftUI
import WMFComponents
import WMF
import CocoaLumberjackSwift
import WMFData

protocol EditorViewControllerDelegate: AnyObject {
    func editorDidCancelEditing(_ editor: EditorViewController, navigateToURL url: URL?)
    func editorDidFinishEditing(_ editor: EditorViewController, result: Result<EditorChanges, Error>, needsNewTempAccountToast: Bool?)
}

final class EditorViewController: UIViewController, WMFNavigationBarConfiguring {
    
    // MARK: - Nested Types
    
    enum EditFlow {
        case editorPreviewSave
        case editorSavePreview
    }
    
    enum Source {
        case article
        case talk
    }
    
    private struct WikitextFetchResponse {
        let wikitext: String
        let onloadSelectRange: NSRange?
        let userGroupLevelCanEdit: Bool
        let protectedPageError: MediaWikiAPIDisplayError?
        let blockedError: MediaWikiAPIDisplayError?
        let otherError: MediaWikiAPIDisplayError?
    }
    
    // MARK: - Properties
    
    private let pageURL: URL
    let sectionID: Int?
    private let editFlow: EditFlow
    private let source: Source
    private let dataStore: MWKDataStore
    private let articleSelectedInfo: SelectedTextEditInfo?
    private let editTag: WMFEditTag
    private weak var delegate: EditorViewControllerDelegate?
    private var theme: Theme
    
    private let wikitextFetcher: WikitextFetcher
    private let editNoticesFetcher: EditNoticesFetcher
    private var editNoticesViewModel: EditNoticesViewModel? = nil
    
    private var sourceEditor: WMFSourceEditorViewController?
    private var editorTopConstraint: NSLayoutConstraint?
    
    private var editConfirmationSavedData: EditSaveViewController.SaveData? = nil
    private var editCloseProblemSource: EditInteractionFunnel.ProblemSource?

    private var wikiHasTempAccounts: Bool?

    private lazy var focusNavigationView: FocusNavigationView = {
        return FocusNavigationView.wmf_viewFromClassNib()
    }()
    
    private var shouldShowEditAlert: Bool {
        return !UserDefaults.standard.didShowInformationEditingMessage && sectionID == 0
    }

    private lazy var navigationItemController: EditorNavigationItemController = {
        let navigationItemController = EditorNavigationItemController(navigationItem: navigationItem, dataStore: dataStore)
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
    
    internal var authManager: WMFAuthenticationManager {
        return dataStore.authenticationManager
    }
    
    // MARK: - Lifecycle
    
    init(pageURL: URL, sectionID: Int?, editFlow: EditFlow, source: Source, dataStore: MWKDataStore, articleSelectedInfo: SelectedTextEditInfo?, editTag: WMFEditTag, delegate: EditorViewControllerDelegate, theme: Theme) {

        self.pageURL = pageURL
        self.sectionID = sectionID
        self.wikitextFetcher = WikitextFetcher(session: dataStore.session, configuration: dataStore.configuration)
        self.editNoticesFetcher = EditNoticesFetcher(session: dataStore.session, configuration: dataStore.configuration)
        self.dataStore = dataStore
        self.articleSelectedInfo = articleSelectedInfo
        self.editTag = editTag
        self.delegate = delegate
        self.theme = theme
        self.editFlow = editFlow
        self.source = source
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }
    
    // MARK: - Private Helpers
    
    
    private func configureNavigationBar() {

        let titleConfig = WMFNavigationBarTitleConfig(title: CommonStrings.editorTitle, customView: nil, alignment: .hidden)
        
        let closeConfig = WMFNavigationBarCloseButtonConfig(text: CommonStrings.cancelActionTitle, target: self, action: #selector(close(_ :)), alignment: .leading)

        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: closeConfig, profileButtonConfig: nil, tabsButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }
    
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
        navigationItemController.readingThemesControlsToolbarItem.isEnabled = false
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

        group.enter()
        checkWikiStatus { langHasTempAccounts in
            defer {
                group.leave()
            }
            self.wikiHasTempAccounts = langHasTempAccounts
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
            var isDifferentErrorBannerShown = false
            if let blockedError = wikitextFetchResponse.blockedError {
                presentBlockedError(error: blockedError)
                isDifferentErrorBannerShown = true
            } else if let protectedPageError = wikitextFetchResponse.protectedPageError {
                presentProtectedPageWarning(error: protectedPageError)
                isDifferentErrorBannerShown = true
            } else if let otherError = wikitextFetchResponse.otherError {
                WMFAlertManager.sharedInstance.showErrorAlertWithMessage(otherError.messageHtml.removingHTML, sticky: false, dismissPreviousAlerts: true)
                isDifferentErrorBannerShown = true
            } else if let editNoticesViewModel,
              !editNoticesViewModel.notices.isEmpty {
               self.editNoticesViewModel = editNoticesViewModel
               self.navigationItemController.addEditNoticesButton()
               self.navigationItemController.apply(theme: self.theme)
               self.presentEditNoticesIfNecessary(viewModel: editNoticesViewModel, blockedError: wikitextFetchResponse.blockedError, userGroupLevelCanEdit: wikitextFetchResponse.userGroupLevelCanEdit)
               isDifferentErrorBannerShown = true
            }
            
            self.navigationItemController.addTempAccountsNoticesButtons(wikiHasTempAccounts: wikiHasTempAccounts)

            let needsReadOnly = (wikitextFetchResponse.blockedError != nil) || (wikitextFetchResponse.protectedPageError != nil && !wikitextFetchResponse.userGroupLevelCanEdit)
            
            if wikitextFetchResponse.blockedError != nil {
                editCloseProblemSource = .blockedMessage
            } else if wikitextFetchResponse.protectedPageError != nil && !wikitextFetchResponse.userGroupLevelCanEdit {
                editCloseProblemSource = .protectedPage
            }
            
            if let onloadSelectRange = wikitextFetchResponse.onloadSelectRange,
               onloadSelectRange.location == NSNotFound {
                presentFailToFindSelectedRangeAlert()
                self.addChildEditor(wikitext: wikitextFetchResponse.wikitext, needsReadOnly: needsReadOnly, onloadSelectRange: nil)
            } else {
                self.addChildEditor(wikitext: wikitextFetchResponse.wikitext, needsReadOnly: needsReadOnly, onloadSelectRange: wikitextFetchResponse.onloadSelectRange)
            }
            if shouldShowEditAlert && !isDifferentErrorBannerShown {
                WMFAlertManager.sharedInstance.showWarningAlert(CommonStrings.editArticleWarning, duration: NSNumber(value: 5), sticky: false, dismissPreviousAlerts: true)
                UserDefaults.standard.didShowInformationEditingMessage = true
            }
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
    
    private func presentFailToFindSelectedRangeAlert() {
        let alert = UIAlertController(title: CommonStrings.editorFailToScrollToArticleSelectedTextTitle, message: CommonStrings.editorFailToScrollToArticleSelectedTextBody, preferredStyle: .alert)
        alert.overrideUserInterfaceStyle = theme.isDark ? .dark : .light
        let action = UIAlertAction(title: CommonStrings.okTitle, style: .default)
        alert.addAction(action)
        present(alert, animated: true)
        editCloseProblemSource = .articleSelectFail
    }

    private func checkWikiStatus(completion: @escaping (Bool) -> Void) {
        guard let language = pageURL.wmf_languageCode else {
            completion(false)
            return
        }

        let dataController = WMFTempAccountDataController.shared
        Task {
            let hasTempStatus = await dataController.asyncCheckWikiTempAccountAvailability(language: language, isCheckingPrimaryWiki: false)
            completion(hasTempStatus)
        }
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
                    
                    var onloadSelectRange: NSRange?
                    if let articleSelectedInfo {
                        let htmlInfo = articleSelectedInfo.htmlInfo()
                        onloadSelectRange = WMFWikitextUtils.rangeOf(htmlInfo: htmlInfo, inWikitext: response.wikitext)
                    }
                    
                    completion(.success(WikitextFetchResponse(wikitext: response.wikitext, onloadSelectRange: onloadSelectRange, userGroupLevelCanEdit: userGroupLevelCanEdit, protectedPageError: protectedPageError, blockedError: blockedError, otherError: otherError)))
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
            
            editCloseProblemSource = .connectionError
            
        } else {
            
            let alert = UIAlertController(title: CommonStrings.unexpectedErrorAlertTitle, message: nsError.alertMessage(), preferredStyle: .alert)
            let action = UIAlertAction(title: CommonStrings.okTitle, style: .default)
            alert.addAction(action)
            alert.overrideUserInterfaceStyle = theme.isDark ? .dark : .light
            present(alert, animated: true)
            editCloseProblemSource = .serverError
        }
    }
    
    private func checkUserGroupLevelCanEdit(protection: [WikitextFetcher.Protection], userInfo: [String]) -> Bool {
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
        
        wmf_showBlockedPanel(messageHtml: error.messageHtml, linkBaseURL: error.linkBaseURL, currentTitle: currentTitle, theme: theme, linkLoggingAction: { [weak self] in
            
            guard let self else {
                return
            }
            
            if let project = WikimediaProject(siteURL: pageURL) {
                switch source {
                case .article:
                    EditInteractionFunnel.shared.logArticleEditorDidTapPanelLink(problemSource: .blockedMessageLink, project: project)
                case .talk:
                    EditInteractionFunnel.shared.logTalkEditorDidTapPanelLink(problemSource: .blockedMessageLink, project: project)
                }
            }
            
            EditAttemptFunnel.shared.logAbort(pageURL: pageURL)
        })
    }
    
    private func presentProtectedPageWarning(error: MediaWikiAPIDisplayError) {
        
        guard let currentTitle = pageURL.wmf_title else {
            return
        }

        wmf_showBlockedPanel(messageHtml: error.messageHtml, linkBaseURL: error.linkBaseURL, currentTitle: currentTitle, theme: theme, image: UIImage(named: "warning-icon"), linkLoggingAction: { [weak self] in
            
            guard let self else {
                return
            }
            
            if let project = WikimediaProject(siteURL: pageURL) {
                switch source {
                case .article:
                    EditInteractionFunnel.shared.logArticleEditorDidTapPanelLink(problemSource: .protectedPageLink, project: project)
                case .talk:
                    EditInteractionFunnel.shared.logTalkEditorDidTapPanelLink(problemSource: .protectedPageLink, project: project)
                }
            }
            
            EditAttemptFunnel.shared.logAbort(pageURL: pageURL)
            
        })
    }
    
    private func addChildEditor(wikitext: String, needsReadOnly: Bool, onloadSelectRange: NSRange?) {
        let localizedStrings = WMFSourceEditorLocalizedStrings(
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
            wikitextEditorAccessibility: CommonStrings.editorWikitextTextViewAccessibility, 
            wikitextEditorLoadingAccessibility: CommonStrings.editorWikitextLoadingAccessibility,
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
        let viewModel = WMFSourceEditorViewModel(configuration: .full, initialText: wikitext, localizedStrings: localizedStrings, isSyntaxHighlightingEnabled: isSyntaxHighlightingEnabled, textAlignment: textAlignment, needsReadOnly: needsReadOnly, onloadSelectRange: onloadSelectRange)

        let sourceEditor = WMFSourceEditorViewController(viewModel: viewModel, delegate: self)
        
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
        self.navigationItemController.readingThemesControlsToolbarItem.isEnabled = true
    }
    
    private func showFocusNavigationView() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        editorTopConstraint?.constant = -focusNavigationView.frame.height
        focusNavigationView.isHidden = false
        navigationItemController.progressButton.isEnabled = false
        navigationItemController.readingThemesControlsToolbarItem.isEnabled = false
    }
    
    private func hideFocusNavigationView() {
        editorTopConstraint?.constant = 0
        focusNavigationView.isHidden = true
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItemController.progressButton.isEnabled = true
        navigationItemController.readingThemesControlsToolbarItem.isEnabled = true
    }
    
    private func setTextSizeInAppEnvironment() {
        let textSizeAdjustment =  WMFFontSizeMultiplier(rawValue: UserDefaults.standard.wmf_articleFontSizeMultiplier().intValue) ?? .large
        WMFAppEnvironment.current.set(articleAndEditorTextSize: textSizeAdjustment.contentSizeCategory)
    }

    private func showDestructiveDismissAlert(sender: UIBarButtonItem, confirmCompletion: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: CommonStrings.editorExitConfirmationMessage, preferredStyle: .actionSheet)
        alert.overrideUserInterfaceStyle = theme.isDark ? .dark : .light
        let confirmClose = UIAlertAction(title: CommonStrings.discardEditActionTitle, style: .destructive) { [weak self] _ in
            
            guard let self else {
                return
            }
            
            if let project = WikimediaProject(siteURL: self.pageURL) {
                switch self.source {
                case .article:
                    EditInteractionFunnel.shared.logArticleEditorDidTapClose(problemSource: editCloseProblemSource, project: project)
                case .talk:
                    EditInteractionFunnel.shared.logTalkEditorDidTapClose(problemSource: editCloseProblemSource, project: project)
                }
            }
            
            EditAttemptFunnel.shared.logAbort(pageURL: pageURL)
            
            confirmCompletion()
        }
        alert.addAction(confirmClose)
        let keepEditing = UIAlertAction(title: CommonStrings.keepEditingActionTitle, style: .cancel) { [weak self] _ in
            
            guard let self else {
                return
            }
            
            if let project = WikimediaProject(siteURL: self.pageURL) {
                switch self.source {
                case .article:
                    EditInteractionFunnel.shared.logArticleEditorConfirmDidTapKeepEditing(project: project)
                case .talk:
                    EditInteractionFunnel.shared.logTalkEditorConfirmDidTapKeepEditing(project: project)
                }
            }
        }
        alert.addAction(keepEditing)
        if let popoverController = alert.popoverPresentationController {
            popoverController.barButtonItem = sender
        }
        present(alert, animated: true)
    }

    private func showEditPreview(editFlow: EditFlow) {
        
        guard let sourceEditor else {
            return
        }
        
        let previewVC = EditPreviewViewController(pageURL: pageURL)
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
        guard let saveVC = EditSaveViewController.wmf_initialViewControllerFromClassStoryboard(),
        let sourceEditor else {
            return
        }

        saveVC.dataStore = dataStore
        saveVC.savedData = editConfirmationSavedData
        saveVC.pageURL = pageURL
        saveVC.sectionID = sectionID
        saveVC.languageCode = pageURL.wmf_languageCode
        saveVC.wikitext = sourceEditor.editedWikitext
        saveVC.source = source
        saveVC.editTags = [editTag]

        if case .editorSavePreview = editFlow {
            saveVC.needsWebPreviewButton = true
        }
        saveVC.delegate = self
        saveVC.editorLoggingDelegate = self
        saveVC.theme = self.theme
        
        navigationController?.pushViewController(saveVC, animated: true)
    }
    
    @objc private func close(_ sender: UIBarButtonItem) {
        let progressButton = navigationItemController.progressButton
        if progressButton.isEnabled {
            showDestructiveDismissAlert(sender: sender) { [weak self] in
                guard let self else {
                    return
                }
                self.delegate?.editorDidCancelEditing(self, navigateToURL: nil)
            }
        } else {
            
            if let project = WikimediaProject(siteURL: pageURL) {
                switch source {
                case .article:
                    EditInteractionFunnel.shared.logArticleEditorDidTapClose(problemSource: editCloseProblemSource, project: project)
                case .talk:
                    EditInteractionFunnel.shared.logTalkEditorDidTapClose(problemSource: editCloseProblemSource, project: project)
                }
            }
            
            EditAttemptFunnel.shared.logAbort(pageURL: pageURL)

            delegate?.editorDidCancelEditing(self, navigateToURL: nil)
        }
    }
}

// MARK: - Themeable

extension EditorViewController: Themeable {
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

extension EditorViewController: WMFSourceEditorViewControllerDelegate {
    func sourceEditorDidChangeUndoState(_ sourceEditorViewController: WMFComponents.WMFSourceEditorViewController, canUndo: Bool, canRedo: Bool) {
        navigationItemController.undoButton.isEnabled = canUndo
        navigationItemController.redoButton.isEnabled = canRedo
    }
    
    func sourceEditorDidChangeText(_ sourceEditorViewController: WMFComponents.WMFSourceEditorViewController, didChangeText: Bool) {
        navigationItemController.progressButton.isEnabled = didChangeText
    }
    
    func sourceEditorViewControllerDidTapFind(_ sourceEditorViewController: WMFSourceEditorViewController) {
        showFocusNavigationView()
    }
    
    func sourceEditorViewControllerDidRemoveFindInputAccessoryView(_ sourceEditorViewController: WMFComponents.WMFSourceEditorViewController) {
        hideFocusNavigationView()
    }
    
    func sourceEditorViewControllerDidTapLink(parameters: WMFSourceEditorFormatterLinkWizardParameters) {
        guard let siteURL = pageURL.wmf_site else {
            return
        }
        
        if let editPageTitle = parameters.editPageTitle {
            guard let link = Link(page: editPageTitle, label: parameters.editPageLabel, exists: true) else {
                return
            }
            
            guard let editLinkViewController = EditLinkViewController(link: link, siteURL: pageURL.wmf_site, dataStore: dataStore, theme: theme) else {
                return
            }
            
            editLinkViewController.delegate = self
            let navigationController = WMFComponentNavigationController(rootViewController: editLinkViewController, modalPresentationStyle: .overFullScreen)
            present(navigationController, animated: true)
        }
        
        if let insertSearchTerm = parameters.insertSearchTerm {
            guard let link = Link(page: insertSearchTerm, label: nil, exists: false) else {
                return
            }
            
            let insertLinkViewController = InsertLinkViewController(link: link, siteURL: siteURL, dataStore: dataStore, theme: theme)
            insertLinkViewController.delegate = self
            let navigationController = WMFComponentNavigationController(rootViewController: insertLinkViewController, modalPresentationStyle: .overFullScreen)
            present(navigationController, animated: true)
        }
    }
    
    func sourceEditorViewControllerDidTapImage() {
        
        guard let sourceEditor,
              let siteURL = pageURL.wmf_site else {
            return
        }
        
        sourceEditor.removeFocus()
        let insertMediaViewController = InsertMediaViewController(articleTitle: pageURL.wmf_title, siteURL: siteURL)
        insertMediaViewController.delegate = self
        insertMediaViewController.apply(theme: theme)
        let navigationController = WMFComponentNavigationController(rootViewController: insertMediaViewController, modalPresentationStyle: .overFullScreen)
        present(navigationController, animated: true)
    }
}

// MARK: - EditorNavigationItemControllerDelegate

extension EditorViewController: EditorNavigationItemControllerDelegate {
    func editorNavigationItemController(_ editorNavigationItemController: EditorNavigationItemController, didTapProgressButton progressButton: UIBarButtonItem) {
        
        guard let sourceEditor else {
            return
        }

        sourceEditor.removeFocus()
        
        if let project = WikimediaProject(siteURL: self.pageURL) {
            switch self.source {
            case .article:
                EditInteractionFunnel.shared.logArticleEditorDidTapNext(project: project)
            case .talk:
                EditInteractionFunnel.shared.logTalkEditorDidTapNext(project: project)
            }
        }
        
        switch editFlow {
        case .editorSavePreview:
            showEditSave(editFlow: editFlow)
        case .editorPreviewSave:
            showEditPreview(editFlow: editFlow)
        }
        
        EditAttemptFunnel.shared.logSaveIntent(pageURL: pageURL)
    }
    
    func editorNavigationItemController(_ editorNavigationItemController: EditorNavigationItemController, didTapUndoButton undoButton: UIBarButtonItem) {
        sourceEditor?.undo()
    }
    
    func editorNavigationItemController(_ editorNavigationItemController: EditorNavigationItemController, didTapRedoButton redoButton: UIBarButtonItem) {
        sourceEditor?.redo()
    }
    
    func editorNavigationItemController(_ editorNavigationItemController: EditorNavigationItemController, didTapTemporaryAccountNoticesButton tempButton: UIBarButtonItem) {
        guard let navigationController else { return }
        let tempAccountSheetCoordinator = TempAccountSheetCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore, didTapDone: { [weak self] in
            self?.dismiss(animated: true)
        }, didTapContinue: { [weak self] in
            self?.dismiss(animated: true)
        }, isTempAccount: true)
        
        _ = tempAccountSheetCoordinator.start()
    }
    
    func editorNavigationItemController(_ editorNavigationItemController: EditorNavigationItemController, didTapIPAccountNoticesButton ipButton: UIBarButtonItem) {
        guard let navigationController else { return }
        let tempAccountSheetCoordinator = TempAccountSheetCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore, didTapDone: { [weak self] in
            self?.dismiss(animated: true)
        }, didTapContinue: { [weak self] in
            self?.dismiss(animated: true)
        }, isTempAccount: false)
        
        _ = tempAccountSheetCoordinator.start()
    }
    
    func editorNavigationItemController(_ editorNavigationItemController: EditorNavigationItemController, didTapReadingThemesControlsButton readingThemesControlsButton: UIBarButtonItem) {
        
        guard let sourceEditor else {
            return
        }
        
        sourceEditor.removeFocus()
        showReadingThemesControlsPopup(on: self, responder: self, theme: theme)
    }
    
    func editorNavigationItemController(_ editorNavigationItemController: EditorNavigationItemController, didTapEditNoticesButton: UIBarButtonItem) {
        presentEditNoticesIfAvailable()
    }
}

// MARK: - FocusNavigationViewDelegate

extension EditorViewController: FocusNavigationViewDelegate {
    func focusNavigationViewDidTapClose(_ focusNavigationView: FocusNavigationView) {
        
        guard let sourceEditor else {
            return
        }
        
        sourceEditor.closeFind()
        hideFocusNavigationView()
    }
}

// MARK: - ReadingThemesControlsResponding

extension EditorViewController: ReadingThemesControlsResponding {
    func updateWebViewTextSize(textSize: Int) {
        setTextSizeInAppEnvironment()
    }
    
    func toggleSyntaxHighlighting(_ controller: ReadingThemesControlsViewController) {
        
        guard let sourceEditor else {
            return
        }
        
        sourceEditor.toggleSyntaxHighlighting()
    }
}

// MARK: - ReadingThemesControlsPresenting

extension EditorViewController: ReadingThemesControlsPresenting {
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

extension EditorViewController: EditLinkViewControllerDelegate {
    func editLinkViewController(_ editLinkViewController: EditLinkViewController, didTapCloseButton button: UIBarButtonItem) {
        editLinkViewController.dismiss(animated: true)
    }
    
    func editLinkViewController(_ editLinkViewController: EditLinkViewController, didFinishEditingLink displayText: String?, linkTarget: String) {
        editLinkViewController.dismiss(animated: true)
        sourceEditor?.editLink(newPageTitle: linkTarget, newPageLabel: displayText)
    }
    
    func editLinkViewController(_ editLinkViewController: EditLinkViewController, didFailToExtractArticleTitleFromArticleURL articleURL: URL) {
        DDLogWarn("Failed to extract article title from \(pageURL)")
        dismiss(animated: true)
    }
    
    func editLinkViewControllerDidRemoveLink(_ editLinkViewController: EditLinkViewController) {
        editLinkViewController.dismiss(animated: true)
        sourceEditor?.removeLink()
    }
}

// MARK: - InsertLinkViewControllerDelegate

extension EditorViewController: InsertLinkViewControllerDelegate {
    func insertLinkViewController(_ insertLinkViewController: InsertLinkViewController, didTapCloseButton button: UIBarButtonItem) {
        insertLinkViewController.dismiss(animated: true)
    }
    
    func insertLinkViewController(_ insertLinkViewController: InsertLinkViewController, didInsertLinkFor page: String, withLabel label: String?) {
        sourceEditor?.insertLink(pageTitle: page)
        insertLinkViewController.dismiss(animated: true)
    }
}

// MARK: - InsertMediaViewControllerDelegate

extension EditorViewController: InsertMediaViewControllerDelegate {
    func didTapCloseButton(insertMediaViewController: InsertMediaViewController) {
        insertMediaViewController.dismiss(animated: true)
    }
    
    func didPrepareWikitextToInsert(wikitext: String, insertMediaViewController: InsertMediaViewController) {
        sourceEditor?.insertImage(wikitext: wikitext)
        insertMediaViewController.dismiss(animated: true)
    }
}

// MARK: - EditPreviewViewControllerDelegate

extension EditorViewController: EditPreviewViewControllerDelegate {
    func editPreviewViewControllerDidTapNext(pageURL: URL, sectionID: Int?, editPreviewViewController: EditPreviewViewController) {
        
        guard case .editorPreviewSave = editFlow else {
            assertionFailure("Edit preview should not have a Next button when using editorSavePreview flow.")
            return
        }
        
        if let project = WikimediaProject(siteURL: self.pageURL) {
            switch self.source {
            case .article:
                EditInteractionFunnel.shared.logArticlePreviewDidTapNext(project: project)
            default:
                assertionFailure("Edit preview with Next button should have article set as source.")
            }
        }
        
        showEditSave(editFlow: editFlow)
    }
}

// MARK: - EditSaveViewControllerDelegate

extension EditorViewController: EditSaveViewControllerDelegate {
    
    func editSaveViewControllerDidSave(_ editSaveViewController: EditSaveViewController, result: Result<EditorChanges, Error>, needsNewTempAccountToast: Bool?) {
        delegate?.editorDidFinishEditing(self, result: result, needsNewTempAccountToast: needsNewTempAccountToast)
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

// MARK: - EditSaveViewControllerEditorLoggingDelegate

extension EditorViewController: EditSaveViewControllerEditorLoggingDelegate {
    func logEditSaveViewControllerDidTapPublish(source: Source, summaryAdded: Bool, isMinor: Bool, isWatched: Bool, project: WikimediaProject) {
        switch source {
        case .article:
            EditInteractionFunnel.shared.logArticleEditSummaryDidTapPublish(summaryAdded: summaryAdded, minorEdit: isMinor, watchlistAdded: isWatched, project: project)
        case .talk:
            EditInteractionFunnel.shared.logTalkEditSummaryDidTapPublish(summaryAdded: summaryAdded, minorEdit: isMinor, project: project)
        }
    }
    
    func logEditSaveViewControllerPublishSuccess(source: Source, revisionID: UInt64, project: WikimediaProject) {
        switch source {
        case .article:
            EditInteractionFunnel.shared.logArticlePublishSuccess(revisionID: Int(revisionID), project: project)
        case .talk:
            EditInteractionFunnel.shared.logTalkPublishSuccess(revisionID: Int(revisionID), project: project)
        }
    }
    
    func logEditSaveViewControllerPublishFailed(source: Source, problemSource: EditInteractionFunnel.ProblemSource?, project: WikimediaProject) {
        switch source {
        case .article:
            EditInteractionFunnel.shared.logArticlePublishFail(problemSource: problemSource, project: project)
        case .talk:
            EditInteractionFunnel.shared.logTalkPublishFail(problemSource: problemSource, project: project)
        }
    }
    
    func logEditSaveViewControllerDidTapBlockedMessageLink(source: Source, project: WikimediaProject) {
        switch source {
        case .article:
            EditInteractionFunnel.shared.logArticleEditSummaryDidTapBlockedMessageLink(project: project)
        case .talk:
            EditInteractionFunnel.shared.logTalkEditSummaryDidTapBlockedMessageLink(project: project)
        }
    }
    
    func logEditSaveViewControllerDidTapShowWebPreview() {
        if let project = WikimediaProject(siteURL: self.pageURL) {
            switch self.source {
            case .talk:
                EditInteractionFunnel.shared.logTalkEditSummaryDidTapPreview(project: project)
            default:
                assertionFailure("Article sources should not have show web preview button on edit save.")
            }
        }
    }
}

// MARK: - EditSaveViewControllerDelegate

extension EditorViewController: EditNoticesViewControllerDelegate {
    func editNoticesControllerUserTapped(url: URL) {
        
        guard let closeBarButtonItem = navigationItem.leftBarButtonItem else {
            return
        }
        
        let progressButton = navigationItemController.progressButton
        if progressButton.isEnabled {
            editCloseProblemSource = .editNoticeLink
            showDestructiveDismissAlert(sender: closeBarButtonItem) { [weak self] in
                guard let self else {
                    return
                }

                self.delegate?.editorDidCancelEditing(self, navigateToURL: url)
            }
        } else {
            
            if let project = WikimediaProject(siteURL: self.pageURL) {
                switch self.source {
                case .article:
                    EditInteractionFunnel.shared.logArticleEditorDidTapPanelLink(problemSource: .editNoticeLink, project: project)
                case .talk:
                    EditInteractionFunnel.shared.logTalkEditorDidTapPanelLink(problemSource: .editNoticeLink, project: project)
                }
                
                EditAttemptFunnel.shared.logAbort(pageURL: pageURL)
            }

            delegate?.editorDidCancelEditing(self, navigateToURL: url)
        }
    }
}

// MARK: - SelectedTextEditInfo extension

private extension SelectedTextEditInfo {
    func htmlInfo() -> WMFWikitextUtils.HtmlInfo {
        return WMFWikitextUtils.HtmlInfo(textBeforeTargetText: selectedAndAdjacentText.textBeforeSelectedText, targetText: selectedAndAdjacentText.selectedText, textAfterTargetText: selectedAndAdjacentText.textAfterSelectedText)
    }
}

// MARK: - Accessibility Identifiers

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

extension EditorViewController: EditingFlowViewController {
    
}
