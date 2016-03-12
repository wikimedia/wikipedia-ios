//
//  SavedPageSpotlightManager.swift
//  Wikipedia
//
//  Created by Corey Floyd on 2/19/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

import UIKit
import MobileCoreServices
import CoreSpotlight
import CocoaLumberjack

@available(iOS 9.0, *)

public extension CSSearchableItemAttributeSet {
    
    public class func attributes(article: MWKArticle) -> CSSearchableItemAttributeSet {
        
        let searchableItem = CSSearchableItemAttributeSet(itemContentType: kUTTypeInternetLocation as String)

        searchableItem.keywords = ["Wikipedia","Wikimedia","Wiki"] + article.title.text.componentsSeparatedByString(" ")
        
        searchableItem.title = article.title.text
        searchableItem.subject = article.entityDescription
        searchableItem.contentDescription = article.summary()
        searchableItem.displayName = article.title.text
        searchableItem.identifier = article.title.desktopURL.absoluteString
        searchableItem.relatedUniqueIdentifier = article.title.desktopURL.absoluteString

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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didSaveTitle:", name: MWKSavedPageListDidSaveNotification, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didUnsaveTitle:", name: MWKSavedPageListDidUnsaveNotification, object: nil)
        
    }
    
    public func reindexSavedPages() {
        for element in savedPageList.entries {
            if let element = element as? MWKSavedPageEntry {
                addToIndex(element.title)
            }
        }
    }
    
    func didSaveTitle(notification: NSNotification){
        if let title = notification.userInfo?[MWKTitleKey] as? MWKTitle {
            addToIndex(title)
        }
    }

    func didUnsaveTitle(notification: NSNotification){
        if let title = notification.userInfo?[MWKTitleKey] as? MWKTitle {
            removeFromIndex(title)
        }
    }
    
    func addToIndex(title: MWKTitle) {
        if let article = dataStore.existingArticleWithTitle(title) {
            
            let searchableItemAttributes = CSSearchableItemAttributeSet.attributes(article)
            searchableItemAttributes.keywords?.append("Saved")
            
            let item = CSSearchableItem(uniqueIdentifier: article.title.desktopURL.absoluteString, domainIdentifier: "org.wikimedia.wikipedia", attributeSet: searchableItemAttributes)
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
    
    func removeFromIndex(title: MWKTitle) {
        CSSearchableIndex.defaultSearchableIndex().deleteSearchableItemsWithIdentifiers([title.desktopURL.absoluteString]) { (error: NSError?) -> Void in
            if let error = error {
                DDLogError("Deindexing error: \(error.localizedDescription)")
            } else {
                DDLogVerbose("Search item successfully removed!")
            }
            
        }
    }

}


