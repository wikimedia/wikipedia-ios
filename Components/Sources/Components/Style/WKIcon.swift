import Foundation
import UIKit

public enum WKIcon {
    
    static let checkmark = UIImage(named: "checkmark", in: .module, with: nil)
    static let chevronDown = UIImage(named: "chevron-down", in: .module, with: nil)
    static let chevronLeft = UIImage(named: "chevron-left", in: .module, with: nil)
    static let chevronRight = UIImage(named: "chevron-right", in: .module, with: nil)
    static let chevronRightCircle = UIImage(named: "chevron-right-circle", in: .module, with: nil)
    static let chevronUp = UIImage(named: "chevron-up", in: .module, with: nil)
    static let close = UIImage(named: "close", in: .module, with: nil)
    static let closeCircle = UIImage(named: "close-circle", in: .module, with: nil)
    static let exclamationPointCircle = UIImage(named: "exclamation-point-circle", in: .module, with: nil)
    static let find = UIImage(named: "find", in: .module, with: nil)
    static let findInPage = UIImage(named: "find-in-page", in: .module, with: nil)
    static let link = UIImage(named: "link", in: .module, with: nil)
    static let media = UIImage(named: "media", in: .module, with: nil)
    static let more = UIImage(named: "more", in: .module, with: nil)
    static let pencil = UIImage(named: "pencil", in: .module, with: nil)
    static let plus = UIImage(named: "plus", in: .module, with: nil)
    static let plusCircle = UIImage(named: "plus-circle", in: .module, with: nil)
    static let replace = UIImage(named: "replace", in: .module, with: nil)
    static let thank = UIImage(named: "thank", in: .module, with: nil)
    static let userContributions = UIImage(named: "user-contributions", in: .module, with: nil)

    // Editor-specific icons
    static let clear = UIImage(named: "editor/clear", in: .module, with: nil) //
    static let formatText = UIImage(named: "editor/format-text", in: .module, with: nil)//
    static let formatHeading = UIImage(named: "editor/format-heading", in: .module, with: nil)//

    // Project icons
    static let commons = UIImage(named: "project-icons/commons", in: .module, with: nil)
    static let wikidata = UIImage(named: "project-icons/wikidata", in: .module, with: nil)
}

public enum WKSFSymbolIcon {
    case checkmark
    case checkmarkSquareFill
    case square
    case star
    case person
	case personFilled
    case starLeadingHalfFilled
    case heart
	case conversation
    case quoteOpening
    case link
    case curlybraces
    case photo
    case docTextMagnifyingGlass
    case magnifyingGlass
    case listBullet
    case listNumber
    case increaseIndent
    case decreaseIndent
    case chevronUp
    case chevronDown
    case chevronBackward
    case chevronForward
    case bold
    case italic
    case exclamationMarkCircle
    case textFormatSuperscript
    case textFormatSubscript
    case underline
    case strikethrough
    case multiplyCircleFill
    case chevronRightCircle
    case close
    case ellipsis
    case pencil
    case plusCircleFill

    public static func `for`(symbol: WKSFSymbolIcon, font: WKFont = .body, compatibleWith traitCollection: UITraitCollection = WKAppEnvironment.current.traitCollection) -> UIImage? {
        let font = WKFont.for(font)
        let configuration = UIImage.SymbolConfiguration(font: font)

        switch symbol {
        case .checkmark:
            return UIImage(systemName: "checkmark", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .checkmarkSquareFill:
            return UIImage(systemName: "checkmark.square.fill", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .square:
            return UIImage(systemName: "square", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .star:
            return UIImage(systemName: "star", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .person:
            return UIImage(systemName: "person", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .personFilled:
            return UIImage(systemName: "person.fill", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .starLeadingHalfFilled:
            return UIImage(systemName: "star.leadinghalf.filled", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .heart:
            return UIImage(systemName: "heart", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .conversation:
            return UIImage(systemName: "bubble.left.and.bubble.right", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .quoteOpening:
            return UIImage(systemName: "quote.opening", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .link:
            return UIImage(systemName: "link", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .curlybraces:
            return UIImage(systemName: "curlybraces", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .photo:
            return UIImage(systemName: "photo", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .docTextMagnifyingGlass:
            return UIImage(systemName: "doc.text.magnifyingglass", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .magnifyingGlass:
            return UIImage(systemName: "magnifyingglass", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .listBullet:
            return UIImage(systemName: "list.bullet", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .listNumber:
            return UIImage(systemName: "list.number", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .increaseIndent:
            return UIImage(systemName: "increase.indent", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .decreaseIndent:
            return UIImage(systemName: "decrease.indent", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .chevronUp:
            return UIImage(systemName: "chevron.up", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .chevronDown:
            return UIImage(systemName: "chevron.down", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .chevronBackward:
            return UIImage(systemName: "chevron.backward", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .chevronForward:
            return UIImage(systemName: "chevron.forward", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .bold:
            return UIImage(systemName: "bold", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .italic:
            return UIImage(systemName: "italic", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .exclamationMarkCircle:
            return UIImage(systemName: "exclamationmark.circle", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .textFormatSuperscript:
            return UIImage(systemName: "textformat.superscript", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .textFormatSubscript:
            return UIImage(systemName: "textformat.subscript", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .underline:
            return UIImage(systemName: "underline", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .strikethrough:
            return UIImage(systemName: "strikethrough", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .multiplyCircleFill:
            return UIImage(systemName: "multiply.circle.fill", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .chevronRightCircle:
            return UIImage(systemName: "chevron.right.circle.fill", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .close:
            return UIImage(systemName: "multiply", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .ellipsis:
            return UIImage(systemName: "ellipsis", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .pencil:
            return UIImage(systemName: "pencil", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .plusCircleFill:
            return UIImage(systemName: "plus.circle.fill", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)

        }
    }

}
