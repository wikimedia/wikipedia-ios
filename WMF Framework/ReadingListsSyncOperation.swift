internal class ReadingListsSyncOperation: ReadingListsOperation {
    override func execute() {
        DispatchQueue.main.async {
            self.dataStore.performBackgroundCoreDataOperation { (moc) in
                do {
                    try self.executeSync(on: moc)
                } catch let error {
                    DDLogError("error during sync operation: \(error)")
                    do {
                        if moc.hasChanges {
                            try moc.save()
                        }
                    } catch let error {
                        DDLogError("error during sync save: \(error)")
                    }
                    if let readingListError = error as? APIReadingListError, readingListError == .notSetup {
                        DispatchQueue.main.async {
                            self.readingListsController.setSyncEnabled(false, shouldDeleteLocalLists: false, shouldDeleteRemoteLists: false)
                            self.finish()
                        }
                    } else {
                        self.finish(with: error)
                    }
                }
            }
        }
    }
    
    func executeSync(on moc: NSManagedObjectContext) throws {
        let rawSyncState = moc.wmf_numberValue(forKey: WMFReadingListSyncStateKey)?.int64Value ?? 0
        var syncState = ReadingListSyncState(rawValue: rawSyncState)
        
        let taskGroup = WMFTaskGroup()
        
        if syncState.contains(.needsRemoteDisable) {
            var disableReadingListsError: Error? = nil
            taskGroup.enter()
            apiController.teardownReadingLists(completion: { (error) in
                disableReadingListsError = error
                taskGroup.leave()
            })
            taskGroup.wait()
            if let error = disableReadingListsError {
                try moc.save()
                self.finish(with: error)
                return
            } else {
                syncState.remove(.needsRemoteDisable)
                moc.wmf_setValue(NSNumber(value: syncState.rawValue), forKey: WMFReadingListSyncStateKey)
            }
        }
        
        if syncState.contains(.needsLocalReset) {
            try moc.wmf_batchProcessObjects(resetAfterSave: true, handler: { (readingList: ReadingList) in
                readingList.readingListID = nil
                readingList.isUpdatedLocally = true
            })
            try moc.wmf_batchProcessObjects(resetAfterSave: true, handler: { (readingListEntry: ReadingListEntry) in
                readingListEntry.readingListEntryID = nil
                readingListEntry.isUpdatedLocally = true
            })
            syncState.remove(.needsLocalReset)
            moc.wmf_setValue(NSNumber(value: syncState.rawValue), forKey: WMFReadingListSyncStateKey)
            try moc.save()
            moc.reset()
        }
        
        if syncState.contains(.needsLocalClear) {
            try moc.wmf_batchProcess(matchingPredicate: NSPredicate(format: "savedDate != NULL"), resetAfterSave: true, handler: { (articles: [WMFArticle]) in
                self.readingListsController.unsave(articles)
            })
            syncState.remove(.needsLocalClear)
            moc.wmf_setValue(NSNumber(value: syncState.rawValue), forKey: WMFReadingListSyncStateKey)
            try moc.save()
            moc.reset()
        }
        
        // local only sync
        guard syncState != [] else {
            try executeLocalOnlySync(on: moc)
            try moc.save()
            finish()
            return
        }
        
        if syncState.contains(.needsRemoteEnable) {
            var enableReadingListsError: Error? = nil
            taskGroup.enter()
            apiController.setupReadingLists(completion: { (error) in
                enableReadingListsError = error
                taskGroup.leave()
            })
            taskGroup.wait()
            if let error = enableReadingListsError {
                try moc.save()
                finish(with: error)
                return
            } else {
                syncState.remove(.needsRemoteEnable)
                moc.wmf_setValue(NSNumber(value: syncState.rawValue), forKey: WMFReadingListSyncStateKey)
            }
        }
        
        if syncState.contains(.needsSync) {
           try executeFullSync(on: moc)
            syncState.remove(.needsSync)
            syncState.insert(.needsUpdate)
        } else if syncState.contains(.needsUpdate) {
            try executeUpdate(on: moc)
        }
        
        moc.wmf_setValue(NSNumber(value: syncState.rawValue), forKey: WMFReadingListSyncStateKey)
        if moc.hasChanges {
            try moc.save()
        }
        finish()
    }

    func executeLocalOnlySync(on moc: NSManagedObjectContext) throws {
        try moc.wmf_batchProcessObjects(matchingPredicate: NSPredicate(format: "isDeletedLocally == YES"), resetAfterSave: true, handler: { (list: ReadingList) in
            moc.delete(list)
        })
        try moc.wmf_batchProcessObjects(matchingPredicate: NSPredicate(format: "isDeletedLocally == YES"), resetAfterSave: true, handler: { (entry: ReadingListEntry) in
            moc.delete(entry)
        })
    }
    
    func executeFullSync(on moc: NSManagedObjectContext) throws {
        let taskGroup = WMFTaskGroup()
        var allAPIReadingLists: [APIReadingList] = []
        var getAllAPIReadingListsError: Error?
        taskGroup.enter()
        readingListsController.apiController.getAllReadingLists { (readingLists, error) in
            getAllAPIReadingListsError = error
            allAPIReadingLists = readingLists
            taskGroup.leave()
        }
        
        taskGroup.wait()
        
        if let getAllAPIReadingListsError = getAllAPIReadingListsError {
            throw getAllAPIReadingListsError
        }
        
        if let remoteDefaultReadingList: APIReadingList = allAPIReadingLists.filter({ (list) -> Bool in return list.isDefault }).first {
            let defaultReadingList = moc.wmf_fetchDefaultReadingList()
            defaultReadingList?.readingListID = NSNumber(value: remoteDefaultReadingList.id)
        }
        
        let group = WMFTaskGroup()
        
        let readingListSinceDate = try readingListsController.createOrUpdate(remoteReadingLists: allAPIReadingLists, inManagedObjectContext: moc)
        
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
        try readingListsController.markLocalDeletion(for: localReadingListsToDelete)
        for readingList in localReadingListsToDelete {
            moc.delete(readingList)
        }
        
        // Get all entries
        var remoteEntriesByReadingListID: [Int64: [APIReadingListEntry]] = [:]
        for remoteReadingList in allAPIReadingLists {
            group.enter()
            apiController.getAllEntriesForReadingListWithID(readingListID: remoteReadingList.id, completion: { (entries, error) in
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
            let listEntrySinceDate = try readingListsController.createOrUpdate(remoteReadingListEntries: remoteReadingListEntries, for: readingListID, inManagedObjectContext: moc)
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
            try readingListsController.markLocalDeletion(for: localReadingListEntriesToDelete)
            for readingListEntry in localReadingListEntriesToDelete {
                moc.delete(readingListEntry)
            }
        }
        
        let sinceDate = readingListSinceDate.compare(entrySinceDate) == .orderedDescending ? readingListSinceDate : entrySinceDate
        if sinceDate.compare(Date.distantPast) != .orderedSame {
            let iso8601String = DateFormatter.wmf_iso8601().string(from: sinceDate)
            moc.wmf_setValue(iso8601String as NSString, forKey: WMFReadingListUpdateKey)
        }
        
        try readingListsController.processLocalUpdates(in: moc)
        
        guard moc.hasChanges else {
            return
        }
        try moc.save()
    }

    func executeUpdate(on moc: NSManagedObjectContext) throws {
        try readingListsController.processLocalUpdates(in: moc)
        
        if moc.hasChanges {
            try moc.save()
        }
        
        guard let since = moc.wmf_stringValue(forKey: WMFReadingListUpdateKey) else {
            return
        }
        
        var updatedLists: [APIReadingList] = []
        var updatedEntries: [APIReadingListEntry] = []
        var updateError: Error?
        
        let taskGroup = WMFTaskGroup()
        taskGroup.enter()
        apiController.updatedListsAndEntries(since: since, completion: { (lists, entries, error) in
            updateError = error
            updatedLists =  lists
            updatedEntries = entries
            taskGroup.leave()
        })
        
        taskGroup.wait()
        
        if let error = updateError {
            throw error
        }
        
        let listSinceDate = try readingListsController.createOrUpdate(remoteReadingLists: updatedLists, inManagedObjectContext: moc)
        let entrySinceDate = try readingListsController.createOrUpdate(remoteReadingListEntries: updatedEntries, inManagedObjectContext: moc)
        let sinceDate: Date = listSinceDate.compare(entrySinceDate) == .orderedDescending ? listSinceDate : entrySinceDate
        
        if sinceDate.compare(Date.distantPast) != .orderedSame {
            let iso8601String = DateFormatter.wmf_iso8601().string(from: sinceDate)
            moc.wmf_setValue(iso8601String as NSString, forKey: WMFReadingListUpdateKey)
        }
        
        guard moc.hasChanges else {
            return
        }
        try moc.save()
    }
}
