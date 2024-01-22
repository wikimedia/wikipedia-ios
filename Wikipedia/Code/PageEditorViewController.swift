import UIKit
import Components
import WMF
import CocoaLumberjackSwift

protocol PageEditorViewControllerDelegate: AnyObject {
    func pageEditorDidCancelEditing(_ pageEditor: PageEditorViewController, navigateToURL url: URL?)
    func pageEditorDidFinishEditing(_ pageEditor: PageEditorViewController, result: Result<SectionEditorChanges, Error>)
}

final class PageEditorViewController: UIViewController {
    
    // MARK: - Properties
    
    private let pageURL: URL
    private let sectionID: Int?
    private let dataStore: MWKDataStore
    private weak var delegate: PageEditorViewControllerDelegate?
    private var theme: Theme
    
    private let fetcher: SectionFetcher
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
    
    // MARK: - Lifecycle
    
    init(pageURL: URL, sectionID: Int?, dataStore: MWKDataStore, delegate: PageEditorViewControllerDelegate, theme: Theme) {
        self.pageURL = pageURL
        self.sectionID = sectionID
        self.fetcher = SectionFetcher(session: dataStore.session, configuration: dataStore.configuration)
        self.dataStore = dataStore
        self.delegate = delegate
        self.theme = theme
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setTextSizeInAppEnvironment()
        setupFocusNavigationView()
        loadWikitext()
        
        apply(theme: theme)
    }
    
    // MARK: - Private Helpers
    
    private func setupFocusNavigationView() {

        let closeAccessibilityText = WMFLocalizedString("find-replace-header-close-accessibility", value: "Close find and replace", comment: "Accessibility label for closing the find and replace view.")
        let headerTitle = WMFLocalizedString("find-replace-header", value: "Find and replace", comment: "Find and replace header title.")
        
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
    
    private func loadWikitext() {
        fetcher.fetchSection(with: sectionID, articleURL: pageURL) {  [weak self] (result) in
            DispatchQueue.main.async { [weak self] in
                
                guard let self else {
                    return
                }
                
                switch result {
                case .failure(let error):
                    print(error)
                case .success(let response):
                    self.addChildEditor(wikitext: response.wikitext)
                }
            }
        }
    }
    
    private func addChildEditor(wikitext: String) {
        let localizedStrings = WKSourceEditorLocalizedStrings(inputViewTextFormatting: CommonStrings.textFormatting,
                                                              inputViewStyle: CommonStrings.style,
                                                              inputViewClearFormatting: CommonStrings.clearFormatting,
                                                              inputViewParagraph: CommonStrings.paragraph,
                                                              inputViewHeading: CommonStrings.heading,
                                                              inputViewSubheading1: CommonStrings.subheading1,
                                                              inputViewSubheading2: CommonStrings.subheading2,
                                                              inputViewSubheading3: CommonStrings.subheading3,
                                                              inputViewSubheading4: CommonStrings.subheading4,
                                                              findReplaceTypeSingle: CommonStrings.findAndReplaceSingle,
                                                              findReplaceTypeAll: CommonStrings.findAndReplaceAll,
                                                              findReplaceWith: CommonStrings.replaceWith,
                                                              accessibilityLabelButtonFormatText: CommonStrings.accessibilityLabelButtonFormatText,
                                                              accessibilityLabelButtonCitation: CommonStrings.accessibilityLabelButtonCitation,
                                                              accessibilityLabelButtonCitationSelected: CommonStrings.accessibilityLabelButtonCitationSelected,
                                                              accessibilityLabelButtonLink: CommonStrings.accessibilityLabelButtonBold,
                                                              accessibilityLabelButtonLinkSelected: CommonStrings.accessibilityLabelButtonLinkSelected,
                                                              accessibilityLabelButtonTemplate: CommonStrings.accessibilityLabelButtonTemplate,
                                                              accessibilityLabelButtonTemplateSelected: CommonStrings.accessibilityLabelButtonTemplateSelected,
                                                              accessibilityLabelButtonMedia: CommonStrings.accessibilityLabelButtonMedia,
                                                              accessibilityLabelButtonFind: CommonStrings.accessibilityLabelButtonFind,
                                                              accessibilityLabelButtonListUnordered: CommonStrings.accessibilityLabelButtonListUnordered,
                                                              accessibilityLabelButtonListUnorderedSelected: CommonStrings.accessibilityLabelButtonListUnorderedSelected,
                                                              accessibilityLabelButtonListOrdered: CommonStrings.accessibilityLabelButtonListOrdered,
                                                              accessibilityLabelButtonListOrderedSelected: CommonStrings.accessibilityLabelButtonListOrderedSelected,
                                                              accessibilityLabelButtonInceaseIndent: CommonStrings.accessibilityLabelButtonIncreaseIndent,
                                                              accessibilityLabelButtonDecreaseIndent: CommonStrings.accessibilityLabelButtonDecreaseIndent,
                                                              accessibilityLabelButtonCursorUp: CommonStrings.accessibilityLabelButtonCursorUp,
                                                              accessibilityLabelButtonCursorDown: CommonStrings.accessibilityLabelButtonCursorDown,
                                                              accessibilityLabelButtonCursorLeft: CommonStrings.accessibilityLabelButtonCursorLeft,
                                                              accessibilityLabelButtonCursorRight: CommonStrings.accessibilityLabelButtonCursorRight,
                                                              accessibilityLabelButtonBold: CommonStrings.accessibilityLabelButtonBold,
                                                              accessibilityLabelButtonBoldSelected: CommonStrings.accessibilityLabelButtonBoldSelected,
                                                              accessibilityLabelButtonItalics: CommonStrings.accessibilityLabelButtonItalics,
                                                              accessibilityLabelButtonItalicsSelected: CommonStrings.accessibilityLabelButtonItalicsSelected,
                                                              accessibilityLabelButtonShowMore: CommonStrings.accessibilityLabelButtonShowMore,
                                                              accessibilityLabelButtonComment: CommonStrings.accessibilityLabelButtonComment,
                                                              accessibilityLabelButtonCommentSelected: CommonStrings.accessibilityLabelButtonCommentSelected,
                                                              accessibilityLabelButtonSuperscript: CommonStrings.accessibilityLabelButtonSuperscript,
                                                              accessibilityLabelButtonSuperscriptSelected: CommonStrings.accessibilityLabelButtonSuperscriptSelected,
                                                              accessibilityLabelButtonSubscript: CommonStrings.accessibilityLabelButtonSubscript,
                                                              accessibilityLabelButtonSubscriptSelected: CommonStrings.accessibilityLabelButtonSubscriptSelected,
                                                              accessibilityLabelButtonUnderline: CommonStrings.accessibilityLabelButtonUnderline,
                                                              accessibilityLabelButtonUnderlineSelected: CommonStrings.accessibilityLabelButtonUnderlineSelected,
                                                              accessibilityLabelButtonStrikethrough: CommonStrings.accessibilityLabelButtonStrikethrough,
                                                              accessibilityLabelButtonStrikethroughSelected: CommonStrings.accessibilityLabelButtonStrikethroughSelected,
                                                              accessibilityLabelButtonCloseMainInputView: CommonStrings.accessibilityLabelButtonCloseMainInputView,
                                                              accessibilityLabelButtonCloseHeaderSelectInputView: CommonStrings.accessibilityLabelButtonCloseHeaderSelectInputView,
                                                              accessibilityLabelFindTextField: CommonStrings.accessibilityLabelButtonFind,
                                                              accessibilityLabelFindButtonClear: CommonStrings.accessibilityLabelButtonClearFormatting,
                                                              accessibilityLabelFindButtonClose: CommonStrings.accessibilityLabelFindButtonClose,
                                                              accessibilityLabelFindButtonNext: CommonStrings.accessibilityLabelFindButtonNext,
                                                              accessibilityLabelFindButtonPrevious: CommonStrings.accessibilityLabelFindButtonPrevious,
                                                              accessibilityLabelReplaceTextField: CommonStrings.accessibilityLabelReplaceTextField,
                                                              accessibilityLabelReplaceButtonClear: CommonStrings.accessibilityLabelReplaceButtonClear,
                                                              accessibilityLabelReplaceButtonPerformFormat: CommonStrings.accessibilityLabelReplaceButtonPerformFormat,
                                                              accessibilityLabelReplaceButtonSwitchFormat: CommonStrings.accessibilityLabelReplaceButtonSwitchFormat,
                                                              accessibilityLabelReplaceTypeSingle: CommonStrings.accessibilityLabelReplaceTypeSingle,
                                                              accessibilityLabelReplaceTypeAll: CommonStrings.accessibilityLabelReplaceTypeAll)

        let isSyntaxHighlightingEnabled = UserDefaults.standard.wmf_IsSyntaxHighlightingEnabled
        let textAlignment = MWKLanguageLinkController.isLanguageRTL(forContentLanguageCode: pageURL.wmf_contentLanguageCode) ? NSTextAlignment.right : NSTextAlignment.left
        let viewModel = WKSourceEditorViewModel(configuration: .full, initialText: wikitext, localizedStrings: localizedStrings, isSyntaxHighlightingEnabled: isSyntaxHighlightingEnabled, textAlignment: textAlignment)

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
    }
}

// MARK: - WKSourceEditorViewControllerDelegate

extension PageEditorViewController: WKSourceEditorViewControllerDelegate {
    
    func sourceEditorViewControllerDidTapFind(sourceEditorViewController: WKSourceEditorViewController) {
        showFocusNavigationView()
    }
    
    func sourceEditorViewControllerDidRemoveFindInputAccessoryView(sourceEditorViewController: Components.WKSourceEditorViewController) {
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

        sourceEditor.resignFirstResponder()
        
        let previewVC = EditPreviewViewController(articleURL: pageURL)
        previewVC.theme = theme
        previewVC.sectionID = sectionID
        previewVC.languageCode = pageURL.wmf_languageCode
        previewVC.wikitext = sourceEditor.editedWikitext
        previewVC.delegate = self
        navigationController?.pushViewController(previewVC, animated: true)
    }
    
    func sectionEditorNavigationItemController(_ sectionEditorNavigationItemController: SectionEditorNavigationItemController, didTapCloseButton closeButton: UIBarButtonItem) {
        delegate?.pageEditorDidCancelEditing(self, navigateToURL: nil)
    }
    
    func sectionEditorNavigationItemController(_ sectionEditorNavigationItemController: SectionEditorNavigationItemController, didTapUndoButton undoButton: UIBarButtonItem) {
    }
    
    func sectionEditorNavigationItemController(_ sectionEditorNavigationItemController: SectionEditorNavigationItemController, didTapRedoButton redoButton: UIBarButtonItem) {
    }
    
    func sectionEditorNavigationItemController(_ sectionEditorNavigationItemController: SectionEditorNavigationItemController, didTapReadingThemesControlsButton readingThemesControlsButton: UIBarButtonItem) {
        showReadingThemesControlsPopup(on: self, responder: self, theme: theme)
    }
    
    func sectionEditorNavigationItemController(_ sectionEditorNavigationItemController: SectionEditorNavigationItemController, didTapEditNoticesButton: UIBarButtonItem) {
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
        guard let saveVC = EditSaveViewController.wmf_initialViewControllerFromClassStoryboard() else {
            return
        }

        saveVC.savedData = editConfirmationSavedData
        saveVC.dataStore = dataStore
        saveVC.articleURL = pageURL
        saveVC.sectionID = sectionID
        saveVC.languageCode = pageURL.wmf_languageCode
        saveVC.wikitext = editPreviewViewController.wikitext
        saveVC.delegate = self
        saveVC.theme = self.theme
        
        navigationController?.pushViewController(saveVC, animated: true)
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
