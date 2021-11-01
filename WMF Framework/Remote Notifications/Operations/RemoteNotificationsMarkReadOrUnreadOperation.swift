class RemoteNotificationsMarkReadOrUnreadOperation: RemoteNotificationsOperation {
    
    private let shouldMarkRead: Bool
    private let notifications: Set<RemoteNotification>
    
    required init(with apiController: RemoteNotificationsAPIController, modelController: RemoteNotificationsModelController, notifications: Set<RemoteNotification>, shouldMarkRead: Bool) {
        self.shouldMarkRead = shouldMarkRead
        self.notifications = notifications
        super.init(with: apiController, modelController: modelController)
    }
    
    required init(with apiController: RemoteNotificationsAPIController, modelController: RemoteNotificationsModelController) {
        fatalError("init(with:modelController:) has not been implemented")
    }
    
    override func execute() {
        
        //optimistically mark in database first for UI to reflect, then in API.
        modelController.markAsReadOrUnread(notifications: notifications, shouldMarkRead: shouldMarkRead) { [weak self] in
            
            guard let self = self else {
                return
            }
            
            self.apiController.markAsReadOrUnread(self.notifications, shouldMarkRead: self.shouldMarkRead) { error in
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
