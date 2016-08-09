import Foundation

// MARK: - TOC Item Types

public enum TableOfContentsItemType {
    case Primary
    case Secondary

    var titleFont: UIFont {
        get {
            switch (self) {
            case .Primary:
                return UIFont.wmf_tableOfContentsSectionFont()
            case .Secondary:
                return UIFont.wmf_tableOfContentsSubsectionFont()
            }
        }
    }

    var titleColor: UIColor {
        get {
            switch (self) {
            case .Primary:
                return UIColor.wmf_tableOfContentsSectionTextColor()
            case .Secondary:
                return UIColor.wmf_tableOfContentsSubsectionTextColor()
            }
        }
    }
}

public enum TableOfContentsBorderType {
    case TopOnly
    case None
}

// MARK: - TOC Item

public protocol TableOfContentsItem : NSObjectProtocol {
    var titleText: String { get }
    var itemType: TableOfContentsItemType { get }
    var borderType: TableOfContentsBorderType { get }
    var indentationLevel: Int { get }

    func shouldBeHighlightedAlongWithItem(item: TableOfContentsItem) -> Bool
}

// MARK: - TOC Item Defaults

extension TableOfContentsItem {
    public func shouldBeHighlightedAlongWithItem(item: TableOfContentsItem) -> Bool {
        return false
    }

    public var borderType: TableOfContentsBorderType { get { return TableOfContentsBorderType.TopOnly } }

    public var indentationLevel: Int { get { return 0 } }
}

