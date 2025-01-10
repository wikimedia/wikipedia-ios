import CocoaLumberjackSwift

class RemoteNotificationsImportOperation: RemoteNotificationsPagingOperation, @unchecked Sendable {
    
    // MARK: Overrides
    
    override var shouldExecute: Bool {
        // isAlreadyImported computed property fetches a persisted flag
        return !isAlreadyImported
    }
    
    override var initialContinueId: String? {
        // continueId computed property fetches a persisted continue id, so we can pick up importing where we left off
        return continueId
    }
    
    override func didFetchAndSaveAllPages() {
        saveLanguageAsImportCompleted()
    }
    
    override func willFetchAndSaveNewPage(newContinueId: String) {
        saveContinueId(newContinueId)
    }
    
    // MARK: Private
    
    private func saveLanguageAsImportCompleted() {
        let key = RemoteNotificationsModelController.LibraryKey.completedImportFlags.fullKeyForProject(project)
        setAlreadyImported(true, forKey: key)
    }
    
    private func saveContinueId(_ continueId: String) {
        let key = RemoteNotificationsModelController.LibraryKey.continueIdentifer.fullKeyForProject(project)
        setContinueId(continueId, forKey: key)
    }
}

// MARK: Library Key Value helpers

private extension RemoteNotificationsImportOperation {
    var continueId: String? {
        
        let key = RemoteNotificationsModelController.LibraryKey.continueIdentifer.fullKeyForProject(project)
        return modelController.libraryValue(forKey: key) as? String
    }
    
    var isAlreadyImported: Bool {
        return modelController.isProjectAlreadyImported(project: project)
    }
    
    func setContinueId(_ continueId: String, forKey key: String) {
        modelController.setLibraryValue(continueId as NSString, forKey: key)
    }
    
    func setAlreadyImported(_ value: Bool, forKey key: String) {
        let nsNumber = NSNumber(value: value)
        modelController.setLibraryValue(nsNumber, forKey: key)
    }
}
