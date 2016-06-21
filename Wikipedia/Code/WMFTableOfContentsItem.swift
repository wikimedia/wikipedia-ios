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
    case DefaultTopOnly
    case None
}

// MARK: - TOC Item

public protocol TableOfContentsItem : NSObjectProtocol {
    var titleText: String { get }
    var itemType: TableOfContentsItemType { get }
    var borderType: TableOfContentsBorderType { get }
    var indentationLevel: UInt { get }

    func shouldBeHighlightedAlongWithItem(item: TableOfContentsItem) -> Bool
}

// MARK: - TOC Item Defaults

extension TableOfContentsItem {
    public func shouldBeHighlightedAlongWithItem(item: TableOfContentsItem) -> Bool {
        return false
    }

    public var borderType: TableOfContentsBorderType { get { return TableOfContentsBorderType.Default } }

    public var indentationLevel: UInt { get { return 0 } }
}

