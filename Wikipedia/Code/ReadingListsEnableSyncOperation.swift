import UIKit

class ReadingListsEnableSyncOperation: ReadingListsOperation {
    
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
                        try moc.wmf_batchProcessObjects(matchingPredicate: NSPredicate(format: "savedDate != NULL"), handler: { (article: WMFArticle) in
                            self.readingListsController.unsave(article)
                        })
                    }
                    let setup = {
                        self.apiController.setupReadingLists(completion: { (error) in
                            DispatchQueue.main.async {
                                if let error = error {
                                    DDLogError("Error enabling sync: \(error)")
                                    self.dataStore.viewContext.wmf_setValue(NSNumber(value: false), forKey: self.readingListsController.isSyncEnabledKey)
                                    self.finish(with: error)
                                } else {
                                    self.finish()
                                }
                            }
                        })
                    }
                    if self.shouldDeleteRemoteLists {
                        self.apiController.teardownReadingLists(completion: { (error) in
                            DispatchQueue.main.async {
                                if let error = error {
                                    DDLogError("Error disabling sync: \(error)")
                                    self.finish(with: error)
                                } else {
                                    setup()
                                }
                            }
                        })
                    } else {
                        setup()
                    }
                    
                } catch let error {
                    DDLogError("Error disabling sync: \(error)")
                    self.dataStore.viewContext.wmf_setValue(NSNumber(value: true), forKey: self.readingListsController.isSyncEnabledKey)
                    self.finish(with: error)
                }
            })
        }
        
        
    }
}
