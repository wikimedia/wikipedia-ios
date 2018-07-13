import Foundation
import WMF
// MARK: - TOC Item Types

public enum TableOfContentsItemType {
    case primary
    case secondary
    
    var titleTextStyle: DynamicTextStyle {
        get {
            switch (self) {
            case .primary:
                return .georgiaTitle3
            case .secondary:
                return .subheadline
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

