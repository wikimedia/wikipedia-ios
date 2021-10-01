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
        let key = LibraryKey.completedImportFlags.fullKeyForProject(project)
        let isAlreadyImported = libraryBool(for: key)
        
        guard !isAlreadyImported else {
            finish()
            return
        }
        
        importNotifications()
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
                        self.markLanguageAsImportCompleted()
                        self.finish()
                        return
                    }
                    
                    self.importNotifications(continueId: newContinueId)
                })
            } catch let error {
                self.finish(with: error)
            }
        }
    }
    
    private func markLanguageAsImportCompleted() {
        let key = LibraryKey.completedImportFlags.fullKeyForProject(project)
        setLibraryBool(true, for: key)
    }
}

//MARK: Library Key Value helpers

private extension RemoteNotificationsImportOperation {
    func libraryBool(for key: String) -> Bool {
        
        var result: Bool = false
        let backgroundContext = self.modelController.newBackgroundContext()
        backgroundContext.performAndWait {
            result = backgroundContext.wmf_numberValue(forKey: key)?.boolValue ?? false
        }
        
        return result
    }
    
    func setLibraryBool(_ bool: Bool, for key: String) {
        
        let backgroundContext = self.modelController.newBackgroundContext()
        backgroundContext.perform {
            let nsNumber = NSNumber(value: bool)
            backgroundContext.wmf_setValue(nsNumber, forKey: key)
            do {
                try backgroundContext.save()
            } catch let error {
                DDLogError("Error saving RemoteNotificationsImportOperation backgroundContext for library keys: \(error)")
            }
        }
    }
}
