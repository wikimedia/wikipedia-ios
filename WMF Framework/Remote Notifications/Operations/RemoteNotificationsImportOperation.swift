import CocoaLumberjackSwift

class RemoteNotificationsImportOperation: RemoteNotificationsPagingOperation {
    
    private enum LibraryKey: String {
        case completedImportFlags = "RemoteNotificationsCompletedImportFlags"
        case continueIdentifer = "RemoteNotificationsContinueIdentifier"
        
        func fullKeyForProject(_ project: RemoteNotificationsProject) -> String {
            return "\(self.rawValue)-\(project.notificationsApiWikiIdentifier)"
        }
    }
    
    //MARK: Overrides
    
    override var shouldExecute: Bool {
        //isAlreadyImported computed property fetches a persisted flag
        return !isAlreadyImported
    }
    
    override var initialContinueId: String? {
        //continueId computed property fetches a persisted continue id, so we can pick up importing where we left off
        return continueId
    }
    
    override func didFetchAndSaveAllPages() {
        saveLanguageAsImportCompleted()
    }
    
    override func willFetchAndSaveNewPage(newContinueId: String) {
        saveContinueId(newContinueId)
    }
    
    //MARK: Private
    
    private func saveLanguageAsImportCompleted() {
        let key = LibraryKey.completedImportFlags.fullKeyForProject(project)
        setAlreadyImported(true, forKey: key)
    }
    
    private func saveContinueId(_ continueId: String) {
        let key = LibraryKey.continueIdentifer.fullKeyForProject(project)
        setContinueId(continueId, forKey: key)
    }
}

//MARK: Library Key Value helpers

private extension RemoteNotificationsImportOperation {
    var continueId: String? {
        
        let key = LibraryKey.continueIdentifer.fullKeyForProject(project)
        return libraryValue(forKey: key) as? String
    }
    
    var isAlreadyImported: Bool {
        
        let key = LibraryKey.completedImportFlags.fullKeyForProject(project)
        guard let nsNumber = libraryValue(forKey: key) as? NSNumber else {
            return false
        }
        
        return nsNumber.boolValue
    }
    
    func setContinueId(_ continueId: String, forKey key: String) {
        setLibraryValue(continueId as NSString, forKey: key)
    }
    
    func setAlreadyImported(_ value: Bool, forKey key: String) {
        let nsNumber = NSNumber(value: value)
        setLibraryValue(nsNumber, forKey: key)
    }
    
    func libraryValue(forKey key: String) -> NSCoding? {
        var result: NSCoding? = nil
        let backgroundContext = self.modelController.newBackgroundContext()
        backgroundContext.performAndWait {
            result = backgroundContext.wmf_keyValue(forKey: key)?.value
        }
        
        return result
    }
    
    func setLibraryValue(_ value: NSCoding, forKey key: String) {
        let backgroundContext = self.modelController.newBackgroundContext()
        backgroundContext.perform {
            backgroundContext.wmf_setValue(value, forKey: key)
            do {
                try backgroundContext.save()
            } catch let error {
                DDLogError("Error saving RemoteNotificationsImportOperation backgroundContext for library keys: \(error)")
            }
        }
    }
}
