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
    case increaseDepth
    case decreaseDepth
    case undo
    case redo
    case cursorDown
    case cursorUp
    case cursorLeft
    case cursorRight
}

extension SectionEditorWebView {
    @objc func toggleBoldSelection() {
        print("0")
    }
    @objc func toggleItalicSelection() {
        print("1")
    }
    @objc func toggleReferenceSelection() {
        print("2")
    }
    @objc func toggleTemplateSelection() {
        print("3")
    }
    @objc func toggleAnchorSelection() {
        print("4")
    }
    @objc func toggleIndentSelection() {
        print("5")
    }
    @objc func toggleSignatureSelection() {
        print("6")
    }
    @objc func toggleListSelection() {
        print("7")
    }
    @objc func toggleHeadingSelection() {
        print("8")
    }
    @objc func increaseIndentDepth() {
        print("9")
    }
    @objc func decreaseIndentDepth() {
        print("10")
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
