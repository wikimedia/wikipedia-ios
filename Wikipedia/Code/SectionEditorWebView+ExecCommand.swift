
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
        evaluateJavaScript("window.wmf.commands.undo();", completionHandler: nil)
    }
    @objc func redo() {
        evaluateJavaScript("window.wmf.commands.redo();", completionHandler: nil)
    }

    
    @objc func moveCursorDown() {
        evaluateJavaScript("window.wmf.commands.cursorDown();", completionHandler: nil)
    }
    @objc func moveCursorUp() {
        evaluateJavaScript("window.wmf.commands.cursorUp();", completionHandler: nil)
    }
    @objc func moveCursorLeft() {
        evaluateJavaScript("window.wmf.commands.cursorLeft();", completionHandler: nil)
    }
    @objc func moveCursorRight() {
        evaluateJavaScript("window.wmf.commands.cursorRight();", completionHandler: nil)
    }

    
}
