class RemoteNotificationsOperation: AsyncOperation, @unchecked Sendable {
    let apiController: RemoteNotificationsAPIController
    let modelController: RemoteNotificationsModelController
    
    required init(apiController: RemoteNotificationsAPIController, modelController: RemoteNotificationsModelController) {
        self.apiController = apiController
        self.modelController = modelController
        super.init()
    }
}
