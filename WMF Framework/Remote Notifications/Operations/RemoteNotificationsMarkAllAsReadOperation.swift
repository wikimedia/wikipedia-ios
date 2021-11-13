
import Foundation

class RemoteNotificationsMarkAllAsReadOperation: RemoteNotificationsOperation {
    
    override func execute() {
        
        self.apiController.markAllAsRead { [weak self] error in
            
            if let error = error {
                self?.finish(with: error)
                return
            }
            
            self?.modelController.markAllAsRead { [weak self] in
                self?.finish()
            }
        }
    }
}
