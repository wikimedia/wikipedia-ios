
import UIKit
import MobileCoreServices
import CoreSpotlight

@available(iOS 9.0, *)

public extension CSSearchableItemAttributeSet {
    
    public class func attributes(article: MWKArticle) -> CSSearchableItemAttributeSet {
        
        let searchableItem = CSSearchableItemAttributeSet(itemContentType: kUTTypeInternetLocation as String)

        searchableItem.keywords = ["Wikipedia","Wikimedia","Wiki"] + article.url.wmf_title.componentsSeparatedByString(" ")
        
        searchableItem.title = article.url.wmf_title
        searchableItem.subject = article.entityDescription
        searchableItem.contentDescription = article.summary()
        searchableItem.displayName = article.url.wmf_title
        searchableItem.identifier = NSURL.wmf_desktopURLForURL(article.url).absoluteString
        searchableItem.relatedUniqueIdentifier = NSURL.wmf_desktopURLForURL(article.url).absoluteString

        if (article.imageURL != nil) {
            if let url = NSURL(string: article.imageURL) {
                searchableItem.thumbnailData = WMFImageController.sharedInstance().diskDataForImageWithURL(url);
            }
        }
        return searchableItem
    }
}

@available(iOS 9.0, *)

public class WMFSavedPageSpotlightManager: NSObject {
    
    let dataStore: MWKDataStore
    var savedPageList: MWKSavedPageList {
        return dataStore.userDataStore.savedPageList
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    public required init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(WMFSavedPageSpotlightManager.didUpdateItem(_:)), name: MWKItemUpdatedNotification, object: nil)
    }
    
    public func reindexSavedPages() {
        self.savedPageList.enumerateItemsWithBlock { (item, stop) in
            self.addToIndex(item.url)
        }
    }
    
    func didUpdateItem(notification: NSNotification){
        if let urlString = notification.object as? String {
            if let url = NSURL.init(string: urlString) {
                if self.savedPageList.isSaved(url){
                    addToIndex(url)
                }else{
                    removeFromIndex(url)
                }
            }
        }
    }
    
    func addToIndex(url: NSURL) {
        if let article = dataStore.existingArticleWithURL(url) {
            
            let searchableItemAttributes = CSSearchableItemAttributeSet.attributes(article)
            searchableItemAttributes.keywords?.append("Saved")
            
            let item = CSSearchableItem(uniqueIdentifier: NSURL.wmf_desktopURLForURL(url).absoluteString, domainIdentifier: "org.wikimedia.wikipedia", attributeSet: searchableItemAttributes)
            item.expirationDate = NSDate.distantFuture()
            
            CSSearchableIndex.defaultSearchableIndex().indexSearchableItems([item]) { (error: NSError?) -> Void in
                if let error = error {
                    DDLogError("Indexing error: \(error.localizedDescription)")
                } else {
                    DDLogVerbose("Search item successfully indexed!")
                }
            }
        }
    }
    
    func removeFromIndex(url: NSURL) {
        CSSearchableIndex.defaultSearchableIndex().deleteSearchableItemsWithIdentifiers([NSURL.wmf_desktopURLForURL(url).absoluteString]) { (error: NSError?) -> Void in
            if let error = error {
                DDLogError("Deindexing error: \(error.localizedDescription)")
            } else {
                DDLogVerbose("Search item successfully removed!")
            }
            
        }
    }

}


