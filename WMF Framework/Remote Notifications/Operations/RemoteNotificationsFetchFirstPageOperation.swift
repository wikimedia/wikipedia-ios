class RemoteNotificationsFetchFirstPageOperation: RemoteNotificationsOperation {
    let languageCode: String
    private var backgroundContext: NSManagedObjectContext
    
    init(with apiController: RemoteNotificationsAPIController, modelController: RemoteNotificationsModelController, languageCode: String) {
        self.languageCode = languageCode
        assert(Thread.isMainThread)
        self.backgroundContext = modelController.newBackgroundContext()
        super.init(with: apiController, modelController: modelController)
    }
    
    override func execute() {
            self.apiController.getAllNotifications(from: self.languageCode) { [weak self] result, error in
                
                guard let self = self else {
                    return
                }
                
                DispatchQueue.main.async {
                    if let error = error {
                        self.finish(with: error)
                        return
                    }
                    
                    guard let fetchedNotifications = result?.list else {
                        self.finish(with: RequestError.unexpectedResponse)
                        return
                    }
                    
                    do {
                        assert(Thread.isMainThread)
                        try self.modelController.createNewNotifications(moc: self.backgroundContext, notificationsFetchedFromTheServer: Set(fetchedNotifications), completion: { [weak self] in
                            
                            guard let self = self else {
                                return
                            }
                            
                            DispatchQueue.main.async {
                                self.finish()
                            }
                            
                        })
                    } catch let error {
                        self.finish(with: error)
                    }
                }
        }
    }
}
