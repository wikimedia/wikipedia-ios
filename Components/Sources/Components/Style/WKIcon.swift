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
   
    // Editor-specific icons
    static let bold = UIImage(named: "editor/bold", in: .module, with: nil)
    static let citation = UIImage(named: "editor/citation", in: .module, with: nil)
    static let clear = UIImage(named: "editor/clear", in: .module, with: nil)
    static let formatText = UIImage(named: "editor/format-text", in: .module, with: nil)
    static let formatHeading = UIImage(named: "editor/format-heading", in: .module, with: nil)
    static let indentDecrease = UIImage(named: "editor/indent-decrease", in: .module, with: nil)
    static let indentIncrease = UIImage(named: "editor/indent-increase", in: .module, with: nil)
    static let italics = UIImage(named: "editor/italics", in: .module, with: nil)
    static let listOrdered = UIImage(named: "editor/list-ordered", in: .module, with: nil)
    static let listUnordered = UIImage(named: "editor/list-unordered", in: .module, with: nil)
    static let strikethrough = UIImage(named: "editor/strikethrough", in: .module, with: nil)
    static let `subscript` = UIImage(named: "editor/subscript", in: .module, with: nil)
    static let superscript = UIImage(named: "editor/superscript", in: .module, with: nil)
    static let template = UIImage(named: "editor/template", in: .module, with: nil)
    static let underline = UIImage(named: "editor/underline", in: .module, with: nil)
    
    // Project icons
    static let commons = UIImage(named: "project-icons/commons", in: .module, with: nil)
    static let wikidata = UIImage(named: "project-icons/wikidata", in: .module, with: nil)
}

public enum WKSFSymbolIcon {
    case checkmark
    case star
    case person
    case starLeadingHalfFilled
    case heart
    
    public static func `for`(symbol: WKSFSymbolIcon, font: WKFont, compatibleWith traitCollection: UITraitCollection = WKAppEnvironment.current.traitCollection) -> UIImage? {
        let font = WKFont.for(font)
        let configuration = UIImage.SymbolConfiguration(font: font)
        switch symbol {
        case .checkmark:
            return UIImage(systemName: "checkmark", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .star:
            return UIImage(systemName: "star", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .person:
            return UIImage(systemName: "person", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .starLeadingHalfFilled:
            return UIImage(systemName: "star.leadinghalf.filled", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        case .heart:
            return UIImage(systemName: "heart", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
        }
    }
}
