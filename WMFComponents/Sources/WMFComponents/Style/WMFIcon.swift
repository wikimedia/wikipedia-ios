import Foundation
import UIKit

public enum WMFIcon {
    
    static let checkmark = UIImage(named: "checkmark", in: .module, with: nil)
    static let close = UIImage(named: "close", in: .module, with: nil)
    static let closeCircle = UIImage(named: "close-circle", in: .module, with: nil)
    static let exclamationPointCircle = UIImage(named: "exclamation-point-circle", in: .module, with: nil)
    static let find = UIImage(named: "find", in: .module, with: nil)
    static let findInPage = UIImage(named: "find-in-page", in: .module, with: nil)
    static let link = UIImage(named: "link", in: .module, with: nil)
    static let media = UIImage(named: "media", in: .module, with: nil)
    static let more = UIImage(named: "more", in: .module, with: nil)
    public static let pencil = UIImage(named: "pencil", in: .module, with: nil)
    static let plus = UIImage(named: "plus", in: .module, with: nil)
    static let plusCircle = UIImage(named: "plus-circle", in: .module, with: nil)
    static let replace = UIImage(named: "replace", in: .module, with: nil)
    static let thank = UIImage(named: "thank", in: .module, with: nil)
    static let userContributions = UIImage(named: "user-contributions", in: .module, with: nil)
    public static let externalLink = UIImage(named: "external-link", in: .module, with: nil)
    static let bot = UIImage(named: "bot", in: .module, with: nil)
    public static let checkPhoto = UIImage(named: "photo-badge-checkmark", in: .module, with: nil) // Use SFSymbol once target is iOS17+
    public static let addPhoto = UIImage(named: "photo-badge-plus", in: .module, with: nil) // Use SFSymbol once target is iOS17+
    public static let error = UIImage(named: "error", in: .module, with: nil)

    // Project icons
    public static let commons = UIImage(named: "project-icons/commons", in: .module, with: nil)
    static let wikidata = UIImage(named: "project-icons/wikidata", in: .module, with: nil)

    // License

    static let ccLicense = UIImage(named: "project-icons/license-cc", in: .module, with: nil)

}

public enum WMFSFSymbolIcon {
    
    case checkmark
    case checkmarkSquareFill
    case square
    case star
    case person
	case personFilled
    case starLeadingHalfFilled
    case heart
    case heartFilled
	case conversation
    case quoteOpening
    case link
    case curlybraces
    case photo
    case addPhoto
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
    case exclamationMarkCircleFill
    case textFormatSuperscript
    case textFormatSubscript
    case underline
    case strikethrough
    case multiplyCircleFill
    case chevronRightCircle
    case close
    case closeCircleFill
    case ellipsis
    case pencil
    case plusCircleFill
    case undo
    case redo
    case textFormatSize
    case textFormat
	case plusForwardSlashMinus
	case photoOnRectangleAngled
    case xMark
    case textBelowPhoto
    case infoCircle
    case squareTextSquare
    case eye
    case ellipsisBubble
    case flag
    case lightbulbMin
    case ellipsisCircle
    case personCropCircleBadge
    case personCropCircle
    case bookmark
    case bookmarkFill
    case book
    case map
    case squareAndArrowUp
    case circleFill
    case bellFill
    case chatBubbleFilled
    case textBadgeStar
    case leave
    case gear
    case calendar
    case share
    case infoCircleFill

    public static func `for`(symbol: WMFSFSymbolIcon, font: WMFFont = .subheadline, compatibleWith traitCollection: UITraitCollection = WMFAppEnvironment.current.traitCollection, paletteColors: [UIColor]? = nil) -> UIImage? {
        let font = WMFFont.for(font, compatibleWith: traitCollection)
        let configuration = UIImage.SymbolConfiguration(font: font)

        var image: UIImage?
        switch symbol {
        case .checkmark:
            image = UIImage(systemName: "checkmark", withConfiguration: configuration)
        case .checkmarkSquareFill:
            image = UIImage(systemName: "checkmark.square.fill", withConfiguration: configuration)
        case .square:
            image = UIImage(systemName: "square", withConfiguration: configuration)
        case .star:
            image = UIImage(systemName: "star", withConfiguration: configuration)
        case .person:
            image = UIImage(systemName: "person", withConfiguration: configuration)
        case .personFilled:
            image = UIImage(systemName: "person.fill", withConfiguration: configuration)
        case .starLeadingHalfFilled:
            image = UIImage(systemName: "star.leadinghalf.filled", withConfiguration: configuration)
        case .heart:
            image = UIImage(systemName: "heart", withConfiguration: configuration)
        case .conversation:
            image = UIImage(systemName: "bubble.left.and.bubble.right", withConfiguration: configuration)
        case .quoteOpening:
            image = UIImage(systemName: "quote.opening", withConfiguration: configuration)
        case .link:
            image = UIImage(systemName: "link", withConfiguration: configuration)
        case .curlybraces:
            image = UIImage(systemName: "curlybraces", withConfiguration: configuration)
        case .photo:
            image = UIImage(systemName: "photo", withConfiguration: configuration)
        case .addPhoto:
            image = UIImage(systemName: "photo.badge.plus", withConfiguration: configuration)
        case .docTextMagnifyingGlass:
            image = UIImage(systemName: "doc.text.magnifyingglass", withConfiguration: configuration)
        case .magnifyingGlass:
            image = UIImage(systemName: "magnifyingglass", withConfiguration: configuration)
        case .listBullet:
            image = UIImage(systemName: "list.bullet", withConfiguration: configuration)
        case .listNumber:
            image = UIImage(systemName: "list.number", withConfiguration: configuration)
        case .increaseIndent:
            image = UIImage(systemName: "increase.indent", withConfiguration: configuration)?.imageFlippedForRightToLeftLayoutDirection()
        case .decreaseIndent:
            image = UIImage(systemName: "decrease.indent", withConfiguration: configuration)?.imageFlippedForRightToLeftLayoutDirection()
        case .chevronUp:
            image = UIImage(systemName: "chevron.up", withConfiguration: configuration)
        case .chevronDown:
            image = UIImage(systemName: "chevron.down", withConfiguration: configuration)
        case .chevronBackward:
            image = UIImage(systemName: "chevron.backward", withConfiguration: configuration)
        case .chevronForward:
            image = UIImage(systemName: "chevron.forward", withConfiguration: configuration)
        case .bold:
            image = UIImage(systemName: "bold", withConfiguration: configuration)
        case .italic:
            image = UIImage(systemName: "italic", withConfiguration: configuration)
        case .exclamationMarkCircle:
            image = UIImage(systemName: "exclamationmark.circle", withConfiguration: configuration)
        case .exclamationMarkCircleFill:
            image = UIImage(systemName: "exclamationmark.circle.fill", withConfiguration: configuration)
        case .textFormatSuperscript:
            image = UIImage(systemName: "textformat.superscript", withConfiguration: configuration)
        case .textFormatSubscript:
            image = UIImage(systemName: "textformat.subscript", withConfiguration: configuration)
        case .underline:
            image = UIImage(systemName: "underline", withConfiguration: configuration)
        case .strikethrough:
            image = UIImage(systemName: "strikethrough", withConfiguration: configuration)
        case .multiplyCircleFill:
            image = UIImage(systemName: "multiply.circle.fill", withConfiguration: configuration)
        case .chevronRightCircle:
            image = UIImage(systemName: "chevron.right.circle.fill", withConfiguration: configuration)?.imageFlippedForRightToLeftLayoutDirection()
        case .close:
            image = UIImage(systemName: "multiply", withConfiguration: configuration)
        case .closeCircleFill:
            image = UIImage(systemName: "xmark.circle.fill", withConfiguration: configuration)
        case .ellipsis:
            image = UIImage(systemName: "ellipsis", withConfiguration: configuration)
        case .pencil:
            image = UIImage(systemName: "pencil", withConfiguration: configuration)
        case .plusCircleFill:
            image = UIImage(systemName: "plus.circle.fill", withConfiguration: configuration)
        case .undo:
            image = UIImage(systemName: "arrow.uturn.backward", withConfiguration: configuration)
        case .redo:
            image = UIImage(systemName: "arrow.uturn.forward", withConfiguration: configuration)
        case .textFormatSize:
            image = UIImage(systemName: "textformat.size", withConfiguration: configuration)
        case .textFormat:
            image = UIImage(systemName: "textformat", withConfiguration: configuration)
        case .plusForwardSlashMinus:
            image = UIImage(systemName: "plus.forwardslash.minus", withConfiguration: configuration)
        case .photoOnRectangleAngled:
            image = UIImage(systemName: "photo.on.rectangle.angled", withConfiguration: configuration)
        case .xMark:
            image = UIImage(systemName: "xmark", withConfiguration: configuration)
        case .textBelowPhoto:
            image = UIImage(systemName: "text.below.photo", withConfiguration: configuration)?.imageFlippedForRightToLeftLayoutDirection()
        case .infoCircle:
            image = UIImage(systemName: "info.circle", withConfiguration: configuration)
        case .squareTextSquare:
            image = UIImage(systemName: "square.text.square", withConfiguration: configuration)
        case .eye:
            image = UIImage(systemName: "eye", withConfiguration: configuration)
        case.ellipsisBubble:
            image = UIImage(systemName: "ellipsis.bubble", withConfiguration: configuration)
        case .flag:
            image = UIImage(systemName: "flag", withConfiguration: configuration)
        case .lightbulbMin:
            image = UIImage(systemName: "lightbulb.min", withConfiguration: configuration)
        case .ellipsisCircle:
            image = UIImage(systemName: "ellipsis.circle", withConfiguration: configuration)
        case .personCropCircleBadge:
            image = UIImage(systemName: "person.crop.circle.badge", withConfiguration: configuration)
        case .personCropCircle:
            image = UIImage(systemName: "person.crop.circle", withConfiguration: configuration)
        case .bookmark:
            image = UIImage(systemName: "bookmark", withConfiguration: configuration)
        case .bookmarkFill:
            image = UIImage(systemName: "bookmark.fill", withConfiguration: configuration)
        case .book:
            image = UIImage(systemName: "book", withConfiguration: configuration)
        case .map:
            image = UIImage(systemName: "map", withConfiguration: configuration)
        case .squareAndArrowUp:
            image = UIImage(systemName: "square.and.arrow.up", withConfiguration: configuration)
        case .circleFill:
            image = UIImage(systemName: "circle.fill", withConfiguration: configuration)
        case .bellFill:
            image = UIImage(systemName: "bell.fill", withConfiguration: configuration)
        case .chatBubbleFilled:
            image = UIImage(systemName: "bubble.fill", withConfiguration: configuration)
        case .textBadgeStar:
            image = UIImage(systemName: "text.badge.star", withConfiguration: configuration)
        case .leave:
            image = UIImage(systemName: "rectangle.portrait.and.arrow.right", withConfiguration: configuration)
        case .gear:
            image = UIImage(systemName: "gear", withConfiguration: configuration)
        case .heartFilled:
            image = UIImage(systemName: "heart.fill", withConfiguration: configuration)
        case .calendar:
            image = UIImage(systemName: "calendar", withConfiguration: configuration)
        case .share:
            image = UIImage(systemName: "square.and.arrow.up", withConfiguration: configuration)
        case .infoCircleFill:
            image = UIImage(systemName: "info.circle.fill", withConfiguration: configuration)
        }
        
        image = image?.withRenderingMode(.alwaysTemplate)
        if let paletteColors {
            let paletteSymbolConfiguration = UIImage.SymbolConfiguration(paletteColors: paletteColors)
            image = image?.applyingSymbolConfiguration(paletteSymbolConfiguration)
        }
        
        return image
    }

}
