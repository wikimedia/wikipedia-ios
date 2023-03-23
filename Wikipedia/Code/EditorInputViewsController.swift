protocol EditorInputViewsSource: AnyObject {
    var inputViewController: UIInputViewController? { get }
}

protocol EditorInputViewsControllerDelegate: AnyObject {
    func editorInputViewsControllerDidTapMediaInsert(_ editorInputViewsController: EditorInputViewsController)
    func editorInputViewsControllerDidTapLinkInsert(_ editorInputViewsController: EditorInputViewsController)
    
    // Additional methods for native editor
    func editorInputViewsControllerDidChangeInputAccessoryView(_ editorInputViewsController: EditorInputViewsController, inputAccessoryView: UIView?)
    func editorInputViewsControllerDidTapBold(_ editorInputViewsController: EditorInputViewsController)
    func editorInputViewsControllerDidTapItalic(_ editorInputViewsController: EditorInputViewsController)
    func editorInputViewsControllerDidTapHeading(_ editorInputViewsController: EditorInputViewsController, depth: Int)
    func editorInputViewsControllerDidTapTemplate(_ editorInputViewsController: EditorInputViewsController)
    func editorInputViewsControllerDidTapReference(_ editorInputViewsController: EditorInputViewsController)
    func editorInputViewsControllerDidTapSuperscript(_ editorInputViewsController: EditorInputViewsController)
    func editorInputViewsControllerDidTapSubscript(_ editorInputViewsController: EditorInputViewsController)
    func editorInputViewsControllerDidTapUnderline(_ editorInputViewsController: EditorInputViewsController)
    func editorInputViewsControllerDidTapStrikethrough(_ editorInputViewsController: EditorInputViewsController)
    func editorInputViewsControllerDidTapListBullet(_ editorInputViewsController: EditorInputViewsController)
    func editorInputViewsControllerDidTapListNumber(_ editorInputViewsController: EditorInputViewsController)
    func editorInputViewsControllerDidTapIndent(_ editorInputViewsController: EditorInputViewsController)
    func editorInputViewsControllerDidTapUnindent(_ editorInputViewsController: EditorInputViewsController)
}

extension EditorInputViewsControllerDelegate {
    func editorInputViewsControllerDidTapHeading(_ editorInputViewsController: EditorInputViewsController, depth: Int) {
        // nothing
    }
    
    func editorInputViewsControllerDidTapBold(_ editorInputViewsController: EditorInputViewsController) {
        // nothing
    }
    
    func editorInputViewsControllerDidTapItalic(_ editorInputViewsController: EditorInputViewsController) {
        // nothing
    }
    
    func editorInputViewsControllerDidTapTemplate(_ editorInputViewsController: EditorInputViewsController) {
        // nothing
    }
    
    func editorInputViewsControllerDidTapReference(_ editorInputViewsController: EditorInputViewsController) {
        // nothing
    }
    
    func editorInputViewsControllerDidTapSuperscript(_ editorInputViewsController: EditorInputViewsController) {
        // nothing
    }
    
    func editorInputViewsControllerDidTapSubscript(_ editorInputViewsController: EditorInputViewsController) {
        // nothing
    }
    
    func editorInputViewsControllerDidTapUnderline(_ editorInputViewsController: EditorInputViewsController) {
        // nothing
    }
    
    func editorInputViewsControllerDidTapStrikethrough(_ editorInputViewsController: EditorInputViewsController) {
        // nothing
    }
    
    func editorInputViewsControllerDidTapListBullet(_ editorInputViewsController: EditorInputViewsController) {
        // nothing
    }
    
    func editorInputViewsControllerDidTapListNumber(_ editorInputViewsController: EditorInputViewsController) {
        // nothing
    }
    
    func editorInputViewsControllerDidTapIndent(_ editorInputViewsController: EditorInputViewsController) {
        // nothing
    }
    
    func editorInputViewsControllerDidTapUnindent(_ editorInputViewsController: EditorInputViewsController) {
        // nothing
    }
    
    func editorInputViewsControllerDidChangeInputAccessoryView(_ editorInputViewsController: EditorInputViewsController, inputAccessoryView: UIView?) {
        // nothing
    }
}

class EditorInputViewsController: NSObject, EditorInputViewsSource, Themeable {
    let webView: SectionEditorWebView?
    let webMessagingController: SectionEditorWebViewMessagingController?

    let textFormattingInputViewController = TextFormattingInputViewController.wmf_viewControllerFromStoryboardNamed("TextFormatting")
    let defaultEditToolbarView = DefaultEditToolbarView.wmf_viewFromClassNib()
    let contextualHighlightEditToolbarView = ContextualHighlightEditToolbarView.wmf_viewFromClassNib()
    let findAndReplaceView: FindAndReplaceKeyboardBar? = FindAndReplaceKeyboardBar.wmf_viewFromClassNib()

    private var isRangeSelected = false

    weak var delegate: EditorInputViewsControllerDelegate?

    init(webView: SectionEditorWebView?, webMessagingController: SectionEditorWebViewMessagingController?, findAndReplaceDisplayDelegate: FindAndReplaceKeyboardBarDisplayDelegate) {
        self.webView = webView
        self.webMessagingController = webMessagingController

        super.init()

        textFormattingInputViewController.delegate = self
        defaultEditToolbarView?.delegate = self
        contextualHighlightEditToolbarView?.delegate = self
        findAndReplaceView?.delegate = self
        findAndReplaceView?.displayDelegate = findAndReplaceDisplayDelegate
        findAndReplaceView?.isShowingReplace = true

        webMessagingController?.findInPageDelegate = self

        inputViewType = nil
        inputAccessoryViewType = .default
    }

    func textSelectionDidChange(isRangeSelected: Bool) {
        self.isRangeSelected = isRangeSelected

        if inputViewType == nil {
            if inputAccessoryViewType == .findInPage {
                webMessagingController?.clearSearch()
                findAndReplaceView?.reset()
                findAndReplaceView?.hide()
            }
            inputAccessoryViewType = isRangeSelected ? .highlight : .default
        }

        defaultEditToolbarView?.enableAllButtons()
        contextualHighlightEditToolbarView?.enableAllButtons()
        defaultEditToolbarView?.deselectAllButtons()
        contextualHighlightEditToolbarView?.deselectAllButtons()
        textFormattingInputViewController.textSelectionDidChange(isRangeSelected: isRangeSelected)
    }

    func disableButton(button: EditorButton) {
        defaultEditToolbarView?.disableButton(button)
        contextualHighlightEditToolbarView?.disableButton(button)
        textFormattingInputViewController.disableButton(button: button)
    }

    func buttonSelectionDidChange(button: EditorButton) {
        defaultEditToolbarView?.selectButton(button)
        contextualHighlightEditToolbarView?.selectButton(button)
        textFormattingInputViewController.buttonSelectionDidChange(button: button)
    }
    
    func updateReplaceType(type: ReplaceType) {
        findAndReplaceView?.replaceType = type
    }

    var inputViewType: TextFormattingInputViewController.InputViewType?

    var suppressMenus: Bool = false {
        didSet {
            if suppressMenus {
                inputAccessoryViewType = nil
            }
        }
    }

    var inputViewController: UIInputViewController? {
        guard
            let inputViewType = inputViewType,
            !suppressMenus
        else {
            return nil
        }
        textFormattingInputViewController.inputViewType = inputViewType
        return textFormattingInputViewController
    }

    enum InputAccessoryViewType {
        case `default`
        case highlight
        case findInPage
    }

    private var previousInputAccessoryViewType: InputAccessoryViewType?
    private(set) var inputAccessoryViewType: InputAccessoryViewType? {
        didSet {
            previousInputAccessoryViewType = oldValue
            webView?.setInputAccessoryView(inputAccessoryView)
            delegate?.editorInputViewsControllerDidChangeInputAccessoryView(self, inputAccessoryView: inputAccessoryView)
        }
    }

    private var inputAccessoryView: UIView? {
        guard let inputAccessoryViewType = inputAccessoryViewType,
        !suppressMenus else {
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

    func resetFormattingAndStyleSubmenus() {
        guard inputViewType != nil else {
            return
        }
        inputViewType = nil
        inputAccessoryViewType = .default
    }
    
    func closeFindAndReplace() {
        
        guard let keyboardBar = findAndReplaceView else {
            return
        }
        
        webMessagingController?.clearSearch()
        keyboardBar.reset()
        keyboardBar.hide()
        inputAccessoryViewType = previousInputAccessoryViewType
        if keyboardBar.isVisible {
            webMessagingController?.selectLastFocusedMatch()
            webMessagingController?.focusWithoutScroll()
        }
    }
}

// MARK: TextFormattingDelegate

extension EditorInputViewsController: TextFormattingDelegate {
    func textFormattingProvidingDidTapMediaInsert() {
        delegate?.editorInputViewsControllerDidTapMediaInsert(self)
    }

    func textFormattingProvidingDidTapTextSize(newSize: TextSizeType) {
        webMessagingController?.setTextSize(newSize: newSize.rawValue)
    }

    func textFormattingProvidingDidTapFindInPage() {
        inputAccessoryViewType = .findInPage
        UIView.performWithoutAnimation {
            findAndReplaceView?.show()
        }
    }

    func textFormattingProvidingDidTapCursorUp() {
        webMessagingController?.moveCursorUp()
    }

    func textFormattingProvidingDidTapCursorDown() {
        webMessagingController?.moveCursorDown()
    }

    func textFormattingProvidingDidTapCursorRight() {
        webMessagingController?.moveCursorRight()
    }

    func textFormattingProvidingDidTapCursorLeft() {
        webMessagingController?.moveCursorLeft()
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
        inputAccessoryViewType = isRangeSelected ? .highlight : .default
    }

    func textFormattingProvidingDidTapHeading(depth: Int) {
        webMessagingController?.setHeadingSelection(depth: depth)
        delegate?.editorInputViewsControllerDidTapHeading(self, depth: depth)
    }

    func textFormattingProvidingDidTapBold() {
        webMessagingController?.toggleBoldSelection()
        delegate?.editorInputViewsControllerDidTapBold(self)
    }

    func textFormattingProvidingDidTapItalics() {
        webMessagingController?.toggleItalicSelection()
        delegate?.editorInputViewsControllerDidTapItalic(self)
    }

    func textFormattingProvidingDidTapUnderline() {
        webMessagingController?.toggleUnderline()
        delegate?.editorInputViewsControllerDidTapUnderline(self)
    }

    func textFormattingProvidingDidTapStrikethrough() {
        webMessagingController?.toggleStrikethrough()
        delegate?.editorInputViewsControllerDidTapStrikethrough(self)
    }

    func textFormattingProvidingDidTapReference() {
        webMessagingController?.toggleReferenceSelection()
        delegate?.editorInputViewsControllerDidTapReference(self)
    }

    func textFormattingProvidingDidTapTemplate() {
        webMessagingController?.toggleTemplateSelection()
        delegate?.editorInputViewsControllerDidTapTemplate(self)
    }

    func textFormattingProvidingDidTapComment() {
        webMessagingController?.toggleComment()
    }

    func textFormattingProvidingDidTapLink() {
        delegate?.editorInputViewsControllerDidTapLinkInsert(self)
    }

    func textFormattingProvidingDidTapIncreaseIndent() {
        webMessagingController?.increaseIndentDepth()
        delegate?.editorInputViewsControllerDidTapIndent(self)
    }

    func textFormattingProvidingDidTapDecreaseIndent() {
        webMessagingController?.decreaseIndentDepth()
        delegate?.editorInputViewsControllerDidTapUnindent(self)
    }

    func textFormattingProvidingDidTapOrderedList() {
        webMessagingController?.toggleOrderedListSelection()
        delegate?.editorInputViewsControllerDidTapListNumber(self)
    }

    func textFormattingProvidingDidTapUnorderedList() {
        webMessagingController?.toggleUnorderedListSelection()
        delegate?.editorInputViewsControllerDidTapListBullet(self)
    }

    func textFormattingProvidingDidTapSuperscript() {
        webMessagingController?.toggleSuperscript()
        delegate?.editorInputViewsControllerDidTapSuperscript(self)
    }

    func textFormattingProvidingDidTapSubscript() {
        webMessagingController?.toggleSubscript()
        delegate?.editorInputViewsControllerDidTapSubscript(self)
    }
    
    func textFormattingProvidingDidTapClearFormatting() {
        webMessagingController?.clearFormatting()
    }
}

extension EditorInputViewsController: SectionEditorWebViewMessagingControllerFindInPageDelegate {
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
        webView?.getScrollRectForHtmlElement(withId: matchID) { [weak self] (matchRect) in
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

extension EditorInputViewsController: FindAndReplaceKeyboardBarDelegate {
    func keyboardBarDidTapReturn(_ keyboardBar: FindAndReplaceKeyboardBar) {
        webMessagingController?.findNext()
    }
    
    func keyboardBar(_ keyboardBar: FindAndReplaceKeyboardBar, didChangeSearchTerm searchTerm: String?) {
        
        guard let searchTerm = searchTerm else {
            return
        }
        webMessagingController?.find(text: searchTerm)
    }
    
    func keyboardBarDidTapClose(_ keyboardBar: FindAndReplaceKeyboardBar) {
         // no-op, FindAndReplaceKeyboardBar not showing close button in Editor context
    }
    
    func keyboardBarDidTapClear(_ keyboardBar: FindAndReplaceKeyboardBar) {
        webMessagingController?.clearSearch()
        keyboardBar.resetFind()
    }
    
    func keyboardBarDidTapPrevious(_ keyboardBar: FindAndReplaceKeyboardBar) {
        webMessagingController?.findPrevious()
    }
    
    func keyboardBarDidTapNext(_ keyboardBar: FindAndReplaceKeyboardBar?) {
        webMessagingController?.findNext()
    }
    
    func keyboardBarDidTapReplace(_ keyboardBar: FindAndReplaceKeyboardBar, replaceText: String, replaceType: ReplaceType) {
        switch replaceType {
        case .replaceSingle:
            webMessagingController?.replaceSingle(text: replaceText)
        case .replaceAll:
            webMessagingController?.replaceAll(text: replaceText)
        }
    }
}

#if (TEST)
// MARK: Helpers for testing
extension EditorInputViewsController {
    var findAndReplaceViewForTesting: FindAndReplaceKeyboardBar? {
        return findAndReplaceView
    }
}
#endif
