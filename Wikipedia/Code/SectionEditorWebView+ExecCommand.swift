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
}

extension SectionEditorWebView {
    @objc func toggleBoldSelection() {
        execCommand(for: .bold)
    }
    @objc func toggleItalicSelection() {
        execCommand(for: .italic)
    }
    @objc func toggleReferenceSelection() {
        execCommand(for: .reference)
    }
    @objc func toggleTemplateSelection() {
        execCommand(for: .template)
    }
    @objc func toggleAnchorSelection() {
        execCommand(for: .anchor)
    }
    @objc func toggleIndentSelection() {
        execCommand(for: .indent)
    }
    @objc func toggleSignatureSelection() {
        execCommand(for: .signature)
    }
    @objc func toggleListSelection() {
        execCommand(for: .list)
    }
    @objc func toggleHeadingSelection() {
        execCommand(for: .heading)
    }
    @objc func increaseIndentDepth() {
        execCommand(for: .increaseIndentDepth)
    }
    @objc func decreaseIndentDepth() {
        execCommand(for: .decreaseIndentDepth)
    }
    
    
    @objc func undo() {
        execCommand(for: .undo)
    }
    @objc func redo() {
        execCommand(for: .redo)
    }

    
    @objc func moveCursorDown() {
        execCommand(for: .cursorDown)
    }
    @objc func moveCursorUp() {
        execCommand(for: .cursorUp)
    }
    @objc func moveCursorLeft() {
        execCommand(for: .cursorLeft)
    }
    @objc func moveCursorRight() {
        execCommand(for: .cursorRight)
    }

    
    private func commandJS(for commandType: CodeMirrorCommandType) -> String {
        return "window.wmf.commands.\(commandType.rawValue)();"
    }
    private func execCommand(for commandType: CodeMirrorCommandType) {
        evaluateJavaScript(commandJS(for: commandType), completionHandler: nil)
    }
}
