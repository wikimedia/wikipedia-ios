protocol SectionEditorInputViewsSource: class {
    var inputViewController: UIInputViewController? { get }
}

protocol SectionEditorInputViewsControllerDelegate: AnyObject {
    func sectionEditorInputViewsControllerDidTapMediaInsert(_ sectionEditorInputViewsController: SectionEditorInputViewsController)
    func sectionEditorInputViewsControllerDidTapLinkInsert(_ sectionEditorInputViewsController: SectionEditorInputViewsController)
}

class SectionEditorInputViewsController: NSObject, SectionEditorInputViewsSource, Themeable {
    let webView: SectionEditorWebView
    let messagingController: SectionEditorWebViewMessagingController

    let textFormattingInputViewController = TextFormattingInputViewController.wmf_viewControllerFromStoryboardNamed("TextFormatting")
    let defaultEditToolbarView = DefaultEditToolbarView.wmf_viewFromClassNib()
    let contextualHighlightEditToolbarView = ContextualHighlightEditToolbarView.wmf_viewFromClassNib()
    let findAndReplaceView: FindAndReplaceKeyboardBar? = FindAndReplaceKeyboardBar.wmf_viewFromClassNib()

    private var isRangeSelected = false

    weak var delegate: SectionEditorInputViewsControllerDelegate?

    init(webView: SectionEditorWebView, messagingController: SectionEditorWebViewMessagingController, findAndReplaceDisplayDelegate: FindAndReplaceKeyboardBarDisplayDelegate) {
        self.webView = webView
        self.messagingController = messagingController

        super.init()

        textFormattingInputViewController.delegate = self
        defaultEditToolbarView?.delegate = self
        contextualHighlightEditToolbarView?.delegate = self
        findAndReplaceView?.delegate = self
        findAndReplaceView?.displayDelegate = findAndReplaceDisplayDelegate
        findAndReplaceView?.isShowingReplace = true

        messagingController.findInPageDelegate = self

        inputViewType = nil
        inputAccessoryViewType = .default
    }

    func textSelectionDidChange(isRangeSelected: Bool) {
        self.isRangeSelected = isRangeSelected

        if inputViewType == nil {
            if inputAccessoryViewType == .findInPage {
                messagingController.clearSearch()
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
            webView.setInputAccessoryView(inputAccessoryView)
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
        
        messagingController.clearSearch()
        keyboardBar.reset()
        keyboardBar.hide()
        inputAccessoryViewType = previousInputAccessoryViewType
        if keyboardBar.isVisible {
            messagingController.selectLastFocusedMatch()
            messagingController.focusWithoutScroll()
        }
    }
}

// MARK: TextFormattingDelegate

extension SectionEditorInputViewsController: TextFormattingDelegate {
    func textFormattingProvidingDidTapMediaInsert() {
        delegate?.sectionEditorInputViewsControllerDidTapMediaInsert(self)
    }

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
        inputAccessoryViewType = isRangeSelected ? .highlight : .default
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
        delegate?.sectionEditorInputViewsControllerDidTapLinkInsert(self)
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
    
    func textFormattingProvidingDidTapClearFormatting() {
        messagingController.clearFormatting()
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
         //no-op, FindAndReplaceKeyboardBar not showing close button in Editor context
    }
    
    func keyboardBarDidTapClear(_ keyboardBar: FindAndReplaceKeyboardBar) {
        messagingController.clearSearch()
        keyboardBar.resetFind()
    }
    
    func keyboardBarDidTapPrevious(_ keyboardBar: FindAndReplaceKeyboardBar) {
        messagingController.findPrevious()
    }
    
    func keyboardBarDidTapNext(_ keyboardBar: FindAndReplaceKeyboardBar?) {
        messagingController.findNext()
    }
    
    func keyboardBarDidTapReplace(_ keyboardBar: FindAndReplaceKeyboardBar, replaceText: String, replaceType: ReplaceType) {
        switch replaceType {
        case .replaceSingle:
            messagingController.replaceSingle(text: replaceText)
        case .replaceAll:
            messagingController.replaceAll(text: replaceText)
        }
    }
}

#if (TEST)
//MARK: Helpers for testing
extension SectionEditorInputViewsController {
    var findAndReplaceViewForTesting: FindAndReplaceKeyboardBar? {
        return findAndReplaceView
    }
}
#endif
