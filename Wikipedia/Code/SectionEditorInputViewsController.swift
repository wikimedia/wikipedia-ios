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

        messagingController.findInPageDelegate = self

        inputViewType = nil
        inputAccessoryViewType = .default
    }


    func textSelectionDidChange(isRangeSelected: Bool) {
        if inputViewType == nil {
            if inputAccessoryViewType == .findInPage {
                messagingController.clearSearch()
                findInPageView?.reset()
            }
            inputAccessoryViewType = isRangeSelected ? .highlight : .default
        }
        defaultEditToolbarView?.enableAllButtons()
        contextualHighlightEditToolbarView?.enableAllButtons()
        defaultEditToolbarView?.deselectAllButtons()
        contextualHighlightEditToolbarView?.deselectAllButtons()
        textFormattingInputViewController.textSelectionDidChange(isRangeSelected: isRangeSelected)
    }

    func disableButton(button: SectionEditorWebViewMessagingController.Button) {
        defaultEditToolbarView?.disableButton(button)
        contextualHighlightEditToolbarView?.disableButton(button)
        textFormattingInputViewController.disableButton(button: button)
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
        findInPageView?.apply(theme)
    }

    private var findInPageFocusedMatchID: String?

    func didTransitionToNewCollection() {
        scrollToFindInPageMatchWithID(findInPageFocusedMatchID)
    }

    func keyboardDidHide() {
        guard inputViewType != nil else {
            return
        }
        inputViewType = nil
        inputAccessoryViewType = .default
    }
}

// MARK: TextFormattingDelegate

extension SectionEditorInputViewsController: TextFormattingDelegate {
    func textFormattingProvidingDidTapTextSize(newSize: TextSizeType) {
        messagingController.setTextSize(newSize: newSize.rawValue)
    }

    func textFormattingProvidingDidTapFindInPage() {
        inputAccessoryViewType = .findInPage
        UIView.performWithoutAnimation {
            findInPageView?.show()
        }
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

extension SectionEditorInputViewsController: SectionEditorWebViewMessagingControllerFindInPageDelegate {
    func sectionEditorWebViewMessagingControllerDidReceiveFindInPagesMatchesMessage(_ sectionEditorWebViewMessagingController: SectionEditorWebViewMessagingController, matchesCount: Int, matchIndex: Int, matchID: String) {
        guard inputAccessoryViewType == .findInPage else {
            return
        }
        findInPageView?.update(forCurrentMatch: matchIndex, matchesCount: UInt(matchesCount))
        scrollToFindInPageMatchWithID(matchID)
        findInPageFocusedMatchID = matchID
    }

    private func scrollToFindInPageMatchWithID(_ matchID: String?) {
        guard let matchID = matchID else {
            return
        }
        webView.getScrollRectForHtmlElement(withId: matchID) { [weak self] (matchRect) in
            guard
                let findInPageView = self?.findInPageView,
                let webView = self?.webView,
                let findInPageViewY = findInPageView.window?.convert(.zero, from: findInPageView).y
            else {
                return
            }
            let matchRectY = matchRect.minY
            let contentInsetTop = webView.scrollView.contentInset.top
            let newOffsetY = matchRectY + contentInsetTop - (0.5 * findInPageViewY) + (0.5 * matchRect.height)
            let centeredOffset = CGPoint(x: webView.scrollView.contentOffset.x, y: newOffsetY)
            self?.scrollToOffset(centeredOffset, in: webView)
        }
    }

    private func scrollToOffset(_ newOffset: CGPoint, in webView: WKWebView) {
        guard !newOffset.x.isNaN && !newOffset.y.isNaN && newOffset.x.isFinite && newOffset.y.isFinite else {
            return
        }
        let safeOffset = CGPoint(x: newOffset.x, y: max(0 - webView.scrollView.contentInset.top, newOffset.y))
        webView.scrollView.setContentOffset(safeOffset, animated: true)
    }
}

extension SectionEditorInputViewsController: WMFFindInPageKeyboardBarDelegate {
    func keyboardBarReturnTapped(_ keyboardBar: WMFFindInPageKeyboardBar!) {
        messagingController.findNext() // TODO ?
    }

    func keyboardBar(_ keyboardBar: WMFFindInPageKeyboardBar!, searchTermChanged term: String!) {
        messagingController.find(text: term)
    }

    func keyboardBarCloseButtonTapped(_ keyboardBar: WMFFindInPageKeyboardBar!) {
        messagingController.clearSearch()
        keyboardBar.reset()
        inputAccessoryViewType = previousInputAccessoryViewType
        if keyboardBar.isVisible() {
            messagingController.focus()
        }
    }

    func keyboardBarClearButtonTapped(_ keyboardBar: WMFFindInPageKeyboardBar!) {
        messagingController.clearSearch()
        keyboardBar.reset()
    }

    func keyboardBarPreviousButtonTapped(_ keyboardBar: WMFFindInPageKeyboardBar!) {
        messagingController.findPrevious()
    }

    func keyboardBarNextButtonTapped(_ keyboardBar: WMFFindInPageKeyboardBar!) {
        messagingController.findNext()
    }
}
