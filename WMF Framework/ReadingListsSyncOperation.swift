import CocoaLumberjackSwift

internal enum ReadingListsOperationError: Error {
    case cancelled
}

internal class ReadingListsSyncOperation: ReadingListsOperation {
    var syncedReadingListsCount = 0
    var syncedReadingListEntriesCount = 0
    
    override func execute() {
        syncedReadingListsCount = 0
        syncedReadingListEntriesCount = 0
        
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
                        let readingListsController = self.readingListsController
                        DispatchQueue.main.async {
                            guard let oldState = readingListsController?.syncState else {
                                return
                            }
                            var newState = oldState
                            newState.insert(.needsSync)
                            if newState != oldState {
                                readingListsController?.syncState = newState
                            }
                            self.finish()
                            DispatchQueue.main.async {
                                readingListsController?.sync()
                            }
                        }
                    }  else if let readingListError = error as? ReadingListsOperationError, readingListError == .cancelled {
                        self.apiController.cancelAllTasks()
                        self.finish()
                    } else {
                        self.finish(with: error)
                    }
                }
            }
        }
    }
    
    func executeSync(on moc: NSManagedObjectContext) throws {
        
        let syncEndpointsAreAvailable = moc.wmf_isSyncRemotelyEnabled
        
        let rawSyncState = moc.wmf_numberValue(forKey: WMFReadingListSyncStateKey)?.int64Value ?? 0
        var syncState = ReadingListSyncState(rawValue: rawSyncState)
        
        let taskGroup = WMFTaskGroup()
        
        let hasValidLocalCredentials = apiController.session.hasValidCentralAuthCookies(for: Configuration.current.wikipediaCookieDomain)
    
        if syncEndpointsAreAvailable && syncState.contains(.needsRemoteDisable) && hasValidLocalCredentials {
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
            try executeRandomArticlePopulation(in: moc, englishOnly: false)
            syncState.remove(.needsRandomEntries)
            moc.wmf_setValue(NSNumber(value: syncState.rawValue), forKey: WMFReadingListSyncStateKey)
            try moc.save()
        } else if syncState.contains(.needsRandomEnEntries) {
            try executeRandomArticlePopulation(in: moc, englishOnly: true)
            syncState.remove(.needsRandomEnEntries)
            moc.wmf_setValue(NSNumber(value: syncState.rawValue), forKey: WMFReadingListSyncStateKey)
            try moc.save()
        }
        
        if syncState.contains(.needsLocalReset) {
            try moc.wmf_batchProcessObjects(handler: { (readingListEntry: ReadingListEntry) in
                readingListEntry.readingListEntryID = nil
                readingListEntry.isUpdatedLocally = true
                readingListEntry.errorCode = nil
                guard !self.isCancelled else {
                    throw ReadingListsOperationError.cancelled
                }
            })
            try moc.wmf_batchProcessObjects(handler: { (readingList: ReadingList) in
                readingList.readingListID = nil
                readingList.isUpdatedLocally = true
                readingList.errorCode = nil
                guard !self.isCancelled else {
                    throw ReadingListsOperationError.cancelled
                }
            })
            syncState.remove(.needsLocalReset)
            moc.wmf_setValue(NSNumber(value: syncState.rawValue), forKey: WMFReadingListSyncStateKey)
            try moc.save()
            moc.reset()
        }
        
        if syncState.contains(.needsLocalListClear) {
            try moc.wmf_batchProcess(matchingPredicate: NSPredicate(format: "isDefault != YES"), handler: { (lists: [ReadingList]) in
                try self.readingListsController.markLocalDeletion(for: lists)
                guard !self.isCancelled else {
                    throw ReadingListsOperationError.cancelled
                }
            })
            
            syncState.remove(.needsLocalListClear)
            moc.wmf_setValue(NSNumber(value: syncState.rawValue), forKey: WMFReadingListSyncStateKey)
            try moc.save()
        }
        
        if syncState.contains(.needsLocalArticleClear) {
            try moc.wmf_batchProcess(matchingPredicate: NSPredicate(format: "savedDate != NULL"), handler: { (articles: [WMFArticle]) in
                self.readingListsController.unsave(articles, in: moc)
                guard !self.isCancelled else {
                    throw ReadingListsOperationError.cancelled
                }
            })
        
            syncState.remove(.needsLocalArticleClear)
            moc.wmf_setValue(NSNumber(value: syncState.rawValue), forKey: WMFReadingListSyncStateKey)
            try moc.save()
        }
        
        let localSyncOnly = {
            try self.executeLocalOnlySync(on: moc)
            try moc.save()
            self.finish()
        }
        
        guard hasValidLocalCredentials else {
            try localSyncOnly()
            return
        }
        
        // local only sync
        guard syncState != [] else {
            if syncEndpointsAreAvailable {
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
                        self.readingListsController.postReadingListsServerDidConfirmSyncWasEnabledForAccountNotification(true)
                        self.finish()
                    }
                } else {
                    if let apiError = updateError as? APIReadingListError, apiError == .notSetup {
                        readingListsController.postReadingListsServerDidConfirmSyncWasEnabledForAccountNotification(false)
                    }
                    try localSyncOnly()
                }
            } else {
                readingListsController.postReadingListsServerDidConfirmSyncWasEnabledForAccountNotification(false)
                try localSyncOnly()
            }
            return
        }
        
        guard syncEndpointsAreAvailable else {
            self.finish()
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
                self.readingListsController.postReadingListsServerDidConfirmSyncWasEnabledForAccountNotification(true)
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
        guard !isCancelled  else {
            throw ReadingListsOperationError.cancelled
        }
        
        if let getAllAPIReadingListsError = getAllAPIReadingListsError {
            throw getAllAPIReadingListsError
        }
        
        let group = WMFTaskGroup()
        
        syncedReadingListsCount += try createOrUpdate(remoteReadingLists: allAPIReadingLists, deleteMissingLocalLists: true, inManagedObjectContext: moc)
        
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
        guard !isCancelled  else {
            throw ReadingListsOperationError.cancelled
        }
        
        for (readingListID, remoteReadingListEntries) in remoteEntriesByReadingListID {
            syncedReadingListEntriesCount += try createOrUpdate(remoteReadingListEntries: remoteReadingListEntries, for: readingListID, deleteMissingLocalEntries: true, inManagedObjectContext: moc)
        }
        
        if let since = nextSince {
            moc.wmf_setValue(since as NSString, forKey: WMFReadingListUpdateKey)
        }
        
        if moc.hasChanges {
            try moc.save()
        }
        
        try processLocalUpdates(in: moc)
        
        guard moc.hasChanges else {
            return
        }
        try moc.save()
    }

    func executeUpdate(on moc: NSManagedObjectContext) throws {
        try processLocalUpdates(in: moc)
        
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
        guard !isCancelled  else {
            throw ReadingListsOperationError.cancelled
        }
        
        if let error = updateError {
            throw error
        }
        
        syncedReadingListsCount += try createOrUpdate(remoteReadingLists: updatedLists, inManagedObjectContext: moc)
        syncedReadingListEntriesCount += try createOrUpdate(remoteReadingListEntries: updatedEntries, inManagedObjectContext: moc)
        
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
        
    func executeRandomArticlePopulation(in moc: NSManagedObjectContext, englishOnly: Bool) throws {
 
        let countOfEntriesToCreate = moc.wmf_numberValue(forKey: "WMFCountOfEntriesToCreate")?.int64Value ?? 10
        
        var maybeSiteURL = URL(string: "https://en.wikipedia.org")
        
        let randomArticleFetcher = RandomArticleFetcher()
        let taskGroup = WMFTaskGroup()
        try moc.wmf_batchProcessObjects { (list: ReadingList) in
            guard !list.isDefault else {
                return
            }
            do {
                var summaryResponses: [WMFInMemoryURLKey: ArticleSummary] = [:]
                for i in 1...countOfEntriesToCreate {
                    
                    if !englishOnly {
                        if let randomLanguage = dataStore.languageLinkController.allLanguages.randomElement() {
                            maybeSiteURL = randomLanguage.siteURL
                        }
                    }
                    
                    guard let siteURL = maybeSiteURL else {
                        continue
                    }
                    
                    taskGroup.enter()
                    randomArticleFetcher.fetchRandomArticle(withSiteURL: siteURL, completion: { (error, result, summary) in
                        if let key = result?.wmf_inMemoryKey, let summary = summary {
                           summaryResponses[key] = summary
                        }
                        taskGroup.leave()
                    })
                    if i % 16 == 0 || i == countOfEntriesToCreate {
                        taskGroup.wait()
                        guard !isCancelled  else {
                            throw ReadingListsOperationError.cancelled
                        }
                        let articlesByKey = try moc.wmf_createOrUpdateArticleSummmaries(withSummaryResponses: summaryResponses)
                        let articles = Array(articlesByKey.values)
                        try readingListsController.add(articles: articles, to: list, in: moc)
                        if let defaultReadingList = moc.defaultReadingList {
                            try readingListsController.add(articles: articles, to: defaultReadingList, in: moc)
                        }
                        try moc.save()
                        summaryResponses.removeAll(keepingCapacity: true)
                    }
                }
            } catch let error {
                DDLogError("error populating lists: \(error)")
            }
        }
    }
    
    private func split(readingList: ReadingList, intoReadingListsOfSize size: Int, in moc: NSManagedObjectContext) throws -> [ReadingList] {
        var newReadingLists: [ReadingList] = []
        
        guard let readingListName = readingList.name else {
            assertionFailure("Missing reading list name")
            return newReadingLists
        }
        
        let entries = Array(readingList.entries ?? [])
        let entriesCount = Int(readingList.countOfEntries)
        
        let splitEntriesArrays = stride(from: size, to: entriesCount, by: size).map {
            Array(entries[$0..<min($0 + size, entriesCount)])
        }
        
        for (index, splitEntries) in splitEntriesArrays.enumerated() {
            guard let newReadingList = NSEntityDescription.insertNewObject(forEntityName: "ReadingList", into: moc) as? ReadingList else {
                continue
            }
            let splitIndex = index + 1
            var newReadingListName = "\(readingListName)_\(splitIndex)"
            while try readingListsController.listExists(with: newReadingListName, in: moc) {
                newReadingListName = "\(newReadingListName)_\(splitIndex)"
            }
            newReadingList.name = newReadingListName
            newReadingList.createdDate = NSDate()
            newReadingList.updatedDate = newReadingList.createdDate
            newReadingList.isUpdatedLocally = true
            for splitEntry in splitEntries {
                splitEntry.list = newReadingList
                splitEntry.isUpdatedLocally = true
            }
            readingList.isUpdatedLocally = true
            try readingList.updateArticlesAndEntries()
            try newReadingList.updateArticlesAndEntries()
            newReadingLists.append(newReadingList)
        }
        newReadingLists.append(readingList)
        if !newReadingLists.isEmpty {
            let userInfo = [ReadingListsController.readingListsWereSplitNotificationEntryLimitKey: size]
            NotificationCenter.default.post(name: ReadingListsController.readingListsWereSplitNotification, object: nil, userInfo: userInfo)
            UserDefaults.standard.wmf_setDidSplitExistingReadingLists(true)
        }
        return newReadingLists
    }
    
    
    func processLocalUpdates(in moc: NSManagedObjectContext) throws {
        let taskGroup = WMFTaskGroup()
        let listsToCreateOrUpdateFetch: NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
        listsToCreateOrUpdateFetch.sortDescriptors = [NSSortDescriptor(keyPath: \ReadingList.createdDate, ascending: false)]
        listsToCreateOrUpdateFetch.predicate = NSPredicate(format: "isUpdatedLocally == YES")
        let listsToUpdate =  try moc.fetch(listsToCreateOrUpdateFetch)
        var createdReadingLists: [Int64: ReadingList] = [:]
        var failedReadingLists: [(ReadingList, APIReadingListError)] = []
        var updatedReadingLists: [Int64: ReadingList] = [:]
        var deletedReadingLists: [Int64: ReadingList] = [:]
        var listsToCreate: [ReadingList] = []
        var requestCount = 0
        for localReadingList in listsToUpdate {
            autoreleasepool {
                guard let readingListName = localReadingList.name else {
                    moc.delete(localReadingList)
                    return
                }
                guard let readingListID = localReadingList.readingListID?.int64Value else {
                    if localReadingList.isDeletedLocally || localReadingList.canonicalName == nil {
                        // if it has no id and is deleted locally, it can just be deleted
                        moc.delete(localReadingList)
                    } else if !localReadingList.isDefault {
                        let entryLimit = moc.wmf_readingListsConfigMaxListsPerUser
                        if localReadingList.countOfEntries > entryLimit && !UserDefaults.standard.wmf_didSplitExistingReadingLists() {
                            if let splitReadingLists = try? split(readingList: localReadingList, intoReadingListsOfSize: entryLimit, in: moc) {
                                listsToCreate.append(contentsOf: splitReadingLists)
                            }
                        } else {
                            listsToCreate.append(localReadingList)
                        }
                    }
                    return
                }
                if localReadingList.isDeletedLocally {
                    requestCount += 1
                    taskGroup.enter()
                    self.apiController.deleteList(withListID: readingListID, completion: { (deleteError) in
                        defer {
                            taskGroup.leave()
                        }
                        guard deleteError == nil else {
                            DDLogError("Error deleting reading list: \(String(describing: deleteError))")
                            return
                        }
                        deletedReadingLists[readingListID] = localReadingList
                    })
                } else if localReadingList.isUpdatedLocally {
                    requestCount += 1
                    taskGroup.enter()
                    self.apiController.updateList(withListID: readingListID, name: readingListName, description: localReadingList.readingListDescription, completion: { (updateError) in
                        defer {
                            taskGroup.leave()
                        }
                        guard updateError == nil else {
                            DDLogError("Error updating reading list: \(String(describing: updateError))")
                            return
                        }
                        updatedReadingLists[readingListID] = localReadingList
                    })
                }
            }
        }
        

        let listNamesAndDescriptionsToCreate: [(name: String, description: String?)] = listsToCreate.map {
            assert($0.canonicalName != nil)
            return (name: $0.canonicalName ?? "", description: $0.readingListDescription)
        }
        var start = 0
        var end = 0
        while end < listNamesAndDescriptionsToCreate.count {
            end = min(listNamesAndDescriptionsToCreate.count, start + WMFReadingListBatchSizePerRequestLimit)
            autoreleasepool {
                taskGroup.enter()
                let listsToCreateSubarray = Array(listsToCreate[start..<end])
                let namesAndDescriptionsSubarray = Array(listNamesAndDescriptionsToCreate[start..<end])
                self.apiController.createLists(namesAndDescriptionsSubarray, completion: { (readingListIDs, createError) in
                    defer {
                        taskGroup.leave()
                    }
                    guard let readingListIDs = readingListIDs else {
                        DDLogError("Error creating reading list: \(String(describing: createError))")
                        if let apiError = createError as? APIReadingListError {
                            for list in listsToCreateSubarray {
                                failedReadingLists.append((list, apiError))
                            }
                        }
                        return
                    }
                    for (index, readingList) in readingListIDs.enumerated() {
                        guard index < listsToCreateSubarray.count else {
                            break
                        }
                        let localReadingList = listsToCreateSubarray[index]
                        guard let readingListID = readingList.0 else {
                            if let apiError = readingList.1 as? APIReadingListError {
                                failedReadingLists.append((localReadingList, apiError))
                            }
                            continue
                        }
                        createdReadingLists[readingListID] = localReadingList
                    }
                })
            }
            start = end
        }
        taskGroup.wait()
        guard !isCancelled  else {
            throw ReadingListsOperationError.cancelled
        }
        
        for (readingListID, localReadingList) in createdReadingLists {
            localReadingList.readingListID = NSNumber(value: readingListID)
            localReadingList.isUpdatedLocally = false
        }
        
        for (_, localReadingList) in updatedReadingLists {
            localReadingList.isUpdatedLocally = false
        }
        
        for (_, localReadingList) in deletedReadingLists {
            moc.delete(localReadingList)
        }
        
        for failed in failedReadingLists {
            failed.0.errorCode = failed.1.rawValue
        }
        
        let entriesToCreateOrUpdateFetch: NSFetchRequest<ReadingListEntry> = ReadingListEntry.fetchRequest()
        entriesToCreateOrUpdateFetch.predicate = NSPredicate(format: "isUpdatedLocally == YES")
        entriesToCreateOrUpdateFetch.sortDescriptors = [NSSortDescriptor(keyPath: \ReadingListEntry.createdDate, ascending: false)]
        let localReadingListEntriesToUpdate =  try moc.fetch(entriesToCreateOrUpdateFetch)
        
       
        var deletedReadingListEntries: [Int64: ReadingListEntry] = [:]
        var entriesToAddByListID: [Int64: [(project: String, title: String, entry: ReadingListEntry)]] = [:]
        
        for localReadingListEntry in localReadingListEntriesToUpdate {
            try autoreleasepool {
                guard let articleKey = localReadingListEntry.articleKey, let articleURL = URL(string: articleKey), let project = articleURL.wmf_site?.absoluteString, let title = articleURL.wmf_title else {
                    moc.delete(localReadingListEntry)
                    return
                }
                guard let readingListID = localReadingListEntry.list?.readingListID?.int64Value else {
                    return
                }
                guard let readingListEntryID = localReadingListEntry.readingListEntryID?.int64Value else {
                    if localReadingListEntry.isDeletedLocally {
                        // if it has no id and is deleted locally, it can just be deleted
                        moc.delete(localReadingListEntry)
                    } else {
                        entriesToAddByListID[readingListID, default: []].append((project: project, title: title, entry: localReadingListEntry))
                    }
                    return
                }
                if localReadingListEntry.isDeletedLocally {
                    requestCount += 1
                    taskGroup.enter()
                    self.apiController.removeEntry(withEntryID: readingListEntryID, fromListWithListID: readingListID, completion: { (deleteError) in
                        defer {
                            taskGroup.leave()
                        }
                        guard deleteError == nil else {
                            DDLogError("Error deleting reading list entry: \(String(describing: deleteError))")
                            return
                        }
                        deletedReadingListEntries[readingListEntryID] = localReadingListEntry
                    })
                    if requestCount % WMFReadingListBatchSizePerRequestLimit == 0 {
                        taskGroup.wait()
                        for (_, localReadingListEntry) in deletedReadingListEntries {
                            moc.delete(localReadingListEntry)
                        }
                        deletedReadingListEntries.removeAll(keepingCapacity: true)
                        try moc.save()
                        guard !isCancelled  else {
                            throw ReadingListsOperationError.cancelled
                        }
                    }
                } else {
                    // there's no "updating" of an entry currently
                    localReadingListEntry.isUpdatedLocally = false
                }
            }
        }
        
        taskGroup.wait()
        
        for (_, localReadingListEntry) in deletedReadingListEntries {
            moc.delete(localReadingListEntry)
        }
        
        try moc.save()
        
        guard !isCancelled  else {
            throw ReadingListsOperationError.cancelled
        }
        
        for (readingListID, entries) in entriesToAddByListID {
            var start = 0
            var end = 0
            while end < entries.count {
                end = min(entries.count, start + WMFReadingListBatchSizePerRequestLimit)
                try autoreleasepool {
                    var createdReadingListEntries: [Int64: ReadingListEntry] = [:]
                    var failedReadingListEntries: [(ReadingListEntry, APIReadingListError)] = []
                    requestCount += 1
                    taskGroup.enter()
                    let entrySubarray = Array(entries[start..<end])
                    let entryProjectAndTitles = entrySubarray.map { (project: $0.project, title: $0.title) }
                    self.apiController.addEntriesToList(withListID: readingListID, entries: entryProjectAndTitles, completion: { (readingListEntryIDs, createError) in
                        defer {
                            taskGroup.leave()
                        }
                        guard let readingListEntryIDs = readingListEntryIDs else {
                            DDLogError("Error creating reading list entry: \(String(describing: createError))")
                            if let apiError = createError as? APIReadingListError {
                                for entry in entrySubarray {
                                    failedReadingListEntries.append((entry.entry, apiError))
                                }
                            }
                            return
                        }
                        for (index, readingListEntryIDOrError) in readingListEntryIDs.enumerated() {
                            guard index < entrySubarray.count else {
                                break
                            }
                            let localReadingListEntry = entrySubarray[index].entry
                            
                            guard let readingListEntryID = readingListEntryIDOrError.0 else {
                                if let apiError = readingListEntryIDOrError.1 as? APIReadingListError {
                                    failedReadingListEntries.append((localReadingListEntry, apiError))
                                }
                                continue
                            }
                            createdReadingListEntries[readingListEntryID] = localReadingListEntry
                        }
                        
                    })
                    taskGroup.wait()
                    for (readingListEntryID, localReadingListEntry) in createdReadingListEntries {
                        localReadingListEntry.readingListEntryID = NSNumber(value: readingListEntryID)
                        localReadingListEntry.isUpdatedLocally = false
                    }
                    for failed in failedReadingListEntries {
                        failed.0.errorCode = failed.1.rawValue
                    }
                    if moc.hasChanges {
                        try moc.save()
                    }
                    guard !isCancelled  else {
                        throw ReadingListsOperationError.cancelled
                    }
                }
                start = end
            }
            
        }
    }
    
    // Given a remote reading list entry, returns a URL with its language variant code set.
    // For languages without variants, language variant code is nil.
    // For languages with variants, uses a best guess heuristic searching app preferred languages,
    // then OS preferred languages/locales, then an app-defined fallback.
    private func variantAwareURLForRemoteEntry(_ remoteEntry: APIReadingListEntry) -> URL? {
        guard let articleURL = remoteEntry.articleURL  else {
            return nil
        }
        let preferredLanguageVariantCode = dataStore.languageLinkController.preferredLanguageVariantCode(forLanguageCode: articleURL.wmf_language)
        var variantAwareArticleURL = articleURL
        variantAwareArticleURL.wmf_languageVariantCode = preferredLanguageVariantCode
        return variantAwareArticleURL
    }
    
    // Code using RemoteReadingListArticleKey as a key coordinate between remote and local readling list entries.
    // This key is the articleKey value which *does not* take language variants into account.
    // Collections using the WMFInMemoryURLKey *do* take language variants into account.
    internal func locallyCreate(_ readingListEntries: [APIReadingListEntry], with readingListsByEntryID: [Int64: ReadingList]? = nil, in moc: NSManagedObjectContext) throws {
        guard !readingListEntries.isEmpty else {
            return
        }
        let summaryFetcher = ArticleFetcher(session: apiController.session, configuration: Configuration.current)
        let group = WMFTaskGroup()
        let semaphore = DispatchSemaphore(value: 1)
        var remoteEntriesToCreateLocallyByArticleKey: [WMFInMemoryURLKey: APIReadingListEntry] = [:]
        var requestedArticleKeys: Set<RemoteReadingListArticleKey> = []
        var articleSummariesByArticleKey: [WMFInMemoryURLKey: ArticleSummary] = [:]
        var entryCount = 0
        var articlesByKey: [WMFInMemoryURLKey: WMFArticle] = [:]
        for remoteEntry in readingListEntries {
            autoreleasepool {
                let isDeleted = remoteEntry.deleted ?? false
                guard !isDeleted else {
                    return
                }
                
                guard let variantAwareArticleURL = variantAwareURLForRemoteEntry(remoteEntry),
                      let variantAwareArticleKey = variantAwareArticleURL.wmf_inMemoryKey,
                      let remoteArticleKey = remoteEntry.articleKey else {
                    return
                }
                
                remoteEntriesToCreateLocallyByArticleKey[variantAwareArticleKey] = remoteEntry
                guard !requestedArticleKeys.contains(remoteArticleKey) else {
                    return
                }
                requestedArticleKeys.insert(remoteArticleKey)
                if let article = dataStore.fetchArticle(with: variantAwareArticleURL, in: moc) {
                    articlesByKey[variantAwareArticleKey] = article
                } else {
                    group.enter()
                    summaryFetcher.fetchSummaryForArticle(with: variantAwareArticleKey, completion: { (result, response, error) in
                        guard let result = result else {
                            group.leave()
                            return
                        }
                        semaphore.wait()
                        articleSummariesByArticleKey[variantAwareArticleKey] = result
                        semaphore.signal()
                        group.leave()
                    })
                    entryCount += 1
                }
            }
        }
        
        group.wait()
        guard !isCancelled  else {
            throw ReadingListsOperationError.cancelled
        }
        
        let updatedArticlesByKey = try moc.wmf_createOrUpdateArticleSummmaries(withSummaryResponses: articleSummariesByArticleKey)
        articlesByKey.merge(updatedArticlesByKey, uniquingKeysWith: { (a, b) in return a })
        var finalReadingListsByEntryID: [Int64: ReadingList]
        if let readingListsByEntryID = readingListsByEntryID {
            finalReadingListsByEntryID = readingListsByEntryID
        } else {
            finalReadingListsByEntryID = [:]
            var readingListsByReadingListID: [Int64: ReadingList] = [:]
            let localReadingListsFetch: NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
            localReadingListsFetch.predicate = NSPredicate(format: "readingListID IN %@", readingListEntries.compactMap { $0.listId } )
            let localReadingLists = try moc.fetch(localReadingListsFetch)
            for localReadingList in localReadingLists {
                guard let localReadingListID = localReadingList.readingListID?.int64Value else {
                    continue
                }
                readingListsByReadingListID[localReadingListID] = localReadingList
            }
            for readingListEntry in readingListEntries {
                guard let listId = readingListEntry.listId, let readingList = readingListsByReadingListID[listId] else {
                    DDLogError("Missing list for reading list entry: \(readingListEntry)")
                    throw APIReadingListError.needsFullSync
                }
                finalReadingListsByEntryID[readingListEntry.id] = readingList
            }
        }
        
        var updatedLists: Set<ReadingList> = []
        for (variantAwareArticleKey, remoteEntry) in remoteEntriesToCreateLocallyByArticleKey {
            autoreleasepool {
                guard let readingList = finalReadingListsByEntryID[remoteEntry.id] else {
                    return
                }
                
                var fetchedArticle = articlesByKey[variantAwareArticleKey]
                if fetchedArticle == nil {
                    if let newArticle = dataStore.fetchArticle(withKey: variantAwareArticleKey.databaseKey, variant: variantAwareArticleKey.languageVariantCode, in: moc) {
                        if newArticle.displayTitleHTML == "" {
                            newArticle.displayTitleHTML = remoteEntry.title
                        }
                        fetchedArticle = newArticle
                    }
                }
                
                guard let article = fetchedArticle else {
                    return
                }
                
                var entry = ReadingListEntry(context: moc)
                entry.update(with: remoteEntry)
    
                // if there's a key mismatch, locally delete the bad entry and create a new one with the correct key
                // Note the remote entry has no variant info, so its *articleKey* should match the article *key* property.
                // Comparing inMemoryKey values leads to a mismatch since the article will potentially have variant info
                if remoteEntry.articleKey != article.key {
                    entry.list = readingList
                    entry.articleKey = remoteEntry.articleKey
                    try? readingListsController.markLocalDeletion(for: [entry])
                    entry = ReadingListEntry(context: moc)
                    entry.update(with: remoteEntry)
                    entry.readingListEntryID = nil
                    entry.isUpdatedLocally = true
                }
                
                if entry.createdDate == nil {
                    entry.createdDate = NSDate()
                }
                if entry.updatedDate == nil {
                    entry.updatedDate = entry.createdDate
                }
                entry.list = readingList
                entry.articleKey = article.key
                entry.variant = article.variant
                entry.displayTitle = article.displayTitle
                if article.savedDate == nil {
                    article.savedDate = entry.createdDate as Date?
                }
                updatedLists.insert(readingList)
            }
        }
        for readingList in updatedLists {
            try autoreleasepool {
                try readingList.updateArticlesAndEntries()
            }
        }
    }
    
    internal func createOrUpdate(remoteReadingLists: [APIReadingList], deleteMissingLocalLists: Bool = false, inManagedObjectContext moc: NSManagedObjectContext) throws -> Int {
        guard !remoteReadingLists.isEmpty || deleteMissingLocalLists else {
            return 0
        }
        var createdOrUpdatedReadingListsCount = 0
        // Arrange remote lists by ID and name for merging with local lists
        var remoteReadingListsByID: [Int64: APIReadingList] = [:]
        var remoteReadingListsByName: [String: [Int64: APIReadingList]] = [:] // server still allows multiple lists with the same name
        var remoteDefaultReadingList: APIReadingList? = nil
        for remoteReadingList in remoteReadingLists {
            if remoteReadingList.isDefault {
                remoteDefaultReadingList = remoteReadingList
            }
            remoteReadingListsByID[remoteReadingList.id] = remoteReadingList
            remoteReadingListsByName[remoteReadingList.name.precomposedStringWithCanonicalMapping, default: [:]][remoteReadingList.id] = remoteReadingList
        }
        
        if let remoteDefaultReadingList = remoteDefaultReadingList {
            let defaultReadingList = moc.defaultReadingList
            defaultReadingList?.readingListID = NSNumber(value: remoteDefaultReadingList.id)
        }
        
        let localReadingListsFetch: NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
        let localReadingLists = try moc.fetch(localReadingListsFetch)
        var localListsMissingRemotely: [ReadingList] = []
        for localReadingList in localReadingLists {
            var remoteReadingList: APIReadingList?
            if let localReadingListID = localReadingList.readingListID?.int64Value {
                // remove from the dictionary because we will create any lists left in the dictionary
                if let remoteReadingListByID = remoteReadingListsByID.removeValue(forKey: localReadingListID) {
                    remoteReadingListsByName[remoteReadingListByID.name]?.removeValue(forKey: remoteReadingListByID.id)
                    remoteReadingList = remoteReadingListByID
                }
            }
            
            if remoteReadingList == nil {
                if localReadingList.readingListID == nil, let localReadingListName = localReadingList.name?.precomposedStringWithCanonicalMapping {
                    if let remoteReadingListByName = remoteReadingListsByName[localReadingListName]?.values.first {
                        // remove from the dictionary because we will create any lists left in this dictionary
                        remoteReadingListsByID.removeValue(forKey: remoteReadingListByName.id)
                        remoteReadingList = remoteReadingListByName
                    }
                }
            }
            
            guard let remoteReadingListForUpdate = remoteReadingList else {
                if localReadingList.readingListID != nil {
                    localListsMissingRemotely.append(localReadingList)
                }
                continue
            }
            
            let isDeleted = remoteReadingListForUpdate.deleted ?? false
            if isDeleted {
                try readingListsController.markLocalDeletion(for: [localReadingList])
                moc.delete(localReadingList) // object can be removed since we have the server-side update
                createdOrUpdatedReadingListsCount += 1
            } else {
                localReadingList.update(with: remoteReadingListForUpdate)
                createdOrUpdatedReadingListsCount += 1
            }
        }
        
        if deleteMissingLocalLists {
            // Delete missing reading lists
            try readingListsController.markLocalDeletion(for: localListsMissingRemotely)
            for readingList in localListsMissingRemotely {
                moc.delete(readingList)
                createdOrUpdatedReadingListsCount += 1
            }
        }
        
        // create any list that wasn't matched by ID or name
        for (_, remoteReadingList) in remoteReadingListsByID {
            let isDeleted = remoteReadingList.deleted ?? false
            guard !isDeleted else {
                continue
            }
            guard let localList = NSEntityDescription.insertNewObject(forEntityName: "ReadingList", into: moc) as? ReadingList else {
                continue
            }
            localList.update(with: remoteReadingList)
            if localList.createdDate == nil {
                localList.createdDate = NSDate()
            }
            if localList.updatedDate == nil {
                localList.updatedDate = localList.createdDate
            }
            createdOrUpdatedReadingListsCount += 1
        }
        return createdOrUpdatedReadingListsCount
    }
    
    // This method uses RemoteReadingListArticleKey as a key to coordinate between remote and local readling list entries.
    // This key is the articleKey value which *does not* take language variants into account.
    // Since APIReadingListEntry does not support language variants, this is the desired behavior.
    internal func createOrUpdate(remoteReadingListEntries: [APIReadingListEntry], for readingListID: Int64? = nil, deleteMissingLocalEntries: Bool = false, inManagedObjectContext moc: NSManagedObjectContext) throws -> Int {
        guard !remoteReadingListEntries.isEmpty || deleteMissingLocalEntries else {
            return 0
        }
        var createdOrUpdatedReadingListEntriesCount = 0
        // Arrange remote list entries by ID and key for merging with local lists
        var remoteReadingListEntriesByReadingListID: [Int64: [RemoteReadingListArticleKey: APIReadingListEntry]] = [:]
        
        if let readingListID = readingListID {
            remoteReadingListEntriesByReadingListID[readingListID] = [:]
        }
        
        for remoteReadingListEntry in remoteReadingListEntries {
            guard let listID = remoteReadingListEntry.listId ?? readingListID, let articleKey = remoteReadingListEntry.articleKey else {
                DDLogError("missing id or article key for remote entry: \(remoteReadingListEntry)")
                assert(false)
                continue
            }
            
            remoteReadingListEntriesByReadingListID[listID, default: [:]][articleKey] = remoteReadingListEntry
        }
        
        var entriesToDelete: [ReadingListEntry] = []
        for (readingListID, readingListEntriesByKey) in remoteReadingListEntriesByReadingListID {
            try autoreleasepool {

                let localReadingListsFetch: NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
                localReadingListsFetch.predicate = NSPredicate(format: "readingListID == %@", NSNumber(value: readingListID))
                let localReadingLists = try moc.fetch(localReadingListsFetch)
                let localReadingListEntries = localReadingLists.first?.entries?.filter { !$0.isDeletedLocally } ?? []
                
                var localEntriesMissingRemotely: [ReadingListEntry] = []
                var remoteEntriesMissingLocally: [RemoteReadingListArticleKey: APIReadingListEntry] = readingListEntriesByKey
                for localReadingListEntry in localReadingListEntries {
                    guard let articleKey = localReadingListEntry.articleKey else {
                        moc.delete(localReadingListEntry)
                        createdOrUpdatedReadingListEntriesCount += 1
                        continue
                    }
                    
                    guard let remoteReadingListEntryForUpdate: APIReadingListEntry = remoteEntriesMissingLocally.removeValue(forKey: articleKey) else {
                        if localReadingListEntry.readingListEntryID != nil {
                            localEntriesMissingRemotely.append(localReadingListEntry)
                        }
                        continue
                    }
                    
                    let isDeleted = remoteReadingListEntryForUpdate.deleted ?? false
                    if isDeleted {
                        entriesToDelete.append(localReadingListEntry)
                        createdOrUpdatedReadingListEntriesCount += 1
                    } else {
                        localReadingListEntry.update(with: remoteReadingListEntryForUpdate)
                        createdOrUpdatedReadingListEntriesCount += 1
                    }
                }
                
                if deleteMissingLocalEntries {
                    entriesToDelete.append(contentsOf: localEntriesMissingRemotely)
                }
                
                try readingListsController.markLocalDeletion(for: entriesToDelete)
                for entry in entriesToDelete {
                    moc.delete(entry)
                    createdOrUpdatedReadingListEntriesCount += 1
                }
                
                try moc.save()
                moc.reset()
                
                // create any entry that wasn't matched
                var start = 0
                var end = 0
                let entries = Array(remoteEntriesMissingLocally.values)
                while end < entries.count {
                    end = min(entries.count, start + WMFReadingListCoreDataBatchSize)
                    try locallyCreate(Array(entries[start..<end]), in: moc)
                    start = end
                    try moc.save()
                    moc.reset()
                    createdOrUpdatedReadingListEntriesCount += 1
                }
            }
        }
        return createdOrUpdatedReadingListEntriesCount
    }
}
