class RemoteNotificationsOperation: AsyncOperation {
    let apiController: RemoteNotificationsAPIController
    let modelController: RemoteNotificationsModelController
    let managedObjectContext: NSManagedObjectContext

    init(with apiController: RemoteNotificationsAPIController, modelController: RemoteNotificationsModelController) {
        self.apiController = apiController
        self.modelController = modelController
        self.managedObjectContext = modelController.managedObjectContext
        super.init()
    }
}
