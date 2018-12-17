private enum CodeMirrorCommandType: String {
    case bold
    case italic
    case reference
    case template
    case anchor
    case indent
    case signature
    case list
    case heading
    case increaseIndentDepth
    case decreaseIndentDepth
    case undo
    case redo
    case cursorDown
    case cursorUp
    case cursorLeft
    case cursorRight
    case comment
    case focus
    case selectAll
    case highlighting
}

extension SectionEditorWebView {
    @objc func toggleBoldSelection(_ sender: Any) {
        execCommand(for: .bold)
    }
    @objc func toggleItalicSelection(_ sender: Any) {
        execCommand(for: .italic)
    }
    @objc func toggleReferenceSelection(_ sender: Any) {
        execCommand(for: .reference)
    }
    @objc func toggleTemplateSelection(_ sender: Any) {
        execCommand(for: .template)
    }
    @objc func toggleAnchorSelection(_ sender: Any) {
        execCommand(for: .anchor)
    }
    @objc func toggleIndentSelection(_ sender: Any) {
        execCommand(for: .indent)
    }
    @objc func toggleSignatureSelection(_ sender: Any) {
        execCommand(for: .signature)
    }
    @objc func toggleListSelection(_ sender: Any) {
        execCommand(for: .list)
    }
    @objc func toggleHeadingSelection(_ sender: Any) {
        execCommand(for: .heading)
    }
    @objc func increaseIndentDepth(_ sender: Any) {
        execCommand(for: .increaseIndentDepth)
    }
    @objc func decreaseIndentDepth(_ sender: Any) {
        execCommand(for: .decreaseIndentDepth)
    }
    
    
    @objc func undo(_ sender: Any) {
        execCommand(for: .undo)
    }
    @objc func redo(_ sender: Any) {
        execCommand(for: .redo)
    }

    
    @objc func moveCursorDown(_ sender: Any) {
        execCommand(for: .cursorDown)
    }
    @objc func moveCursorUp(_ sender: Any) {
        execCommand(for: .cursorUp)
    }
    @objc func moveCursorLeft(_ sender: Any) {
        execCommand(for: .cursorLeft)
    }
    @objc func moveCursorRight(_ sender: Any) {
        execCommand(for: .cursorRight)
    }

    @objc func toggleComment(_ sender: Any) {
        execCommand(for: .comment)
    }
    
    @objc func focus(_ sender: Any) {
        execCommand(for: .focus)
    }

    func selectAllText(_ sender: Any) {
        execCommand(for: .selectAll)
    }
    
    @objc func toggleSyntaxHighlighting(_ sender: Any) {
        execCommand(for: .highlighting)
    }

    private func commandJS(for commandType: CodeMirrorCommandType) -> String {
        return "window.wmf.commands.\(commandType.rawValue)();"
    }
    private func execCommand(for commandType: CodeMirrorCommandType) {
        evaluateJavaScript(commandJS(for: commandType), completionHandler: nil)
    }
}
