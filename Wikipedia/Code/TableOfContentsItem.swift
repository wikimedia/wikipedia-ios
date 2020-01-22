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

public struct TableOfContentsItem: Equatable {
    let id: Int
    let titleHTML: String
    let anchor: String
    let rootItemId: Int?
    var itemType: TableOfContentsItemType {
        return indentationLevel < 1 ? .primary : .secondary
    }
    let indentationLevel: Int

    func shouldBeHighlightedAlongWithItem(_ item: TableOfContentsItem) -> Bool {
        return item.id == rootItemId || item.rootItemId == id
    }

    public static func == (lhs: TableOfContentsItem, rhs: TableOfContentsItem) -> Bool {
        return lhs.id == rhs.id
    }
}

