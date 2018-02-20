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
                    } else if let readingListError = error as? APIReadingListError, readingListError == .needsFullSync {
                        DispatchQueue.main.async {
                            let oldState = self.readingListsController.syncState
                            var newState = oldState
                            newState.insert(.needsSync)
                            if newState != oldState {
                                self.readingListsController.syncState = newState
                            }
                            self.finish()
                        }
                    }  else {
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
                try moc.save()
            }
        }
        
        #if DEBUG
            if syncState.contains(.needsRandomEntries) {
                try executeRandomArticlePopulation(in: moc)
                syncState.remove(.needsRandomEntries)
                moc.wmf_setValue(NSNumber(value: syncState.rawValue), forKey: WMFReadingListSyncStateKey)
                try moc.save()
            }
        #endif
        
        if syncState.contains(.needsLocalReset) {
            try moc.wmf_batchProcessObjects(handler: { (readingListEntry: ReadingListEntry) in
                readingListEntry.readingListEntryID = nil
                readingListEntry.isUpdatedLocally = true
            })
            try moc.wmf_batchProcessObjects(handler: { (readingList: ReadingList) in
                readingList.readingListID = nil
                readingList.isUpdatedLocally = true
            })
            syncState.remove(.needsLocalReset)
            moc.wmf_setValue(NSNumber(value: syncState.rawValue), forKey: WMFReadingListSyncStateKey)
            try moc.save()
            moc.reset()
        }
        
        if syncState.contains(.needsLocalArticleClear) {
            try moc.wmf_batchProcess(matchingPredicate: NSPredicate(format: "savedDate != NULL"), handler: { (articles: [WMFArticle]) in
                self.readingListsController.unsave(articles, in: moc)
            })
        
            syncState.remove(.needsLocalArticleClear)
            moc.wmf_setValue(NSNumber(value: syncState.rawValue), forKey: WMFReadingListSyncStateKey)
            try moc.save()
        }
        
        if syncState.contains(.needsLocalListClear) {
            try moc.wmf_batchProcess(matchingPredicate: NSPredicate(format: "isDefault != YES"), handler: { (lists: [ReadingList]) in
                try self.readingListsController.markLocalDeletion(for: lists)
                for list in lists {
                    moc.delete(list)
                }
            })
            
            syncState.remove(.needsLocalListClear)
            moc.wmf_setValue(NSNumber(value: syncState.rawValue), forKey: WMFReadingListSyncStateKey)
            try moc.save()
        }
        
        // local only sync
        guard syncState != [] else {
            
            // make an update call to see if the user has enabled sync on another device
            var updateError: Error? = nil
            
            taskGroup.enter()
            let iso8601String = DateFormatter.wmf_iso8601().string(from: Date())
            apiController.updatedListsAndEntries(since: iso8601String, completion: { (lists, entries, error) in
                updateError = error
                taskGroup.leave()
            })
            taskGroup.wait()
            
            if updateError == nil {
                DispatchQueue.main.async {
                    self.readingListsController.setSyncEnabled(true, shouldDeleteLocalLists: false, shouldDeleteRemoteLists: false)
                    self.finish()
                }
            } else {
                try executeLocalOnlySync(on: moc)
                try moc.save()
                finish()
            }
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
                try moc.save()
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
        try moc.wmf_batchProcessObjects(matchingPredicate: NSPredicate(format: "isDeletedLocally == YES"), handler: { (list: ReadingList) in
            moc.delete(list)
        })
        try moc.wmf_batchProcessObjects(matchingPredicate: NSPredicate(format: "isDeletedLocally == YES"), handler: { (entry: ReadingListEntry) in
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
        
        let readingListSinceDate = try readingListsController.createOrUpdate(remoteReadingLists: allAPIReadingLists, deleteMissingLocalLists: true, inManagedObjectContext: moc)
        
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
            let listEntrySinceDate = try readingListsController.createOrUpdate(remoteReadingListEntries: remoteReadingListEntries, for: readingListID, deleteMissingLocalEntries: true, inManagedObjectContext: moc)
            if listEntrySinceDate.compare(entrySinceDate) == .orderedDescending {
                entrySinceDate = listEntrySinceDate
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
    
    func executeRandomArticlePopulation(in moc: NSManagedObjectContext) throws {
        guard let siteURL = URL(string: "https://en.wikipedia.org") else {
            return
        }
        let randomArticleFetcher = WMFRandomArticleFetcher()
        let taskGroup = WMFTaskGroup()
        try moc.wmf_batchProcessObjects { (list: ReadingList) in
            do {
                for _ in 0...200 {
                    guard let entries = list.entries, entries.count < 996 else {
                        return
                    }
                    var results: [MWKSearchResult] = []
                    for _ in 0...5 {
                        taskGroup.enter()
                        randomArticleFetcher.fetchRandomArticle(withSiteURL: siteURL, failure: { (failure) in
                            taskGroup.leave()
                        }, success: { (searchResult) in
                            results.append(searchResult)
                            taskGroup.leave()
                        })
                    }
                    taskGroup.wait()
                    let keys = results.flatMap { $0.articleURL(forSiteURL: siteURL)?.wmf_articleDatabaseKey }
                    let articles = try moc.wmf_fetchOrCreate(objectsForEntityName: "WMFArticle", withValues: keys, forKey: "key") as? [WMFArticle] ?? []
                    for (index, article) in articles.enumerated() {
                        guard index < results.count else {
                            continue
                        }
                        let result = results[index]
                        article.update(with: result)
                    }
                    try readingListsController.add(articles: articles, to: list, in: moc)
                    try moc.save()
                }
            } catch let error {
                DDLogError("error populating lists: \(error)")
            }
        }
    }
}
