class RemoteNotificationsMarkReadOrUnreadOperation: RemoteNotificationsOperation {
    
    private let project: RemoteNotificationsProject
    private let shouldMarkRead: Bool
    private let identifierGroups: Set<RemoteNotification.IdentifierGroup>
    
    required init(project: RemoteNotificationsProject, apiController: RemoteNotificationsAPIController, modelController: RemoteNotificationsModelController, identifierGroups: Set<RemoteNotification.IdentifierGroup>, shouldMarkRead: Bool) {
        self.project = project
        self.shouldMarkRead = shouldMarkRead
        self.identifierGroups = identifierGroups
        super.init(with: apiController, modelController: modelController)
    }
    
    required init(with apiController: RemoteNotificationsAPIController, modelController: RemoteNotificationsModelController) {
        fatalError("init(with:modelController:) has not been implemented")
    }
    
    override func execute() {
        
        //optimistically mark in database first for UI to reflect, then in API.
        modelController.markAsReadOrUnread(identifierGroups: identifierGroups, shouldMarkRead: shouldMarkRead) { [weak self] in
            
            guard let self = self else {
                return
            }
            
            self.apiController.markAsReadOrUnread(project: self.project, identifierGroups: self.identifierGroups, shouldMarkRead: self.shouldMarkRead) { error in
                if let error = error {
                    //MAYBETODO: Revert to old values?
                    self.finish(with: error)
                    return
                }
                
                self.finish()
            }
        }
    }
}
