internal class ReadingListsSyncOperation: ReadingListsOperation {
    override func execute() {
        readingListsController.apiController.getAllReadingLists { (allAPIReadingLists, getAllAPIReadingListsError) in
            if let error = getAllAPIReadingListsError {
                self.finish(with: error)
                return
            }
            var sinceDate: Date = Date.distantPast
            var remoteReadingListsByID: [Int64: APIReadingList] = [:]
            var remoteReadingListsToCreateLocally: [Int64: APIReadingList] = [:]
            var remoteReadingListsByName: [String: APIReadingList] = [:]
            var remoteDefaultReadingList: APIReadingList?
            for apiReadingList in allAPIReadingLists {
                if apiReadingList.isDefault {
                    remoteDefaultReadingList = apiReadingList
                }
                remoteReadingListsByID[apiReadingList.id] = apiReadingList
                remoteReadingListsToCreateLocally[apiReadingList.id] = apiReadingList
                remoteReadingListsByName[apiReadingList.name.precomposedStringWithCanonicalMapping] = apiReadingList
                if let date = DateFormatter.wmf_iso8601().date(from: apiReadingList.updated),
                    date.compare(sinceDate) == .orderedDescending {
                    sinceDate = date
                }
            }
            DispatchQueue.main.async {
                self.dataStore.performBackgroundCoreDataOperation(onATemporaryContext: { (moc) in
                    let group = WMFTaskGroup()
                    let localReadingListsFetchRequest: NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
                    do {
                        let localReadingLists = try moc.fetch(localReadingListsFetchRequest)
                        var localReadingListsToDelete: [Int64: ReadingList] = [:]
                        var localReadingListsToSync: [Int64: [ReadingList]] = [:]
                        var localReadingListsIdsToMarkLocallyUpdatedFalse: Set<Int64> = []
                        var localDefaultReadingList: ReadingList? = nil
                        for localReadingList in localReadingLists {
                            guard !(localReadingList.isDefault?.boolValue ?? false) else {
                                if localDefaultReadingList != nil {
                                    moc.delete(localReadingList)
                                } else{
                                    localDefaultReadingList = localReadingList
                                    if let defaultReadingListID = remoteDefaultReadingList?.id {
                                        localReadingListsToSync[defaultReadingListID, default: []].append(localReadingList)
                                        remoteReadingListsToCreateLocally.removeValue(forKey: defaultReadingListID)
                                    }
                                }
                                continue
                            }
                            guard let readingListID = localReadingList.readingListID?.int64Value else {
                                let name = localReadingList.name ?? ""
                                if let remoteReadingListWithTheSameName = remoteReadingListsByName[name.precomposedStringWithCanonicalMapping] {
                                    localReadingListsToSync[remoteReadingListWithTheSameName.id, default: []].append(localReadingList)
                                } else {
                                    group.enter()
                                    self.apiController.createList(name: name, description: localReadingList.readingListDescription ?? "", completion: { (listID, error) in
                                        if let listID = listID {
                                            localReadingListsToSync[listID, default: []].append(localReadingList)
                                        }
                                        group.leave()
                                    })
                                }
                                continue
                            }
                            
                            
                            guard let remoteList = remoteReadingListsByID[readingListID] else {
                                localReadingListsToDelete[readingListID] = localReadingList
                                continue
                            }
                            
                            localReadingListsToSync[readingListID, default: []].append(localReadingList)
                            remoteReadingListsToCreateLocally.removeValue(forKey: readingListID)
                            
                            guard !localReadingList.isDeletedLocally else {
                                group.enter()
                                self.apiController.deleteList(withListID: readingListID, completion: { (error) in
                                    if let error = error {
                                        DDLogError("error deleting list with id: \(readingListID) error: \(error)")
                                        localReadingListsToDelete.removeValue(forKey: readingListID)
                                    }
                                    group.leave()
                                })
                                continue
                            }
                            
                            localReadingListsToDelete.removeValue(forKey: readingListID)
                            
                            if localReadingList.isUpdatedLocally {
                                group.enter()
                                self.apiController.updateList(withListID: readingListID, name: localReadingList.name ?? "", description: localReadingList.readingListDescription ?? "", completion: { (error) in
                                    if let error = error {
                                        DDLogError("error updating list with id: \(readingListID) error: \(error)")
                                    } else {
                                        localReadingListsIdsToMarkLocallyUpdatedFalse.insert(readingListID)
                                    }
                                    group.leave()
                                })
                                localReadingList.isUpdatedLocally = false
                            } else {
                                localReadingList.update(with: remoteList)
                            }
                        }
                        
                        group.wait()
                        
                        for (_, list) in remoteReadingListsToCreateLocally {
                            guard let localList = NSEntityDescription.insertNewObject(forEntityName: "ReadingList", into: moc) as? ReadingList else {
                                continue
                            }
                            localList.update(with: list)
                            localReadingListsToSync[list.id, default: []].append(localList)
                        }
                        
                        for (_, list) in localReadingListsToDelete {
                            moc.delete(list)
                        }
                        
                        
                        var entriesByReadingListID: [Int64: [APIReadingListEntry]] = [:]
                        
                        for (readingListID, readingLists) in localReadingListsToSync {
                            guard let readingList = readingLists.first else {
                                continue
                            }
                            
                            guard let remoteList = remoteReadingListsByID[readingListID] else {
                                continue
                            }
                            
                            readingList.update(with: remoteList)
                            
                            if readingList.readingListID == nil {
                                readingList.readingListID = NSNumber(value: readingListID)
                            }
                            
                            if localReadingListsIdsToMarkLocallyUpdatedFalse.contains(readingListID) {
                                readingList.isUpdatedLocally = false
                            }
                            
                            for duplicateReadingList in readingLists[1..<readingLists.count] {
                                if let entries = duplicateReadingList.entries {
                                    readingList.addToEntries(entries)
                                }
                                moc.delete(duplicateReadingList)
                            }
                            
                            group.enter()
                            self.apiController.getAllEntriesForReadingListWithID(readingListID: readingListID, completion: { (entries, error) in
                                if error == nil {
                                    entriesByReadingListID[readingListID] = entries
                                }
                                group.leave()
                            })
                        }
                        
                        group.wait()
                        
                        var localEntriesToSync: [Int64: ReadingListEntry] = [:]
                        var localEntriesToDelete: [ReadingListEntry] = []
                        var remoteEntriesToCreateLocally: [Int64: (APIReadingListEntry, ReadingList)] = [:]
                        
                        for (readingListID, readingLists) in localReadingListsToSync {
                            guard let readingList = readingLists.first else {
                                continue
                            }
                            guard let localEntries = readingList.entries else {
                                continue
                            }
                            let remoteEntries = entriesByReadingListID[readingListID] ?? []
                            //print("List \(readingList.name) has remote entries: \(remoteEntries)")
                            for entry in remoteEntries {
                                remoteEntriesToCreateLocally[entry.id] = (entry, readingList)
                                if let date = DateFormatter.wmf_iso8601().date(from: entry.updated),
                                    date.compare(sinceDate) == .orderedDescending {
                                    sinceDate = date
                                }
                            }
                            for localEntry in localEntries {
                                guard !localEntry.isDeletedLocally else {
                                    // the entry has been deleted locally
                                    guard let entryID = localEntry.readingListEntryID?.int64Value else {
                                        localEntriesToDelete.append(localEntry)  // the entry has been deleted locally but doesn't have an entry ID, so just delete it
                                        continue
                                    }
                                    
                                    remoteEntriesToCreateLocally.removeValue(forKey: entryID)
                                    
                                    group.enter()
                                    self.apiController.removeEntry(withEntryID: entryID, fromListWithListID: readingListID, completion: { (error) in
                                        defer {
                                            group.leave()
                                        }
                                        guard error == nil else {
                                            DDLogError("Error deleting entry withEntryID: \(entryID) fromListWithListID: \(readingListID) error: \(String(describing: error))")
                                            return
                                        }
                                        localEntriesToDelete.append(localEntry)
                                    })
                                    continue
                                }
                                
                                guard let articleURL = localEntry.articleURL, let articleSite = articleURL.wmf_site, let articleTitle = articleURL.wmf_title else {
                                    moc.delete(localEntry)
                                    continue
                                }
                                
                                guard let entryID = localEntry.readingListEntryID?.int64Value else {
                                    group.enter()
                                    self.apiController.addEntryToList(withListID: readingListID, project: articleSite.absoluteString, title: articleTitle, completion: { (entryID, error) in
                                        if let entryID = entryID {
                                            localEntriesToSync[entryID] = localEntry
                                        } else {
                                            DDLogError("Missing entryID for entry: \(articleSite) \(articleTitle) in list: \(readingListID)")
                                        }
                                        group.leave()
                                    })
                                    continue
                                }
                                remoteEntriesToCreateLocally.removeValue(forKey: entryID)
                            }
                        }
                        
                        var remoteEntriesToCreateLocallyByArticleKey: [String: APIReadingListEntry] = [:]
                        var requestedArticleKeys: Set<String> = []
                        var articleSummariesByArticleKey: [String: [String: Any]] = [:]
                        for (_, (remoteEntry, _)) in remoteEntriesToCreateLocally {
                            guard let articleURL = remoteEntry.articleURL, let articleKey = articleURL.wmf_articleDatabaseKey else {
                                continue
                            }
                            remoteEntriesToCreateLocallyByArticleKey[articleKey] = remoteEntry
                            guard !requestedArticleKeys.contains(articleKey) else {
                                continue
                            }
                            requestedArticleKeys.insert(articleKey)
                            group.enter()
                            URLSession.shared.wmf_fetchSummary(with: articleURL, completionHandler: { (result, response, error) in
                                guard let result = result else {
                                    group.leave()
                                    return
                                }
                                articleSummariesByArticleKey[articleKey] = result
                                group.leave()
                            })
                        }
                        
                        group.wait()
                        
                        
                        let articles = try moc.wmf_createOrUpdateArticleSummmaries(withSummaryResponses: articleSummariesByArticleKey)
                        var articlesByKey: [String: WMFArticle] = [:]
                        for article in articles {
                            guard let articleKey = article.key else {
                                continue
                            }
                            articlesByKey[articleKey] = article
                        }
                        
                        for (_, (remoteEntry, readingList)) in remoteEntriesToCreateLocally {
                            guard let articleURL = remoteEntry.articleURL, let articleKey = articleURL.wmf_articleDatabaseKey, let article = articlesByKey[articleKey] else {
                                continue
                            }
                            guard let entry = NSEntityDescription.insertNewObject(forEntityName: "ReadingListEntry", into: moc) as? ReadingListEntry else {
                                continue
                            }
                            entry.update(with: remoteEntry)
                            entry.list = readingList
                            entry.articleKey = article.key
                            entry.displayTitle = article.displayTitle
                            article.savedDate = entry.createdDate as Date?
                            readingList.addToArticles(article)
                            readingList.updateCountOfEntries()
                        }
                        
                        for (entryID, entry) in localEntriesToSync {
                            if entry.readingListEntryID == nil {
                                entry.readingListEntryID = NSNumber(value: entryID)
                            }
                        }
                        
                        for entry in localEntriesToDelete {
                            moc.delete(entry)
                        }
                        
                        if sinceDate.compare(Date.distantPast) != .orderedSame {
                            let iso8601String = DateFormatter.wmf_iso8601().string(from: sinceDate)
                            moc.wmf_setValue(iso8601String as NSString, forKey: WMFReadingListUpdateKey)
                        }
                        
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
