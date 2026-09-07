import Foundation
import WMF

@objc class WMFDatabaseHousekeeper : NSObject {

    /// The maximum number of articles that one pass deletes.
    private static let articleDeletionLimit = 2000

    /// The number of managed objects that Core Data reads from the store at one time.
    private static let fetchBatchSize = 100

    /// Gets the keys of the articles that are in use. Call this on the main thread.
    @objc func articleKeysToPreserve(in dataStore: MWKDataStore, navigationStateController: NavigationStateController) -> Set<String> {
        assert(Thread.isMainThread, "Read the view context on the main thread.")

        let viewContext = dataStore.viewContext

        var keys = Set<String>()

        for object in viewContext.registeredObjects {
            guard let article = object as? WMFArticle, !article.isFault, let key = article.key else {
                continue
            }
            keys.insert(key)
        }

        if let preservedArticleKeys = navigationStateController.allPreservedArticleKeys(in: viewContext) {
            keys.formUnion(preservedArticleKeys)
        }

        return keys
    }

    // Returns deleted URLs
    // Note: A cleanupLevel of high will attempt to do additional scrubbing in the case of vandalism.
    // The caller must own the queue of the context. Do not use the main queue view context.
    @discardableResult @objc func performHousekeeping(on moc: NSManagedObjectContext, excludedArticleKeys: Set<String>, cleanupLevel: WMFCleanupLevel) throws -> [URL] {
        
        if cleanupLevel == .high {
            moc.navigationState = nil
        }
        
        let urls = try deleteStaleUnreferencedArticles(moc, excludedArticleKeys: excludedArticleKeys, cleanupLevel: cleanupLevel)

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
        
        if moc.hasChanges {
            try moc.save()
        }
    }

    private func deleteStaleUnreferencedArticles(_ moc: NSManagedObjectContext, excludedArticleKeys: Set<String>, cleanupLevel: WMFCleanupLevel = .low) throws -> [URL] {
        
        /**
 
        Find `WMFContentGroup`s more than WMFExploreFeedMaximumNumberOfDays days old.
 
        */
        
        let finalMaxDays = cleanupLevel == .high ? 0 : WMFExploreFeedMaximumNumberOfDays
        let today = Date() as NSDate
        guard let oldestFeedDateMidnightUTC = today.wmf_midnightUTCDateFromLocalDate(byAddingDays: 0 - finalMaxDays) else {
            assertionFailure("Calculating midnight UTC on the oldest feed date failed")
            return []
        }
        
        let allContentGroupFetchRequest = WMFContentGroup.fetchRequest()
        // Read all of the groups in batches. Each group can hold the only reference to an article.
        allContentGroupFetchRequest.fetchBatchSize = Self.fetchBatchSize
        
        let allContentGroups = try moc.fetch(allContentGroupFetchRequest)
        var referencedArticleKeys = Set<String>(minimumCapacity: allContentGroups.count * 5 + 1)
        referencedArticleKeys.formUnion(excludedArticleKeys)
        
        for group in allContentGroups {
            if cleanupLevel == .high && (group.midnightUTCDate?.compare(oldestFeedDateMidnightUTC) == .orderedAscending ||
                                  group.midnightUTCDate?.compare(oldestFeedDateMidnightUTC) == .orderedSame) {
                moc.delete(group)
                continue
            } else if group.midnightUTCDate?.compare(oldestFeedDateMidnightUTC) == .orderedAscending {
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
                if group.contentType != .dailyGame {
                    assertionFailure("Unknown Content Type")
                }
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
        
        var urls: [URL] = []

        // The high level deletes no articles. The earlier `isFault` test gave the same result.
        guard cleanupLevel != .high else {
            if moc.hasChanges {
                try moc.save()
            }
            postDidCompleteNotification()
            return urls
        }

        let articlesToDeleteFetchRequest = WMFArticle.fetchRequest()
        // savedDate == NULL && isDownloaded == YES will be picked up by SavedArticlesFetcher for deletion
        articlesToDeleteFetchRequest.predicate = NSPredicate(format: "viewedDate == NULL && savedDate == NULL && isDownloaded == NO && placesSortOrder == 0 && isExcludedFromFeed == NO")
        articlesToDeleteFetchRequest.fetchLimit = Self.articleDeletionLimit
        articlesToDeleteFetchRequest.fetchBatchSize = Self.fetchBatchSize

        let articlesToDelete = try moc.fetch(articlesToDeleteFetchRequest)
        
        for obj in articlesToDelete {
            guard let key = obj.key, !referencedArticleKeys.contains(key) else {
                continue
            }
            moc.delete(obj)
            guard let url = obj.url else {
                continue
            }
            urls.append(url)
        }
        
        
        if moc.hasChanges {
            try moc.save()
        }
        
        postDidCompleteNotification()
        
        return urls
    }

    private func postDidCompleteNotification() {
        // The observers change the UI, therefore send the notification on the main actor.
        Task { @MainActor in
            NotificationCenter.default.post(name: .databaseHousekeeperDidComplete, object: nil)
        }
    }
}
