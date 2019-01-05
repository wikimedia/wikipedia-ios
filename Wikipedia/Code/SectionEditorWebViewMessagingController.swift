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
                // Ignore debug buttons for now
                guard button.kind != .debug else {
                    return
                }
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
        let depth = info[Button.Info.depth] as? Int ?? 0
        let textStyleType = TextStyleType(rawValue: depth)

        let size = info[Button.Info.size] as? String ?? "normal"
        let textSizeType = TextSizeType(rawValue: size)

        let ordered = info[Button.Info.ordered] as? Bool

        return Button.Info(textStyleType: textStyleType, textSizeType: textSizeType, ordered: ordered)
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
            case debug
            case comment
            case textSize(type: TextSizeType)
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
                    case "debug":
                        self = .debug
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
