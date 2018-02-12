import UIKit

class ReadingListsEnableSyncOperation: ReadingListsOperation {
    override func execute() {
        apiController.setupReadingLists(completion: { (error) in
            DispatchQueue.main.async {
                if let error = error {
                    DDLogError("Error enabling sync: \(error)")
                    self.dataStore.viewContext.wmf_setValue(NSNumber(value: false), forKey: self.readingListsController.isSyncEnabledKey)
                }
                self.finish()
            }
        })
    }
}
