protocol SectionEditorInputViewsSource: class {
    var inputViewController: UIInputViewController? { get }
}

class SectionEditorInputViewsController: NSObject, SectionEditorInputViewsSource, Themeable {
    let webView: SectionEditorWebView
    let messagingController: SectionEditorWebViewMessagingController

    let textFormattingInputViewController = TextFormattingInputViewController.wmf_viewControllerFromStoryboardNamed("TextFormatting")
    let defaultEditToolbarView = DefaultEditToolbarView.wmf_viewFromClassNib()
    let contextualHighlightEditToolbarView = ContextualHighlightEditToolbarView.wmf_viewFromClassNib()
    let findInPageView = WMFFindInPageKeyboardBar.wmf_viewFromClassNib()

    init(webView: SectionEditorWebView, messagingController: SectionEditorWebViewMessagingController) {
        self.webView = webView
        self.messagingController = messagingController

        super.init()

        textFormattingInputViewController.delegate = self
        defaultEditToolbarView?.delegate = self
        contextualHighlightEditToolbarView?.delegate = self
        findInPageView?.delegate = self

        inputViewType = nil
        inputAccessoryViewType = .default
    }


    func textSelectionDidChange(isRangeSelected: Bool) {
        if inputViewType == nil, inputAccessoryViewType != .findInPage {
            inputAccessoryViewType = isRangeSelected ? .highlight : .default
        }
        defaultEditToolbarView?.deselectAllButtons()
        contextualHighlightEditToolbarView?.deselectAllButtons()
        textFormattingInputViewController.textSelectionDidChange(isRangeSelected: isRangeSelected)
    }

    func buttonSelectionDidChange(button: SectionEditorWebViewMessagingController.Button) {
        defaultEditToolbarView?.selectButton(button)
        contextualHighlightEditToolbarView?.selectButton(button)
        textFormattingInputViewController.buttonSelectionDidChange(button: button)
    }

    var inputViewType: TextFormattingInputViewController.InputViewType?

    var inputViewController: UIInputViewController? {
        guard let inputViewType = inputViewType else {
            return nil
        }
        textFormattingInputViewController.inputViewType = inputViewType
        return textFormattingInputViewController
    }

    private enum InputAccessoryViewType {
        case `default`
        case highlight
        case findInPage
    }

    private var previousInputAccessoryViewType: InputAccessoryViewType?
    private var inputAccessoryViewType: InputAccessoryViewType? {
        didSet {
            previousInputAccessoryViewType = oldValue
            webView.setInputAccessoryView(inputAccessoryView)
        }
    }

    private var inputAccessoryView: UIView? {
        guard let inputAccessoryViewType = inputAccessoryViewType else {
            return nil
        }

        let maybeView: Any?

        switch inputAccessoryViewType {
        case .default:
            maybeView = defaultEditToolbarView
        case .highlight:
            maybeView = contextualHighlightEditToolbarView
        case .findInPage:
            maybeView = findInPageView
        }

        guard let inputAccessoryView = maybeView as? UIView else {
            assertionFailure("Couldn't get preferredInputAccessoryView")
            return nil
        }

        return inputAccessoryView
    }
    
    func apply(theme: Theme) {
        textFormattingInputViewController.apply(theme: theme)
        defaultEditToolbarView?.apply(theme: theme)
        contextualHighlightEditToolbarView?.apply(theme: theme)
    }
}

// MARK: TextFormattingDelegate

extension SectionEditorInputViewsController: TextFormattingDelegate {
    func textFormattingProvidingDidTapTextSize(newSize: TextSizeType) {
        messagingController.setTextSize(newSize: newSize.rawValue)
    }

    func textFormattingProvidingDidTapFindInPage() {
        inputAccessoryViewType = .findInPage
    }

    func textFormattingProvidingDidTapCursorUp() {
        messagingController.moveCursorUp()
    }

    func textFormattingProvidingDidTapCursorDown() {
        messagingController.moveCursorDown()
    }

    func textFormattingProvidingDidTapCursorRight() {
        messagingController.moveCursorRight()
    }

    func textFormattingProvidingDidTapCursorLeft() {
        messagingController.moveCursorLeft()
    }

    func textFormattingProvidingDidTapTextStyleFormatting() {
        inputViewType = .textStyle
        inputAccessoryViewType = nil
    }

    func textFormattingProvidingDidTapTextFormatting() {
        inputViewType = .textFormatting
        inputAccessoryViewType = nil
    }

    func textFormattingProvidingDidTapClose() {
        inputViewType = nil
        inputAccessoryViewType = previousInputAccessoryViewType
    }

    func textFormattingProvidingDidTapHeading(depth: Int) {
        messagingController.setHeadingSelection(depth: depth)
    }

    func textFormattingProvidingDidTapBold() {
        messagingController.toggleBoldSelection()
    }

    func textFormattingProvidingDidTapItalics() {
        messagingController.toggleItalicSelection()
    }

    func textFormattingProvidingDidTapUnderline() {
        messagingController.toggleUnderline()
    }

    func textFormattingProvidingDidTapStrikethrough() {
        messagingController.toggleStrikethrough()
    }

    func textFormattingProvidingDidTapReference() {
        messagingController.toggleReferenceSelection()
    }

    func textFormattingProvidingDidTapTemplate() {
        messagingController.toggleTemplateSelection()
    }

    func textFormattingProvidingDidTapComment() {
        messagingController.toggleComment()
    }

    func textFormattingProvidingDidTapLink() {
        messagingController.toggleAnchorSelection()
    }

    func textFormattingProvidingDidTapIncreaseIndent() {
        messagingController.increaseIndentDepth()
    }

    func textFormattingProvidingDidTapDecreaseIndent() {
        messagingController.decreaseIndentDepth()
    }

    func textFormattingProvidingDidTapOrderedList() {
        messagingController.toggleOrderedListSelection()
    }

    func textFormattingProvidingDidTapUnorderedList() {
        messagingController.toggleUnorderedListSelection()
    }

    func textFormattingProvidingDidTapSuperscript() {
        messagingController.toggleSuperscript()
    }

    func textFormattingProvidingDidTapSubscript() {
        messagingController.toggleSubscript()
    }
}

extension SectionEditorInputViewsController: WMFFindInPageKeyboardBarDelegate {
    func keyboardBar(_ keyboardBar: WMFFindInPageKeyboardBar!, searchTermChanged term: String!) {
        messagingController.search(text: term)
    }

    func keyboardBarCloseButtonTapped(_ keyboardBar: WMFFindInPageKeyboardBar!) {
        messagingController.clearSearch()
        inputAccessoryViewType = previousInputAccessoryViewType
    }

    func keyboardBarClearButtonTapped(_ keyboardBar: WMFFindInPageKeyboardBar!) {
        messagingController.clearSearch()
    }

    func keyboardBarPreviousButtonTapped(_ keyboardBar: WMFFindInPageKeyboardBar!) {
        //
    }

    func keyboardBarNextButtonTapped(_ keyboardBar: WMFFindInPageKeyboardBar!) {
        //
    }
}
