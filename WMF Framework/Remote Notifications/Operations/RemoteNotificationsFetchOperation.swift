class RemoteNotificationsFetchOperation: RemoteNotificationsOperation {
    override func execute() {
        DispatchQueue.main.async {
            self.managedObjectContext.perform {
                self.apiController.getAllUnreadNotifications(from: ["wikidata", "en"]) { fetchedNotifications, error in
                    if let error = error {
                        assertionFailure()
                        self.finish(with: error)
                    } else {
                        self.modelController.getAllNotifications { savedNotifications in
                            guard let savedNotifications = savedNotifications, let fetchedNotifications = fetchedNotifications else {
                                assertionFailure()
                                self.finish()
                                return
                            }
                            if fetchedNotifications.isEmpty {
                                self.finish()
                            } else {
                                if savedNotifications.isEmpty {
                                    do {
                                        try self.modelController.createNewNotifications(from: fetchedNotifications) {
                                            self.finish()
                                        }
                                    } catch let error {
                                        assertionFailure()
                                        self.finish(with: error)
                                    }
                                } else {
                                    do {
                                        try self.modelController.updateNotifications(savedNotifications, with: fetchedNotifications) {
                                            self.finish()
                                        }
                                    } catch let error {
                                        assertionFailure()
                                        self.finish(with: error)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
