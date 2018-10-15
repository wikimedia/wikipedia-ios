class RemoteNotificationsFetchOperation: RemoteNotificationsOperation {
    override func execute() {
        self.managedObjectContext.perform {
            var targetWikis = MWKLanguageLinkController.sharedInstance().readPreferredLanguageCodes()
            targetWikis.append("wikidata")
            self.apiController.getAllUnreadNotifications(from: targetWikis) { fetchedNotifications, error in
                if let error = error {
                    self.finish(with: error)
                } else {
                    self.modelController.getAllNotifications { savedNotifications in
                        guard let savedNotifications = savedNotifications, let fetchedNotifications = fetchedNotifications else {
                            assertionFailure()
                            self.finish()
                            return
                        }
                        if fetchedNotifications.isEmpty && savedNotifications.isEmpty {
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
