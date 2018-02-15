internal class ReadingListsSyncOperation: ReadingListsOperation {
    override func execute() {
        readingListsController.apiController.getAllReadingLists { (allAPIReadingLists, getAllAPIReadingListsError) in
            if let error = getAllAPIReadingListsError {
                DDLogError("Error from all lists response: \(error)")
                if let readingListError = error as? APIReadingListError, readingListError == .notSetup {
                    DispatchQueue.main.async {
                        self.readingListsController.setSyncEnabled(false, shouldDeleteLocalLists: false, shouldDeleteRemoteLists: false)
                    }
                }
                self.finish(with: error)
                return
            }
            DispatchQueue.main.async {
                self.dataStore.performBackgroundCoreDataOperation(onATemporaryContext: { (moc) in
                    if let remoteDefaultReadingList: APIReadingList = allAPIReadingLists.filter({ (list) -> Bool in return list.isDefault }).first {
                        let defaultReadingList = moc.wmf_fetchDefaultReadingList()
                        defaultReadingList?.readingListID = NSNumber(value: remoteDefaultReadingList.id)
                    }

                    let group = WMFTaskGroup()
                    
                    do {
                        let readingListSinceDate = try self.readingListsController.createOrUpdate(remoteReadingLists: allAPIReadingLists, inManagedObjectContext: moc)
                        
//                        for readingList in allAPIReadingLists {
//                            let randomArticleFetcher = WMFRandomArticleFetcher()
//                            guard let siteURL = URL(string: "https://en.wikipedia.org") else {
//                                return
//                            }
//                            for _ in 0...200 {
//                                let taskGroup = WMFTaskGroup()
//                                var listIsFull = false
//                                for _ in 0...5 {
//                                    taskGroup.enter()
//                                    randomArticleFetcher.fetchRandomArticle(withSiteURL: siteURL, failure: { (failure) in
//                                        taskGroup.leave()
//                                    }, success: { (searchResult) in
//                                        let articleURL = searchResult.articleURL(forSiteURL: siteURL)
//                                        self.apiController.addEntryToList(withListID: readingList.id, project: siteURL.absoluteString, title: articleURL?.wmf_title ?? "", completion: { (entryID, error) in
//                                            print("\(String(describing: entryID))")
//                                            if let apiError = error as? APIReadingListError, apiError == .entryLimit {
//                                                listIsFull = true
//                                            }
//                                            taskGroup.leave()
//                                        })
//                                    })
//
//                                }
//                                taskGroup.wait()
//                                if listIsFull {
//                                    break
//                                }
//                            }
//                        }
                        
                        // Delete missing reading lists
                        let remoteReadingListIDs = Set<Int64>(allAPIReadingLists.flatMap { $0.id })
                        let fetchForAllLocalLists: NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
                        let localReadingListsToDelete = try moc.fetch(fetchForAllLocalLists).filter {
                            guard let readingListID = $0.readingListID?.int64Value else {
                                return false
                            }
                            return !remoteReadingListIDs.contains(readingListID)
                        }
                        try self.readingListsController.markLocalDeletion(for: localReadingListsToDelete)
                        for readingList in localReadingListsToDelete {
                            moc.delete(readingList)
                        }
                        
                        // Get all entries
                        var remoteEntriesByReadingListID: [Int64: [APIReadingListEntry]] = [:]
                        for remoteReadingList in allAPIReadingLists {
                            group.enter()
                            self.apiController.getAllEntriesForReadingListWithID(readingListID: remoteReadingList.id, completion: { (entries, error) in
                                if let error = error {
                                    DDLogError("Error fetching entries for reading list with ID \(remoteReadingList.id): \(error)")
                                } else {
                                    remoteEntriesByReadingListID[remoteReadingList.id] = entries
                                }
                                group.leave()
                            })
                        }
                        
                        group.wait()
                        
                        var entrySinceDate = Date.distantPast
                        
                        for (readingListID, remoteReadingListEntries) in remoteEntriesByReadingListID {
                            let listEntrySinceDate = try self.readingListsController.createOrUpdate(remoteReadingListEntries: remoteReadingListEntries, for: readingListID, inManagedObjectContext: moc)
                            if listEntrySinceDate.compare(entrySinceDate) == .orderedDescending {
                                entrySinceDate = listEntrySinceDate
                            }
                            // Delete missing entries
                            let readingListEntryIDs = Set<Int64>(remoteReadingListEntries.map { $0.id })
                            let fetchForDeletedRemoteEntries: NSFetchRequest<ReadingListEntry> = ReadingListEntry.fetchRequest()
                            fetchForDeletedRemoteEntries.predicate = NSPredicate(format: "list.readingListID == %d", readingListID)
                            let localReadingListEntriesToDelete = try moc.fetch(fetchForDeletedRemoteEntries).filter {
                                guard let readingListID = $0.readingListEntryID?.int64Value else {
                                    return false
                                }
                                return !readingListEntryIDs.contains(readingListID)
                            }
                            try self.readingListsController.markLocalDeletion(for: localReadingListEntriesToDelete)
                            for readingListEntry in localReadingListEntriesToDelete {
                                moc.delete(readingListEntry)
                            }
                        }
                        
                        let sinceDate = readingListSinceDate.compare(entrySinceDate) == .orderedDescending ? readingListSinceDate : entrySinceDate
                        if sinceDate.compare(Date.distantPast) != .orderedSame {
                            let iso8601String = DateFormatter.wmf_iso8601().string(from: sinceDate)
                            moc.wmf_setValue(iso8601String as NSString, forKey: WMFReadingListUpdateKey)
                        }
                        
                        try self.readingListsController.processLocalUpdates(in: moc)
                        
                        guard moc.hasChanges else {
                            return
                        }
                        try moc.save()
                        
                    } catch let error {
                        DDLogError("Error during reading list sync: \(error)")
                    }
                    self.finish()
                })
            }
        }
    }
}
