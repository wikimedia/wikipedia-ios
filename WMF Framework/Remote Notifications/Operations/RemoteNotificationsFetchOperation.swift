class RemoteNotificationsFetchOperation: RemoteNotificationsOperation {
    override func execute() {
        DispatchQueue.main.async {
            self.managedObjectContext.perform {
                self.apiController.getAllUnreadNotifications { fetchedNotifications, error in
                    if let error = error {
                        self.finish(with: error)
                        return
                    } else {
                        self.modelController.getAllNotifications { savedNotifications in
                            guard let savedNotifications = savedNotifications, let fetchedNotifications = fetchedNotifications else {
                                assertionFailure()
                                self.finish()
                                return
                            }
                            if savedNotifications.isEmpty {
                                do {
                                    try self.modelController.createNewNotifications(from: fetchedNotifications)
                                } catch let error {
                                    assertionFailure()
                                    self.finish(with: error)
                                    return
                                }
                            } else {
                                do {
                                    try self.modelController.updateNotifications(savedNotifications, with: fetchedNotifications)
                                } catch let error {
                                    assertionFailure()
                                    self.finish(with: error)
                                    return
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
