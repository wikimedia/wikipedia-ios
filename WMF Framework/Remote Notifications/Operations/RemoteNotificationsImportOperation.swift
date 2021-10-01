class RemoteNotificationsImportOperation: RemoteNotificationsOperation {
    private let project: RemoteNotificationsProject
    private let cookieDomain: String
    init(with apiController: RemoteNotificationsAPIController, modelController: RemoteNotificationsModelController, project: RemoteNotificationsProject, cookieDomain: String) {
        self.project = project
        self.cookieDomain = cookieDomain
        super.init(with: apiController, modelController: modelController)
    }
    
    override func execute() {
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
}
