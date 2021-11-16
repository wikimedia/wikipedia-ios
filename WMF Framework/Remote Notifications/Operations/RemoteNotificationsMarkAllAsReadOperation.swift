
import Foundation

class RemoteNotificationsMarkAllAsReadOperation: RemoteNotificationsOperation {
    
    private let project: RemoteNotificationsProject
    private let languageLinkController: MWKLanguageLinkController
    
    init(project: RemoteNotificationsProject, modelController: RemoteNotificationsModelController, apiController: RemoteNotificationsAPIController, languageLinkController: MWKLanguageLinkController) {
        self.project = project
        self.languageLinkController = languageLinkController
        super.init(with: apiController, modelController: modelController)
    }
    
    required init(with apiController: RemoteNotificationsAPIController, modelController: RemoteNotificationsModelController) {
        fatalError("init(with:modelController:) has not been implemented")
    }
    
    override func execute() {
        
        //optimistically marking local objects as read first.
        self.modelController.markAllAsRead(project: project) { [weak self] in
            
            guard let self = self else {
                return
            }
            
            self.apiController.markAllAsRead(project: self.project) { [weak self] error in
                
                guard let self = self else {
                    return
                }
                
                if let error = error {
                    self.finish(with: error)
                    return
                }
                
                self.finish()
            }
        }
    }
}
