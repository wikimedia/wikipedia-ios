import WebKit
import WMF

typealias SectionEditorWebViewCompletionBlock = (Error?) -> Void
typealias SectionEditorWebViewCompletionWithResultBlock = (Any?, Error?) -> Void

class SectionEditorWebView: WKWebView {
    
    private let config = SectionEditorWebViewConfiguration()
    private let codeMirrorIndexFileName = "mediawiki-extensions-CodeMirror/codemirror-index.html"

    init() {
        super.init(frame: .zero, configuration: config)
        config.selectionChangedDelegate = self
        loadHTMLFromAssetsFile(codeMirrorIndexFileName, scrolledToFragment: nil)
        scrollView.keyboardDismissMode = .interactive
        setEditMenuItems()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc var useRichEditor: Bool = true

    private func update(completionHandler: (SectionEditorWebViewCompletionBlock)? = nil) {
        evaluateJavaScript("""
            window.wmf.setCurrentEditorType(window.wmf.EditorType.\(useRichEditor ? "codemirror" : "wikitext"));
            window.wmf.update();
        """) { (_, error) in
            guard let completionHandler = completionHandler else {
                return
            }
            completionHandler(error)
        }
    }
    
    @objc func setWikitext(_ wikitext: String, completionHandler: (SectionEditorWebViewCompletionBlock)? = nil) {
        // Can use ES6 backticks ` now instead of 'wmf_stringBySanitizingForJavaScript' with apostrophes.
        // Doing so means we *only* have to escape backticks instead of apostrophes, quotes and line breaks.
        // (May consider switching other native-to-JS messaging to do same later.)
        let escapedWikitext = wikitext.replacingOccurrences(of: "`", with: "\\`", options: .literal, range: nil)
        evaluateJavaScript("window.wmf.setWikitext(`\(escapedWikitext)`);") { (_, error) in
            guard let completionHandler = completionHandler else {
                return
            }
            completionHandler(error)
        }
    }

    @objc func getWikitext(completionHandler: (SectionEditorWebViewCompletionWithResultBlock)? = nil) {
        evaluateJavaScript("window.wmf.getWikitext();", completionHandler: completionHandler)
    }

    func getSelectedButtons(completionHandler: (SectionEditorWebViewCompletionWithResultBlock)? = nil) {
        evaluateJavaScript("window.wmf.getSelectedButtons(editor);", completionHandler: completionHandler)
    }
    
    // Toggle between codemirror and plain wikitext editing
    @objc func toggleRichEditor() {
        useRichEditor = !useRichEditor
        update() { error in
            guard let error = error else {
                return
            }
            DDLogError("Error toggling editor: \(error)")
        }
    }

    // Convenience kickoff method for initial setting of wikitext & codemirror setup.
    @objc func setup(wikitext: String, useRichEditor: Bool, completionHandler: (SectionEditorWebViewCompletionBlock)? = nil) {
        self.useRichEditor = useRichEditor
        update() { error in
            guard let error = error else {
                self.setWikitext(wikitext, completionHandler: completionHandler)
                return
            }
            DDLogError("Error setting up editor: \(error)")
        }
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

    // TODO: Dispatch once
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

        let newSelector = #selector(getter: SectionEditorWebView.customInputAccessoryView)
        guard let newMethod = class_getInstanceMethod(SectionEditorWebView.self, newSelector) else {
            assertionFailure("Couldn't get instance method for \(newSelector)")
            return
        }

        let originalSelector = #selector(getter: SectionEditorWebView.inputAccessoryView)

        class_addMethod(newClass, originalSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))
        objc_registerClassPair(newClass)
        object_setClass(wkContent, newClass)
    }()

    @objc private var customInputAccessoryView: UIView? {
        var trueSelf: UIView? = self
        while (trueSelf != nil) && !(trueSelf is WKWebView) {
            trueSelf = trueSelf?.superview
        }
        guard let webView = trueSelf as? SectionEditorWebView else {
            return nil
        }

        guard let preferredInputAccessoryView = preferredInputAccessoryView(associatedWith: webView) else {
            return nil
        }

        preferredInputAccessoryView.apply(theme: Theme.standard)
        return preferredInputAccessoryView
    }

    private func preferredInputAccessoryView(associatedWith webView: SectionEditorWebView) -> (UIView & Themeable)? {
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

        let animator = UIViewPropertyAnimator.init(duration: 0.3, curve: .easeInOut) {
            self.resignFirstResponder()
        }

        animator.addCompletion { (_) in
            self.becomeFirstResponder()
        }

        inputViewType = type

        animator.startAnimation()
    }

    // MARK: Menu items

    lazy var menuItems: [UIMenuItem] = {
        let addCitation = UIMenuItem(title: "+", action: #selector(toggleCitation(menuItem:)))
        let addLink = UIMenuItem(title: "🔗", action: #selector(toggleLink(menuItem:)))
        let addCurlyBrackets = UIMenuItem(title: "{}", action: #selector(toggleCurlyBrackets(menuItem:)))
        let makeBold = UIMenuItem(title: "𝗕", action: #selector(toggleBoldface(menuItem:)))
        let makeItalic = UIMenuItem(title: "𝐼", action: #selector(toggleItalics(menuItem:)))
        return [addCitation, addLink, addCurlyBrackets, makeBold, makeItalic]
    }()

    lazy var availableMenuActions: [Selector] = {
        let actions = [
            #selector(WKWebView.cut(_:)),
            #selector(WKWebView.copy(_:)),
            #selector(WKWebView.paste(_:)),
            #selector(SectionEditorWebView.toggleBoldface(menuItem:)),
            #selector(SectionEditorWebView.toggleItalics(menuItem:)),
            #selector(SectionEditorWebView.toggleCitation(menuItem:)),
            #selector(SectionEditorWebView.toggleLink(menuItem:)),
            #selector(SectionEditorWebView.toggleCurlyBrackets(menuItem:))
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
}

extension SectionEditorWebView: DefaultEditToolbarViewDelegate {
    func defaultEditToolbarViewDidTapTextFormattingButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton) {
        getSelectedTextStyleType { (textStyleType) in
            self.setInputViewHidden(type: .textFormatting(textStyleType ?? .paragraph), hidden: false)
        }
    }

    // gets all selected buttons
    // checks if there are any headings selected
    // if so, lets TextStyleFormattingTableViewController know which heading is selected
    // (so that it can be selected in the view)
    // multiple text styles not handled
    // should moved out of here probably
    private func getSelectedTextStyleType(_ completion: @escaping (TextStyleType?) -> Void) {
        getSelectedButtons { (results, error) in
            var textStyleRawValue: Int?
            defer {
                if let rawValue = textStyleRawValue {
                    let textStyleType = TextStyleType(rawValue: rawValue)
                    completion(textStyleType)
                } else {
                    completion(nil)
                }
            }
            guard let results = results as? [[String: Any]] else {
                return
            }
            for result in results {
                guard let button = result["button"] as? String, button == "heading" else {
                    continue
                }
                guard
                    let info = result["info"] as? [String: Any],
                    let depth = info["depth"] as? Int
                    else {
                        return
                }
                textStyleRawValue = depth
                // TODO: multiple text styles
                break
            }
        }
    }

    func defaultEditToolbarViewDidTapHeaderFormattingButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton) {
        getSelectedTextStyleType { (textStyleType) in
            self.setInputViewHidden(type: .textStyle(textStyleType ?? .paragraph), hidden: false)
        }
    }

    func defaultEditToolbarViewDidTapCitationButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton) {
        // TODO
    }

    func defaultEditToolbarViewDidTapLinkButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton) {
        // TODO
    }

    func defaultEditToolbarViewDidTapUnorderedListButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton) {
        // TODO
    }

    func defaultEditToolbarViewDidTapOrderedListButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton) {
        // TODO
    }

    func defaultEditToolbarViewDidTapCursorUpButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton) {
        moveCursorUp()
    }

    func defaultEditToolbarViewDidTapCursorDownButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton) {
        moveCursorDown()
    }

    func defaultEditToolbarViewDidTapCursorLeftButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton) {
        moveCursorLeft()
    }

    func defaultEditToolbarViewDidTapCursorRightButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton) {
        moveCursorRight()
    }
}

extension SectionEditorWebView: TextFormattingDelegate {
    func textFormattingProvidingDidTapItalicsButton(_ textFormattingProviding: TextFormattingProviding, button: UIButton) {
        toggleItalicSelection()
    }

    func textFormattingProvidingDidTapCloseButton(_ textFormattingProviding: TextFormattingProviding, button: UIBarButtonItem) {
        setInputViewHidden(hidden: true)
    }
    func textFormattingProvidingDidTapBoldButton(_ textFormattingProviding: TextFormattingProviding, button: UIButton) {
        toggleBoldSelection()
    }
}

extension SectionEditorWebView: SectionEditorWebViewSelectionChangedDelegate {
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
        //
    }

    func highlightUndoButton() {
        //
    }

    func highlightRedoButton() {
        //
    }
}
