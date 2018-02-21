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
        
        if syncState.contains(.needsRandomLists) {
            try executeRandomListPopulation(in: moc)
            syncState.remove(.needsRandomLists)
            moc.wmf_setValue(NSNumber(value: syncState.rawValue), forKey: WMFReadingListSyncStateKey)
            try moc.save()
        }
        
        if syncState.contains(.needsRandomEntries) {
            try executeRandomArticlePopulation(in: moc)
            syncState.remove(.needsRandomEntries)
            moc.wmf_setValue(NSNumber(value: syncState.rawValue), forKey: WMFReadingListSyncStateKey)
            try moc.save()
        }
        
        if syncState.contains(.needsLocalReset) {
            try moc.wmf_batchProcessObjects(handler: { (readingListEntry: ReadingListEntry) in
                readingListEntry.readingListEntryID = nil
                readingListEntry.isUpdatedLocally = true
                readingListEntry.errorCode = nil
            })
            try moc.wmf_batchProcessObjects(handler: { (readingList: ReadingList) in
                readingList.readingListID = nil
                readingList.isUpdatedLocally = true
                readingList.errorCode = nil
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
            apiController.updatedListsAndEntries(since: iso8601String, completion: { (lists, entries, since, error) in
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
        var nextSince: String? = nil
        taskGroup.enter()
        readingListsController.apiController.getAllReadingLists { (readingLists, since, error) in
            getAllAPIReadingListsError = error
            allAPIReadingLists = readingLists
            nextSince = since
            taskGroup.leave()
        }
        
        taskGroup.wait()
        
        if let getAllAPIReadingListsError = getAllAPIReadingListsError {
            throw getAllAPIReadingListsError
        }
        
        let group = WMFTaskGroup()
        
        try readingListsController.createOrUpdate(remoteReadingLists: allAPIReadingLists, deleteMissingLocalLists: true, inManagedObjectContext: moc)
        
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
        
        for (readingListID, remoteReadingListEntries) in remoteEntriesByReadingListID {
            try readingListsController.createOrUpdate(remoteReadingListEntries: remoteReadingListEntries, for: readingListID, deleteMissingLocalEntries: true, inManagedObjectContext: moc)
        }
        
        if let since = nextSince {
            moc.wmf_setValue(since as NSString, forKey: WMFReadingListUpdateKey)
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
        var nextSince: String?
        
        let taskGroup = WMFTaskGroup()
        taskGroup.enter()
        apiController.updatedListsAndEntries(since: since, completion: { (lists, entries, since, error) in
            updateError = error
            updatedLists =  lists
            updatedEntries = entries
            nextSince = since
            taskGroup.leave()
        })
        
        taskGroup.wait()
        
        if let error = updateError {
            throw error
        }
        
        try readingListsController.createOrUpdate(remoteReadingLists: updatedLists, inManagedObjectContext: moc)
        try readingListsController.createOrUpdate(remoteReadingListEntries: updatedEntries, inManagedObjectContext: moc)
        
        if let since = nextSince {
            moc.wmf_setValue(since as NSString, forKey: WMFReadingListUpdateKey)
        }
        
        guard moc.hasChanges else {
            return
        }
        try moc.save()
    }
    
    func executeRandomListPopulation(in moc: NSManagedObjectContext) throws {
        let countOfListsToCreate = moc.wmf_numberValue(forKey: "WMFCountOfListsToCreate")?.int64Value ?? 10
        for i in 1...countOfListsToCreate {
            do {
                _ = try readingListsController.createReadingList(named: "\(i)", in: moc)
            } catch {
                _ = try readingListsController.createReadingList(named: "\(arc4random())", in: moc)
            }
        }
        try moc.save()
    }
        
    func executeRandomArticlePopulation(in moc: NSManagedObjectContext) throws {
        guard let siteURL = URL(string: "https://en.wikipedia.org") else {
            return
        }
        let countOfEntriesToCreate = moc.wmf_numberValue(forKey: "WMFCountOfEntriesToCreate")?.int64Value ?? 10
        
        let randomArticleFetcher = WMFRandomArticleFetcher()
        let taskGroup = WMFTaskGroup()
        try moc.wmf_batchProcessObjects { (list: ReadingList) in
            do {
                var results: [MWKSearchResult] = []
                for i in 1...countOfEntriesToCreate {
                    taskGroup.enter()
                    randomArticleFetcher.fetchRandomArticle(withSiteURL: siteURL, failure: { (failure) in
                        taskGroup.leave()
                    }, success: { (searchResult) in
                        results.append(searchResult)
                        taskGroup.leave()
                    })
                    if i % 16 == 0 || i == countOfEntriesToCreate {
                        taskGroup.wait()
                        let articleURLs = results.flatMap { $0.articleURL(forSiteURL: siteURL) }
                        taskGroup.enter()
                        var summaryResponses: [String: [String: Any]] = [:]
                        URLSession.shared.wmf_fetchArticleSummaryResponsesForArticles(withURLs: articleURLs, completion: { (actualSummaryResponses) in
                            // workaround this method not being async
                            summaryResponses = actualSummaryResponses
                            taskGroup.leave()
                        })
                        taskGroup.wait()
                        let articles = try moc.wmf_createOrUpdateArticleSummmaries(withSummaryResponses: summaryResponses)
                        try readingListsController.add(articles: articles, to: list, in: moc)
                        try moc.save()
                        results.removeAll(keepingCapacity: true)
                    }
                }
            } catch let error {
                DDLogError("error populating lists: \(error)")
            }
        }
    }
}
