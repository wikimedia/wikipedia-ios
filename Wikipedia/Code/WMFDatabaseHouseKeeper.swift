import Foundation

@objc class WMFDatabaseHouseKeeper : NSObject {
    
    private let readingListsController: ReadingListsController
    private let articleSummaryController: ArticleSummaryController
    
    @objc init(readingListsController: ReadingListsController, articleSummaryController: ArticleSummaryController) {
        self.readingListsController = readingListsController
        self.articleSummaryController = articleSummaryController
    }
    
    // Returns deleted WMFArticle URLs. Deleted WMFAnnouncements, ReadingListEntries TalkPages and CacheGroups are not returned.
    @objc func performHouseKeepingOnManagedObjectContext(_ moc: NSManagedObjectContext, navigationStateController: NavigationStateController, completion: @escaping (([URL], Error?) -> Void)) {
        
        moc.perform {
            do {
                let urls = try self.deleteStaleUnreferencedArticles(moc, navigationStateController: navigationStateController)

                try self.deleteStaleTalkPages(moc)
                try self.deleteStaleAnnouncements(moc)
                
                self.deleteOrphanedReadingListEntries(moc) { result in
                    switch result {
                    case .success:
                        completion(urls, nil)
                    case .failure(let error):
                        completion([], error)
                    }
                }
            } catch (let error) {
                completion([], error)
            }
        }
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
    
    @discardableResult
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
    
    //TODO: maybe do this one-time as a part of migration instead, not sure.
    private func deleteOrphanedReadingListEntries(_ moc: NSManagedObjectContext, completion: @escaping (Result<Void, Error>) -> Void) {
        let readingListRequest: NSFetchRequest<ReadingListEntry> = ReadingListEntry.fetchRequest()
        
        let readingListEntries: [ReadingListEntry]
        do {
            readingListEntries = try moc.fetch(readingListRequest)
        } catch (let error) {
            completion(.failure(error))
            return
        }
        
        var entriesToDelete: [ReadingListEntry] = []
        for readingListEntry in readingListEntries {
            
            guard let readingListKey = readingListEntry.articleKey else {
                continue
            }
            
            let articleFetchRequest: NSFetchRequest<WMFArticle> = WMFArticle.fetchRequest()
            let finalPredicate: NSPredicate
            let firstPredicate = NSPredicate(format: "key == %@", readingListKey)
            if let variant = readingListEntry.variant {
                let nextPredicate = NSPredicate(format: "variant == %@", variant)
                finalPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [firstPredicate, nextPredicate])
            } else {
                finalPredicate = firstPredicate
            }
            
            articleFetchRequest.predicate = finalPredicate
            if let countOfArticles = try? moc.count(for: articleFetchRequest),
               countOfArticles == 0 {
                entriesToDelete.append(readingListEntry)
            }
        }
        
        let articleKeys: [WMFInMemoryURLKey] = entriesToDelete.compactMap {
            guard let articleKey = $0.articleKey else { return nil }
            return WMFInMemoryURLKey(databaseKey: articleKey, languageVariantCode: $0.variant)
        }
        
        do {
            try self.readingListsController.remove(entries: entriesToDelete)
        } catch (let error) {
            completion(.failure(error))
            return
        }
        
        self.articleSummaryController.updateOrCreateArticleSummariesForArticles(withKeys: articleKeys, cachePolicy: .reloadRevalidatingCacheData) { result, error in
            
            if let summaryUpdateError = error {
                if (moc.hasChanges) {
                    do {
                        try moc.save()
                        completion(.failure((summaryUpdateError)))
                    } catch (let error) {
                        completion(.failure(error))
                    }
                    return
                }
                completion(.failure(summaryUpdateError))
                return
            }
            
            for (originalKey, newArticle) in result {
                let deletedReadingListEntry = entriesToDelete.first { deletedEntry in
                    
                    guard let deletedEntryArticleKey = deletedEntry.articleKey else {
                        return false
                    }
                    
                    let deletedEntryVariant = deletedEntry.variant

                    return deletedEntryArticleKey == originalKey.databaseKey && deletedEntryVariant == originalKey.languageVariantCode
                }
                if let deletedEntryList = deletedReadingListEntry?.list {
                    //TODO: this changes savedDate which will alter sorting, should we instead set savedDate (for WMFArticle and new ReadingListEntry) to deletedReadingListEntry date?
                    try? self.readingListsController.add(articles: [newArticle], to: deletedEntryList)
                }
            }
            
            if (moc.hasChanges) {
                do {
                    try moc.save()
                    completion(.success(()))
                } catch (let error) {
                    completion(.failure(error))
                }
            }
        }
    }
}
