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
        
        private var isFormatting: Bool {
            switch self {
            case .li:
                fallthrough
            case .signature:
                fallthrough
            case .link:
                fallthrough
            case .bold:
                fallthrough
            case .italic:
               fallthrough
            case .reference:
                fallthrough
            case .template:
                fallthrough
            case .comment:
               fallthrough
            case .superscript:
               fallthrough
            case .subscript:
                fallthrough
            case .underline:
                fallthrough
            case .strikethrough:
                return true
            default:
                return false
            }
        }
        
        private var title: String? {
            switch self {
            case .li(let ordered):
                return ordered ? WMFLocalizedString("edit-ordered-list-title", value: "Ordered list", comment: "Title for ordered list button") : WMFLocalizedString("edit-unordered-list-title", value: "Unordered list", comment: "Title for unordered list button")
            case .indent:
                return WMFLocalizedString("edit-indent-title", value: "Indent", comment: "Title for indent button")
            case .heading:
                return nil
            case .signature:
                return WMFLocalizedString("edit-signature-label", value: "Signature", comment: "Title for signature button")
            case .link:
                return WMFLocalizedString("edit-link-title", value: "Link", comment: "Title for link button")
            case .bold:
                return WMFLocalizedString("edit-bold-title", value: "Bold", comment: "Title for bold button")
            case .italic:
                return WMFLocalizedString("edit-italic-title", value: "Italic", comment: "Title for italic button")
            case .reference:
                return WMFLocalizedString("edit-reference-title", value: "Reference", comment: "Title for reference button")
            case .template:
                return WMFLocalizedString("edit-template-title", value: "Template", comment: "Title for template button")
            case .undo:
                return CommonStrings.undo
            case .redo:
                return CommonStrings.redo
            case .comment:
                return WMFLocalizedString("edit-comment-title", value: "Comment", comment: "Title for comment button")
            case .superscript:
                return WMFLocalizedString("edit-superscript-title", value: "Superscript", comment: "Title for superscript button")
            case .subscript:
                return WMFLocalizedString("edit-subscript-title", value: "Subscript", comment: "Title for subscript button")
            case .underline:
                return WMFLocalizedString("edit-underline-title", value: "Underline", comment: "Title for underline button")
            case .strikethrough:
                return WMFLocalizedString("edit-strikethrough-title", value: "Strikethrough", comment: "Title for strikethrough button")
            case .decreaseIndentDepth:
                return WMFLocalizedString("edit-decrease-indent-depth-title", value: "Decrease indent depth", comment: "Title for decrease indent depth button")
            case .increaseIndentDepth:
                return WMFLocalizedString("edit-increase-indent-depth-title", value: "Increase indent depth", comment: "Title for increase indent depth button")
            case .directionUp:
                return WMFLocalizedString("edit-direction-up-title", value: "Move cursor up", comment: "Title for move cursor up button")
            case .directionDown:
                return WMFLocalizedString("edit-direction-down-title", value: "Move cursor down", comment: "Title for move cursor down button")
            case .directionLeft:
                return WMFLocalizedString("edit-direction-left-title", value: "Move cursor left", comment: "Title for move cursor left button")
            case .directionRight:
                return WMFLocalizedString("edit-direction-right-title", value: "Move cursor right", comment: "Title for move cursor right button")
            case .findInPage:
                return CommonStrings.findInPage
            case .progress:
                return nil
            case .textSize:
                return nil
            case .textFormattingMenu:
                return WMFLocalizedString("edit-text-formatting-title", value: "Show text formatting menu", comment: "Title for text formatting menu")
            case .textStyleMenu:
                return WMFLocalizedString("edit-text-style-title", value: "Show text style menu", comment: "Title for text style menu")
            }
        }
        
        var accessibilityLabel: String? {
            guard isFormatting else {
                return title
            }
            guard let title = title else {
                return nil
            }
            let format = WMFLocalizedString("edit-remove-formatting-accessibility-label", value: "Add “%1$@” formatting", comment: "Adds formatting. Type of formatting replaces %1$@/")
            return String.localizedStringWithFormat(format, title)
        }
        
        var selectedAccessibilityLabel: String? {
            guard isFormatting else {
                return title
            }
            guard let title = title else {
                return nil
            }
            let format = WMFLocalizedString("edit-add-formatting-accessibility-label", value: "Remove “%1$@” formatting", comment: "Removes formatting. Type of formatting replaces %1$@/")
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
