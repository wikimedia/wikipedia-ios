import Foundation

class RemoteNotificationsMarkAsSeenOperation: RemoteNotificationsProjectOperation {
    override func execute() {
        let backgroundContext = modelController.newBackgroundContext()
//        self.modelController.markAllAsSeen(moc: backgroundContext, project: project) { [weak self] result in
//
//            guard let self = self else {
//                return
//            }
            
//            switch result {
//            case .success:
                self.apiController.markAllAsSeen(project: self.project) { [weak self] error in
                    guard let self = self else {
                        return
                    }
                    
                    if let error = error {
                        self.finish(with: error)
                        return
                    }
                    self.finish()
//                }
//            case let .failure(error):
//                self.finish(with: error)
//            }
        }
    }
}
