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
        
        //Confirm we haven't already imported for this language before kicking off import
        let importedFlagkey = LibraryKey.completedImportFlags.fullKeyForProject(project)
        let isAlreadyImported = libraryBoolValue(for: importedFlagkey)
        
        guard !isAlreadyImported else {
            finish()
            return
        }
        
        //see if there is a persisted continue flag so we can pick up importing where we left off
        let continueIdKey = LibraryKey.continueIdentifer.fullKeyForProject(project)
        let continueId = libraryStringValue(for: continueIdKey)
        
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
        setLibraryBoolValue(true, for: key)
    }
    
    private func saveContinueId(_ continueId: String) {
        let key = LibraryKey.continueIdentifer.fullKeyForProject(project)
        setLibraryStringValue(continueId, for: key)
    }
}

//MARK: Library Key Value helpers

private extension RemoteNotificationsImportOperation {
    func libraryStringValue(for key: String) -> String? {
        
        var result: String? = nil
        let backgroundContext = self.modelController.newBackgroundContext()
        backgroundContext.performAndWait {
            result = backgroundContext.wmf_stringValue(forKey: key)
        }
        
        return result
    }
    
    func setLibraryStringValue(_ value: String, for key: String) {
        
        let backgroundContext = self.modelController.newBackgroundContext()
        backgroundContext.perform {
            backgroundContext.wmf_setValue(value as NSString, forKey: key)
            do {
                try backgroundContext.save()
            } catch let error {
                DDLogError("Error saving RemoteNotificationsImportOperation backgroundContext for library keys: \(error)")
            }
        }
    }
    
    func libraryBoolValue(for key: String) -> Bool {
        
        var result: Bool = false
        let backgroundContext = self.modelController.newBackgroundContext()
        backgroundContext.performAndWait {
            result = backgroundContext.wmf_numberValue(forKey: key)?.boolValue ?? false
        }
        
        return result
    }
    
    func setLibraryBoolValue(_ value: Bool, for key: String) {
        
        let backgroundContext = self.modelController.newBackgroundContext()
        backgroundContext.perform {
            let nsNumber = NSNumber(value: value)
            backgroundContext.wmf_setValue(nsNumber, forKey: key)
            do {
                try backgroundContext.save()
            } catch let error {
                DDLogError("Error saving RemoteNotificationsImportOperation backgroundContext for library keys: \(error)")
            }
        }
    }
}
