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
                                
                                try self.readingListsController.processLocalUpdates(in: moc)
                                
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
