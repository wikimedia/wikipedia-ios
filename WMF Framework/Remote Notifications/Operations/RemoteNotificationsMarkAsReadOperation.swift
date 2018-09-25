class RemoteNotificationsMarkAsReadOperation: RemoteNotificationsOperation {
    override func execute() {
        DispatchQueue.main.async {
            self.managedObjectContext.perform {
                self.modelController.getReadNotifications { readNotifications in
                    guard let readNotifications = readNotifications, !readNotifications.isEmpty else {
                        self.finish()
                        return
                    }
                    print(readNotifications)
                    self.finish()
                }
            }
        }
    }
}
