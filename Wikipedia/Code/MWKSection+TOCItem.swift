import Foundation
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}


extension MWKSection : TableOfContentsItem {
    public var titleText: String {
        get {
            if(isLead()) {
                return url.wmf_title ?? ""
            } else {
                return line?.wmf_stringByRemovingHTML() ?? ""
            }
        }
    }

    public var itemType: TableOfContentsItemType {
        get {
            return level?.int32Value <= 2 ? TableOfContentsItemType.primary : TableOfContentsItemType.secondary
        }
    }

    public var borderType: TableOfContentsBorderType {
        get {
            if isLead() {
                return .none
            } else if let level = level?.uintValue, level <= 2 {
                return .topOnly
            } else {
                return .none
            }
        }
    }

    public var indentationLevel: Int {
        get {
            if let level = toclevel?.intValue {
                return max(level - 1, 0)
            } else {
                return 0
            }
        }
    }

    public func shouldBeHighlightedAlongWithItem(_ item: TableOfContentsItem) -> Bool {
        guard let sectionItem = item as? MWKSection else {
            return false
        }
        return sectionItem.sectionHasSameRootSection(self)
    }
}
