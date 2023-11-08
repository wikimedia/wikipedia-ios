import UIKit
import Components
import WMF

protocol PageEditorViewControllerDelegate: AnyObject {
    func pageEditorDidCancelEditing(_ pageEditor: PageEditorViewController, navigateToURL: URL?)
}

final class PageEditorViewController: UIViewController {
    
    // MARK: - Properties
    
    private let pageURL: URL
    private let sectionID: Int?
    private let dataStore: MWKDataStore
    private weak var delegate: PageEditorViewControllerDelegate?
    private let theme: Theme
    
    private let fetcher: SectionFetcher
    private var sourceEditor: WKSourceEditorViewController!
    private var editorTopConstraint: NSLayoutConstraint!
    
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

        let localizedStrings = WKSourceEditorLocalizedStrings(inputViewTextFormatting: PageEditorLocalizedStrings.textFormatting,
                                                              inputViewStyle: PageEditorLocalizedStrings.style,
                                                              inputViewClearFormatting: PageEditorLocalizedStrings.clearFormatting,
                                                              inputViewParagraph: PageEditorLocalizedStrings.paragraph,
                                                              inputViewHeading: PageEditorLocalizedStrings.heading,
                                                              inputViewSubheading1: PageEditorLocalizedStrings.subheading1,
                                                              inputViewSubheading2: PageEditorLocalizedStrings.subheading2,
                                                              inputViewSubheading3: PageEditorLocalizedStrings.subheading3,
                                                              inputViewSubheading4: PageEditorLocalizedStrings.subheading4,
                                                              findReplaceTypeSingle: PageEditorLocalizedStrings.findAndReplaceSingle,
                                                              findReplaceTypeAll: PageEditorLocalizedStrings.findAndReplaceAll,
                                                              findReplaceWith: PageEditorLocalizedStrings.replaceWith,
                                                              accessibilityLabelButtonFormatText: PageEditorLocalizedStrings.accessibilityLabelButtonFormatText,
                                                              accessibilityLabelButtonFormatHeading: PageEditorLocalizedStrings.accessibilityLabelButtonFormatHeading,
                                                              accessibilityLabelButtonCitation: PageEditorLocalizedStrings.accessibilityLabelButtonCitation,
                                                              accessibilityLabelButtonCitationSelected: PageEditorLocalizedStrings.accessibilityLabelButtonCitationSelected,
                                                              accessibilityLabelButtonLink: PageEditorLocalizedStrings.accessibilityLabelButtonBold,
                                                              accessibilityLabelButtonLinkSelected: PageEditorLocalizedStrings.accessibilityLabelButtonLinkSelected,
                                                              accessibilityLabelButtonTemplate: PageEditorLocalizedStrings.accessibilityLabelButtonTemplate,
                                                              accessibilityLabelButtonTemplateSelected: PageEditorLocalizedStrings.accessibilityLabelButtonTemplateSelected,
                                                              accessibilityLabelButtonMedia: PageEditorLocalizedStrings.accessibilityLabelButtonMedia,
                                                              accessibilityLabelButtonFind: PageEditorLocalizedStrings.accessibilityLabelButtonFind,
                                                              accessibilityLabelButtonListUnordered: PageEditorLocalizedStrings.accessibilityLabelButtonListUnordered,
                                                              accessibilityLabelButtonListUnorderedSelected: PageEditorLocalizedStrings.accessibilityLabelButtonListUnorderedSelected,
                                                              accessibilityLabelButtonListOrdered: PageEditorLocalizedStrings.accessibilityLabelButtonListOrdered,
                                                              accessibilityLabelButtonListOrderedSelected: PageEditorLocalizedStrings.accessibilityLabelButtonListOrderedSelected,
                                                              accessibilityLabelButtonInceaseIndent: PageEditorLocalizedStrings.accessibilityLabelButtonIncreaseIndent,
                                                              accessibilityLabelButtonDecreaseIndent: PageEditorLocalizedStrings.accessibilityLabelButtonDecreaseIndent,
                                                              accessibilityLabelButtonCursorUp: PageEditorLocalizedStrings.accessibilityLabelButtonCursorUp,
                                                              accessibilityLabelButtonCursorDown: PageEditorLocalizedStrings.accessibilityLabelButtonCursorDown,
                                                              accessibilityLabelButtonCursorLeft: PageEditorLocalizedStrings.accessibilityLabelButtonCursorLeft,
                                                              accessibilityLabelButtonCursorRight: PageEditorLocalizedStrings.accessibilityLabelButtonCursorRight,
                                                              accessibilityLabelButtonBold: PageEditorLocalizedStrings.accessibilityLabelButtonBold,
                                                              accessibilityLabelButtonBoldSelected: PageEditorLocalizedStrings.accessibilityLabelButtonBoldSelected,
                                                              accessibilityLabelButtonItalics: PageEditorLocalizedStrings.accessibilityLabelButtonItalics,
                                                              accessibilityLabelButtonItalicsSelected: PageEditorLocalizedStrings.accessibilityLabelButtonItalicsSelected,
                                                              accessibilityLabelButtonClearFormatting: PageEditorLocalizedStrings.accessibilityLabelButtonClearFormatting,
                                                              accessibilityLabelButtonShowMore: PageEditorLocalizedStrings.accessibilityLabelButtonShowMore,
                                                              accessibilityLabelButtonComment: PageEditorLocalizedStrings.accessibilityLabelButtonComment,
                                                              accessibilityLabelButtonCommentSelected: PageEditorLocalizedStrings.accessibilityLabelButtonCommentSelected,
                                                              accessibilityLabelButtonSuperscript: PageEditorLocalizedStrings.accessibilityLabelButtonSuperscript,
                                                              accessibilityLabelButtonSuperscriptSelected: PageEditorLocalizedStrings.accessibilityLabelButtonSuperscriptSelected,
                                                              accessibilityLabelButtonSubscript: PageEditorLocalizedStrings.accessibilityLabelButtonSubscript,
                                                              accessibilityLabelButtonSubscriptSelected: PageEditorLocalizedStrings.accessibilityLabelButtonSubscriptSelected,
                                                              accessibilityLabelButtonUnderline: PageEditorLocalizedStrings.accessibilityLabelButtonUnderline,
                                                              accessibilityLabelButtonUnderlineSelected: PageEditorLocalizedStrings.accessibilityLabelButtonUnderlineSelected,
                                                              accessibilityLabelButtonStrikethrough: PageEditorLocalizedStrings.accessibilityLabelButtonStrikethrough,
                                                              accessibilityLabelButtonStrikethroughSelected: PageEditorLocalizedStrings.accessibilityLabelButtonStrikethroughSelected,
                                                              accessibilityLabelButtonCloseMainInputView: PageEditorLocalizedStrings.accessibilityLabelButtonCloseMainInputView,
                                                              accessibilityLabelButtonCloseHeaderSelectInputView: PageEditorLocalizedStrings.accessibilityLabelButtonCloseHeaderSelectInputView,
                                                              accessibilityLabelFindTextField: PageEditorLocalizedStrings.accessibilityLabelButtonFind,
                                                              accessibilityLabelFindButtonClear: PageEditorLocalizedStrings.accessibilityLabelButtonClearFormatting,
                                                              accessibilityLabelFindButtonClose: PageEditorLocalizedStrings.accessibilityLabelFindButtonClose,
                                                              accessibilityLabelFindButtonNext: PageEditorLocalizedStrings.accessibilityLabelFindButtonNext,
                                                              accessibilityLabelFindButtonPrevious: PageEditorLocalizedStrings.accessibilityLabelFindButtonPrevious,
                                                              accessibilityLabelReplaceTextField: PageEditorLocalizedStrings.accessibilityLabelReplaceTextField,
                                                              accessibilityLabelReplaceButtonClear: PageEditorLocalizedStrings.accessibilityLabelReplaceButtonClear,
                                                              accessibilityLabelReplaceButtonPerformFormat: PageEditorLocalizedStrings.accessibilityLabelReplaceButtonPerformFormat,
                                                              accessibilityLabelReplaceButtonSwitchFormat: PageEditorLocalizedStrings.accessibilityLabelReplaceButtonSwitchFormat,
                                                              accessibilityLabelReplaceTypeSingle: PageEditorLocalizedStrings.accessibilityLabelReplaceTypeSingle,
                                                              accessibilityLabelReplaceTypeAll: PageEditorLocalizedStrings.accessibilityLabelReplaceTypeAll)

        let viewModel = WKSourceEditorViewModel(configuration: .full, initialText: wikitext, localizedStrings: localizedStrings)
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
        
    }
    
    private func hideFocusNavigationView() {
        editorTopConstraint.constant = 0
        focusNavigationView.isHidden = true
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
}

// MARK: - Themeable

extension PageEditorViewController: Themeable {
    func apply(theme: Theme) {
        guard isViewLoaded else {
            return
        }
        
        navigationItemController.apply(theme: theme)
        view.backgroundColor = theme.colors.paperBackground
    }
}

// MARK: - WKSourceEditorViewControllerDelegate

extension PageEditorViewController: WKSourceEditorViewControllerDelegate {
    func sourceEditorViewControllerDidTapFind(sourceEditorViewController: WKSourceEditorViewController) {
        navigationItemController.progressButton.isEnabled = false
        navigationItemController.readingThemesControlsToolbarItem.isEnabled = false
        showFocusNavigationView()
    }
}

// MARK: - PageEditorNavigationItemControllerDelegate

extension PageEditorViewController: SectionEditorNavigationItemControllerDelegate {
    func sectionEditorNavigationItemController(_ sectionEditorNavigationItemController: SectionEditorNavigationItemController, didTapProgressButton progressButton: UIBarButtonItem) {
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
    }
    
    func toggleSyntaxHighlighting(_ controller: ReadingThemesControlsViewController) {
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

enum SourceEditorAccessibilityIdentifiers: String {
    case entryButton = "Source Editor Entry Button"
    case textView = "Source Editor TextView"
    case findButton = "Source Editor Find Button"
    case showMoreButton = "Source Editor Show More Button"
    case closeButton = "Source Editor Close Button"
    case formatTextButton = "Source Editor Format Text Button"
    case formatHeadingButton = "Source Editor Format Heading Button"
    case expandingToolbar = "Source Editor Expanding Toolbar"
    case highlightToolbar = "Source Editor Highlight Toolbar"
    case findToolbar = "Source Editor Find Toolbar"
    case mainInputView = "Source Editor Main Input View"
    case headerSelectInputView = "Source Editor Header Select Input View"
}


extension PageEditorViewController {

    enum PageEditorLocalizedStrings {

        static let textFormatting = WMFLocalizedString("source-editor-text-formatting", value: "Text Formatting", comment: "Label for text formatting section on the page editor")
        static let style = WMFLocalizedString("source-editor-style", value: "Style", comment: "Label for style formatting section on the page editor ")
        static let clearFormatting = WMFLocalizedString("source-editor-clear-formatting", value: "Clear formatting", comment: "Label for clear formatting on the page editor")
        static let paragraph = WMFLocalizedString("source-editor-paragraph", value: "Paragraph", comment: "Label for paragraph formatting section on the page editor")
        static let heading = WMFLocalizedString("source-editor-heading", value: "Heading", comment: "Label for heading formatting button on section editor")
        static let subheading1 = WMFLocalizedString("source-editor-subheading1", value: "Subheading 1", comment: "Label for subheading 1 formatting button on the page editor")
        static let subheading2 = WMFLocalizedString("source-editor-subheading2", value: "Subheading 2", comment: "Label for subheading 2 formatting button on the page editor")
        static let subheading3 = WMFLocalizedString("source-editor-subheading3", value: "Subheading 3", comment: "Label for subheading 3 formatting button on the page editor")
        static let subheading4 = WMFLocalizedString("source-editor-subheading3", value: "Subheading 4", comment: "Label for subheading 4 formatting button on the page editor")
        static let findAndReplaceSingle = WMFLocalizedString("source-editor-find-replace-single", value: "Replace", comment: "Label for replace single string button on page editor")
        static let findAndReplaceAll = WMFLocalizedString("source-editor-find-replace-all", value: "Replace all", comment: "Label for replace all ocurrences of a string on the peage editor")
        static let replaceWith = WMFLocalizedString("source-editor-find-replace-with", value: "Replace with...", comment: "Lable for replace with string button on page editor")
        static let accessibilityLabelButtonFormatText = WMFLocalizedString("source-editor-accessibility-label-format-text", value: "Show text formatting menu", comment: "Accessibility label for text formatting menu button on the page editor")
        static let accessibilityLabelButtonFormatHeading = WMFLocalizedString("source-editor-accessibility-label-format-heading", value: "Show text style menu", comment: "Accessibility label for heading style formatting menu button on the page editor")
        static let accessibilityLabelButtonCitation = WMFLocalizedString("source-editor-accessibility-label-citation", value: "Add reference syntax", comment: "Accessibility label for add reference syntax button on the page editor")
        static let  accessibilityLabelButtonCitationSelected = WMFLocalizedString("source-editor-accessibility-label-citation-selected", value: "Remove reference syntax", comment: "Accessibility label for remove reference syntax button on the page editor")
        static let accessibilityLabelButtonLink = WMFLocalizedString("source-editor-accessibility-label-link", value: "Add link syntax", comment: "Accessibility label for the add link syntax button on the page editor")
        static let accessibilityLabelButtonLinkSelected = WMFLocalizedString("source-editor-accessibility-label-link-selected", value: "Remove link syntax", comment: "Accessibility label for the remove link syntax button on the page editor")
        static let accessibilityLabelButtonTemplate = WMFLocalizedString("source-editor-accessibility-label-template", value: "Add template syntax", comment: "Accessibility label for the add template syntax button on the page editor")
        static let accessibilityLabelButtonTemplateSelected = WMFLocalizedString("source-editor-accessibility-label-template-selected", value: "Remove template syntax", comment: "Accessibility label for the remove template syntax button on the page editor")
        static let accessibilityLabelButtonMedia = WMFLocalizedString("source-editor-accessibility-label-media", value: "Insert media", comment: "Accessibility label for the insert media syntax button on the page editor")
        static let accessibilityLabelButtonFind = WMFLocalizedString("source-editor-accessibility-label-find", value: "Find in page", comment: "Accessibility label for the find in page button on the page editor")
        static let accessibilityLabelButtonListUnordered = WMFLocalizedString("source-editor-accessibility-label-unordered", value: "Make current line unordered list", comment: "Accessibility label for make unordered list button on the page editor")
        static let accessibilityLabelButtonListUnorderedSelected = WMFLocalizedString("source-editor-accessibility-label-unordered-selected", value: "Remove unordered list from current line", comment: "Accessibility label for remove unordered list button on the page editor")
        static let accessibilityLabelButtonListOrdered = WMFLocalizedString("source-editor-accessibility-label-ordered", value: "Make current line ordered list", comment: "Accessibility label for make ordered list button on the page editor")
        static let accessibilityLabelButtonListOrderedSelected = WMFLocalizedString("source-editor-accessibility-label-ordered-selected", value: "Remove ordered list from current line", comment: "accessibility label for remove ordered list button on the page editor")
        static let accessibilityLabelButtonIncreaseIndent = WMFLocalizedString("source-editor-accessibility-label-indent-increase", value: "Increase indent depth", comment: "Accessibility label for the increase indent button on the page editor")
        static let accessibilityLabelButtonDecreaseIndent = WMFLocalizedString("source-editor-accessibility-label-indent-decrease", value: "Decrease indent depth", comment: "Accessibility label for the decrease indent button on the page editor")
        static let accessibilityLabelButtonCursorUp = WMFLocalizedString("source-editor-accessibility-label-cursor-up", value: "Move cursor up", comment: "Accessibility label for the move cursor up button on the page editor")
        static let accessibilityLabelButtonCursorDown = WMFLocalizedString("source-editor-accessibility-label-cursor-down", value: "Move cursor down", comment: "Accessibility label for the move cursor down button on the page editor")
        static let accessibilityLabelButtonCursorLeft = WMFLocalizedString("source-editor-accessibility-label-cursor-left", value: "Move cursor left", comment: "Accessibility label for the move cursor left button the page editor")
        static let accessibilityLabelButtonCursorRight = WMFLocalizedString("source-editor-accessibility-label-cursor-right", value: "Move cursor right", comment: "Accessibility label for the move cursor right on the page editor")
        static let accessibilityLabelButtonBold = WMFLocalizedString("source-editor-accessibility-label-bold", value: "Add bold formatting", comment: "Accessibility label for the bold button on the page editor")
        static let accessibilityLabelButtonBoldSelected = WMFLocalizedString("source-editor-accessibility-label-bold-selected", value: "Remove bold formatting", comment: "Accessibility label for the selected bold button on the page editor")
        static let accessibilityLabelButtonItalics = WMFLocalizedString("source-editor-accessibility-label-italics", value: "Add italic formatting", comment: "Accessibility label for the italics button on the page editor")
        static let accessibilityLabelButtonItalicsSelected = WMFLocalizedString("source-editor-accessibility-label-italics-selected", value: "Remove italic formatting", comment: "Accessibility label for the selected italics button on the page editor")
        static let accessibilityLabelButtonClearFormatting = WMFLocalizedString("source-editor-accessibility-label-clear-formatting", value: "Clear formatting", comment: "Accessibility label for the clear formatting button on the page editor")
        static let accessibilityLabelButtonShowMore = WMFLocalizedString("source-editor-accessibility-label-format-text", value: "Show text formatting menu", comment: "Accessibility label for the show more button on the page editor")
        static let accessibilityLabelButtonComment = WMFLocalizedString("source-editor-accessibility-label-comment", value: "Add comment syntax", comment: "Accessibility label for the add comment button on the page editor")
        static let accessibilityLabelButtonCommentSelected = WMFLocalizedString("source-editor-accessibility-label-comment-selected", value: "Remove comment syntax", comment: "Accessibility label for the selected comment button on the page editor")
        static let accessibilityLabelButtonSuperscript = WMFLocalizedString("source-editor-accessibility-label-superscript", value: "Add superscript formatting", comment: "Accessibility label for the superscript button on the page editor")
        static let accessibilityLabelButtonSuperscriptSelected = WMFLocalizedString("source-editor-accessibility-label-superscript-selected", value: "Remove superscript formatting", comment: "Accessibility string for the selected superscript button on the page editor")
        static let accessibilityLabelButtonSubscript = WMFLocalizedString("source-editor-accessibility-label-subscript", value: "Add subscript formatting", comment: "Accessibility label for the subscript button on the page editor")
        static let accessibilityLabelButtonSubscriptSelected = WMFLocalizedString("source-editor-accessibility-label-subscript-selected", value: "Remove subscript formatting", comment: "Accessibility label for the selected subscript button on the page editor")
        static let accessibilityLabelButtonUnderline = WMFLocalizedString("source-editor-accessibility-label-underline", value: "Add underline", comment: "Accessibility label for the underline button on the page editor")
        static let accessibilityLabelButtonUnderlineSelected = WMFLocalizedString("source-editor-accessibility-label-underline-selected", value: "Remove underline", comment: "Accessibility label for the selected underline button on the page editor")
        static let accessibilityLabelButtonStrikethrough = WMFLocalizedString("source-editor-accessibility-label-strikethrough", value: "Add strikethrough", comment: "Accessibility label for the strikethrough button on the page editor")
        static let accessibilityLabelButtonStrikethroughSelected = WMFLocalizedString("source-editor-accessibility-label-strikethrough-selected", value: "Remove strikethrough", comment: "Accessibility label for the selected strikethrough button on the page editor")
        static let accessibilityLabelButtonCloseMainInputView = WMFLocalizedString("source-editor-accessibility-label-close-main-input", value: "Close text formatting menu", comment: "Accessibility label for the close formatting menu button on the page editor")
        static let accessibilityLabelButtonCloseHeaderSelectInputView = WMFLocalizedString("source-editor-accessibility-label-close-header-select", value: "Close text style menu", comment: "Accessibility label for the close text style menu button on the page editor")
        static let accessibilityLabelFindTextField = WMFLocalizedString("source-editor-accessibility-label-find-text-field", value: "Find", comment: "Accessibility label for the find text field on the page editor")
        static let accessibilityLabelFindButtonClear = WMFLocalizedString("source-editor-accessibility-label-find-button-clear", value: "Clear find", comment: "Accessibility label for the clear find button on the page editor")
        static let accessibilityLabelFindButtonClose = WMFLocalizedString("source-editor-accessibility-label-find-button-close", value: "Close find", comment: "Accessibility label for the close find button on the page editor")
        static let accessibilityLabelFindButtonNext = WMFLocalizedString("source-editor-accessibility-label-find-button-next", value: "Next find result", comment: "Accessibility label for the find next result on the page editor")
        static let accessibilityLabelFindButtonPrevious = WMFLocalizedString("source-editor-accessibility-label-find-button-prev", value: "Previous find result", comment: "Accessibility label for the find previous result button on the page editor")
        static let accessibilityLabelReplaceTextField = WMFLocalizedString("source-editor-accessibility-label-replace-text-field", value: "Replace", comment: "Accessibility label for the replace text field on the page editor")
        static let accessibilityLabelReplaceButtonClear = WMFLocalizedString("source-editor-accessibility-label-replace-button-clear", value: "Clear replace", comment: "Accessibility label for the clear replace field button on the page editor")
        static let accessibilityLabelReplaceButtonPerformFormat = WMFLocalizedString("source-editor-accessibility-label-replace-button-perform-format", value: "Perform replace operation. Replace type is set to %@", comment: "Accessibility label for the perform replace button on the page editor") // TODO get replaced text correctly
        static let accessibilityLabelReplaceButtonSwitchFormat = WMFLocalizedString("source-editor-accessibility-label-replace-button-switch-format", value: "Switch replace type. Currently set to %@. Select to change.", comment: "Accessibility label for switch format button on page editor")
        static let accessibilityLabelReplaceTypeSingle = WMFLocalizedString("source-editor-accessibility-label-replace-type-single", value: "Replace single instance", comment: "Accessibility label for replace single instance button on the page editor")
        static let accessibilityLabelReplaceTypeAll = WMFLocalizedString("source-editor-accessibility-label-replace-type-all", value: "Replace all instances", comment: "Accessibility label for the replace all instances button on the page editor")
    }
}
