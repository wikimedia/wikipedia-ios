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
                                var sinceDate: Date = Date.distantPast
                                for list in updatedLists {
                                    if let date = DateFormatter.wmf_iso8601().date(from: list.updated),
                                        date.compare(sinceDate) == .orderedDescending {
                                        sinceDate = date
                                    }
                                    
                                }
                                
                                for entry in updatedEntries {
                                    if let date = DateFormatter.wmf_iso8601().date(from: entry.updated),
                                        date.compare(sinceDate) == .orderedDescending {
                                        sinceDate = date
                                    }
                                }
                                
                                if sinceDate.compare(Date.distantPast) != .orderedSame {
                                    let iso8601String = DateFormatter.wmf_iso8601().string(from: sinceDate)
                                    moc.wmf_setValue(iso8601String as NSString, forKey: WMFReadingListUpdateKey)
                                }
                                
//                                let listsToCreateOrUpdateFetch: NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
//                                listsToCreateOrUpdateFetch.predicate = NSPredicate(format: "isUpdatedLocally == YES")
//                                let listsToCreateOrUpdate =  try moc.fetch(listsToCreateOrUpdateFetch)
//
//                                let entriesToCreateOrUpdateFetch: NSFetchRequest<ReadingListEntry> = ReadingListEntry.fetchRequest()
//                                entriesToCreateOrUpdateFetch.predicate = NSPredicate(format: "isUpdatedLocally == YES")
//                                let entriesToCreateOrUpdate =  try moc.fetch(entriesToCreateOrUpdateFetch)
//
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
