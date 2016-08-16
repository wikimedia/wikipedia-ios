//
//  MWKSection+TOCItem.swift
//  Wikipedia
//
//  Created by Brian Gerstle on 10/20/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

import Foundation

extension MWKSection : TableOfContentsItem {
    public var titleText: String {
        get {
            if(isLeadSection()) {
                return url.wmf_title
            } else {
                return line?.wmf_stringByRemovingHTML() ?? ""
            }
        }
    }

    public var itemType: TableOfContentsItemType {
        get {
            return level?.intValue <= 2 ? TableOfContentsItemType.Primary : TableOfContentsItemType.Secondary
        }
    }

    public var borderType: TableOfContentsBorderType {
        get {
            if isLeadSection() {
                return .None
            } else if let level = level?.unsignedIntegerValue , level <= 2 {
                return .TopOnly
            } else {
                return .None
            }
        }
    }

    public var indentationLevel: Int {
        get {
            if let level = toclevel?.integerValue {
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
