class RemoteNotificationsMarkReadOrUnreadOperation: RemoteNotificationsProjectOperation, @unchecked Sendable {
    
    private let shouldMarkRead: Bool
    private let identifierGroups: Set<RemoteNotification.IdentifierGroup>
    
    required init(project: WikimediaProject, apiController: RemoteNotificationsAPIController, modelController: RemoteNotificationsModelController, identifierGroups: Set<RemoteNotification.IdentifierGroup>, shouldMarkRead: Bool) {
        self.shouldMarkRead = shouldMarkRead
        self.identifierGroups = identifierGroups
        super.init(project: project, apiController: apiController, modelController: modelController)
    }
    
    required init(project: WikimediaProject, apiController: RemoteNotificationsAPIController, modelController: RemoteNotificationsModelController) {
        fatalError("init(project:apiController:modelController:) has not been implemented")
    }
    
    required init(apiController: RemoteNotificationsAPIController, modelController: RemoteNotificationsModelController) {
        fatalError("init(apiController:modelController:) has not been implemented")
    }
    
    override func execute() {
        
        // optimistically mark in database first for UI to reflect, then in API.
        
        let backgroundContext = modelController.newBackgroundContext()
        modelController.markAsReadOrUnread(moc: backgroundContext, identifierGroups: identifierGroups, shouldMarkRead: shouldMarkRead) { [weak self]  result in
            
            guard let self = self else {
                return
            }
            
            switch result {
            case .success:
                
                self.apiController.markAsReadOrUnread(project: self.project, identifierGroups: self.identifierGroups, shouldMarkRead: self.shouldMarkRead) { error in
                    if let error = error {
                        self.finish(with: error)
                        return
                    }
                    
                    self.finish()
                }
                
            case .failure(let error):
                self.finish(with: error)
            }
            
        }
    }
}
