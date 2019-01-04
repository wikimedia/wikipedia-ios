protocol SectionEditorInputViewsSource: class {
    var inputViewController: UIInputViewController? { get }
}

class SectionEditorInputViewsController: SectionEditorInputViewsSource {
    let webView: SectionEditorWebViewWithEditToolbar

    let textFormattingInputViewController = TextFormattingInputViewController.wmf_viewControllerFromStoryboardNamed("TextFormatting")
    let defaultEditToolbarView = DefaultEditToolbarView.wmf_viewFromClassNib()
    let contextualHighlightEditToolbarView = ContextualHighlightEditToolbarView.wmf_viewFromClassNib()

    init(webView: SectionEditorWebViewWithEditToolbar) {
        defer {
            inputAccessoryViewType = .default
        }

        self.webView = webView

        textFormattingInputViewController.delegate = self
        defaultEditToolbarView?.delegate = self
        contextualHighlightEditToolbarView?.delegate = self

        inputViewType = nil
        inputAccessoryViewType = .default
    }


    func textSelectionDidChange(isRangeSelected: Bool) {
        if inputViewType == nil {
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
    }

    private var previousInputAccessoryViewType: InputAccessoryViewType?
    private var inputAccessoryViewType: InputAccessoryViewType? {
        didSet {
            previousInputAccessoryViewType = oldValue
            webView.setInputAccessoryView(inputAccessoryView)
        }
    }

    private var inputAccessoryView: (UIView & Themeable)? {
        guard let inputAccessoryViewType = inputAccessoryViewType else {
            return nil
        }

        let maybeView: Any?

        switch inputAccessoryViewType {
        case .default:
            maybeView = defaultEditToolbarView
        case .highlight:
            maybeView = contextualHighlightEditToolbarView
        }

        guard let inputAccessoryView = maybeView as? UIView & Themeable else {
            assertionFailure("Couldn't get preferredInputAccessoryView")
            return nil
        }

        return inputAccessoryView
    }
}

// MARK: TextFormattingDelegate

extension SectionEditorInputViewsController: TextFormattingDelegate {
    func textFormattingProvidingDidTapMore() {
        //
    }

    func textFormattingProvidingDidTapCursorUp() {
        webView.moveCursorUp()
    }

    func textFormattingProvidingDidTapCursorDown() {
        webView.moveCursorDown()
    }

    func textFormattingProvidingDidTapCursorRight() {
        webView.moveCursorRight()
    }

    func textFormattingProvidingDidTapCursorLeft() {
        webView.moveCursorLeft()
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
        webView.setHeadingSelection(depth: depth)
    }

    func textFormattingProvidingDidTapBold() {
        webView.toggleBoldSelection()
    }

    func textFormattingProvidingDidTapItalics() {
        webView.toggleItalicSelection()
    }

    func textFormattingProvidingDidTapUnderline() {
        webView.toggleUnderline()
    }

    func textFormattingProvidingDidTapStrikethrough() {
        webView.toggleStrikethrough()
    }

    func textFormattingProvidingDidTapReference() {
        webView.toggleReferenceSelection()
    }

    func textFormattingProvidingDidTapTemplate() {
        webView.toggleTemplateSelection()
    }

    func textFormattingProvidingDidTapComment() {
        webView.toggleComment()
    }

    func textFormattingProvidingDidTapLink() {
        //
    }

    func textFormattingProvidingDidTapIncreaseIndent() {
        webView.increaseIndentDepth()
    }

    func textFormattingProvidingDidTapDecreaseIndent() {
        webView.decreaseIndentDepth()
    }

    func textFormattingProvidingDidTapOrderedList() {
        webView.toggleOrderedListSelection()
    }

    func textFormattingProvidingDidTapUnorderedList() {
        webView.toggleUnorderedListSelection()
    }

    func textFormattingProvidingDidTapSuperscript() {
        webView.toggleSuperscript()
    }

    func textFormattingProvidingDidTapSubscript() {
        webView.toggleSubscript()
    }
}
