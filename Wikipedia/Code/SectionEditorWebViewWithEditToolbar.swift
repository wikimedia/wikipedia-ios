class SectionEditorWebViewWithEditToolbar: SectionEditorWebView {
    override init() {
        super.init()
        config.selectionChangedDelegate = self
        setEditMenuItems()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var theme = Theme.standard

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
         view.delegate = self
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

    // MARK: - Showing input view

    func setInputViewHidden(type: TextFormattingInputViewController.InputViewType? = nil, hidden: Bool) {
        if hidden {
            inputAccessoryViewType = previousInputAccessoryViewType
        } else {
            inputAccessoryViewType = nil
        }

        inputViewType = type

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
}

extension SectionEditorWebViewWithEditToolbar: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        themeInputViews(theme: theme)
    }

    private func themeInputViews(theme: Theme) {
        (inputAccessoryView as? Themeable)?.apply(theme: theme)
        (inputView as? Themeable)?.apply(theme: theme)
    }
}

extension SectionEditorWebViewWithEditToolbar: DefaultEditToolbarViewDelegate {
    func defaultEditToolbarViewDidTapTextFormattingButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton) {
        setInputViewHidden(type: .textFormatting, hidden: false)
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

extension SectionEditorWebViewWithEditToolbar: ContextualHighlightEditToolbarViewDelegate {
    func contextualHighlightEditToolbarViewDidTapHeaderFormattingButton(_ contextualHighlightEditToolbarView: ContextualHighlightEditToolbarView, button: UIButton) {
        setInputViewHidden(type: .textStyle, hidden: false)
    }

    func contextualHighlightEditToolbarViewDidTapTextFormattingButton(_ contextualHighlightEditToolbarView: ContextualHighlightEditToolbarView, button: UIButton) {
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
        if isRangeSelected {
            inputAccessoryViewType = .highlight
        } else {
            inputAccessoryViewType = .default
        }
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
