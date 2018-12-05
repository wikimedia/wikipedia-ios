
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
        evaluateJavaScript("window.wmf.commands.cursorDown();", completionHandler: nil)
    }
    @objc func moveCursorUp() {
        print("14")
        evaluateJavaScript("window.wmf.commands.cursorUp();", completionHandler: nil)
    }
    @objc func moveCursorLeft() {
        print("15")
        evaluateJavaScript("window.wmf.commands.cursorLeft();", completionHandler: nil)
    }
    @objc func moveCursorRight() {
        print("16")
        evaluateJavaScript("window.wmf.commands.cursorRight();", completionHandler: nil)
    }

    
}
