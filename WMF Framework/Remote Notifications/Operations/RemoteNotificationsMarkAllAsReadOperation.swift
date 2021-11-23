
import Foundation

class RemoteNotificationsMarkAllAsReadOperation: RemoteNotificationsOperation {
    
    override func execute() {
        
        //optimistically mark in database first for UI to reflect, then in API.
        let backgroundContext = modelController.newBackgroundContext()
        self.modelController.markAllAsRead(moc: backgroundContext, project: project) { [weak self] in
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
