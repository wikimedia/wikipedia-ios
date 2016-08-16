
import UIKit
import MobileCoreServices
import CoreSpotlight


public extension URL {
    @available(iOS 9.0, *)
    func searchableItemAttributes() -> CSSearchableItemAttributeSet? {
        guard wmf_isWikiResource else {
            return nil
        }
        let searchableItem = CSSearchableItemAttributeSet(itemContentType: kUTTypeInternetLocation as String)
        searchableItem.keywords = ["Wikipedia","Wikimedia","Wiki"] + wmf_title.components(separatedBy: " ")
        searchableItem.title = wmf_title
        searchableItem.displayName = wmf_title
        searchableItem.identifier = URL.wmf_desktopURL(for: self).absoluteString
        searchableItem.relatedUniqueIdentifier = URL.wmf_desktopURL(for: self).absoluteString
        return searchableItem
    }
}

public extension MWKArticle {
    @available(iOS 9.0, *)
    func searchableItemAttributes() -> CSSearchableItemAttributeSet {
        let searchableItem = url.searchableItemAttributes() ??
                CSSearchableItemAttributeSet(itemContentType: kUTTypeInternetLocation as String)

        searchableItem.subject = entityDescription
        searchableItem.contentDescription = summary()
        if (imageURL != nil) {
            if let url = NSURL(string: imageURL) {
                searchableItem.thumbnailData = WMFImageController.sharedInstance().diskDataForImageWithURL(url);
            }
        }
        return searchableItem
    }
}

@available(iOS 9.0, *)

open class WMFSavedPageSpotlightManager: NSObject {
    
    let dataStore: MWKDataStore
    var savedPageList: MWKSavedPageList {
        return dataStore.userDataStore.savedPageList
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public required init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(WMFSavedPageSpotlightManager.didUpdateItem(_:)), name: MWKItemUpdatedNotification, object: nil)
    }
    
    open func reindexSavedPages() {
        self.savedPageList.enumerateItemsWithBlock { (item, stop) in
            self.addToIndex(item.url)
        }
    }
    
    func didUpdateItem(_ notification: Notification){
        if let urlString = notification.object as? String {
            if let url = URL.init(string: urlString) {
                if self.savedPageList.isSaved(url){
                    addToIndex(url)
                }else{
                    removeFromIndex(url)
                }
            }
        }
    }
    
    func addToIndex(_ url: URL) {
        if let article = dataStore.existingArticleWithURL(url) {
            

            let searchableItemAttributes = article.searchableItemAttributes()
            searchableItemAttributes.keywords?.append("Saved")
            
            let item = CSSearchableItem(uniqueIdentifier: URL.wmf_desktopURLForURL(url).absoluteString, domainIdentifier: "org.wikimedia.wikipedia", attributeSet: searchableItemAttributes)
            item.expirationDate = Date.distantFuture()
            
            CSSearchableIndex.defaultSearchableIndex().indexSearchableItems([item]) { (error: NSError?) -> Void in
                if let error = error {
                    DDLogError("Indexing error: \(error.localizedDescription)")
                } else {
                    DDLogVerbose("Search item successfully indexed!")
                }
            }
        }
    }
    
    func removeFromIndex(_ url: URL) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [URL.wmf_desktopURL(for: url).absoluteString]) { (error: NSError?) -> Void in
            if let error = error {
                DDLogError("Deindexing error: \(error.localizedDescription)")
            } else {
                DDLogVerbose("Search item successfully removed!")
            }
            
        }
    }

}


