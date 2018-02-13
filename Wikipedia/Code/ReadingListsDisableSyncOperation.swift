import UIKit

class ReadingListsDisableSyncOperation: ReadingListsOperation {
    let shouldDeleteLocalLists: Bool
    let shouldDeleteRemoteLists: Bool
    init(readingListsController: ReadingListsController, shouldDeleteLocalLists: Bool, shouldDeleteRemoteLists: Bool) {
        self.shouldDeleteLocalLists = shouldDeleteLocalLists
        self.shouldDeleteRemoteLists = shouldDeleteRemoteLists
        super.init(readingListsController: readingListsController)
    }
    
    override func execute() {
        DispatchQueue.main.async {
            self.dataStore.performBackgroundCoreDataOperation(onATemporaryContext: { (moc) in
                do {
                    if self.shouldDeleteLocalLists {
                        try moc.wmf_batchProcessObjects(matchingPredicate: NSPredicate(format: "savedDate != NULL"), resetAfterSave: true, handler: { (article: WMFArticle) in
                            self.readingListsController.unsave(article)
                        })
                    } else {
                        try moc.wmf_batchProcessObjects(resetAfterSave: true, handler: { (readingList: ReadingList) in
                            readingList.readingListID = nil
                            readingList.isUpdatedLocally = true
                        })
                        try moc.wmf_batchProcessObjects(resetAfterSave: true, handler: { (readingListEntry: ReadingListEntry) in
                            readingListEntry.readingListEntryID = nil
                            readingListEntry.isUpdatedLocally = true
                        })
                    }
                    if self.shouldDeleteRemoteLists {
                        self.apiController.teardownReadingLists(completion: { (error) in
                            DispatchQueue.main.async {
                                if let error = error {
                                    DDLogError("Error disabling sync: \(error)")
                                    self.dataStore.viewContext.wmf_setValue(NSNumber(value: true), forKey: self.readingListsController.isSyncEnabledKey)
                                }
                                self.finish()
                            }
                        })
                    } else {
                        self.finish()
                    }
                } catch let error {
                    DDLogError("Error disabling sync: \(error)")
                    self.dataStore.viewContext.wmf_setValue(NSNumber(value: true), forKey: self.readingListsController.isSyncEnabledKey)
                    self.finish()
                }
            })
        }
    }
}
