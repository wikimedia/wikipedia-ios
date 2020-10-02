import CocoaLumberjackSwift

@objc enum RemoteNotificationsModelChangeType: Int {
    case addedNewNotifications
    case updatedExistingNotifications
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

    @objc(markAsReadNotificationWithID:)
    func markAsRead(notificationWithID notificationID: String) {
        modelController.markAsRead(notificationWithID: notificationID)
    }

    @objc func markAsExcluded(_ notification: RemoteNotification) {
        modelController.markAsExcluded(notification)
    }

    @objc(markAsSeenNotificationWithID:)
    func markAsSeen(notificationWithID notificationID: String) {
        modelController.markAsSeen(notificationWithID: notificationID)
    }
}

final class RemoteNotificationsModelController: NSObject {
    public static let modelDidChangeNotification = NSNotification.Name(rawValue: "RemoteNotificationsModelDidChange")
    public static let didLoadPersistentStoresNotification = NSNotification.Name(rawValue: "ModelControllerDidLoadPersistentStores")
    
    let managedObjectContext: NSManagedObjectContext

    enum InitializationError: Error {
        case unableToCreateModelURL(String, String, Bundle)
        case unableToCreateModel(URL, String)

        var localizedDescription: String {
            switch self {
            case .unableToCreateModelURL(let modelName, let modelExtension, let modelBundle):
                return "Couldn't find url for resource named \(modelName) with extension \(modelExtension) in bundle \(modelBundle); make sure you're providing the right name, extension and bundle"
            case .unableToCreateModel(let modelURL, let modelName):
                return "Couldn't create model with contents of \(modelURL); make sure \(modelURL) is the correct url for \(modelName)"
            }
        }
    }

    required init?(_ initializationError: inout Error?) {
        let modelName = "RemoteNotifications"
        let modelExtension = "momd"
        let modelBundle = Bundle.wmf
        guard let modelURL = modelBundle.url(forResource: modelName, withExtension: modelExtension) else {
            let error = InitializationError.unableToCreateModelURL(modelName, modelExtension, modelBundle)
            assertionFailure(error.localizedDescription)
            initializationError = error
            return nil
        }
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            let error = InitializationError.unableToCreateModel(modelURL, modelName)
            assertionFailure(error.localizedDescription)
            initializationError = error
            return nil
        }
        let container = NSPersistentContainer(name: modelName, managedObjectModel: model)
        let sharedAppContainerURL = FileManager.default.wmf_containerURL()
        let remoteNotificationsStorageURL = sharedAppContainerURL.appendingPathComponent(modelName)
        let description = NSPersistentStoreDescription(url: remoteNotificationsStorageURL)
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { (storeDescription, error) in
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: RemoteNotificationsModelController.didLoadPersistentStoresNotification, object: error)
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
        return notifications(with: NSPredicate(format: "stateNumber == nil"), completion: completion)
    }

    public func getReadNotifications(_ completion: @escaping ResultHandler) {
        let read = RemoteNotification.State.read.number
        return notifications(with: NSPredicate(format: "stateNumber == %@", read), completion: completion)
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
            // Delete notifications that were marked as read on the server
            for notification in savedNotifications {
                guard let id = notification.id, !commonIDs.contains(id) else {
                    continue
                }
                moc.delete(notification)
            }

            for notification in notificationsFetchedFromTheServer {
                guard let id = notification.id else {
                    assertionFailure("Expected notification to have id")
                    continue
                }
                guard !commonIDs.contains(id) else {
                    if let savedNotification = savedNotifications.first(where: { $0.id == id }) {
                        // Update notifications that weren't seen so that moc is notified of the update
                        savedNotification.state = .read
                    }
                    continue
                }
                self.createNewNotification(from: notification)
            }

            self.save()
            completion()
        }
    }

    // MARK: Mark as read

    public func markAsRead(_ notification: RemoteNotification) {
        self.managedObjectContext.perform {
            notification.state = .read
            self.save()
        }
    }

    public func markAsRead(notificationWithID notificationID: String) {
        processNotificationWithID(notificationID) { (notification) in
            notification.state = .read
        }
    }

    // MARK: Mark as excluded

    public func markAsExcluded(_ notification: RemoteNotification) {
        let moc = managedObjectContext
        moc.perform {
            notification.state = .excluded
            self.save()
        }
    }

    // MARK: Mark as seen

    public func markAsSeen(notificationWithID notificationID: String) {
        processNotificationWithID(notificationID) { (notification) in
            notification.state = .seen
        }
    }

    private func processNotificationWithID(_ notificationID: String, handler: @escaping (RemoteNotification) -> Void) {
        let moc = managedObjectContext
        moc.perform {
            let fetchRequest: NSFetchRequest<RemoteNotification> = RemoteNotification.fetchRequest()
            fetchRequest.fetchLimit = 1
            let predicate = NSPredicate(format: "id == %@", notificationID)
            fetchRequest.predicate = predicate
            guard let notifications = try? moc.fetch(fetchRequest), let notification = notifications.first else {
                return
            }
            handler(notification)
            self.save()
        }
    }

    // MARK: Notifications

    @objc private func managedObjectContextDidSave(_ note: Notification) {
        guard let userInfo = note.userInfo else {
            assertionFailure("Expected note with userInfo dictionary")
            return
        }
        if let insertedObjects = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, !insertedObjects.isEmpty {
            postModelDidChangeNotification(ofType: .addedNewNotifications, withNotificationsFromObjects: insertedObjects)
        }
        if let updatedObjects = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, !updatedObjects.isEmpty {
            postModelDidChangeNotification(ofType: .updatedExistingNotifications, withNotificationsFromObjects: updatedObjects)
        }
    }

    private func postModelDidChangeNotification(ofType modelChangeType: RemoteNotificationsModelChangeType, withNotificationsFromObjects objects: Set<NSManagedObject>) {
        let notifications = objects.compactMap { $0 as? RemoteNotification }.filter { $0.state == nil }
        guard !notifications.isEmpty else {
            return
        }
        let notificationsGroupedByCategoryNumber = Dictionary(grouping: notifications, by: { NSNumber(value: $0.category.rawValue) })
        let modelChange = RemoteNotificationsModelChange(type: modelChangeType, notificationsGroupedByCategoryNumber: notificationsGroupedByCategoryNumber)
        let responseCoordinator = RemoteNotificationsModelChangeResponseCoordinator(modelChange: modelChange, modelController: self)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: RemoteNotificationsModelController.modelDidChangeNotification, object: responseCoordinator)
        }
    }
}


@objc public class RemoteNotificationsModelControllerNotification: NSObject {
    @objc public static let modelDidChange = RemoteNotificationsModelController.modelDidChangeNotification
}
