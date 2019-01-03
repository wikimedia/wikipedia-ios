class SectionEditorWebViewWithEditToolbar: SectionEditorWebView {
    weak var inputViewsSource: SectionEditorInputViewsSource?

    override init(theme: Theme) {
        super.init(theme: theme)
        setEditMenuItems()
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

    // MARK: Input view controller

    // inputViewController is a get-only property
    // so we can't set it the same way we're setting inputAccessoryView
    override var inputViewController: UIInputViewController? {
        return inputViewsSource?.inputViewController
    }

    // MARK: Input accessory view

    func setInputAccessoryView(_ inputAccessoryView: UIView?) {
        self.inputAccessoryView = inputAccessoryView
        reloadInputViews()
    }

    override func reloadInputViews() {
        themeInputViews(theme: theme)
        super.reloadInputViews()
    }
}

// MARK: Themeable

extension SectionEditorWebViewWithEditToolbar {
    private func themeInputViews(theme: Theme) {
        (inputAccessoryView as? Themeable)?.apply(theme: theme)
        (inputView as? Themeable)?.apply(theme: theme)
    }

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        scrollView.backgroundColor = theme.colors.baseBackground
        backgroundColor = theme.colors.baseBackground
        themeInputViews(theme: theme)
    }
}
