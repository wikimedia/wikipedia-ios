protocol SectionEditorWebViewMessagingControllerButtonMessageDelegate: class {
    func sectionEditorWebViewMessagingControllerDidReceiveSelectButtonMessage(_ sectionEditorWebViewMessagingController: SectionEditorWebViewMessagingController, button: SectionEditorButton)
    func sectionEditorWebViewMessagingControllerDidReceiveDisableButtonMessage(_ sectionEditorWebViewMessagingController: SectionEditorWebViewMessagingController, button: SectionEditorButton)
}

protocol SectionEditorWebViewMessagingControllerTextSelectionDelegate: class {
    func sectionEditorWebViewMessagingControllerDidReceiveTextSelectionChangeMessage(_ sectionEditorWebViewMessagingController: SectionEditorWebViewMessagingController, isRangeSelected: Bool)
}

protocol SectionEditorWebViewMessagingControllerFindInPageDelegate: class {
    func sectionEditorWebViewMessagingControllerDidReceiveFindInPagesMatchesMessage(_ sectionEditorWebViewMessagingController: SectionEditorWebViewMessagingController, matchesCount: Int, matchIndex: Int, matchID: String?)
}

class SectionEditorWebViewMessagingController: NSObject, WKScriptMessageHandler {
    weak var buttonSelectionDelegate: SectionEditorWebViewMessagingControllerButtonMessageDelegate?
    weak var textSelectionDelegate: SectionEditorWebViewMessagingControllerTextSelectionDelegate?
    weak var findInPageDelegate: SectionEditorWebViewMessagingControllerFindInPageDelegate?

    weak var webView: WKWebView!

    // MARK: - Receiving messages

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch (message.name, message.body) {

        case (Message.Name.smoothScrollToYOffsetMessage, let yOffset as CGFloat):
            let newOffset = CGPoint(x: webView.scrollView.contentOffset.x, y: webView.scrollView.contentOffset.y + yOffset)
            webView.scrollView.setContentOffset(newOffset, animated: true)
        case (Message.Name.codeMirrorMessage, let message as [String: Any]):
            guard
                let selectionChangedMessage = message[Message.Name.selectionChanged],
                let isRangeSelected = selectionChangedMessage as? Bool,
                let highlightTheseButtonsMessage = message[Message.Name.highlightTheseButtons],
                let buttonsToHighlight = highlightTheseButtonsMessage as? [[String: Any]],
                let disableTheseButtonsMessage = message[Message.Name.disableTheseButtons],
                let buttonsToDisable = disableTheseButtonsMessage as? [[String: Any]]
            else {
                assertionFailure("Expected messages not extracted: \(message)")
                return
            }

            // Process the 'selectionChanged' message first so buttons can be reset before subsequent button messages are processed.
            textSelectionDelegate?.sectionEditorWebViewMessagingControllerDidReceiveTextSelectionChangeMessage(self, isRangeSelected: isRangeSelected)

            // Process 'highlightTheseButtons' message.
            for element in buttonsToHighlight {
                guard let kind = buttonKind(from: element) else {
                    continue
                }
                buttonSelectionDelegate?.sectionEditorWebViewMessagingControllerDidReceiveSelectButtonMessage(self, button: SectionEditorButton(kind: kind))
            }

            // Process 'disableTheseButtons' message.
            for element in buttonsToDisable {
                guard let kind = buttonKind(from: element) else {
                    continue
                }
                buttonSelectionDelegate?.sectionEditorWebViewMessagingControllerDidReceiveDisableButtonMessage(self, button: SectionEditorButton(kind: kind))
            }
        case (Message.Name.codeMirrorSearchMessage, let message as [String: Any]):
            guard
                let count = message[Message.Name.findInPageMatchesCount] as? Int,
                let index = message[Message.Name.findInPageFocusedMatchIndex] as? Int
            else {
                assertionFailure("Expected message with findInPageMatchesCount and findInPageFocusedMatchIndex, received: \(message)")
                return
            }
            let id = message[Message.Name.findInPageFocusedMatchID] as? String
            findInPageDelegate?.sectionEditorWebViewMessagingControllerDidReceiveFindInPagesMatchesMessage(self, matchesCount: count, matchIndex: index, matchID: id)
        default:
            assertionFailure("Unsupported message: \(message.name), \(message.body)")
        }
    }

    func buttonKind(from dictionary: [String: Any]) -> SectionEditorButton.Kind? {
        guard let rawValue = dictionary[Message.Body.Key.button] as? String else {
            return nil
        }
        let info = buttonInfo(from: dictionary)
        guard let kind = SectionEditorButton.Kind(rawValue: rawValue, info: info) else {
            return nil
        }
        return kind
    }

    func buttonInfo(from dictionary: [String: Any]) -> SectionEditorButton.Info? {
        guard let info = dictionary[Message.Body.Key.info] as? [String: Any] else {
            return nil
        }
        let depth = info[SectionEditorButton.Info.depth] as? Int ?? 0
        let textStyleType = TextStyleType(rawValue: depth)

        let size = info[SectionEditorButton.Info.size] as? String ?? "normal"
        let textSizeType = TextSizeType(rawValue: size)

        let ordered = info[SectionEditorButton.Info.ordered] as? Bool

        return SectionEditorButton.Info(textStyleType: textStyleType, textSizeType: textSizeType, ordered: ordered)
    }

    // MARK: - Sending messages

    func performSetupJS(completionHandler: ((Error?) -> Void)? = nil) {
        webView.evaluateJavaScript("""
            window.wmf.setup();
        """) { (_, error) in
            guard let completionHandler = completionHandler else {
                return
            }
            completionHandler(error)
        }
    }

    func setWikitext(_ wikitext: String, completionHandler: ((Error?) -> Void)? = nil) {
        let escapedWikitext = wikitext.wmf_stringBySanitizingForBacktickDelimitedJavascript()
        webView.evaluateJavaScript("window.wmf.setWikitext(`\(escapedWikitext)`);") { (_, error) in
            guard let completionHandler = completionHandler else {
                return
            }
            completionHandler(error)
        }
    }

    func highlightAndScrollToText(for selectedTextEditInfo: SelectedTextEditInfo, completionHandler: ((Error?) -> Void)? = nil) {
        let selectedAndAdjacentText = selectedTextEditInfo.selectedAndAdjacentText
        let escapedSelectedText = selectedAndAdjacentText.selectedText.wmf_stringBySanitizingForBacktickDelimitedJavascript()
        let escapedTextBeforeSelectedText = selectedAndAdjacentText.textBeforeSelectedText.wmf_stringBySanitizingForBacktickDelimitedJavascript()
        let escapedTextAfterSelectedText = selectedAndAdjacentText.textAfterSelectedText.wmf_stringBySanitizingForBacktickDelimitedJavascript()
        webView.evaluateJavaScript("""
            window.wmf.highlightAndScrollToWikitextForSelectedAndAdjacentText(`\(escapedSelectedText)`, `\(escapedTextBeforeSelectedText)`, `\(escapedTextAfterSelectedText)`);
        """) { (_, error) in
            guard let completionHandler = completionHandler else {
                return
            }
            completionHandler(error)
        }
    }

    func getWikitext(completionHandler: ((Any?, Error?) -> Void)? = nil) {
        webView.evaluateJavaScript("window.wmf.getWikitext();", completionHandler: completionHandler)
    }

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
        case blur
        case selectAll
        case highlighting
        case lineNumbers
        case syntaxColors
        case scaleBodyText
        case theme
        case `subscript`
        case superscript
        case underline
        case strikethrough
        case textSize
        case find
        case clearSearch
        case findNext
        case findPrevious
        case adjustedContentInsetChanged
    }

    private func commandJS(for commandType: CodeMirrorCommandType, argument: Any? = nil) -> String {
        return "window.wmf.commands.\(commandType.rawValue)(\(argument ?? ""));"
    }

    private func execCommand(for commandType: CodeMirrorCommandType, argument: Any? = nil) {
        webView.evaluateJavaScript(commandJS(for: commandType, argument: argument), completionHandler: nil)
    }

    func toggleBoldSelection() {
        execCommand(for: .bold)
    }

    func toggleItalicSelection() {
        execCommand(for: .italic)
    }

    func toggleReferenceSelection() {
        execCommand(for: .reference)
    }

    func toggleTemplateSelection() {
        execCommand(for: .template)
    }

    func toggleAnchorSelection() {
        execCommand(for: .anchor)
    }

    func toggleIndentSelection() {
        execCommand(for: .indent)
    }

    func toggleSignatureSelection() {
        execCommand(for: .signature)
    }

    func toggleOrderedListSelection() {
        execCommand(for: .orderedList)
    }

    func toggleUnorderedListSelection() {
        execCommand(for: .unorderedList)
    }

    func setHeadingSelection(depth: Int) {
        execCommand(for: .heading, argument: depth)
    }

    func increaseIndentDepth() {
        execCommand(for: .increaseIndentDepth)
    }

    func decreaseIndentDepth() {
        execCommand(for: .decreaseIndentDepth)
    }

    func undo() {
        execCommand(for: .undo)
    }
    func redo() {
        execCommand(for: .redo)
    }

    func moveCursorDown() {
        execCommand(for: .cursorDown)
    }

    func moveCursorUp() {
        execCommand(for: .cursorUp)
    }

    func moveCursorLeft() {
        execCommand(for: .cursorLeft)
    }

    func moveCursorRight() {
        execCommand(for: .cursorRight)
    }

    func toggleComment() {
        execCommand(for: .comment)
    }

    func focus() {
        execCommand(for: .focus)
    }
    
    func blur() {
        execCommand(for: .blur)
    }

    func selectAllText() {
        execCommand(for: .selectAll)
    }

    func toggleSyntaxHighlighting() {
        execCommand(for: .highlighting)
    }
    
    func toggleLineNumbers() {
        execCommand(for: .lineNumbers)
    }
    
    func applyTheme(theme: Theme) {
        execCommand(for: .theme, argument: "'\(theme.webName)'")
    }
    
    func toggleSyntaxColors() {
        execCommand(for: .syntaxColors)
    }
    
    func scaleBodyText(newSize: String) {
        execCommand(for: .scaleBodyText, argument: "\"\(newSize)\"")
    }

    func toggleSubscript() {
        execCommand(for: .subscript)
    }

    func toggleSuperscript() {
        execCommand(for: .superscript)
    }

    func toggleUnderline() {
        execCommand(for: .underline)
    }

    func toggleStrikethrough() {
        execCommand(for: .strikethrough)
    }

    func setTextSize(newSize: String) {
        execCommand(for: .textSize, argument: "\"\(newSize)\"")
    }

    func find(text: String) {
        let escapedText = text.wmf_stringBySanitizingForBacktickDelimitedJavascript()
        execCommand(for: .find, argument: "`\(escapedText)`")
    }

    func clearSearch() {
        execCommand(for: .clearSearch)
    }

    func findNext() {
        execCommand(for: .findNext)
    }

    func findPrevious() {
        execCommand(for: .findPrevious)
    }

    func setAdjustedContentInset(newInset: UIEdgeInsets) {
        execCommand(for: .adjustedContentInsetChanged, argument: "{top: \(newInset.top), left: \(newInset.left), bottom: \(newInset.bottom), right: \(newInset.right)}")
    }
}

extension SectionEditorWebViewMessagingController {
    struct Message {
        struct Name {
            static let selectionChanged = "selectionChanged"
            static let highlightTheseButtons = "highlightTheseButtons"
            static let disableTheseButtons = "disableTheseButtons"
            static let codeMirrorMessage = "codeMirrorMessage"
            static let codeMirrorSearchMessage = "codeMirrorSearchMessage"
            static let findInPageMatchesCount = "findInPageMatchesCount"
            static let findInPageFocusedMatchIndex = "findInPageFocusedMatchIndex"
            static let findInPageFocusedMatchID = "findInPageFocusedMatchID"
            static let smoothScrollToYOffsetMessage = "smoothScrollToYOffsetMessage"
        }
        struct Body {
            struct Key {
                static let button = "button"
                static let info = "info"
            }
        }
    }
}
