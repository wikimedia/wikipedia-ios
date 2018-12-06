import WebKit
import WMF

typealias SectionEditorWebViewCompletionBlock = (Error?) -> Void
typealias SectionEditorWebViewCompletionWithResultBlock = (Any?, Error?) -> Void

class SectionEditorWebView: WKWebView {
    
    private var config: SectionEditorWebViewConfiguration
    private let codeMirrorIndexFileName = "mediawiki-extensions-CodeMirror/codemirror-index.html"

    init() {
        config = SectionEditorWebViewConfiguration()
        super.init(frame: .zero, configuration: SectionEditorWebViewConfiguration())
        loadHTMLFromAssetsFile(codeMirrorIndexFileName, scrolledToFragment: nil)
        config.selectionChangedDelegate = self
        scrollView.keyboardDismissMode = .interactive
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

    override var inputViewController: UIInputViewController? {
        guard let inputViewType = inputViewType else {
            return nil
        }
        let textFormattingInputViewController = TextFormattingInputViewController.wmf_viewControllerFromStoryboardNamed("TextFormatting")
        textFormattingInputViewController.delegate = self
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
        guard let newClass = NSClassFromString(newClassName) ?? objc_allocateClassPair(object_getClass(wkContent), newClassName, 0) else {
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

    private func associateViewWithSelf(_ view: UIView, using key: inout Int) {
        objc_setAssociatedObject(self, &key, view, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

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

    // MARK: -

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
}

extension SectionEditorWebView: DefaultEditToolbarViewDelegate {
    func defaultEditToolbarViewDidTapTextFormattingButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton) {
        setInputViewHidden(type: .textFormatting, hidden: false)
    }

    func defaultEditToolbarViewDidTapHeaderFormattingButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton) {
        setInputViewHidden(type: .textStyle, hidden: false)
    }

    func defaultEditToolbarViewDidTapAddCitationButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton) {
        //
    }

    func defaultEditToolbarViewDidTapAddLinkButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton) {
        //
    }

    func defaultEditToolbarViewDidTapUnorderedListButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton) {
        //
    }

    func defaultEditToolbarViewDidTapOrderedListButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton) {
        //
    }
}

extension SectionEditorWebView: TextFormattingDelegate {
    func textFormattingProvidingDidTapCloseButton(_ textFormattingProviding: TextFormattingProviding) {
        setInputViewHidden(hidden: true)
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
