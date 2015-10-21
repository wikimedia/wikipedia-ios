//
//  TableOfContentsReadMoreItem.swift
//  Wikipedia
//
//  Created by Brian Gerstle on 10/20/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

import Foundation

public class TableOfContentsReadMoreItem : NSObject, TableOfContentsItem {
    public let titleText: String = localizedStringForKeyFallingBackOnEnglish("article-read-more-title")

    public let itemType: TableOfContentsItemType = TableOfContentsItemType.Primary
}
