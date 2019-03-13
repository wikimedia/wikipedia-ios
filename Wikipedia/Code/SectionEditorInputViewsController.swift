protocol SectionEditorInputViewsSource: class {
    var inputViewController: UIInputViewController? { get }
}

class SectionEditorInputViewsController: NSObject, SectionEditorInputViewsSource, Themeable {
    let webView: SectionEditorWebView
    let messagingController: SectionEditorWebViewMessagingController

    let textFormattingInputViewController = TextFormattingInputViewController.wmf_viewControllerFromStoryboardNamed("TextFormatting")
    let defaultEditToolbarView = DefaultEditToolbarView.wmf_viewFromClassNib()
    let contextualHighlightEditToolbarView = ContextualHighlightEditToolbarView.wmf_viewFromClassNib()
    let findAndReplaceView = FindAndReplaceKeyboardBar.wmf_viewFromClassNib()

    init(webView: SectionEditorWebView, messagingController: SectionEditorWebViewMessagingController, findAndReplaceAlertDelegate: FindAndReplaceKeyboardBarAlertDelegate) {
        self.webView = webView
        self.messagingController = messagingController

        super.init()

        textFormattingInputViewController.delegate = self
        defaultEditToolbarView?.delegate = self
        contextualHighlightEditToolbarView?.delegate = self
        findAndReplaceView?.delegate = self
        findAndReplaceView?.alertDelegate = findAndReplaceAlertDelegate

        messagingController.findInPageDelegate = self

        inputViewType = nil
        inputAccessoryViewType = .default
    }


    func textSelectionDidChange(isRangeSelected: Bool) {
        if inputViewType == nil {
            if inputAccessoryViewType == .findInPage {
                messagingController.clearSearch()
                findAndReplaceView?.reset()
            }
            inputAccessoryViewType = isRangeSelected ? .highlight : .default
        }
        defaultEditToolbarView?.enableAllButtons()
        contextualHighlightEditToolbarView?.enableAllButtons()
        defaultEditToolbarView?.deselectAllButtons()
        contextualHighlightEditToolbarView?.deselectAllButtons()
        textFormattingInputViewController.textSelectionDidChange(isRangeSelected: isRangeSelected)
    }

    func disableButton(button: SectionEditorButton) {
        defaultEditToolbarView?.disableButton(button)
        contextualHighlightEditToolbarView?.disableButton(button)
        textFormattingInputViewController.disableButton(button: button)
    }

    func buttonSelectionDidChange(button: SectionEditorButton) {
        defaultEditToolbarView?.selectButton(button)
        contextualHighlightEditToolbarView?.selectButton(button)
        textFormattingInputViewController.buttonSelectionDidChange(button: button)
    }
    
    func updateReplaceState(state: ReplaceState) {
        findAndReplaceView?.replaceState = state
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
            maybeView = findAndReplaceView
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
        findAndReplaceView?.apply(theme: theme)
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
            findAndReplaceView?.show()
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
    func sectionEditorWebViewMessagingControllerDidReceiveFindInPagesMatchesMessage(_ sectionEditorWebViewMessagingController: SectionEditorWebViewMessagingController, matchesCount: Int, matchIndex: Int, matchID: String?) {
        guard inputAccessoryViewType == .findInPage else {
            return
        }
        findAndReplaceView?.updateMatchCounts(index: matchIndex, total: UInt(matchesCount))
        scrollToFindInPageMatchWithID(matchID)
        findInPageFocusedMatchID = matchID
    }

    private func scrollToFindInPageMatchWithID(_ matchID: String?) {
        guard let matchID = matchID else {
            return
        }
        webView.getScrollRectForHtmlElement(withId: matchID) { [weak self] (matchRect) in
            guard
                let findAndReplaceView = self?.findAndReplaceView,
                let webView = self?.webView,
                let findAndReplaceViewY = findAndReplaceView.window?.convert(.zero, from: findAndReplaceView).y
            else {
                return
            }
            let matchRectY = matchRect.minY
            let contentInsetTop = webView.scrollView.contentInset.top
            let newOffsetY = matchRectY + contentInsetTop - (0.5 * findAndReplaceViewY) + (0.5 * matchRect.height)
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

extension SectionEditorInputViewsController: FindAndReplaceKeyboardBarDelegate {
    func keyboardBarDidTapReturn(_ keyboardBar: FindAndReplaceKeyboardBar) {
        messagingController.findNext()
    }
    
    func keyboardBar(_ keyboardBar: FindAndReplaceKeyboardBar, didChangeSearchTerm searchTerm: String?) {
        
        guard let searchTerm = searchTerm else {
            return
        }
        messagingController.find(text: searchTerm)
    }
    
    func keyboardBarDidTapClose(_ keyboardBar: FindAndReplaceKeyboardBar) {
        messagingController.replaceAll(text: "blerg")
        /*
         messagingController.clearSearch()
         keyboardBar.reset()
         inputAccessoryViewType = previousInputAccessoryViewType
         if keyboardBar.isVisible() {
         messagingController.focus()
         }
         */
    }
    
    func keyboardBarDidTapClear(_ keyboardBar: FindAndReplaceKeyboardBar) {
        messagingController.clearSearch()
        keyboardBar.reset()
    }
    
    func keyboardBarDidTapPrevious(_ keyboardBar: FindAndReplaceKeyboardBar) {
        messagingController.findPrevious()
    }
    
    func keyboardBarDidTapNext(_ keyboardBar: FindAndReplaceKeyboardBar) {
        messagingController.findNext()
    }
    
    func keyboardBarDidTapReplace(_ keyboardBar: FindAndReplaceKeyboardBar, replaceText: String, replaceState: ReplaceState) {
        switch replaceState {
        case .replace:
            messagingController.replaceSingle(text: replaceText)
        case .replaceAll:
            messagingController.replaceAll(text: replaceText)
        }
    }
}
