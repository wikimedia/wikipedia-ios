import Foundation
import WMFUI
// MARK: - TOC Item Types

public enum TableOfContentsItemType {
    case primary
    case secondary

    var titleFontFamily: WMFFontFamily {
        get {
            switch (self) {
            case .primary:
                return .georgia
            case .secondary:
                return .system
            }
        }
    }
    
    var titleFontTextStyle: String {
        get {
            switch (self) {
            case .primary:
                return UIFontTextStyle.title3.rawValue
            case .secondary:
                return UIFontTextStyle.subheadline.rawValue
            }
        }
    }

    var titleColor: UIColor {
        get {
            switch (self) {
            case .primary:
                return UIColor.wmf_tableOfContentsSectionText()
            case .secondary:
                return UIColor.wmf_tableOfContentsSubsectionText()
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

