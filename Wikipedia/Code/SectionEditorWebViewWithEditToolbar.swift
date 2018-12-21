class SectionEditorWebViewWithEditToolbar: SectionEditorWebView {
    
    override init(theme: Theme) {
        textFormattingInputViewController = TextFormattingInputViewController.wmf_viewControllerFromStoryboardNamed("TextFormatting")
        super.init(theme: theme)
        setEditMenuItems()
        textFormattingInputViewController.delegate = self
        defaultEditToolbarView?.delegate = self
        contextualHighlightEditToolbarView?.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(textSelectionDidChange(_:)), name: Notification.Name.WMFSectionEditorSelectionChangedNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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
            #selector(WKWebView.select(_:)),
            #selector(WKWebView.selectAll(_:)),
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
        toggleBoldSelection()
    }

    @objc private func toggleItalics(menuItem: UIMenuItem) {
        toggleItalicSelection()
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

    override func selectAll(_ sender: Any?) {
        selectAllText()
    }

    // MARK: Accessory views
    private var defaultEditToolbarView = DefaultEditToolbarView.wmf_viewFromClassNib()
    private var contextualHighlightEditToolbarView = ContextualHighlightEditToolbarView.wmf_viewFromClassNib()

    // MARK: Input view

    private var inputViewType: TextFormattingInputViewController.InputViewType?

    private var textFormattingInputViewController: TextFormattingInputViewController

    override var inputViewController: UIInputViewController? {
        guard let inputViewType = inputViewType else {
            return nil
        }
        textFormattingInputViewController.inputViewType = inputViewType
        return textFormattingInputViewController
    }

    // MARK: - Showing input view

    func setInputViewHidden(type: TextFormattingInputViewController.InputViewType? = nil, hidden: Bool) {
        inputViewType = type

        if hidden {
            inputAccessoryViewType = previousInputAccessoryViewType
        } else {
            inputAccessoryViewType = nil
        }

        reloadInputViews()
    }

    // MARK: Input accessory view

    func configureInputAccessoryViews() {
        inputAccessoryViewType = .default
    }

    private var previousInputAccessoryViewType: InputAccessoryViewType?
    private var inputAccessoryViewType: InputAccessoryViewType? = .default {
        didSet {
            previousInputAccessoryViewType = oldValue
            inputAccessoryView = preferredInputAccessoryView()
            reloadInputViews()
        }
    }

    private enum InputAccessoryViewType {
        case `default`
        case highlight
    }

    override func reloadInputViews() {
        themeInputViews(theme: theme)
        super.reloadInputViews()
    }

    private func preferredInputAccessoryView() -> (UIView & Themeable)? {
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

        guard let preferredInputAccessoryView = maybeView as? UIView & Themeable else {
            assertionFailure("Couldn't get preferredInputAccessoryView")
            return nil
        }

        return preferredInputAccessoryView
    }

    // MARK: Notifications

    @objc private func textSelectionDidChange(_ notification: Notification) {
        guard inputViewController == nil else {
            return
        }
        guard let userInfo = notification.userInfo else {
            return
        }
        guard let message = userInfo[SectionEditorWebViewConfiguration.WMFSectionEditorSelectionChanged] as? SelectionChangedMessage else {
            return
        }
        if message.selectionIsRange {
            inputAccessoryViewType = .highlight
        } else {
            inputAccessoryViewType = .default
        }
    }

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        scrollView.backgroundColor = theme.colors.baseBackground
        backgroundColor = theme.colors.baseBackground
        themeInputViews(theme: theme)
    }
}

extension SectionEditorWebViewWithEditToolbar {
    private func themeInputViews(theme: Theme) {
        (inputAccessoryView as? Themeable)?.apply(theme: theme)
        (inputView as? Themeable)?.apply(theme: theme)
    }
}

extension SectionEditorWebViewWithEditToolbar: DefaultEditToolbarViewDelegate {
    func textFormattingTapped(sender: DefaultEditToolbarView) {
        setInputViewHidden(type: .textFormatting, hidden: false)
    }
    func headerFormattingTapped(sender: DefaultEditToolbarView) {
        setInputViewHidden(type: .textStyle, hidden: false)
    }
    func citationTapped(sender: DefaultEditToolbarView) {
        toggleReferenceSelection()
    }
    func linkTapped(sender: DefaultEditToolbarView) {
        toggleAnchorSelection()
    }
    func unorderedListTapped(sender: DefaultEditToolbarView) {
        toggleUnorderedListSelection()
    }
    func orderedListTapped(sender: DefaultEditToolbarView) {
        toggleOrderedListSelection()
    }
    func decreaseIndentTapped(sender: DefaultEditToolbarView) {
        decreaseIndentDepth()
    }
    func increaseIndentTapped(sender: DefaultEditToolbarView) {
        increaseIndentDepth()
    }
    func cursorUpTapped(sender: DefaultEditToolbarView) {
        moveCursorUp()
    }
    func cursorDownTapped(sender: DefaultEditToolbarView) {
        moveCursorDown()
    }
    func cursorLeftTapped(sender: DefaultEditToolbarView) {
        moveCursorLeft()
    }
    func cursorRightTapped(sender: DefaultEditToolbarView) {
        moveCursorRight()
    }
    func moreTapped(sender: DefaultEditToolbarView) {
        setInputViewHidden(type: .textFormatting, hidden: false)
    }
}

extension SectionEditorWebViewWithEditToolbar: ContextualHighlightEditToolbarViewDelegate {
    func headerFormattingTapped(sender: ContextualHighlightEditToolbarView) {
        setInputViewHidden(type: .textStyle, hidden: false)
    }
    func textFormattingTapped(sender: ContextualHighlightEditToolbarView) {
        setInputViewHidden(type: .textFormatting, hidden: false)
    }
    func boldTapped(sender: ContextualHighlightEditToolbarView) {
        toggleBoldSelection()
    }
    func italicTapped(sender: ContextualHighlightEditToolbarView) {
        toggleItalicSelection()
    }
    func removeSelectionFormattingTapped(sender: ContextualHighlightEditToolbarView) {
        print("TODO: wire up JS for this")
    }
    func referenceTapped(sender: ContextualHighlightEditToolbarView) {
        toggleReferenceSelection()
    }
    func anchorTapped(sender: ContextualHighlightEditToolbarView) {
        toggleAnchorSelection()
    }
    func unorderedListTapped(sender: ContextualHighlightEditToolbarView) {
        toggleUnorderedListSelection()
    }
    func orderedListTapped(sender: ContextualHighlightEditToolbarView) {
        toggleOrderedListSelection()
    }
}

extension SectionEditorWebViewWithEditToolbar: TextFormattingDelegate {
    func closeTapped(sender: TextFormattingProviding) {
        setInputViewHidden(hidden: true)
    }
    func boldTapped(sender: TextFormattingProviding) {
        toggleBoldSelection()
    }
    func italicTapped(sender: TextFormattingProviding) {
        toggleItalicSelection()
    }
    func referenceTapped(sender: TextFormattingProviding) {
        toggleReferenceSelection()
    }
    func templateTapped(sender: TextFormattingProviding) {
        toggleTemplateSelection()
    }
    func commentTapped(sender: TextFormattingProviding) {
        toggleComment()
    }
    func linkTapped(sender: TextFormattingProviding) {
        toggleAnchorSelection()
    }
}
