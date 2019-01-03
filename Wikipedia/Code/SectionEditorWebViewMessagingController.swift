struct ButtonNeedsToBeSelectedMessage {
    let type: EditButtonType
    let ordered: Bool
    let depth: Int
}

struct SelectionChangedMessage {
    let selectionIsRange: Bool
}

private enum MessageConstants: String {
    case button
    case info
}

enum EditButtonType: String {
    case li
    case heading
    case indent
    case signature
    case link
    case bold
    case italic
    case reference
    case template
    case undo
    case redo
    case debug
    case comment
    case smallTextSize
    case bigTextSize
    case superscript
    case `subscript`
    case underline
    case strikethrough
}

private enum ButtonInfoConstants: String {
    case ordered
    case depth
}

protocol SectionEditorWebViewMessagingControllerButtonSelectionDelegate: class {
    func sectionEditorWebViewMessagingControllerDidReceiveButtonSelectionChangeMessage(_ sectionEditorWebViewMessagingController: SectionEditorWebViewMessagingController, button: SectionEditorWebViewMessagingController.Button)
}

protocol SectionEditorWebViewMessagingControllerTextSelectionDelegate: class {
    func sectionEditorWebViewMessagingControllerDidReceiveTextSelectionChangeMessage(_ sectionEditorWebViewMessagingController: SectionEditorWebViewMessagingController, isRangeSelected: Bool)
}

class SectionEditorWebViewMessagingController: NSObject, WKScriptMessageHandler {
    weak var buttonSelectionDelegate: SectionEditorWebViewMessagingControllerButtonSelectionDelegate?
    weak var textSelectionDelegate: SectionEditorWebViewMessagingControllerTextSelectionDelegate?

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch (message.name, message.body) {
        case (Message.Name.selectionChanged, let isRangeSelected as Bool):
            textSelectionDelegate?.sectionEditorWebViewMessagingControllerDidReceiveTextSelectionChangeMessage(self, isRangeSelected: isRangeSelected)
        case (Message.Name.highlightTheseButtons, let message as [[String: Any]]):
            for element in message {
                guard let kind = buttonKind(from: element) else {
                    continue
                }
                let info = buttonInfo(for: element)
                let button = Button(kind: kind, info: info)
                buttonSelectionDelegate?.sectionEditorWebViewMessagingControllerDidReceiveButtonSelectionChangeMessage(self, button: button)
            }
        default:
            assertionFailure("Unsupported message: \(message.name), \(message.body)")
        }
    }

    func buttonKind(from dictionary: [String: Any]) -> Button.Kind? {
        guard let rawValue = dictionary[Message.Body.Key.button] as? String else {
            return nil
        }
        guard let kind = Button.Kind(rawValue: rawValue) else {
            return nil
        }
        return kind
    }

    func buttonInfo(for dictionary: [String: Any]) -> Button.Info? {
        guard let info = dictionary[Message.Body.Key.info] as? [String: Any] else {
            return nil
        }
        let depth = info[Button.Info.depth] as? Int
        let ordered = info[Button.Info.ordered] as? Bool

        return Button.Info.init(depth: depth, ordered: ordered)
    }
}

extension SectionEditorWebViewMessagingController {
    struct Message {
        struct Name {
            static let selectionChanged = "selectionChanged"
            static let highlightTheseButtons = "highlightTheseButtons"
        }
        struct Body {
            struct Key {
                static let button = "button"
                static let info = "info"
            }
        }
    }

    struct Button {
        enum Kind: String {
            case li
            case heading
            case indent
            case signature
            case link
            case bold
            case italic
            case reference
            case template
            case undo
            case redo
            case debug
            case comment
            case smallTextSize
            case bigTextSize
            case superscript
            case `subscript`
            case underline
            case strikethrough
        }
        struct Info {
            static let ordered = "ordered"
            static let depth = "depth"

            let depth: Int?
            let ordered: Bool?

        }
        let kind: Kind
        let info: Info?
    }
}
