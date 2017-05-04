import Foundation

public protocol TableOfContentsFooterItem : TableOfContentsItem {
    var footerViewIndex: WMFArticleFooterViewIndex { get }
}

open class TableOfContentsReadMoreItem : NSObject, TableOfContentsFooterItem {
    let url:URL
    init(url: URL) {
        self.url = url
        super.init()
    }
    
    open var titleText:String {
        return WMFLocalizedStringWithDefaultValue("article-read-more-title", self.url, Bundle.wmf_localization, "Read more", "The text that is displayed before the read more section at the bottom of an article\n{{Identical|Read more}}")
    }
    
    open let itemType: TableOfContentsItemType = TableOfContentsItemType.primary
    open let footerViewIndex: WMFArticleFooterViewIndex = WMFArticleFooterViewIndex.readMore

    open override func isEqual(_ object: Any?) -> Bool {
        if let item = object as? TableOfContentsReadMoreItem {
            return self === item
                || (titleText == item.titleText
                    && itemType == item.itemType
                    && indentationLevel == item.indentationLevel)
        } else {
            return false
        }
    }
}

