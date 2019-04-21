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
        case clearFormatting
        case media
        
        var accessibilityLabel: String? {
            switch self {
            case .li(let ordered):
                return ordered ? WMFLocalizedString("edit-ordered-list-accessibility-label", value: "Make current line ordered list", comment: "Accessibility label for ordered list button") : WMFLocalizedString("edit-unordered-list-accessibility-label", value: "Make current line unordered list", comment: "Accessibility label for unordered list button")
            case .indent:
                return WMFLocalizedString("edit-indent-accessibility-label", value: "Indent current line", comment: "Accessibility label for indent button")
            case .heading:
                return nil
            case .signature:
                return WMFLocalizedString("edit-signature-accessibility-label", value: "Add signature syntax", comment: "Acessibility label for add signature syntax button")
            case .link:
                return WMFLocalizedString("edit-link-accessibility-label", value: "Add link syntax", comment: "Accessibility label for the button that adds link syntax to the current selection")
            case .bold:
                return WMFLocalizedString("edit-bold-accessibility-label", value: "Add bold formatting", comment: "Accessibility label for the button that adds bold formatting to the current selection")
            case .italic:
                return WMFLocalizedString("edit-italic-accessibility-label", value: "Add italic formatting", comment: "Accessibility label for italic button")
            case .reference:
                return WMFLocalizedString("edit-reference-accessibility-label", value: "Add reference syntax", comment: "Accessibility label for add reference syntax button")
            case .template:
                return WMFLocalizedString("edit-template-accessibility-label", value: "Add template syntax", comment: "Accessibility label for add template syntax button")
            case .undo:
                return CommonStrings.undo
            case .redo:
                return CommonStrings.redo
            case .comment:
                return WMFLocalizedString("edit-comment-accessibility-label", value: "Add comment syntax", comment: "Accessibility label for add comment syntax button")
            case .superscript:
                return WMFLocalizedString("edit-superscript-accessibility-label", value: "Add superscript formatting", comment: "Accessibility label for add superscript formatting button")
            case .subscript:
                return WMFLocalizedString("edit-subscript-accessibility-label", value: "Add subscript formatting", comment: "Accessibility label for add subscript formatting button")
            case .underline:
                return WMFLocalizedString("edit-underline-accessibility-label", value: "Add underline", comment: "Accessibility label for add underline button")
            case .strikethrough:
                return WMFLocalizedString("edit-strikethrough-accessibility-label", value: "Add strikethrough", comment: "Accessibility label for add strikethrough button")
            case .decreaseIndentDepth:
                return WMFLocalizedString("edit-decrease-indent-depth-accessibility-label", value: "Decrease indent depth", comment: "Accessibility label for decrease indent depth button")
            case .increaseIndentDepth:
                return WMFLocalizedString("edit-increase-indent-depth-accessibility-label", value: "Increase indent depth", comment: "Accessibility label for increase indent depth button")
            case .directionUp:
                return WMFLocalizedString("edit-direction-up-accessibility-label", value: "Move cursor up", comment: "Accessibility label for move cursor up button")
            case .directionDown:
                return WMFLocalizedString("edit-direction-down-accessibility-label", value: "Move cursor down", comment: "Accessibility label for move cursor down button")
            case .directionLeft:
                return WMFLocalizedString("edit-direction-left-accessibility-label", value: "Move cursor left", comment: "Accessibility label for move cursor left button")
            case .directionRight:
                return WMFLocalizedString("edit-direction-right-accessibility-label", value: "Move cursor right", comment: "Accessibility label for move cursor right button")
            case .findInPage:
                return CommonStrings.findInPage
            case .progress:
                return nil
            case .textSize:
                return nil
            case .textFormattingMenu:
                return WMFLocalizedString("edit-text-formatting-accessibility-label", value: "Show text formatting menu", comment: "Accessibility label for text formatting menu")
            case .textStyleMenu:
                return WMFLocalizedString("edit-text-style-accessibility-label", value: "Show text style menu", comment: "Accessibility label for text style menu")
            case .clearFormatting:
                return nil
            case .media:
                return CommonStrings.insertMediaTitle
            }
        }
        
        var selectedAccessibilityLabel: String? {
            switch self {
            case .li(let ordered):
                return ordered ? WMFLocalizedString("edit-ordered-list-remove-accessibility-label", value: "Remove ordered list from current line", comment: "Accessibility label for remove ordered list button") : WMFLocalizedString("edit-unordered-list-remove-accessibility-label", value: "Remove unordered list from current line", comment: "Accessibility label for remove unordered list button")
            case .signature:
                return WMFLocalizedString("edit-signature-remove-accessibility-label", value: "Remove signature syntax", comment: "Acessibility label for remove signature syntax button")
            case .link:
                return WMFLocalizedString("edit-link-remove-accessibility-label", value: "Remove link syntax", comment: "Accessibility label for the button that removes link syntax to the current selection")
            case .bold:
                return WMFLocalizedString("edit-bold-remove-accessibility-label", value: "Remove bold formatting", comment: "Accessibility label for the button that removes bold formatting to the current selection")
            case .italic:
                return WMFLocalizedString("edit-italic-remove-accessibility-label", value: "Remove italic formatting", comment: "Accessibility label for italic button")
            case .reference:
                return WMFLocalizedString("edit-reference-remove-accessibility-label", value: "Remove reference syntax", comment: "Accessibility label for remove reference syntax button")
            case .template:
                return WMFLocalizedString("edit-template-remove-accessibility-label", value: "Remove template syntax", comment: "Accessibility label for remove template syntax button")
            case .comment:
                return WMFLocalizedString("edit-comment-remove-accessibility-label", value: "Remove comment syntax", comment: "Accessibility label for remove comment syntax button")
            case .superscript:
                return WMFLocalizedString("edit-superscript-remove-accessibility-label", value: "Remove superscript formatting", comment: "Accessibility label for remove superscript formatting button")
            case .subscript:
                return WMFLocalizedString("edit-subscript-remove-accessibility-label", value: "Remove subscript formatting", comment: "Accessibility label for remove subscript formatting button")
            case .underline:
                return WMFLocalizedString("edit-underline-remove-accessibility-label", value: "Remove underline", comment: "Accessibility label for remove underline button")
            case .strikethrough:
                return WMFLocalizedString("edit-strikethrough-remove-accessibility-label", value: "Remove strikethrough", comment: "Accessibility label for remove strikethrough button")
            case .clearFormatting:
                return WMFLocalizedString("edit-clear-formatting-accessibility-label", value: "Remove formatting", comment: "Accessibility label for the button that removes formatting from the current selection")
            default:
                return accessibilityLabel
            }
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
            case 30:
                self = .clearFormatting
            case 31:
                self = .media
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
                case "clearFormatting":
                    self = .clearFormatting
                case "media":
                    self = .media
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
