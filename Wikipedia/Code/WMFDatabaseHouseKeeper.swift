import Foundation

@objc class WMFDatabaseHouseKeeper : NSObject {
    
    // Returns deleted URLs
    @discardableResult @objc func performHouseKeepingOnManagedObjectContext(_ moc: NSManagedObjectContext, navigationStateController: NavigationStateController) throws -> [URL] {
        
        let urls = try deleteStaleUnreferencedArticles(moc, navigationStateController: navigationStateController)

        try deleteStaleTalkPages(moc)
        try deleteStaleAnnouncements(moc)

        return urls
    }
    
    private func deleteStaleAnnouncements(_ moc: NSManagedObjectContext) throws {
        guard let announcementContentGroups = moc.orderedGroups(of: .announcement, with: nil) else {
            return
        }
        let currentDate = Date()
        for announcementGroup in announcementContentGroups {
            guard let announcement = announcementGroup.contentPreview as? WMFAnnouncement,
                  let endDate = announcement.endTime,
                  currentDate > endDate else {
                continue
            }
            moc.delete(announcementGroup)
        }
        
        if (moc.hasChanges) {
            try moc.save()
        }
    }

    /**
     
     We only persist the last 50 most recently accessed talk pages, delete all others.
     
    */
    private func deleteStaleTalkPages(_ moc: NSManagedObjectContext) throws {
        let request: NSFetchRequest<NSFetchRequestResult> = TalkPage.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "dateAccessed", ascending: false)]
        request.fetchOffset = 50
        let batchRequest = NSBatchDeleteRequest(fetchRequest: request)
        batchRequest.resultType = .resultTypeObjectIDs
        
        let result = try moc.execute(batchRequest) as? NSBatchDeleteResult
        let objectIDArray = result?.result as? [NSManagedObjectID]
        let changes: [AnyHashable : Any] = [NSDeletedObjectsKey : objectIDArray as Any]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [moc])
        
        try moc.removeUnlinkedTalkPageTopicContent()
    }
    
    private func deleteStaleUnreferencedArticles(_ moc: NSManagedObjectContext, navigationStateController: NavigationStateController) throws -> [URL] {
        
        /**
 
        Find `WMFContentGroup`s more than WMFExploreFeedMaximumNumberOfDays days old.
 
        */
        
        let today = Date() as NSDate
        guard let oldestFeedDateMidnightUTC = today.wmf_midnightUTCDateFromLocalDate(byAddingDays: 0 - WMFExploreFeedMaximumNumberOfDays) else {
            assertionFailure("Calculating midnight UTC on the oldest feed date failed")
            return []
        }
        
        let allContentGroupFetchRequest = WMFContentGroup.fetchRequest()
        
        let allContentGroups = try moc.fetch(allContentGroupFetchRequest)
        var referencedArticleKeys = Set<String>(minimumCapacity: allContentGroups.count * 5 + 1)
        
        for group in allContentGroups {
            if group.midnightUTCDate?.compare(oldestFeedDateMidnightUTC) == .orderedAscending {
                moc.delete(group)
                continue
            }
            
            if let articleURLDatabaseKey = group.articleURL?.wmf_databaseKey {
                referencedArticleKeys.insert(articleURLDatabaseKey)
            }

            if let previewURL = group.contentPreview as? NSURL, let key = previewURL.wmf_databaseKey {
                referencedArticleKeys.insert(key)
            }
            
            guard let fullContent = group.fullContent else {
                continue
            }

            guard let content = fullContent.object as? [Any] else {
                assertionFailure("Unknown Content Type")
                continue
            }
            
            for obj in content {
                
                switch (group.contentType, obj) {
                    
                case (.URL, let url as NSURL):
                    guard let key = url.wmf_databaseKey else {
                        continue
                    }
                    referencedArticleKeys.insert(key)
                    
                case (.topReadPreview, let preview as WMFFeedTopReadArticlePreview):
                    guard let key = (preview.articleURL as NSURL).wmf_databaseKey else {
                        continue
                    }
                    referencedArticleKeys.insert(key)
                    
                case (.story, let story as WMFFeedNewsStory):
                    guard let articlePreviews = story.articlePreviews else {
                        continue
                    }
                    for preview in articlePreviews {
                        guard let key = (preview.articleURL as NSURL).wmf_databaseKey else {
                            continue
                        }
                        referencedArticleKeys.insert(key)
                    }
                    
                case (.URL, _),
                     (.topReadPreview, _),
                     (.story, _),
                     (.image, _),
                     (.notification, _),
                     (.announcement, _),
                     (.onThisDayEvent, _),
                     (.theme, _):
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
        //savedDate == NULL && isDownloaded == YES will be picked up by SavedArticlesFetcher for deletion
        let articlesToDeletePredicate = NSPredicate(format: "viewedDate == NULL && savedDate == NULL && isDownloaded == NO && placesSortOrder == 0 && isExcludedFromFeed == NO")
        
        if let preservedArticleKeys = navigationStateController.allPreservedArticleKeys(in: moc) {
            referencedArticleKeys.formUnion(preservedArticleKeys)
        }
        
        articlesToDeleteFetchRequest.propertiesToFetch = ["key"]
        articlesToDeleteFetchRequest.predicate = articlesToDeletePredicate

        let articlesToDelete = try moc.fetch(articlesToDeleteFetchRequest)
        
        var urls: [URL] = []
        for obj in articlesToDelete {
            guard obj.isFault else { // only delete articles that are faults. prevents deletion of articles that are being actively viewed. repro steps: open disambiguation pages view -> exit app -> re-enter app
                continue
            }
            
            guard let key = obj.key, !referencedArticleKeys.contains(key) else {
                continue
            }
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
