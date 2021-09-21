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
    public static let didLoadPersistentStoresNotification = NSNotification.Name(rawValue: "ModelControllerDidLoadPersistentStores")
    
    //TODO: Look into removing this in the future (some legacy code still uses this)
    let legacyBackgroundContext: NSManagedObjectContext
    
    let viewContext: NSManagedObjectContext
    let persistentContainer: NSPersistentContainer

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
        legacyBackgroundContext = container.newBackgroundContext()
        legacyBackgroundContext.name = "RemoteNotificationsLegacyBackgroundContext"
        legacyBackgroundContext.automaticallyMergesChangesFromParent = true
        legacyBackgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        viewContext = container.viewContext
        viewContext.name = "RemoteNotificationsViewContext"
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        
        self.persistentContainer = container
        
        super.init()
    }
    
    func deleteLegacyDatabaseFiles() {
        let modelName = Self.modelName
        let sharedAppContainerURL = FileManager.default.wmf_containerURL()
        let legacyStorageURL = sharedAppContainerURL.appendingPathComponent(modelName)
        do {
            try persistentContainer.persistentStoreCoordinator.destroyPersistentStore(at: legacyStorageURL, ofType: NSSQLiteStoreType, options: nil)
        } catch (let error) {
            DDLogError("Error with destroyPersistentStore for RemoteNotifications: \(error)")
        }
        
        let legecyJournalShmUrl = sharedAppContainerURL.appendingPathComponent("\(modelName)-shm")
        let legecyJournalWalUrl = sharedAppContainerURL.appendingPathComponent("\(modelName)-wal")
        
        do {
            try FileManager.default.removeItem(at: legacyStorageURL)
            try FileManager.default.removeItem(at: legecyJournalShmUrl)
            try FileManager.default.removeItem(at: legecyJournalWalUrl)
        } catch (let error) {
            DDLogError("Error deleting legacy RemoteNotifications database files: \(error)")
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    typealias ResultHandler = (Set<RemoteNotification>?) -> Void
    
    public func newBackgroundContext() -> NSManagedObjectContext {
        let backgroundContext = persistentContainer.newBackgroundContext()
        backgroundContext.name = "RemoteNotificationsBackgroundContext"
        backgroundContext.automaticallyMergesChangesFromParent = true
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return backgroundContext
    }

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
        let moc = legacyBackgroundContext
        moc.perform {
            guard let notifications = try? moc.fetch(fetchRequest) else {
                completion(nil)
                return
            }
            completion(Set(notifications))
        }
    }

    private func save(moc: NSManagedObjectContext) {
        if moc.hasChanges {
            do {
                try moc.save()
            } catch let error {
                DDLogError("Error saving RemoteNotificationsModelController managedObjectContext: \(error)")
            }
        }
    }

    public func createNewNotifications(moc: NSManagedObjectContext, notificationsFetchedFromTheServer: Set<RemoteNotificationsAPIController.NotificationsResult.Notification>, completion: @escaping () -> Void) throws {
        moc.perform {
            for notification in notificationsFetchedFromTheServer {
                self.createNewNotification(moc: moc, notification: notification)
            }
            self.save(moc: moc)
            completion()
        }
    }

    // Reminder: Methods that access managedObjectContext should perform their operations
    // inside the perform(_:) or the performAndWait(_:) methods.
    // https://developer.apple.com/documentation/coredata/using_core_data_in_the_background
    private func createNewNotification(moc: NSManagedObjectContext, notification: RemoteNotificationsAPIController.NotificationsResult.Notification) {
        guard let date = date(from: notification.timestamp.utciso8601) else {
            assertionFailure("Notification should have a date")
            return
        }

        let isRead = notification.readString == nil ? NSNumber(booleanLiteral: false) : NSNumber(booleanLiteral: true)
        let _ = moc.wmf_create(entityNamed: "RemoteNotification",
                                                withKeysAndValues: [
                                                    "wiki": notification.wiki,
                                                    "id": notification.id,
                                                    "key": notification.key,
                                                    "typeString": notification.type,
                                                    "categoryString" : notification.category,
                                                    "section" : notification.section,
                                                    "date": date,
                                                    "utcUnixString": notification.timestamp.utcunix,
                                                    "titleFull": notification.title?.full,
                                                    "titleNamespace": notification.title?.namespace,
                                                    "titleNamespaceKey": notification.title?.namespaceKey,
                                                    "titleText": notification.title?.text,
                                                    "agentId": notification.agent?.id,
                                                    "agentName": notification.agent?.name,
                                                    "isRead" : isRead,
                                                    "messageHeader": notification.message?.header,
                                                    "messageBody": notification.message?.body,
                                                    "messageLinks": notification.message?.links])
    }

    private func date(from dateString: String?) -> Date? {
        guard let dateString = dateString else {
            return nil
        }
        return DateFormatter.wmf_iso8601()?.date(from: dateString)
    }

    // MARK: Mark as read

    public func markAsRead(_ notification: RemoteNotification) {
        let moc = legacyBackgroundContext
        moc.perform {
            notification.isRead = true
            self.save(moc: moc)
        }
    }

    public func markAsRead(notificationWithID notificationID: String) {
        processNotificationWithID(notificationID) { (notification) in
            notification.isRead = true
        }
    }

    private func processNotificationWithID(_ notificationID: String, handler: @escaping (RemoteNotification) -> Void) {
        let moc = legacyBackgroundContext
        moc.perform {
            let fetchRequest: NSFetchRequest<RemoteNotification> = RemoteNotification.fetchRequest()
            fetchRequest.fetchLimit = 1
            let predicate = NSPredicate(format: "id == %@", notificationID)
            fetchRequest.predicate = predicate
            guard let notifications = try? moc.fetch(fetchRequest), let notification = notifications.first else {
                return
            }
            handler(notification)
            self.save(moc: moc)
        }
    }
}
