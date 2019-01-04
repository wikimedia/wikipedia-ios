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
                let button = Button(kind: kind)
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
        enum Kind {
            case li(ordered: Bool)
            case heading(depth: Int)
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

            var identifier: Int? {
                switch self {
                case .li(let ordered) where ordered == true:
                    return 1
                case .li(let ordered) where ordered == false:
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
                case .debug:
                    return 13
                case .comment:
                    return 14
                case .smallTextSize:
                    return 15
                case .bigTextSize:
                    return 16
                case .superscript:
                    return 17
                case .subscript:
                    return 18
                case .underline:
                    return 19
                case .strikethrough:
                    return 20
                default:
                    return nil
                }
            }


            init?(rawValue: String, info: Button.Info? = nil) {
                if rawValue == "li", let ordered = info?.ordered {
                    self = .li(ordered: ordered)
                } else if rawValue == "heading", let depth = info?.depth {
                    self = .heading(depth: depth)
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
                    case "debug":
                        self = .debug
                    case "comment":
                        self = .comment
                    case "smallTextSize":
                        self = .smallTextSize
                    case "bigTextSize":
                        self = .bigTextSize
                    case "superscript":
                        self = .superscript
                    case "subscript":
                        self = .subscript
                    case "underline":
                        self = .underline
                    case "strikethrough":
                        self = .strikethrough
                    default:
                        return nil
                    }
                }
            }
        }
        struct Info {
            static let ordered = "ordered"
            static let depth = "depth"

            let depth: Int?
            let ordered: Bool?

        }
        let kind: Kind
    }
}
