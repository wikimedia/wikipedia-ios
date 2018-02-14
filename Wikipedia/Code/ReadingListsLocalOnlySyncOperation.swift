import UIKit

class ReadingListsLocalOnlySyncOperation: ReadingListsOperation {
    override func execute() {
        DispatchQueue.main.async {
            self.dataStore.performBackgroundCoreDataOperation(onATemporaryContext: { (moc) in
                do {
                    try moc.wmf_batchProcessObjects(matchingPredicate: NSPredicate(format: "isDeletedLocally == YES"), resetAfterSave: true, handler: { (list: ReadingList) in
                        moc.delete(list)
                    })
                    try moc.wmf_batchProcessObjects(matchingPredicate: NSPredicate(format: "isDeletedLocally == YES"), resetAfterSave: true, handler: { (entry: ReadingListEntry) in
                        moc.delete(entry)
                    })
                } catch let error {
                    DDLogError("Error batch processing updates: \(error)")
                }
                self.finish()
            })
        }
    }
}
