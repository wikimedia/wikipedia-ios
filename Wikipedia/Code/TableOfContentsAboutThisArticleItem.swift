import Foundation

open class TableOfContentsAboutThisArticleItem : NSObject, TableOfContentsFooterItem {
    let url:URL
    init(url: URL) {
        self.url = url
        super.init()
    }
    
    open var titleText:String {
        return WMFLocalizedStringWithDefaultValue("article-about-title", self.url, Bundle.wmf_localization, "About this article", "The text that is displayed before the 'about' section at the bottom of an article")
    }
    
    open let itemType: TableOfContentsItemType = TableOfContentsItemType.primary
    open let footerViewIndex: WMFArticleFooterViewIndex = WMFArticleFooterViewIndex.aboutThisArticle

    open override func isEqual(_ object: Any?) -> Bool {
        if let item = object as? TableOfContentsAboutThisArticleItem {
            return self === item
                || (titleText == item.titleText
                    && itemType == item.itemType
                    && indentationLevel == item.indentationLevel)
        } else {
            return false
        }
    }
}

