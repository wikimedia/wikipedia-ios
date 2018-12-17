import WebKit

typealias SectionEditorWebViewCompletionBlock = (Error?) -> Void
typealias SectionEditorWebViewCompletionWithResultBlock = (Any?, Error?) -> Void

class SectionEditorWebView: WKWebViewWithSettableInputViews {
    
    let config = SectionEditorWebViewConfiguration()
    private let codeMirrorIndexFileName = "mediawiki-extensions-CodeMirror/codemirror-index.html"

    init() {
        super.init(frame: .zero, configuration: config)
        loadHTMLFromAssetsFile(codeMirrorIndexFileName, scrolledToFragment: nil)
        scrollView.keyboardDismissMode = .interactive
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func performSetupJS(completionHandler: (SectionEditorWebViewCompletionBlock)? = nil) {
        evaluateJavaScript("""
            window.wmf.setup();
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
    

    // Convenience kickoff method for initial setting of wikitext & codemirror setup.
    @objc func setup(wikitext: String, completionHandler: (SectionEditorWebViewCompletionBlock)? = nil) {
        performSetupJS() { error in
            guard let error = error else {
                self.setWikitext(wikitext, completionHandler: completionHandler)
                return
            }
            DDLogError("Error setting up editor: \(error)")
        }
    }

    // TODO: Becoming/resigning is jenky
    override var canBecomeFirstResponder: Bool { return true }
    @discardableResult override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        focus(self)
        return result
    }
}
