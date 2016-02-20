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

@available(iOS 9.0, *)

public extension CSSearchableItemAttributeSet {
    
    public class func attributes(article: MWKArticle) -> CSSearchableItemAttributeSet {
        
        let searchableItem = CSSearchableItemAttributeSet(itemContentType: kUTTypeInternetLocation as String)

        searchableItem.keywords = ["Wikipedia","Wikimedia","Wiki"] + article.displaytitle.componentsSeparatedByString(" ")
        
        searchableItem.title = article.displaytitle
        searchableItem.subject = article.entityDescription
        searchableItem.contentDescription = article.summary()
        searchableItem.displayName = article.displaytitle
        searchableItem.identifier = article.title.mobileURL.absoluteString
        if (article.imageURL != nil) {
            if let url = NSURL(string: article.imageURL) {
                searchableItem.thumbnailData = WMFImageController.sharedInstance().diskDataForImageWithURL(url);
            }
        }
        return searchableItem
    }
}


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
    
    func didSaveTitle(notification: NSNotification){
        if let title = notification.userInfo?[MWKTitleKey] as? MWKTitle {
            // CSSearchableItemAttributes for bill data
            if #available(iOS 9.0, *) {
                if let article = dataStore.existingArticleWithTitle(title) {
                    
                    let searchableItemAttributes = CSSearchableItemAttributeSet.attributes(article)
                    searchableItemAttributes.keywords?.append("Saved")
                    
                    let item = CSSearchableItem(uniqueIdentifier: article.title.mobileURL.absoluteString, domainIdentifier: "org.wikimedia.wikipedia", attributeSet: searchableItemAttributes)
                    item.expirationDate = NSDate.distantFuture()

                    CSSearchableIndex.defaultSearchableIndex().indexSearchableItems([item]) { (error: NSError?) -> Void in
                        if let error = error {
                            print("Indexing error: \(error.localizedDescription)")
                        } else {
                            print("Search item successfully indexed!")
                        }
                    }

                }
            }
        }
    }

    func didUnsaveTitle(notification: NSNotification){
        if let title = notification.userInfo?[MWKTitleKey] as? MWKTitle {
            if #available(iOS 9.0, *) {
                CSSearchableIndex.defaultSearchableIndex().deleteSearchableItemsWithIdentifiers([title.mobileURL.absoluteString]) { (error: NSError?) -> Void in
                    if let error = error {
                        print("Deindexing error: \(error.localizedDescription)")
                    } else {
                        print("Search item successfully removed!")
                    }
            
                }
            }
        }
    }
}


