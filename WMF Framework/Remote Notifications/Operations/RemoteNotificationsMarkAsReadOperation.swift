class RemoteNotificationsMarkAsReadOperation: RemoteNotificationsOperation {
    override func execute() {
        DispatchQueue.main.async {
            self.managedObjectContext.perform {
                self.modelController.getReadNotifications { readNotifications in
                    guard let readNotifications = readNotifications, !readNotifications.isEmpty else {
                        self.finish()
                        return
                    }
                    self.apiController.markAsRead(readNotifications) { error in
                        if let error = error {
                            self.finish(with: error)
                        } else {
                            self.finish()
                        }
                    }
                }
            }
        }
    }
}
