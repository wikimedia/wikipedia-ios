class SectionEditorWebViewWithEditToolbar: SectionEditorWebView {
    override init() {
        super.init()
        config.selectionChangedDelegate = self
        setEditMenuItems()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Menu items

    lazy var menuItems: [UIMenuItem] = {
        let addCitation = UIMenuItem(title: "Add Citation", action: #selector(toggleCitation(menuItem:)))
        let addLink = UIMenuItem(title: "Add Link", action: #selector(toggleLink(menuItem:)))
        let addCurlyBrackets = UIMenuItem(title: "｛ ｝", action: #selector(toggleCurlyBrackets(menuItem:)))
        let makeBold = UIMenuItem(title: "𝗕", action: #selector(toggleBoldface(menuItem:)))
        let makeItalic = UIMenuItem(title: "𝐼", action: #selector(toggleItalics(menuItem:)))
        return [addCitation, addLink, addCurlyBrackets, makeBold, makeItalic]
    }()

    lazy var availableMenuActions: [Selector] = {
        let actions = [
            #selector(WKWebView.cut(_:)),
            #selector(WKWebView.copy(_:)),
            #selector(WKWebView.paste(_:)),
            #selector(SectionEditorWebViewWithEditToolbar.toggleBoldface(menuItem:)),
            #selector(SectionEditorWebViewWithEditToolbar.toggleItalics(menuItem:)),
            #selector(SectionEditorWebViewWithEditToolbar.toggleCitation(menuItem:)),
            #selector(SectionEditorWebViewWithEditToolbar.toggleLink(menuItem:)),
            #selector(SectionEditorWebViewWithEditToolbar.toggleCurlyBrackets(menuItem:))
        ]
        return actions
    }()

    @objc private func toggleCitation(menuItem: UIMenuItem) {

    }

    @objc private func toggleLink(menuItem: UIMenuItem) {

    }

    @objc private func toggleCurlyBrackets(menuItem: UIMenuItem) {

    }

    @objc private func toggleBoldface(menuItem: UIMenuItem) {
        toggleBoldSelection(menuItem)
    }

    @objc private func toggleItalics(menuItem: UIMenuItem) {
        toggleItalicSelection(menuItem)
    }

    // Keep original menu items
    // so that we can bring them back
    // when web view disappears
    var originalMenuItems: [UIMenuItem]?

    private func setEditMenuItems() {
        originalMenuItems = UIMenuController.shared.menuItems
        UIMenuController.shared.menuItems = menuItems
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return availableMenuActions.contains(action)
    }

    // MARK: Accessory views

    private lazy var defaultEditToolbarView: DefaultEditToolbarView = {
        let view = DefaultEditToolbarView.wmf_viewFromClassNib()!
        view.delegate = self
        return view
    }()

    private lazy var contextualHighlightEditToolbarView: ContextualHighlightEditToolbarView = {
        let view = ContextualHighlightEditToolbarView.wmf_viewFromClassNib()!
        // view.delegate = self
        return view
    }()

    // MARK: Input view

    private var inputViewType: TextFormattingInputViewController.InputViewType?

    private lazy var textFormattingInputViewController: TextFormattingInputViewController = {
        let viewController = TextFormattingInputViewController.wmf_viewControllerFromStoryboardNamed("TextFormatting")
        viewController.delegate = self
        return viewController
    }()

    override var inputViewController: UIInputViewController? {
        guard let inputViewType = inputViewType else {
            return nil
        }
        textFormattingInputViewController.inputViewType = inputViewType
        return textFormattingInputViewController
    }

    // MARK: Swizzling input accessory view

    func configureInputAccessoryViews() {
        _ = setInputAccessoryViews
    }

    private var previousInputAccessoryViewType: InputAccessoryViewType?
    private var inputAccessoryViewType: InputAccessoryViewType? = .default {
        didSet {
            previousInputAccessoryViewType = oldValue
        }
    }

    private struct InputAccessoryViewKey {
        static var Default = "wmf_AssociatedDefaultEditToolbarView"
        static var Highlight = "wmf_AssociatedHighlightEditToolbarView"
    }

    private enum InputAccessoryViewType {
        case `default`
        case highlight
    }

    private lazy var setInputAccessoryViews: Void = {
        objc_setAssociatedObject(self, &InputAccessoryViewKey.Default, defaultEditToolbarView, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &InputAccessoryViewKey.Highlight, contextualHighlightEditToolbarView, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        guard let wkContent = self.scrollView.subviews.first(where:  { String(describing: type(of: $0)).hasPrefix("WKContent") }) else {
            assertionFailure("Couldn't find WKContent among scrollView's subviews")
            return
        }

        guard wkContent.superclass != nil else {
            assertionFailure("WKContent has no superclass")
            return
        }

        let newClassName = "_CustomInputAccessoryView"
        if let newClass = NSClassFromString(newClassName) {
            object_setClass(wkContent, newClass)
            return
        }

        guard let newClass = objc_allocateClassPair(object_getClass(wkContent), newClassName, 0) else {
            assertionFailure("Couldn't create a new class for a custom input accessory view")
            return
        }

        let newSelector = #selector(getter: SectionEditorWebViewWithEditToolbar.customInputAccessoryView)
        guard let newMethod = class_getInstanceMethod(SectionEditorWebViewWithEditToolbar.self, newSelector) else {
            assertionFailure("Couldn't get instance method for \(newSelector)")
            return
        }

        let originalSelector = #selector(getter: SectionEditorWebViewWithEditToolbar.inputAccessoryView)

        class_addMethod(newClass, originalSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))
        objc_registerClassPair(newClass)
        object_setClass(wkContent, newClass)
    }()

    @objc private var customInputAccessoryView: UIView? {
        var trueSelf: UIView? = self
        while (trueSelf != nil) && !(trueSelf is WKWebView) {
            trueSelf = trueSelf?.superview
        }
        guard let webView = trueSelf as? SectionEditorWebViewWithEditToolbar else {
            return nil
        }

        guard let preferredInputAccessoryView = preferredInputAccessoryView(associatedWith: webView) else {
            return nil
        }

        preferredInputAccessoryView.apply(theme: Theme.standard)
        return preferredInputAccessoryView
    }

    private func preferredInputAccessoryView(associatedWith webView: SectionEditorWebViewWithEditToolbar) -> (UIView & Themeable)? {
        guard let inputAccessoryViewType = webView.inputAccessoryViewType else {
            return nil
        }

        let maybeView: Any?

        switch inputAccessoryViewType {
        case .default:
            maybeView = objc_getAssociatedObject(webView, &InputAccessoryViewKey.Default)
        case .highlight:
            maybeView = objc_getAssociatedObject(webView, &InputAccessoryViewKey.Highlight)
        }

        guard let preferredInputAccessoryView = maybeView as? UIView & Themeable else {
            assertionFailure("Couldn't get object associated with \(webView)")
            return nil
        }

        return preferredInputAccessoryView
    }

    private func themeableView(associatedWith object: Any, key: inout String) -> (UIView & Themeable)? {
        guard let view = objc_getAssociatedObject(object, key) as? (UIView & Themeable) else {
            return nil
        }
        return view
    }

    // MARK: - Showing input view

    func setInputViewHidden(type: TextFormattingInputViewController.InputViewType? = nil, hidden: Bool) {
        if hidden {
            inputAccessoryViewType = previousInputAccessoryViewType
        } else {
            inputAccessoryViewType = nil
        }

        dispatchOnMainQueueAfterDelayInSeconds(0.1) {
        //let animator = UIViewPropertyAnimator.init(duration: 0.3, curve: .easeInOut) {
            self.resignFirstResponder()
        //}
        }

        //animator.addCompletion { (_) in
            self.becomeFirstResponder()
        //}

        inputViewType = type

        //animator.startAnimation()
    }
}

extension SectionEditorWebViewWithEditToolbar: DefaultEditToolbarViewDelegate {
    func defaultEditToolbarViewDidTapTextFormattingButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton) {
        self.setInputViewHidden(type: .textFormatting, hidden: false)
    }

    func defaultEditToolbarViewDidTapHeaderFormattingButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton) {
        setInputViewHidden(type: .textStyle, hidden: false)
    }

    func defaultEditToolbarViewDidTapCitationButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton) {
        toggleReferenceSelection(button) // ?
    }

    func defaultEditToolbarViewDidTapLinkButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton) {
        toggleAnchorSelection(button) // ?
    }

    func defaultEditToolbarViewDidTapUnorderedListButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton) {
        toggleListSelection(button) // ?
    }

    func defaultEditToolbarViewDidTapOrderedListButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton) {
        toggleListSelection(button) // ?
    }

    func defaultEditToolbarViewDidTapDecreaseIndentationUpButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton) {
        decreaseIndentDepth(button)
    }

    func defaultEditToolbarViewDidTapIncreaseIndentationUpButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton) {
        increaseIndentDepth(button)
    }

    func defaultEditToolbarViewDidTapCursorUpButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton) {
        moveCursorUp(button)
    }

    func defaultEditToolbarViewDidTapCursorDownButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton) {
        moveCursorDown(button)
    }

    func defaultEditToolbarViewDidTapCursorLeftButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton) {
        moveCursorLeft(button)
    }

    func defaultEditToolbarViewDidTapCursorRightButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton) {
        moveCursorRight(button)
    }

    func defaultEditToolbarViewDidTapMoreButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton) {
        setInputViewHidden(type: .textFormatting, hidden: false)
    }
}

extension SectionEditorWebViewWithEditToolbar: TextFormattingDelegate {
    func textFormattingProvidingDidTapItalicsButton(_ textFormattingProviding: TextFormattingProviding, button: UIButton) {
        toggleItalicSelection(button)
    }

    func textFormattingProvidingDidTapCloseButton(_ textFormattingProviding: TextFormattingProviding, button: UIBarButtonItem) {
        setInputViewHidden(hidden: true)
    }
    func textFormattingProvidingDidTapBoldButton(_ textFormattingProviding: TextFormattingProviding, button: UIButton) {
        toggleBoldSelection(button)
    }
}

extension SectionEditorWebViewWithEditToolbar: SectionEditorWebViewSelectionChangedDelegate {
    func selectionChanged(isRangeSelected: Bool) {
        //
    }
    
    func highlightCommentButton() {
        //
    }

    func turnOffAllButtonHighlights() {
        //
    }

    func highlightBoldButton() {
        //
    }

    func highlightItalicButton() {
        //
    }

    func highlightReferenceButton() {
        //
    }

    func highlightTemplateButton() {
        //
    }

    func highlightAnchorButton() {
        //
    }

    func highlightIndentButton(depth: Int) {
        //
    }

    func highlightSignatureButton(depth: Int) {
        //
    }

    func highlightListButton(ordered: Bool, depth: Int) {
        //
    }

    func highlightHeadingButton(depth: Int) {
        let textStyleType = TextStyleType(rawValue: depth)
        textFormattingInputViewController.selectedTextStyleType = textStyleType
    }

    func highlightUndoButton() {
        //
    }

    func highlightRedoButton() {
        //
    }
}
