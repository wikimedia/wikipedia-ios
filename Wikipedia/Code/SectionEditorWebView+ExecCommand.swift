@objc enum CodeMirrorExecCommandType: Int {
    case cursorUp
    case cursorDown
    case cursorLeft
    case cursorRight
    case undo
    case redo
}

extension SectionEditorWebView {
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
}
