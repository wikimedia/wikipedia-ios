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
}

final class RemoteNotificationsModelController: NSObject {
    public static let modelDidChangeNotification = NSNotification.Name(rawValue: "RemoteNotificationsModelDidChange")
    public static let didLoadPersistentStoresNotification = NSNotification.Name(rawValue: "ModelControllerDidLoadPersistentStores")
    
    let backgroundContext: NSManagedObjectContext
    let viewContext: NSManagedObjectContext

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
    
    static let modelName = "RemoteNotifications"

    required init?(_ initializationError: inout Error?) {
        let modelName = RemoteNotificationsModelController.modelName
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
        let remoteNotificationsStorageURL = sharedAppContainerURL.appendingPathComponent("\(modelName).sqlite")
        let description = NSPersistentStoreDescription(url: remoteNotificationsStorageURL)
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { (storeDescription, error) in
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: RemoteNotificationsModelController.didLoadPersistentStoresNotification, object: error)
            }
        }
        backgroundContext = container.newBackgroundContext()
        backgroundContext.name = "RemoteNotificationsBackgroundContext"
        backgroundContext.automaticallyMergesChangesFromParent = true
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        viewContext = container.viewContext
        viewContext.name = "RemoteNotificationsViewContext"
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        
        super.init()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    typealias ResultHandler = (Set<RemoteNotification>?) -> Void

    public func getUnreadNotifications(_ completion: @escaping ResultHandler) {
        return notifications(with: NSPredicate(format: "isRead == %@", NSNumber(value: false)), completion: completion)
    }

    public func getReadNotifications(_ completion: @escaping ResultHandler) {
        return notifications(with: NSPredicate(format: "isRead == %@", NSNumber(value: true)), completion: completion)
    }

    public func getAllNotifications(_ completion: @escaping ResultHandler) {
        return notifications(completion: completion)
    }

    private func notifications(with predicate: NSPredicate? = nil, completion: @escaping ResultHandler) {
        let fetchRequest: NSFetchRequest<RemoteNotification> = RemoteNotification.fetchRequest()
        fetchRequest.predicate = predicate
        let moc = backgroundContext
        moc.perform {
            guard let notifications = try? moc.fetch(fetchRequest) else {
                completion(nil)
                return
            }
            completion(Set(notifications))
        }
    }

    private func save() {
        let moc = backgroundContext
        if moc.hasChanges {
            do {
                try moc.save()
            } catch let error {
                DDLogError("Error saving RemoteNotificationsModelController managedObjectContext: \(error)")
            }
        }
    }

    public func createNewNotifications(from notificationsFetchedFromTheServer: Set<RemoteNotificationsAPIController.NotificationsResult.Notification>, completion: @escaping () -> Void) throws {
        backgroundContext.perform {
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
        guard let date = date(from: notification.timestamp.utciso8601) else {
            assertionFailure("Notification should have a date")
            return
        }

        let isRead = notification.readString == nil ? NSNumber(booleanLiteral: false) : NSNumber(booleanLiteral: true)
        let _ = backgroundContext.wmf_create(entityNamed: "RemoteNotification",
                                                withKeysAndValues: ["id": notification.id,
                                                                    "categoryString" : notification.category,
                                                                    "key": notification.key,
                                                                    "typeString": notification.type,
                                                                    "agent": notification.agent?.name,
                                                                    "affectedPageID": notification.affectedPageID?.full,
                                                                    "message": notification.message?.header,
                                                                    "isRead" : isRead,
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
        let moc = backgroundContext

        moc.perform {
            // Delete notifications that were marked as read on the server
            for notification in savedNotifications {
                guard let id = notification.id, !commonIDs.contains(id) else {
                    continue
                }
                moc.delete(notification)
            }

            for notification in notificationsFetchedFromTheServer {
                guard !commonIDs.contains(notification.id) else {
                    if let savedNotification = savedNotifications.first(where: { $0.id == notification.id }) {
                        // Update notifications that weren't seen so that moc is notified of the update
                        savedNotification.isRead = true
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
        self.backgroundContext.perform {
            notification.isRead = true
            self.save()
        }
    }

    public func markAsRead(notificationWithID notificationID: String) {
        processNotificationWithID(notificationID) { (notification) in
            notification.isRead = true
        }
    }

    private func processNotificationWithID(_ notificationID: String, handler: @escaping (RemoteNotification) -> Void) {
        let moc = backgroundContext
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
}
