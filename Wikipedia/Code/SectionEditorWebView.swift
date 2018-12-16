import WebKit

typealias SectionEditorWebViewCompletionBlock = (Error?) -> Void
typealias SectionEditorWebViewCompletionWithResultBlock = (Any?, Error?) -> Void

class SectionEditorWebView: WKWebViewWithSettableInputViews {
    public weak var selectionChangedDelegate: SectionEditorWebViewSelectionChangedDelegate? {
        didSet {
            config.selectionChangedDelegate = selectionChangedDelegate
        }
    }
    private var config: SectionEditorWebViewConfiguration

    // WKWebView version of same property from UIWebView
    var keyboardDisplayRequiresUserAction: Bool = true {
        didSet {
            updateKeyboardDisplayRequiresUserAction(keyboardDisplayRequiresUserAction)
        }
    }
    
    init() {
        config = SectionEditorWebViewConfiguration.init()
        super.init(frame: .zero, configuration: config)
        keyboardDisplayRequiresUserAction = false
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

    override var canBecomeFirstResponder: Bool { return true }
    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        focus(self)
        return result
    }
}

fileprivate typealias ClosureType =  @convention(c) (Any, Selector, UnsafeRawPointer, Bool, Bool, Bool, Any?) -> Void
fileprivate typealias BlockType =  @convention(block) (Any, UnsafeRawPointer, Bool, Bool, Bool, Any?) -> Void
fileprivate extension SectionEditorWebView {
    func updateKeyboardDisplayRequiresUserAction(_ value: Bool) {
        guard let WKContentView: AnyClass = NSClassFromString("WKContentView") else {
            DDLogError("Could not get class")
            return
        }
        let sel = sel_getUid("_startAssistingNode:userIsInteracting:blurPreviousNode:changingActivityState:userObject:")
        guard let method = class_getInstanceMethod(WKContentView, sel) else {
            DDLogError("Could not get method")
            return
        }
        let originalImp = method_getImplementation(method)
        let original = unsafeBitCast(originalImp, to: ClosureType.self)
        let block: BlockType = { (me, arg0, arg1, arg2, arg3, arg4) in
            original(me, sel, arg0, !value, arg2, arg3, arg4)
        }
        method_setImplementation(method, imp_implementationWithBlock(block))
    }
}
