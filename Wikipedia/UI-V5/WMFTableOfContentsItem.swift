//
//  WMFTableOfContentsItem.swift
//  Wikipedia
//
//  Created by Brian Gerstle on 10/20/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

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
    case Default
    case FullWidth
    case None
}

// MARK: - TOC Item

public protocol TableOfContentsItem {
    var titleText: String { get }
    var itemType: TableOfContentsItemType { get }
    var borderType: TableOfContentsBorderType { get }
    var indentationLevel: UInt { get }

    func shouldBeHighlightedAlongWithItem(item: TableOfContentsItem) -> Bool
}

extension TableOfContentsItem {
    func shouldBeHighlightedAlongWithItem(item: TableOfContentsItem) -> Bool {
        return false
    }

    var borderType: TableOfContentsBorderType { get { return TableOfContentsBorderType.Default } }
}
