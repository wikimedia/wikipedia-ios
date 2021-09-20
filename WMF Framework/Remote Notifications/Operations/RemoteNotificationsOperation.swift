class RemoteNotificationsOperation: AsyncOperation {
    let apiController: RemoteNotificationsAPIController
    let modelController: RemoteNotificationsModelController

    init(with apiController: RemoteNotificationsAPIController, modelController: RemoteNotificationsModelController) {
        self.apiController = apiController
        self.modelController = modelController
        super.init()
    }
}
