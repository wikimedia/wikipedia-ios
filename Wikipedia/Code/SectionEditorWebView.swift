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

    private let defaultEditToolbar = DefaultEditToolbarView.wmf_viewFromClassNib()!
    private let contextualHighlightEditToolbar = ContextualHighlightEditToolbarView.wmf_viewFromClassNib()!

    func gestCustomInputAccessoryView() -> UIView? {
        return defaultEditToolbar
    }

    override var inputView: UIView? {
        return nil
    }

    override var inputAccessoryViewController: UIInputViewController? {
        let textFormattingInputViewController = TextFormattingInputViewController.wmf_viewControllerFromStoryboardNamed("TextFormatting")
        //        textFormattingInputViewController.delegate = textFormattingDelegate
        //        textFormattingInputViewController.inputViewType = preferredInputViewType
        return nil
    }

    override var inputViewController: UIInputViewController? {
        let textFormattingInputViewController = TextFormattingInputViewController.wmf_viewControllerFromStoryboardNamed("TextFormatting")
//        textFormattingInputViewController.delegate = textFormattingDelegate
//        textFormattingInputViewController.inputViewType = preferredInputViewType
        return nil
    }

    func configureCustomInputAccessoryView() {
        setCustomInputAccessoryView(defaultEditToolbar)
    }

    // MARK: Swizzling input accessory view

    static var customInputAccessoryViewKey = 0

    private lazy var setCustomInputAccessoryView: (UIView) -> Void = { customInputAccessoryView in
        objc_setAssociatedObject(self, &SectionEditorWebView.customInputAccessoryViewKey, customInputAccessoryView, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)

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

        guard let getter = class_getInstanceMethod(SectionEditorWebView.self, #selector(getter: SectionEditorWebView.customInputAccessoryView)) else {
            assertionFailure("Couldn't get instance method")
            return
        }

        class_addMethod(newClass, #selector(getter: SectionEditorWebView.inputAccessoryView), method_getImplementation(getter), method_getTypeEncoding(getter))
        objc_registerClassPair(newClass)
        object_setClass(wkContent, newClass)
    }

    @objc private var customInputAccessoryView: UIView? {
        var view: UIView? = self
        while (view != nil) && !(view is WKWebView) {
            view = view?.superview
        }
        guard let webView = view else {
            return nil
        }
        let customInputAccessory = objc_getAssociatedObject(webView, &SectionEditorWebView.customInputAccessoryViewKey)
        return customInputAccessory as? UIView
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
