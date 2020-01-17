import Foundation

public enum ArticleFooterViewIndex: Int {
    case aboutThisArticle = 0
    case readMore = 1
}

public protocol TableOfContentsFooterItem : TableOfContentsItem {
    var footerViewIndex: ArticleFooterViewIndex { get }
}

open class TableOfContentsReadMoreItem : NSObject, TableOfContentsFooterItem {
    let url:URL
    init(url: URL) {
        self.url = url
        super.init()
    }
    
    open var titleText:String {
        return WMFLocalizedString("article-read-more-title", language: self.url.wmf_language, value: "Read more", comment: "The text that is displayed before the read more section at the bottom of an article {{Identical|Read more}}")
    }
    
    public let itemType: TableOfContentsItemType = TableOfContentsItemType.primary
    public let footerViewIndex: ArticleFooterViewIndex = ArticleFooterViewIndex.readMore

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

