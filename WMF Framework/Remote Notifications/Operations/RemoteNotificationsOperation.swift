class RemoteNotificationsOperation: AsyncOperation {
    let apiController: RemoteNotificationsAPIController
    let modelController: RemoteNotificationsModelController
    let project: RemoteNotificationsProject
    
    required init(with apiController: RemoteNotificationsAPIController, modelController: RemoteNotificationsModelController, project: RemoteNotificationsProject) {
        self.apiController = apiController
        self.modelController = modelController
        self.project = project
        super.init()
    }
}
