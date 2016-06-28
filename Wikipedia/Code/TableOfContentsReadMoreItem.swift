//
//  TableOfContentsReadMoreItem.swift
//  Wikipedia
//
//  Created by Brian Gerstle on 10/20/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

import Foundation

public protocol TableOfContentsFooterItem : TableOfContentsItem {
    var footerViewIndex: WMFArticleFooterViewIndex { get }
}

public class TableOfContentsReadMoreItem : NSObject, TableOfContentsFooterItem {
    let url:NSURL
    init(url: NSURL) {
        self.url = url
        super.init()
    }
    
    public var titleText:String {
        return localizedStringForURLWithKeyFallingBackOnEnglish(self.url, "article-read-more-title")
    }
    
    public let itemType: TableOfContentsItemType = TableOfContentsItemType.Primary
    public let footerViewIndex: WMFArticleFooterViewIndex = WMFArticleFooterViewIndex.ReadMore

    public override func isEqual(object: AnyObject?) -> Bool {
        if let item = object as? TableOfContentsReadMoreItem {
            return self === item
                || (titleText == item.titleText
                    && itemType == item.itemType
                    && borderType == item.borderType
                    && indentationLevel == item.indentationLevel)
        } else {
            return false
        }
    }
}

