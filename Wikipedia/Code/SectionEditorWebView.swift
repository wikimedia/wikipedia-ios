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

class SectionEditorWebView: WKWebView {

    init() {
        let config = WKWebViewConfiguration.init()
        config.setURLSchemeHandler(WMFURLSchemeHandler.shared(), forURLScheme: WMFURLSchemeHandlerScheme)
        super.init(frame: .zero, configuration: config)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc var useRichEditor: Bool = true

    @objc func update() {
        evaluateJavaScript("""
            window.wmf.setCurrentEditorType(window.wmf.EditorType.\(useRichEditor ? "codemirror" : "wikitext"));
            window.wmf.update();
        """) { (_, error) in
            guard let error = error else {
                return
            }
            DDLogError("Error: \(error)")
        }
    }
    
    @objc func setWikitext(_ wikitext: String) {
        // Can use ES6 backticks ` now instead of 'wmf_stringBySanitizingForJavaScript' with apostrophes.
        // Doing so means we *only* have to escape backticks instead of apostrophes, quotes and line breaks.
        // (May consider switching other native-to-JS messaging to do same later.)
        let escapedWikitext = wikitext.replacingOccurrences(of: "`", with: "\\`", options: .literal, range: nil)
        evaluateJavaScript("window.wmf.setWikitext(`\(escapedWikitext)`);") { (result, error) in
            guard let error = error else {
                return
            }
            DDLogError("Error: \(error)")
        }
    }

    @objc func getWikitext(completionHandler: ((Any?, Error?) -> Void)? = nil) {
        evaluateJavaScript("window.wmf.getWikitext();", completionHandler: completionHandler)
    }
    
    // Won't need this when we don't need @objc for `execCodeMirrorCommand`.
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
    
    @objc func execCodeMirrorCommand(type: CodeMirrorExecCommandType, completionHandler: ((Any?, Error?) -> Void)? = nil) {
        evaluateJavaScript("window.wmf.execCommand(window.wmf.ExecCommandType.\(string(for: type)));", completionHandler: completionHandler)
    }
}
