import WMFComponents
import WMF

public class UITestHelperViewController: WMFCanvasViewController {

    var theme: Theme

    public init(theme: Theme) {
        self.theme = theme
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        return stackView
    }()

    private lazy var sourceEditorButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.setTitle("Source Editor", for: .normal)
        button.accessibilityIdentifier = SourceEditorAccessibilityIdentifiers.entryButton.rawValue
        button.addTarget(self, action: #selector(tappedSourceEditor), for: .touchUpInside)
        return button
    }()

    @objc func tappedSourceEditor() {

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
            toolbarCursorPreviousButtonAccessibility: CommonStrings.editorToolbarButtonCursorNextAccessiblityLabel,
            toolbarCursorNextButtonAccessibility: CommonStrings.editorToolbarButtonCursorPreviousAccessiblityLabel,
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

        let accessibilityId = WMFSourceEditorAccessibilityIdentifiers(
            textView: SourceEditorAccessibilityIdentifiers.textView.rawValue,
            findButton: SourceEditorAccessibilityIdentifiers.findButton.rawValue,
            showMoreButton: SourceEditorAccessibilityIdentifiers.showMoreButton.rawValue,
            closeButton: SourceEditorAccessibilityIdentifiers.closeButton.rawValue,
            formatTextButton: SourceEditorAccessibilityIdentifiers.formatTextButton.rawValue,
            expandingToolbar: SourceEditorAccessibilityIdentifiers.expandingToolbar.rawValue,
            highlightToolbar: SourceEditorAccessibilityIdentifiers.highlightToolbar.rawValue,
            findToolbar: SourceEditorAccessibilityIdentifiers.findButton.rawValue,
            inputView: SourceEditorAccessibilityIdentifiers.inputView.rawValue
          )

        let textAlignment: NSTextAlignment = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft ? .right : .left
        let viewModel = WMFSourceEditorViewModel(configuration: .full, initialText: "UITest", accessibilityIdentifiers: accessibilityId, localizedStrings: localizedStrings, isSyntaxHighlightingEnabled: true, textAlignment: textAlignment, needsReadOnly: false, onloadSelectRange: nil)
        let editor = WMFSourceEditorViewController(viewModel: viewModel, delegate: self)

        present(editor, animated: false)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        setupInitialViews()

        stackView.addArrangedSubview(sourceEditorButton)
        self.title = "UI Testing"
    }

    func setupInitialViews() {
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.frameLayoutGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.frameLayoutGuide.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.frameLayoutGuide.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

    }

}


extension UITestHelperViewController: WMFSourceEditorViewControllerDelegate {
    public func sourceEditorDidChangeUndoState(_ sourceEditorViewController: WMFComponents.WMFSourceEditorViewController, canUndo: Bool, canRedo: Bool) {
        
    }
    
    public func sourceEditorDidChangeText(_ sourceEditorViewController: WMFComponents.WMFSourceEditorViewController, didChangeText: Bool) {
        
    }
    
    public func sourceEditorViewControllerDidTapImage() {
        
    }
    
    public func sourceEditorViewControllerDidTapLink(parameters: WMFComponents.WMFSourceEditorFormatterLinkWizardParameters) {
        
    }
    
    public func sourceEditorViewControllerDidRemoveFindInputAccessoryView(_ sourceEditorViewController: WMFComponents.WMFSourceEditorViewController) {
        
    }
    
    public func sourceEditorViewControllerDidTapFind(_ sourceEditorViewController: WMFComponents.WMFSourceEditorViewController) {

    }
    

}


