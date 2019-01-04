private enum CodeMirrorCommandType: String {
    case bold
    case italic
    case reference
    case template
    case anchor
    case indent
    case signature
    case orderedList
    case unorderedList
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
    case `subscript`
    case superscript
    case underline
    case strikethrough
    case textSize
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
    @objc func toggleOrderedListSelection() {
        execCommand(for: .orderedList)
    }
    @objc func toggleUnorderedListSelection() {
        execCommand(for: .unorderedList)
    }
    @objc func setHeadingSelection(depth: Int) {
        execCommand(for: .heading, argument: depth)
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

    @objc func toggleComment() {
        execCommand(for: .comment)
    }
    
    @objc func focus() {
        execCommand(for: .focus)
    }

    func selectAllText() {
        execCommand(for: .selectAll)
    }
    
    @objc func toggleSyntaxHighlighting() {
        execCommand(for: .highlighting)
    }

    @objc func toggleSubscript() {
        execCommand(for: .subscript)
    }
    @objc func toggleSuperscript() {
        execCommand(for: .superscript)
    }
    @objc func toggleUnderline() {
        execCommand(for: .underline)
    }
    @objc func toggleStrikethrough() {
        execCommand(for: .strikethrough)
    }

    @objc func setTextSize(newSize: String) {
        execCommand(for: .textSize, argument: "\"\(newSize)\"")
    }

    private func commandJS(for commandType: CodeMirrorCommandType, argument: Any? = nil) -> String {
        return "window.wmf.commands.\(commandType.rawValue)(\(argument ?? ""));"
    }
    private func execCommand(for commandType: CodeMirrorCommandType, argument: Any? = nil) {
        evaluateJavaScript(commandJS(for: commandType, argument: argument), completionHandler: nil)
    }
}
