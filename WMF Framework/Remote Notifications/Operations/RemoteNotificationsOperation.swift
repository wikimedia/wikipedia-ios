class RemoteNotificationsOperation: AsyncOperation {
    let apiController: RemoteNotificationsAPIController
    let modelController: RemoteNotificationsModelController
    let project: RemoteNotificationsProject
    
    required init(project: RemoteNotificationsProject, apiController: RemoteNotificationsAPIController, modelController: RemoteNotificationsModelController) {
        self.project = project
        self.apiController = apiController
        self.modelController = modelController
        super.init()
    }
}
