import Foundation

class RemoteNotificationsMarkAllAsReadOperation: RemoteNotificationsProjectOperation, @unchecked Sendable {
    
    override func execute() {
        
        // optimistically mark in database first for UI to reflect, then in API.
        
        let backgroundContext = modelController.newBackgroundContext()
        self.modelController.markAllAsRead(moc: backgroundContext, project: project) { [weak self] result in
            guard let self = self else {
                return
            }
            
            switch result {
            case .success:
                
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
                
            case .failure(let error):
                self.finish(with: error)
            }
            
            
        }
    }
}
