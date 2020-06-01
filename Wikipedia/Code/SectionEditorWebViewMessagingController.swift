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

protocol SectionEditorWebViewMessagingControllerAlertDelegate: class {
    func sectionEditorWebViewMessagingControllerDidReceiveReplaceAllMessage(_ sectionEditorWebViewMessagingController: SectionEditorWebViewMessagingController, replacedCount: Int)
}

protocol SectionEditorWebViewMessagingControllerScrollDelegate: class {
    func sectionEditorWebViewMessagingController(_ sectionEditorWebViewMessagingController: SectionEditorWebViewMessagingController, didReceiveScrollMessageWithNewContentOffset newContentOffset: CGPoint)
}

enum WebViewMessagingError: LocalizedError {
    case generic
    var localizedDescription: String {
        return CommonStrings.genericErrorDescription
    }
}

enum CompletionType {
    case wikitext
}

class SectionEditorWebViewMessagingController: NSObject, WKScriptMessageHandler {
    weak var buttonSelectionDelegate: SectionEditorWebViewMessagingControllerButtonMessageDelegate?
    weak var textSelectionDelegate: SectionEditorWebViewMessagingControllerTextSelectionDelegate?
    weak var findInPageDelegate: SectionEditorWebViewMessagingControllerFindInPageDelegate?
    weak var alertDelegate: SectionEditorWebViewMessagingControllerAlertDelegate?
    weak var scrollDelegate: SectionEditorWebViewMessagingControllerScrollDelegate?

    weak var webView: WKWebView!
    
    var completions: [CompletionType: (Error?) -> Void] = [:]

    // MARK: - Receiving messages

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch (message.name, message.body) {
        case (Message.Name.didSetWikitextMessage, let result as [String: Any]):
            assert(Thread.isMainThread)
            completions[.wikitext]?(result["error"] != nil ? WebViewMessagingError.generic : nil)
            completions.removeValue(forKey: .wikitext)
        case (Message.Name.replaceAllCountMessage, let count as Int):
            alertDelegate?.sectionEditorWebViewMessagingControllerDidReceiveReplaceAllMessage(self, replacedCount: count)
        case (Message.Name.smoothScrollToYOffsetMessage, let yOffset as CGFloat):
            let newOffset = CGPoint(x: webView.scrollView.contentOffset.x, y: webView.scrollView.contentOffset.y + yOffset)
            scrollDelegate?.sectionEditorWebViewMessagingController(self, didReceiveScrollMessageWithNewContentOffset: newOffset)
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
        assert(Thread.isMainThread)
        let escapedWikitext = wikitext.sanitizedForJavaScriptTemplateLiterals
        completions[.wikitext] = completionHandler
        webView.evaluateJavaScript("window.wmf.setWikitext(`\(escapedWikitext)`, () => {  window.webkit.messageHandlers.didSetWikitextMessage.postMessage({}); });") { (_, error) in
            guard let error = error, let completionHandler = completionHandler else {
                return
            }
            completionHandler(error)
            assert(Thread.isMainThread)
            self.completions.removeValue(forKey: .wikitext)
        }
    }

    func highlightAndScrollToText(for selectedTextEditInfo: SelectedTextEditInfo, completionHandler: ((Error?) -> Void)? = nil) {
        let selectedAndAdjacentText = selectedTextEditInfo.selectedAndAdjacentText
        let escapedSelectedText = selectedAndAdjacentText.selectedText.sanitizedForJavaScriptTemplateLiterals
        let escapedTextBeforeSelectedText = selectedAndAdjacentText.textBeforeSelectedText.sanitizedForJavaScriptTemplateLiterals
        let escapedTextAfterSelectedText = selectedAndAdjacentText.textAfterSelectedText.sanitizedForJavaScriptTemplateLiterals
        webView.evaluateJavaScript("""
            window.wmf.highlightAndScrollToWikitextForSelectedAndAdjacentText(`\(escapedSelectedText)`, `\(escapedTextBeforeSelectedText)`, `\(escapedTextAfterSelectedText)`);
        """) { (_, error) in
            guard let completionHandler = completionHandler else {
                return
            }
            completionHandler(error)
        }
    }

    func getWikitext(completionHandler: ((String?, Error?) -> Void)? = nil) {
        webView.evaluateJavaScript("window.wmf.getWikitext();", completionHandler: { (result, error) in
            guard error == nil, let wikitext = result as? String else {
                completionHandler?(nil, WebViewMessagingError.generic)
                return
            }
            // multiple spaces in a row have non breaking spaces automatically added, so they need to be removed https://phabricator.wikimedia.org/T218993
            let transformedWikitext = wikitext.replacingOccurrences(of: "\u{00a0}", with: " ")
            completionHandler?(transformedWikitext, nil)
        })
    }

    private enum CodeMirrorCommandType: String {
        case bold
        case italic
        case reference
        case template
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
        case focusWithoutScroll
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
        case replaceAll
        case replaceSingle
        case selectLastFocusedMatch
        case selectLastSelection
        case clearFormatting
        case replaceSelection
        case lineInfo
        case newlineAndIndent
        case getLink
        case insertOrEditLink
        case removeLink
    }

    private func commandJS(for commandType: CodeMirrorCommandType, argument: Any? = nil) -> String {
        return "window.wmf.commands.\(commandType.rawValue)(\(argument ?? ""));"
    }

    private func execCommand(for commandType: CodeMirrorCommandType, argument: Any? = nil, completionHandler: ((Any?, Error?) -> Void)? = nil) {
        webView.evaluateJavaScript(commandJS(for: commandType, argument: argument), completionHandler: completionHandler)
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

    struct Link {
        let page: String
        let label: String?
        let exists: Bool

        init?(page: String?, label: String?, exists: Bool?) {
            guard let page = page else {
                assertionFailure("Attempting to create a Link without a page")
                return nil
            }
            guard let exists = exists else {
                assertionFailure("Attempting to create a Link without information about whether it's an existing link")
                return nil
            }
            self.page = page
            self.label = label
            self.exists = exists
        }

        var hasLabel: Bool {
            return label != nil
        }

        func articleURL(for siteURL: URL) -> URL? {
            guard exists else {
                return nil
            }
            return siteURL.wmf_URL(withTitle: page)
        }
    }

    func getLink(completion: @escaping (Link?) -> Void) {
        execCommand(for: .getLink) { result, error in
            guard error == nil else {
                completion(nil)
                return
            }
            guard let link = result as? [String: Any] else {
                return
            }
            let rawPage = link["page"] as? String
            let page = (rawPage?.wmf_hasAlphanumericText == true) ? rawPage : ""
            let label = link["label"] as? String
            let exists = link["hasMarkup"] as? Bool
            completion(Link(page: page, label: label, exists: exists))
        }
    }

    func insertOrEditLink(page: String, label: String?) {
        let labelOrNull = label.flatMap { "\"\($0)\"" } ?? "null"
        let argument = "\"\(page)\", \(labelOrNull)".sanitizedForJavaScriptTemplateLiterals
        execCommand(for: .insertOrEditLink, argument: argument)
    }

    func removeLink() {
        execCommand(for: .removeLink)
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

    func selectLastFocusedMatch() {
        execCommand(for: .selectLastFocusedMatch)
    }
    
    func selectLastSelection() {
        execCommand(for: .selectLastSelection)
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

    func focus(_ completion: (() -> Void)? = nil) {
        execCommand(for: .focus) { (_, _) in
            completion?()
        }
    }

    func focusWithoutScroll() {
        execCommand(for: .focusWithoutScroll)
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
        let escapedText = text.sanitizedForJavaScriptTemplateLiterals
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
    
    func replaceAll(text: String) {
        let escapedText = text.sanitizedForJavaScriptTemplateLiterals
        execCommand(for: .replaceAll, argument: "`\(escapedText)`")
    }
    
    func replaceSingle(text: String) {
        let escapedText = text.sanitizedForJavaScriptTemplateLiterals
        execCommand(for: .replaceSingle, argument: "`\(escapedText)`")
    }
    
    func clearFormatting() {
        execCommand(for: .clearFormatting)
    }

    func replaceSelection(text: String) {
        let escapedText = text.sanitizedForJavaScriptTemplateLiterals
        execCommand(for: .replaceSelection, argument: "`\(escapedText)`")
    }

    struct LineInfo {
        let hasLineTokens: Bool
        let isAtLineEnd: Bool
    }

    func getLineInfo(_ completion: @escaping (LineInfo?) -> Void) {
        execCommand(for: .lineInfo) { result, error in
            guard error == nil else {
                completion(nil)
                return
            }
            guard let result = result as? [String: Bool] else {
                completion(nil)
                return
            }
            guard
                let hasLineTokens = result["hasLineTokens"],
                let isAtLineEnd = result["isAtLineEnd"]
                else {
                    assertionFailure("Unexpected result structure")
                    completion(nil)
                    return
            }
            completion(LineInfo(hasLineTokens: hasLineTokens, isAtLineEnd: isAtLineEnd))
        }
    }

    func newlineAndIndent() {
        execCommand(for: .newlineAndIndent)
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
            static let replaceAllCountMessage = "replaceAllCountMessage"
            static let didSetWikitextMessage = "didSetWikitextMessage"
        }
        struct Body {
            struct Key {
                static let button = "button"
                static let info = "info"
            }
        }
    }
}
