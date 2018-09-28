@objc enum RemoteNotificationsModelChangeType: Int {
    case addedNewNotifications
}

@objc final class RemoteNotificationsModelChange: NSObject {
    @objc let type: RemoteNotificationsModelChangeType
    @objc let notificationsGroupedByCategoryNumber: [NSNumber: [RemoteNotification]]

    init(type: RemoteNotificationsModelChangeType, notificationsGroupedByCategoryNumber: [NSNumber: [RemoteNotification]]) {
        self.type = type
        self.notificationsGroupedByCategoryNumber = notificationsGroupedByCategoryNumber
        super.init()
    }
}

@objc final class RemoteNotificationsModelChangeResponseCoordinator: NSObject {
    @objc let modelChange: RemoteNotificationsModelChange
    private let modelController: RemoteNotificationsModelController

    init(modelChange: RemoteNotificationsModelChange, modelController: RemoteNotificationsModelController) {
        self.modelChange = modelChange
        self.modelController = modelController
        super.init()
    }

    @objc func markAsRead(_ notifications: [RemoteNotification]) {
        modelController.markAsRead(notifications)
    }

    @objc func markAsReadNotificationsWithIDs(_ IDs: [String]) {
        modelController.markAsReadNotificationsWithIDs(IDs)
    }
}

@objc final class RemoteNotificationsModelController: NSObject {
    @objc static let ModelDidChangeNotification = NSNotification.Name(rawValue: "RemoteNotificationsModelDidChange")
    static let ModelControllerDidLoadPersistentStoresNotification = NSNotification.Name(rawValue: "ModelControllerDidLoadPersistentStores")

    let managedObjectContext: NSManagedObjectContext

    required override init() {
        let modelName = "RemoteNotifications"
        let modelExtension = "momd"
        let modelBundle = Bundle.wmf
        guard let modelURL = modelBundle.url(forResource: modelName, withExtension: modelExtension) else {
            assertionFailure("Couldn't find url for resource named \(modelName) with extension \(modelExtension) in bundle \(modelBundle); make sure you're providing the right name, extension and bundle")
            abort()
        }
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            assertionFailure("Couldn't create model with contents of \(modelURL); make sure \(modelURL) is the correct url for \(modelName)")
            abort()
        }
        let container = NSPersistentContainer(name: modelName, managedObjectModel: model)
        let sharedAppContainerURL = FileManager.default.wmf_containerURL()
        let remoteNotificationsStorageURL = sharedAppContainerURL.appendingPathComponent(modelName)
        let description = NSPersistentStoreDescription(url: remoteNotificationsStorageURL)
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { (storeDescription, error) in
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: RemoteNotificationsModelController.ModelControllerDidLoadPersistentStoresNotification, object: error)
            }
        }
        managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = container.persistentStoreCoordinator
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(managedObjectContextDidSave(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: managedObjectContext)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    typealias ResultHandler = (Set<RemoteNotification>?) -> Void

    public func getUnreadNotifications(_ completion: @escaping ResultHandler) {
        return notifications(with: NSPredicate(format: "read == NO"), completion: completion)
    }

    public func getReadNotifications(_ completion: @escaping ResultHandler) {
        return notifications(with: NSPredicate(format: "read == YES"), completion: completion)
    }

    public func getAllNotifications(_ completion: @escaping ResultHandler) {
        return notifications(completion: completion)
    }

    private func notifications(with predicate: NSPredicate? = nil, completion: @escaping ResultHandler) {
        let fetchRequest: NSFetchRequest<RemoteNotification> = RemoteNotification.fetchRequest()
        fetchRequest.predicate = predicate
        let moc = managedObjectContext
        moc.perform {
            guard let notifications = try? moc.fetch(fetchRequest) else {
                completion(nil)
                return
            }
            completion(Set(notifications))
        }
    }

    private func save() {
        let moc = managedObjectContext
        if moc.hasChanges {
            do {
                try moc.save()
            } catch let error {
                DDLogError("Error saving RemoteNotificationsModelController managedObjectContext: \(error)")
            }
        }
    }

    // MARK: Validation

    let validNotificationCategories: Set<RemoteNotificationCategory> = [.editReverted]

    private func validateCategory(of notification: RemoteNotificationsAPIController.NotificationsResult.Notification) -> Bool {
        guard let categoryString = notification.category else {
            assertionFailure("Missing notification category")
            return false
        }
        let category = RemoteNotificationCategory(stringValue: categoryString)
        return validNotificationCategories.contains(category)
    }

    private func validateAge(ofNotificationDated date: Date) -> Bool {
        let sinceNow = Int(date.timeIntervalSinceNow)
        let hoursPassed = abs(sinceNow / 3600)
        let maxHoursPassed = 24
        return hoursPassed <= maxHoursPassed
    }

    public func createNewNotifications(from notificationsFetchedFromTheServer: Set<RemoteNotificationsAPIController.NotificationsResult.Notification>, completion: @escaping () -> Void) throws {
        managedObjectContext.perform {
            for notification in notificationsFetchedFromTheServer {
                self.createNewNotification(from: notification)
            }
            self.save()
            completion()
        }
    }

    // Reminder: Methods that access managedObjectContext should perform their operations
    // inside the perform(_:) or the performAndWait(_:) methods.
    // https://developer.apple.com/documentation/coredata/using_core_data_in_the_background
    private func createNewNotification(from notification: RemoteNotificationsAPIController.NotificationsResult.Notification) {
        guard let date = date(from: notification.timestamp?.utciso8601) else {
            assertionFailure("Notification should have a date")
            return
        }
        guard let id = notification.id else {
            assertionFailure("Notification must have an id")
            return
        }
        guard self.validateCategory(of: notification) else {
            return
        }
        guard self.validateAge(ofNotificationDated: date) else {
            return
        }
        let message = notification.message?.header?.wmf_stringByRemovingHTML()
        let _ = managedObjectContext.wmf_create(entityNamed: "RemoteNotification",
                                                withKeysAndValues: ["id": id,
                                                                    "categoryString" : notification.category,
                                                                    "typeString": notification.type,
                                                                    "agent": notification.agent?.name,
                                                                    "affectedPageID": notification.affectedPageID?.full,
                                                                    "message": message,
                                                                    "read": false,
                                                                    "wiki": notification.wiki,
                                                                    "date": date])
    }

    private func date(from dateString: String?) -> Date? {
        guard let dateString = dateString else {
            return nil
        }
        return DateFormatter.wmf_iso8601()?.date(from: dateString)
    }

    public func updateNotifications(_ savedNotifications: Set<RemoteNotification>, with notificationsFetchedFromTheServer: Set<RemoteNotificationsAPIController.NotificationsResult.Notification>, completion: @escaping () -> Void) throws {
        let savedIDs = Set(savedNotifications.compactMap { $0.id })
        let fetchedIDs = Set(notificationsFetchedFromTheServer.compactMap { $0.id })
        let commonIDs = savedIDs.intersection(fetchedIDs)
        let moc = managedObjectContext

        moc.perform {
            // Delete notifications that were marked as read on the server.
            for notification in savedNotifications {
                guard let id = notification.id, !commonIDs.contains(id) else {
                    continue
                }
                moc.delete(notification)
            }

            for notification in notificationsFetchedFromTheServer {
                // Don't update notifications that are already saved?
                guard let id = notification.id, !commonIDs.contains(id) else {
                    continue
                }
                self.createNewNotification(from: notification)
            }

            self.save()
            completion()
        }
    }

    // MARK: Mark as read

    public func markAsRead(_ notifications: [RemoteNotification]) {
        self.managedObjectContext.perform {
            notifications.forEach { $0.read = true }
            self.save()
        }
    }

    // MARK: Notifications

    @objc private func managedObjectContextDidSave(_ note: Notification) {
        guard let userInfo = note.userInfo else {
            assertionFailure("Expected note with userInfo dictionary")
            return
        }
        if let insertedObjects = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> {
            let notifications = insertedObjects.compactMap { $0 as? RemoteNotification }
            guard !notifications.isEmpty else {
                return
            }
            let notificationsGroupedByCategoryNumber = Dictionary(grouping: notifications, by: { NSNumber(value: $0.category.rawValue) })
            let modelChange = RemoteNotificationsModelChange(type: .addedNewNotifications, notificationsGroupedByCategoryNumber: notificationsGroupedByCategoryNumber)
            let responseCoordinator = RemoteNotificationsModelChangeResponseCoordinator(modelChange: modelChange, modelController: self)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: RemoteNotificationsModelController.ModelDidChangeNotification, object: responseCoordinator)
            }
        }
    }
}
