import Foundation

// MARK: - TOC Item Types

public enum TableOfContentsItemType {
    case primary
    case secondary

    var titleFont: UIFont {
        get {
            switch (self) {
            case .primary:
                return UIFont.wmf_tableOfContentsSectionFont()
            case .secondary:
                return UIFont.wmf_tableOfContentsSubsectionFont()
            }
        }
    }

    var titleColor: UIColor {
        get {
            switch (self) {
            case .primary:
                return UIColor.wmf_tableOfContentsSectionTextColor()
            case .secondary:
                return UIColor.wmf_tableOfContentsSubsectionTextColor()
            }
        }
    }
}

public enum TableOfContentsBorderType {
    case topOnly
    case none
}

// MARK: - TOC Item

public protocol TableOfContentsItem : NSObjectProtocol {
    var titleText: String { get }
    var itemType: TableOfContentsItemType { get }
    var indentationLevel: Int { get }

    func shouldBeHighlightedAlongWithItem(_ item: TableOfContentsItem) -> Bool
}

// MARK: - TOC Item Defaults

extension TableOfContentsItem {
    public func shouldBeHighlightedAlongWithItem(_ item: TableOfContentsItem) -> Bool {
        return item === self
    }
    
    public var indentationLevel: Int { get { return 0 } }
}

