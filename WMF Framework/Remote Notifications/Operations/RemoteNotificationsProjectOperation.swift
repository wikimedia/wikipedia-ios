import Foundation

class RemoteNotificationsProjectOperation: RemoteNotificationsOperation, @unchecked Sendable {
    let project: WikimediaProject
    
    required init(project: WikimediaProject, apiController: RemoteNotificationsAPIController, modelController: RemoteNotificationsModelController) {
        self.project = project
        super.init(apiController: apiController, modelController: modelController)
    }
    
    required init(apiController: RemoteNotificationsAPIController, modelController: RemoteNotificationsModelController) {
        fatalError("init(apiController:modelController:) has not been implemented")
    }
}
