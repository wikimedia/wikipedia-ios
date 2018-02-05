internal class ReadingListsUpdateOperation: ReadingListsOperation {
    override func execute() {
        DispatchQueue.main.async {
            self.dataStore.performBackgroundCoreDataOperation(onATemporaryContext: { (moc) in
                guard let since = moc.wmf_stringValue(forKey: WMFReadingListUpdateKey) else {
                    self.finish()
                    return
                }
                
                self.apiController.updatedListsAndEntries(since: since, completion: { (updatedLists, updatedEntries, error) in
                    DispatchQueue.main.async {
                        self.dataStore.performBackgroundCoreDataOperation(onATemporaryContext: { (moc) in
                            defer {
                                self.finish()
                            }
                            do {
                                let listSinceDate = try self.readingListsController.createOrUpdate(remoteReadingLists: updatedLists, inManagedObjectContext: moc)
                                let entrySinceDate = try self.readingListsController.createOrUpdate(remoteReadingListEntries: updatedEntries, inManagedObjectContext: moc)
                                let sinceDate: Date = listSinceDate.compare(entrySinceDate) == .orderedAscending ? listSinceDate : entrySinceDate

                                if sinceDate.compare(Date.distantPast) != .orderedSame {
                                    let iso8601String = DateFormatter.wmf_iso8601().string(from: sinceDate)
                                    moc.wmf_setValue(iso8601String as NSString, forKey: WMFReadingListUpdateKey)
                                }
                                
                                let taskGroup = WMFTaskGroup()
                                let listsToCreateOrUpdateFetch: NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
                                listsToCreateOrUpdateFetch.predicate = NSPredicate(format: "isUpdatedLocally == YES")
                                let listsToUpdate =  try moc.fetch(listsToCreateOrUpdateFetch)
                                var createdReadingLists: [Int64: ReadingList] = [:]
                                var updatedReadingLists: [Int64: ReadingList] = [:]
                                var deletedReadingLists: [Int64: ReadingList] = [:]
                                for localReadingList in listsToUpdate {
                                    guard let readingListName = localReadingList.name else {
                                        moc.delete(localReadingList)
                                        continue
                                    }
                                    guard let readingListID = localReadingList.readingListID?.int64Value else {
                                        taskGroup.enter()
                                        self.apiController.createList(name: readingListName, description: localReadingList.readingListDescription, completion: { (readingListID, creationError) in
                                            defer {
                                                taskGroup.leave()
                                            }
                                            guard let readingListID = readingListID else {
                                                DDLogError("Error creating reading list: \(String(describing: creationError))")
                                                return
                                            }
                                            createdReadingLists[readingListID] = localReadingList
                                        })
                                        continue
                                    }
                                    if localReadingList.isDeletedLocally {
                                        taskGroup.enter()
                                        self.apiController.deleteList(withListID: readingListID, completion: { (deleteError) in
                                            defer {
                                                taskGroup.leave()
                                            }
                                            guard error == nil else {
                                                DDLogError("Error deleting reading list: \(String(describing: deleteError))")
                                                return
                                            }
                                            deletedReadingLists[readingListID] = localReadingList
                                        })
                                    } else {
                                        taskGroup.enter()
                                        self.apiController.updateList(withListID: readingListID, name: readingListName, description: localReadingList.readingListDescription, completion: { (updateError) in
                                            defer {
                                                taskGroup.leave()
                                            }
                                            guard error == nil else {
                                                DDLogError("Error deleting reading list: \(String(describing: updateError))")
                                                return
                                            }
                                            updatedReadingLists[readingListID] = localReadingList
                                        })
                                    }
                                }
                                
                                taskGroup.wait()
                                
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
                                
                                
                                let entriesToCreateOrUpdateFetch: NSFetchRequest<ReadingListEntry> = ReadingListEntry.fetchRequest()
                                entriesToCreateOrUpdateFetch.predicate = NSPredicate(format: "isUpdatedLocally == YES")
                                let localReadingListEntriesToUpdate =  try moc.fetch(entriesToCreateOrUpdateFetch)
                                
                                var createdReadingListEntries: [Int64: ReadingListEntry] = [:]
                                var deletedReadingListEntries: [Int64: ReadingListEntry] = [:]

                                for localReadingListEntry in localReadingListEntriesToUpdate {
                                    guard let articleKey = localReadingListEntry.articleKey, let articleURL = URL(string: articleKey), let project = articleURL.wmf_site?.absoluteString, let title = articleURL.wmf_title else {
                                        moc.delete(localReadingListEntry)
                                        continue
                                    }
                                    guard let readingListID = localReadingListEntry.list?.readingListID?.int64Value else {
                                        continue
                                    }
                                    guard let readingListEntryID = localReadingListEntry.readingListEntryID?.int64Value else {
                                        taskGroup.enter()
                                        self.apiController.addEntryToList(withListID: readingListID, project:project, title: title, completion: { (readingListEntryID, createError) in
                                            defer {
                                                taskGroup.leave()
                                            }
                                            guard let readingListEntryID = readingListEntryID else {
                                                DDLogError("Error creating reading list entry: \(String(describing: createError))")
                                                return
                                            }
                                            createdReadingListEntries[readingListEntryID] = localReadingListEntry
                                        })
                                        continue
                                    }
                                    if localReadingListEntry.isDeletedLocally {
                                        taskGroup.enter()
                                        self.apiController.removeEntry(withEntryID: readingListEntryID, fromListWithListID: readingListID, completion: { (deleteError) in
                                            defer {
                                                taskGroup.leave()
                                            }
                                            guard error == nil else {
                                                DDLogError("Error deleting reading list entry: \(String(describing: deleteError))")
                                                return
                                            }
                                            deletedReadingListEntries[readingListEntryID] = localReadingListEntry
                                        })
                                    } else {
                                        // there's no "updating" of an entry currently
                                        localReadingListEntry.isUpdatedLocally = false
                                    }
                                }
                                
                                taskGroup.wait()
                                
                                for (readingListEntryID, localReadingListEntry) in createdReadingListEntries {
                                    localReadingListEntry.readingListEntryID = NSNumber(value: readingListEntryID)
                                    localReadingListEntry.isUpdatedLocally = false
                                }
                                
                                for (_, localReadingListEntry) in deletedReadingListEntries {
                                    moc.delete(localReadingListEntry)
                                }
                                
                                guard moc.hasChanges else {
                                    return
                                }
                                try moc.save()
                            } catch let error {
                                DDLogError("Error updating reading lists: \(error)")
                            }
                        })
                    }
                })
            })
        }
    }
    
}
