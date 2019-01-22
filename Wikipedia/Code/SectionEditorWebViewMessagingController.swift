protocol SectionEditorWebViewMessagingControllerButtonMessageDelegate: class {
    func sectionEditorWebViewMessagingControllerDidReceiveSelectButtonMessage(_ sectionEditorWebViewMessagingController: SectionEditorWebViewMessagingController, button: SectionEditorWebViewMessagingController.Button)
    func sectionEditorWebViewMessagingControllerDidReceiveDisableButtonMessage(_ sectionEditorWebViewMessagingController: SectionEditorWebViewMessagingController, button: SectionEditorWebViewMessagingController.Button)
}

protocol SectionEditorWebViewMessagingControllerTextSelectionDelegate: class {
    func sectionEditorWebViewMessagingControllerDidReceiveTextSelectionChangeMessage(_ sectionEditorWebViewMessagingController: SectionEditorWebViewMessagingController, isRangeSelected: Bool)
}

protocol SectionEditorWebViewMessagingControllerFindInPageDelegate: class {
    func sectionEditorWebViewMessagingControllerDidReceiveFindInPagesMatchesMessage(_ sectionEditorWebViewMessagingController: SectionEditorWebViewMessagingController, matchesCount: Int, matchIndex: Int, matchID: String)
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
                buttonSelectionDelegate?.sectionEditorWebViewMessagingControllerDidReceiveSelectButtonMessage(self, button: Button(kind: kind))
            }

            // Process 'disableTheseButtons' message.
            for element in buttonsToDisable {
                guard let kind = buttonKind(from: element) else {
                    continue
                }
                buttonSelectionDelegate?.sectionEditorWebViewMessagingControllerDidReceiveDisableButtonMessage(self, button: Button(kind: kind))
            }
        case (Message.Name.codeMirrorSearchMessage, let message as [String: Any]):
            guard
                let count = message[Message.Name.findInPageMatchesCount] as? Int,
                let index = message[Message.Name.findInPageFocusedMatchIndex] as? Int,
                let id = message[Message.Name.findInPageFocusedMatchID] as? String
            else {
                assertionFailure("Expected message with findInPageMatchesCount, findInPageFocusedMatchIndex and findInPageFocusedMatchID, received: \(message)")
                return
            }
            findInPageDelegate?.sectionEditorWebViewMessagingControllerDidReceiveFindInPagesMatchesMessage(self, matchesCount: count, matchIndex: index, matchID: id)
        default:
            assertionFailure("Unsupported message: \(message.name), \(message.body)")
        }
    }

    func buttonKind(from dictionary: [String: Any]) -> Button.Kind? {
        guard let rawValue = dictionary[Message.Body.Key.button] as? String else {
            return nil
        }
        let info = buttonInfo(from: dictionary)
        guard let kind = Button.Kind(rawValue: rawValue, info: info) else {
            return nil
        }
        return kind
    }

    func buttonInfo(from dictionary: [String: Any]) -> Button.Info? {
        guard let info = dictionary[Message.Body.Key.info] as? [String: Any] else {
            return nil
        }
        let depth = info[Button.Info.depth] as? Int ?? 0
        let textStyleType = TextStyleType(rawValue: depth)

        let size = info[Button.Info.size] as? String ?? "normal"
        let textSizeType = TextSizeType(rawValue: size)

        let ordered = info[Button.Info.ordered] as? Bool

        return Button.Info(textStyleType: textStyleType, textSizeType: textSizeType, ordered: ordered)
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

    @objc func getWikitext(completionHandler: ((Any?, Error?) -> Void)? = nil) {
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
        case selectAll
        case highlighting
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

    func selectAllText() {
        execCommand(for: .selectAll)
    }

    func toggleSyntaxHighlighting() {
        execCommand(for: .highlighting)
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
        execCommand(for: .find, argument: "\"\(text)\"")
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

    struct Button {
        enum Kind: Equatable {
            case li(ordered: Bool)
            case heading(type: TextStyleType)
            case indent
            case signature
            case link
            case bold
            case italic
            case reference
            case template
            case undo
            case redo
            case progress
            case comment
            case textSize(type: TextSizeType)
            case superscript
            case `subscript`
            case underline
            case strikethrough
            case decreaseIndentDepth
            case increaseIndentDepth

            var identifier: Int? {
                switch self {
                case .li(let ordered) where ordered:
                    return 1
                case .li(let ordered) where !ordered:
                    return 2
                case .indent:
                    return 3
                case .heading:
                    return 4
                case .signature:
                    return 5
                case .link:
                    return 6
                case .bold:
                    return 7
                case .italic:
                    return 8
                case .reference:
                    return 9
                case .template:
                    return 10
                case .undo:
                    return 11
                case .redo:
                    return 12
                case .progress:
                    return 13
                case .comment:
                    return 14
                case .superscript:
                    return 17
                case .subscript:
                    return 18
                case .underline:
                    return 19
                case .strikethrough:
                    return 20
                case .decreaseIndentDepth:
                    return 21
                case .increaseIndentDepth:
                    return 22
                default:
                    return nil
                }
            }

            init?(rawValue: String, info: Button.Info? = nil) {
                if rawValue == "li", let ordered = info?.ordered {
                    self = .li(ordered: ordered)
                } else if rawValue == "heading", let textStyleType = info?.textStyleType {
                    self = .heading(type: textStyleType)
                } else if rawValue == "textSize", let textSizeType = info?.textSizeType {
                    self = .textSize(type: textSizeType)
                } else {
                    switch rawValue {
                    case "indent":
                        self = .indent
                    case "signature":
                        self = .signature
                    case "link":
                        self = .link
                    case "bold":
                        self = .bold
                    case "italic":
                        self = .italic
                    case "reference":
                        self = .reference
                    case "template":
                        self = .template
                    case "undo":
                        self = .undo
                    case "redo":
                        self = .redo
                    case "progress":
                        self = .progress
                    case "comment":
                        self = .comment
                    case "superscript":
                        self = .superscript
                    case "subscript":
                        self = .subscript
                    case "underline":
                        self = .underline
                    case "strikethrough":
                        self = .strikethrough
                    case "decreaseIndentDepth":
                        self = .decreaseIndentDepth
                    case "increaseIndentDepth":
                        self = .increaseIndentDepth
                    default:
                        return nil
                    }
                }
            }
        }
        struct Info {
            static let ordered = "ordered"
            static let depth = "depth"
            static let size = "size"

            let textStyleType: TextStyleType?
            let textSizeType: TextSizeType?
            let ordered: Bool?
        }
        let kind: Kind
    }
}
