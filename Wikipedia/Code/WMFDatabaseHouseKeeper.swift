import Foundation

@objc class WMFDatabaseHouseKeeper : NSObject {
    
    // Returns deleted URLs
    @objc func performHouseKeepingOnManagedObjectContext(_ moc: NSManagedObjectContext) throws -> [URL] {
        
        let urls = try deleteStaleUnreferencedArticles(moc)
        return urls
    }
    
    /** TODO: refactor into date utilities? */
    internal func daysBeforeDateInUTC(days : Int, date: Date) -> Date? {
        
        guard let midnightTodayUTC = (date as NSDate).wmf_midnightUTCDateFromLocal else {
            assertionFailure("Calculating midnight UTC today failed")
            return nil
        }
        
        let utcCalendar = NSCalendar.wmf_utcGregorian() as Calendar
        guard let thirtyDaysAgoMidnightUTC = utcCalendar.date(byAdding: .day, value: -30, to: midnightTodayUTC)  else{
            assertionFailure("Calculating midnight UTC 30 days ago failed")
            return nil
        }
        return (thirtyDaysAgoMidnightUTC as NSDate).wmf_midnightUTCDateFromLocal
    }
    
    private func deleteStaleUnreferencedArticles(_ moc: NSManagedObjectContext) throws -> [URL] {
        
        /**
 
        Find `WMFContentGroup`s more than 30 days old.
 
        */
        
        guard let thirtyDaysAgoMidnightUTC = daysBeforeDateInUTC(days: -30, date: Date()) else {
            assertionFailure("Calculating midnight UTC 30 days ago failed")
            return []
        }
        
        let allContentGroupFetchRequest = WMFContentGroup.fetchRequest()
        allContentGroupFetchRequest.propertiesToFetch = ["key", "midnightUTCDate", "content", "articleURLString"]
        
        let allContentGroups = try moc.fetch(allContentGroupFetchRequest)
        var referencedArticleKeys = Set<String>(minimumCapacity: allContentGroups.count * 5 + 1)
        
        for group in allContentGroups {
            if group.midnightUTCDate?.compare(thirtyDaysAgoMidnightUTC) == .orderedAscending {
                moc.delete(group)
                continue
            }
            
            if let articleURLDatabaseKey = (group.articleURL as NSURL?)?.wmf_articleDatabaseKey {
                referencedArticleKeys.insert(articleURLDatabaseKey)
            }
            
            guard let content = group.content else {
                assertionFailure("Unknown Content Type")
                continue
            }
            
            for obj in content {
                
                switch (group.contentType, obj) {
                    
                case (.URL, let url as NSURL):
                    guard let key = url.wmf_articleDatabaseKey else {
                        continue
                    }
                    referencedArticleKeys.insert(key)
                    
                case (.topReadPreview, let preview as WMFFeedTopReadArticlePreview):
                    guard let key = (preview.articleURL as NSURL).wmf_articleDatabaseKey else {
                        continue
                    }
                    referencedArticleKeys.insert(key)
                    
                case (.story, let story as WMFFeedNewsStory):
                    guard let articlePreviews = story.articlePreviews else {
                        continue
                    }
                    for preview in articlePreviews {
                        guard let key = (preview.articleURL as NSURL).wmf_articleDatabaseKey else {
                            continue
                        }
                        referencedArticleKeys.insert(key)
                    }
                    
                case (.URL, _),
                     (.topReadPreview, _),
                     (.story, _),
                     (.image, _),
                     (.announcement, _):
                    break
                    
                default:
                    assertionFailure("Unknown Content Type")
                }
            }
        }
        
      
        /** 
  
        Find WMFArticles that are cached previews only, and have no user-defined state.
 
            - A `viewedDate` of null indicates that the article was never viewed
            - A `savedDate` of null indicates that the article is not saved
            - A `placesSortOrder` of null indicates it is not currently visible on the Places map
            - Items with `isExcludedFromFeed == YES` need to stay in the database so that they will continue to be excluded from the feed
        */
        
        let articlesToDeleteFetchRequest = WMFArticle.fetchRequest()
        var articlesToDeletePredicate = NSPredicate(format: "viewedDate == NULL && savedDate == NULL && placesSortOrder == 0 && isExcludedFromFeed == FALSE")
        if referencedArticleKeys.count > 0 {
            let referencedKeysPredicate = NSPredicate(format: "!(key IN %@)", referencedArticleKeys)
            articlesToDeletePredicate = NSCompoundPredicate(andPredicateWithSubpredicates:[articlesToDeletePredicate,referencedKeysPredicate])
        }
        
        articlesToDeleteFetchRequest.predicate = articlesToDeletePredicate
        articlesToDeleteFetchRequest.propertiesToFetch = ["key", "viewedDate", "savedDate", "isExcludedFromFeed", "placesSortOrder"]
        
        let articlesToDelete = try moc.fetch(articlesToDeleteFetchRequest)
        
        var urls: [URL] = []
        for obj in articlesToDelete {
            moc.delete(obj)
            guard let url = obj.url else {
                continue
            }
            urls.append(url)
        }
        
        
        if (moc.hasChanges) {
            try moc.save()
        }
        
        return urls
    }
}
