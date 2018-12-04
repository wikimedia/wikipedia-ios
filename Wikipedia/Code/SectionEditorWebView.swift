import WebKit
import WMF

@objc enum CodeMirrorExecCommandType: Int {
    case cursorUp
    case cursorDown
    case cursorLeft
    case cursorRight
    case undo
    case redo
}

typealias SectionEditorWebViewCompletionBlock = (Error?) -> Void
typealias SectionEditorWebViewCompletionWithResultBlock = (Any?, Error?) -> Void

class SectionEditorWebView: WKWebView {
    public weak var selectionChangedDelegate: SectionEditorWebViewSelectionChangedDelegate? {
        didSet {
            config.selectionChangedDelegate = selectionChangedDelegate
        }
    }
    private var config: SectionEditorWebViewConfiguration

    init() {
        config = SectionEditorWebViewConfiguration.init()
        super.init(frame: .zero, configuration: config)
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
    
    // Won't need this when we don't need @objc for `execCodeMirrorCommand` - i.e. 'CodeMirrorExecCommandType' could just be string enum.
    private func string(for type: CodeMirrorExecCommandType) -> String {
        switch type {
        case .cursorUp:
            return "cursorUp"
        case .cursorDown:
            return "cursorDown"
        case .cursorLeft:
            return "cursorLeft"
        case .cursorRight:
            return "cursorRight"
        case .undo:
            return "undo"
        case .redo:
            return "redo"
        }
    }
    
    // Method for relaying various commands to codemirror - i.e. 'execCodeMirrorCommand(type: .cursorUp)'
    @objc func execCodeMirrorCommand(type: CodeMirrorExecCommandType, completionHandler: (SectionEditorWebViewCompletionWithResultBlock)? = nil) {
        evaluateJavaScript("window.wmf.execCommand(window.wmf.ExecCommandType.\(string(for: type)));", completionHandler: completionHandler)
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
}
