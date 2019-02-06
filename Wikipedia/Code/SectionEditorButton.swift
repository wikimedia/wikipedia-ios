import Foundation

struct SectionEditorButton {
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
        case directionUp
        case directionDown
        case directionLeft
        case directionRight
        case findInPage
        case textFormattingMenu
        case textStyleMenu
        
        var title: String? {
            switch self {
            case .li(let ordered):
                return ordered ? WMFLocalizedString("editor-ordered-list-title", value: "Ordered list", comment: "Title for ordered list button") : WMFLocalizedString("editor-unordered-list-title", value: "Unordered list", comment: "Title for unordered list button")
            case .indent:
                return WMFLocalizedString("editor-indent-title", value: "Indent", comment: "Title for indent button")
            case .heading:
                return nil
            case .signature:
                return WMFLocalizedString("editor-signature-label", value: "Signature", comment: "Title for signature button")
            case .link:
                return WMFLocalizedString("editor-link-title", value: "Link", comment: "Title for link button")
            case .bold:
                return WMFLocalizedString("editor-bold-title", value: "Bold", comment: "Title for bold button")
            case .italic:
                return WMFLocalizedString("editor-italic-title", value: "Italic", comment: "Title for italic button")
            case .reference:
                return WMFLocalizedString("editor-reference-title", value: "Reference", comment: "Title for reference button")
            case .template:
                return WMFLocalizedString("editor-template-title", value: "Template", comment: "Title for template button")
            case .undo:
                return CommonStrings.undo
            case .redo:
                return CommonStrings.redo
            case .comment:
                return WMFLocalizedString("editor-comment-title", value: "Comment", comment: "Title for comment button")
            case .superscript:
                return WMFLocalizedString("editor-superscript-title", value: "Superscript", comment: "Title for superscript button")
            case .subscript:
                return WMFLocalizedString("editor-subscript-title", value: "Subscript", comment: "Title for subscript button")
            case .underline:
                return WMFLocalizedString("editor-underline-title", value: "Underline", comment: "Title for underline button")
            case .strikethrough:
                return WMFLocalizedString("editor-strikethrough-title", value: "Strikethrough", comment: "Title for strikethrough button")
            case .decreaseIndentDepth:
                return WMFLocalizedString("editor-decrease-indent-depth-title", value: "Decrease indent depth", comment: "Title for decrease indent depth button")
            case .increaseIndentDepth:
                return WMFLocalizedString("editor-increase-indent-depth-title", value: "Increase indent depth", comment: "Title for increase indent depth button")
            case .directionUp:
                return WMFLocalizedString("editor-direction-up-title", value: "Move cursor up", comment: "Title for move cursor up button")
            case .directionDown:
                return WMFLocalizedString("editor-direction-down-title", value: "Move cursor down", comment: "Title for move cursor down button")
            case .directionLeft:
                return WMFLocalizedString("editor-direction-left-title", value: "Move cursor left", comment: "Title for move cursor left button")
            case .directionRight:
                return WMFLocalizedString("editor-direction-right-title", value: "Move cursor right", comment: "Title for move cursor right button")
            case .findInPage:
                return CommonStrings.findInPage
            case .progress:
                return nil
            case .textSize:
                return nil
            case .textFormattingMenu:
                return WMFLocalizedString("editor-text-formatting-title", value: "Text formatting menu", comment: "Title for text formatting menu")
            case .textStyleMenu:
                return WMFLocalizedString("editor-text-style-title", value: "Text style menu", comment: "Title for text style menu")
            }
        }
        
        var removeTitle: String? {
            guard let title = title else {
                return nil
            }
            let format = WMFLocalizedString("editor-remove-title", value: "Remove “%1$@”", comment: "Removes formatting. Type of formatting replaces %1$@/")
            return String.localizedStringWithFormat(format, title)
        }
        
        init?(identifier: Int) {
            switch identifier {
            case 1:
                self = .li(ordered: true)
            case 2:
                self = .li(ordered: false)
            case 3:
                self = .indent
            case 4:
                self = .heading(type: .heading)
            case 5:
                self = .signature
            case 6:
                self = .link
            case 7:
                self = .bold
            case 8:
                self = .italic
            case 9:
                self = .reference
            case 10:
                self = .template
            case 11:
                self = .undo
            case 12:
                self = .redo
            case 13:
                self = .progress
            case 14:
                self = .comment
            case 17:
                self = .superscript
            case 18:
                self = .subscript
            case 19:
                self = .underline
            case 20:
                self = .strikethrough
            case 21:
                self = .decreaseIndentDepth
            case 22:
                self = .increaseIndentDepth
            case 23:
                self = .directionUp
            case 24:
                self = .directionDown
            case 25:
                self = .directionLeft
            case 26:
                self = .directionRight
            case 27:
                self = .findInPage
            case 28:
                self = .textFormattingMenu
            case 29:
                self = .textStyleMenu
            default:
                return nil
            }
        }
        
        init?(rawValue: String, info: SectionEditorButton.Info? = nil) {
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
