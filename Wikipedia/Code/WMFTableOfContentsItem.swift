import Foundation
import WMFUI
// MARK: - TOC Item Types

public enum TableOfContentsItemType {
    case Primary
    case Secondary

    var titleFontFamily: WMFFontFamily {
        get {
            switch (self) {
            case .Primary:
                return .Georgia
            case .Secondary:
                return .System
            }
        }
    }
    
    var titleFontTextStyle: String {
        get {
            switch (self) {
            case .Primary:
                return UIFontTextStyleTitle3
            case .Secondary:
                return UIFontTextStyleSubheadline
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
    var indentationLevel: Int { get }

    func shouldBeHighlightedAlongWithItem(item: TableOfContentsItem) -> Bool
}

// MARK: - TOC Item Defaults

extension TableOfContentsItem {
    public func shouldBeHighlightedAlongWithItem(item: TableOfContentsItem) -> Bool {
        return item === self
    }
    
    public var indentationLevel: Int { get { return 0 } }
}

