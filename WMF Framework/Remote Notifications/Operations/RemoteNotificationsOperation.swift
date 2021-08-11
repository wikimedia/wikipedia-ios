class RemoteNotificationsOperation: AsyncOperation {
    let apiController: RemoteNotificationsAPIController
    let modelController: RemoteNotificationsModelController
    let backgroundContext: NSManagedObjectContext

    init(with apiController: RemoteNotificationsAPIController, modelController: RemoteNotificationsModelController) {
        self.apiController = apiController
        self.modelController = modelController
        self.backgroundContext = modelController.backgroundContext
        super.init()
    }
}
