import UIKit
import MobileCoreServices
import CoreSpotlight

public extension NSURL {
    @available(iOS 9.0, *)
    func searchableItemAttributes() -> CSSearchableItemAttributeSet? {
        guard wmf_isWikiResource else {
            return nil
        }
        guard let title = wmf_title else {
            return nil
        }
        let components = title.componentsSeparatedByString(" ")
        let searchableItem = CSSearchableItemAttributeSet(itemContentType: kUTTypeInternetLocation as String)
        searchableItem.keywords = ["Wikipedia","Wikimedia","Wiki"] + components
        searchableItem.title = wmf_title
        searchableItem.displayName = wmf_title
        searchableItem.identifier = NSURL.wmf_desktopURLForURL(self)?.absoluteString
        searchableItem.relatedUniqueIdentifier = NSURL.wmf_desktopURLForURL(self)?.absoluteString
        return searchableItem
    }
}

public extension MWKArticle {
    @available(iOS 9.0, *)
    func searchableItemAttributes() -> CSSearchableItemAttributeSet {
        let searchableItem = url.searchableItemAttributes() ??
                CSSearchableItemAttributeSet(itemContentType: kUTTypeInternetLocation as String)

        searchableItem.subject = entityDescription
        searchableItem.contentDescription = summary
        if let string = imageURL {
            if let url = NSURL(string: string) {
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
        return dataStore.savedPageList
    }
    
    public required init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
        super.init()
    }
    
    public func reindexSavedPages() {
        self.savedPageList.enumerateItemsWithBlock { (item, stop) in
            self.addToIndex(item.url)
        }
    }
    
    public func addToIndex(url: NSURL) {
        guard let article = dataStore.existingArticleWithURL(url), let identifier = NSURL.wmf_desktopURLForURL(url)?.absoluteString else {
            return
        }
        
        let searchableItemAttributes = article.searchableItemAttributes()
        searchableItemAttributes.keywords?.append("Saved")
        
        let item = CSSearchableItem(uniqueIdentifier: identifier, domainIdentifier: "org.wikimedia.wikipedia", attributeSet: searchableItemAttributes)
        item.expirationDate = NSDate.distantFuture()
        
        CSSearchableIndex.defaultSearchableIndex().indexSearchableItems([item]) { (error: NSError?) -> Void in
            if let error = error {
                DDLogError("Indexing error: \(error.localizedDescription)")
            } else {
                DDLogVerbose("Search item successfully indexed!")
            }
        }
    }
    
    public func removeFromIndex(url: NSURL) {
        guard let identifier = NSURL.wmf_desktopURLForURL(url)?.absoluteString else {
            return
        }
        CSSearchableIndex.defaultSearchableIndex().deleteSearchableItemsWithIdentifiers([identifier]) { (error: NSError?) -> Void in
            if let error = error {
                DDLogError("Deindexing error: \(error.localizedDescription)")
            } else {
                DDLogVerbose("Search item successfully removed!")
            }
            
        }
    }

}


