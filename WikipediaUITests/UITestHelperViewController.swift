import Components
import WMF

public class UITestHelperViewController: WKCanvasViewController {

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
                                                              accessibilityLabelButtonFormatHeading: CommonStrings.accessibilityLabelButtonFormatHeading,
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
                                                              accessibilityLabelButtonClearFormatting: CommonStrings.accessibilityLabelButtonClearFormatting,
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

        let accessibilityId = WKSourceEditorAccessibilityIdentifiers(
            textView: SourceEditorAccessibilityIdentifiers.textView.rawValue,
            findButton: SourceEditorAccessibilityIdentifiers.findButton.rawValue,
            showMoreButton: SourceEditorAccessibilityIdentifiers.showMoreButton.rawValue,
            closeButton: SourceEditorAccessibilityIdentifiers.closeButton.rawValue,
            formatTextButton: SourceEditorAccessibilityIdentifiers.formatTextButton.rawValue,
            formatHeadingButton: SourceEditorAccessibilityIdentifiers.formatHeadingButton.rawValue,
            expandingToolbar: SourceEditorAccessibilityIdentifiers.expandingToolbar.rawValue,
            highlightToolbar: SourceEditorAccessibilityIdentifiers.highlightToolbar.rawValue,
            findToolbar: SourceEditorAccessibilityIdentifiers.findButton.rawValue,
            mainInputView: SourceEditorAccessibilityIdentifiers.mainInputView.rawValue,
            headerSelectInputView: SourceEditorAccessibilityIdentifiers.headerSelectInputView.rawValue
          )

        let textAlignment: NSTextAlignment = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft ? .right : .left
        let viewModel = WKSourceEditorViewModel(configuration: .full, initialText: "UITest", accessibilityIdentifiers: accessibilityId, localizedStrings: localizedStrings, isSyntaxHighlightingEnabled: true, textAlignment: textAlignment)
        let editor = WKSourceEditorViewController(viewModel: viewModel, delegate: self)

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


extension UITestHelperViewController: WKSourceEditorViewControllerDelegate {
    public func sourceEditorViewControllerDidTapImage() {
        
    }
    
    public func sourceEditorViewControllerDidTapLink(parameters: Components.WKSourceEditorFormatterLinkWizardParameters) {
        
    }
    
    public func sourceEditorViewControllerDidRemoveFindInputAccessoryView(sourceEditorViewController: Components.WKSourceEditorViewController) {
        
    }
    
    public func sourceEditorViewControllerDidTapFind(sourceEditorViewController: Components.WKSourceEditorViewController) {

    }
    

}


