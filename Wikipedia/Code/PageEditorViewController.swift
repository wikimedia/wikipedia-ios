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
