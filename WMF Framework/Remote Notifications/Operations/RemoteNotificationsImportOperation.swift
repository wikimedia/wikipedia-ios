import CocoaLumberjackSwift

class RemoteNotificationsImportOperation: RemoteNotificationsOperation {
    
    private enum LibraryKey: String {
        case completedImportFlags = "RemoteNotificationsCompletedImportFlags"
        case continueIdentifer = "RemoteNotificationsContinueIdentifier"
        
        func fullKeyForProject(_ project: RemoteNotificationsProject) -> String {
            return "\(self.rawValue)-\(project.notificationsApiWikiIdentifier)"
        }
    }
    
    private let project: RemoteNotificationsProject
    private let cookieDomain: String
    init(with apiController: RemoteNotificationsAPIController, modelController: RemoteNotificationsModelController, project: RemoteNotificationsProject, cookieDomain: String) {
        self.project = project
        self.cookieDomain = cookieDomain
        super.init(with: apiController, modelController: modelController)
    }
    
    override func execute() {
        
        //Confirm we haven't already imported for this language before kicking off import.
        //isAlreadyImported computed property fetches a persisted flag
        guard !isAlreadyImported else {
            finish()
            return
        }
        
        //See if there is a persisted continue flag so we can pick up importing where we left off
        //continueId computed property fetches a persisted continue id
        importNotifications(continueId: continueId)
    }
    
    private func importNotifications(continueId: String? = nil) {
        guard apiController.isAuthenticatedForCookieDomain(cookieDomain) else {
            self.finish(with: RequestError.unauthenticated)
            return
        }

        apiController.getAllNotifications(from: project, continueId: continueId) { [weak self] result, error in
            
            guard let self = self else {
                return
            }
            
            if let error = error {
                self.finish(with: error)
                return
            }
            
            guard let fetchedNotifications = result?.list else {
                self.finish(with: RequestError.unexpectedResponse)
                return
            }

            do {
                let backgroundContext = self.modelController.newBackgroundContext()
                try self.modelController.createNewNotifications(moc: backgroundContext, notificationsFetchedFromTheServer: Set(fetchedNotifications), completion: { [weak self] in

                    guard let self = self else {
                        return
                    }
                    
                    guard let newContinueId = result?.continueId,
                          newContinueId != continueId else {
                        self.saveLanguageAsImportCompleted()
                        self.finish()
                        return
                    }
                    
                    self.saveContinueId(newContinueId)
                    self.importNotifications(continueId: newContinueId)
                })
            } catch let error {
                self.finish(with: error)
            }
        }
    }
    
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
