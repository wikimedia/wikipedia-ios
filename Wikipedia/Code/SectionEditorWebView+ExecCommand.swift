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



/*
TODO:
- use separate methods instead of the exec command approach above
*/

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
        print("11")
        evaluateJavaScript("window.wmf.commands.undo();", completionHandler: nil)
    }
    @objc func redo() {
        print("12")
        evaluateJavaScript("window.wmf.commands.redo();", completionHandler: nil)
    }

    
    @objc func moveCursorDown() {
        print("13")
    }
    @objc func moveCursorUp() {
        print("14")
    }
    @objc func moveCursorLeft() {
        print("15")
    }
    @objc func moveCursorRight() {
        print("16")
    }

    
}
