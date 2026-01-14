import CocoaLumberjackSwift
import CoreData

public extension Notification.Name {
    static let NotificationsCenterContextDidSave = Notification.Name("NotificationsCenterContextDidSave")
    static let NotificationsCenterBadgeNeedsUpdate = Notification.Name("NotificationsCenterBadgeNeedsUpdate")
}

@objc public extension NSNotification {
    static let notificationsCenterContextDidSave = Notification.Name.NotificationsCenterContextDidSave
    static let notificationsCenterBadgeNeedsUpdate = Notification.Name.NotificationsCenterBadgeNeedsUpdate
}

final class RemoteNotificationsModelController {
    
    enum LibraryKey: String {
        case completedImportFlags = "RemoteNotificationsCompletedImportFlags"
        case continueIdentifer = "RemoteNotificationsContinueIdentifier"
        case filterSettings = "RemoteNotificationsFilterSettings"
        
        func fullKeyForProject(_ project: WikimediaProject) -> String {
            if self == .filterSettings {
                assertionFailure("Shouldn't be using this key for filterSettings")
            }
            return "\(self.rawValue)-\(project.notificationsApiWikiIdentifier)"
        }
    }
    
    public static let didLoadPersistentStoresNotification = NSNotification.Name(rawValue: "ModelControllerDidLoadPersistentStores")
    
    let viewContext: NSManagedObjectContext
    let persistentContainer: NSPersistentContainer
    private let containerURL: URL

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
    
    enum ReadWriteError: LocalizedError {
        case unexpectedResultsForDistinctWikis
        case missingNotifications
        case missingDateInNotification
        
        var errorDescription: String? {
            return CommonStrings.genericErrorDescription
        }
    }
    
    static let modelName = "RemoteNotifications"

    required init(containerURL: URL) throws {
        self.containerURL = containerURL
        let modelName = RemoteNotificationsModelController.modelName
        let modelExtension = "momd"
        let modelBundle = Bundle.wmf
        
        guard let modelURL = modelBundle.url(forResource: modelName, withExtension: modelExtension) else {
            let error = InitializationError.unableToCreateModelURL(modelName, modelExtension, modelBundle)
            assertionFailure(error.localizedDescription)
            throw error
        }
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            let error = InitializationError.unableToCreateModel(modelURL, modelName)
            assertionFailure(error.localizedDescription)
            throw error
        }
        let container = NSPersistentContainer(name: modelName, managedObjectModel: model)
        let remoteNotificationsStorageURL = containerURL.appendingPathComponent("\(modelName).sqlite")

        let description = NSPersistentStoreDescription(url: remoteNotificationsStorageURL)
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { (storeDescription, error) in
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: RemoteNotificationsModelController.didLoadPersistentStoresNotification, object: error)
            }
        }
        
        viewContext = container.viewContext
        viewContext.name = "RemoteNotificationsViewContext"
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        
        self.persistentContainer = container
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Public
    
    func deleteLegacyDatabaseFiles() throws {
        let modelName = Self.modelName
        let legacyStorageURL = containerURL.appendingPathComponent(modelName)
        
        try persistentContainer.persistentStoreCoordinator.destroyPersistentStore(at: legacyStorageURL, ofType: NSSQLiteStoreType, options: nil)
        
        let legecyJournalShmUrl = containerURL.appendingPathComponent("\(modelName)-shm")
        let legecyJournalWalUrl = containerURL.appendingPathComponent("\(modelName)-wal")
        
        try FileManager.default.removeItem(at: legacyStorageURL)
        try FileManager.default.removeItem(at: legecyJournalShmUrl)
        try FileManager.default.removeItem(at: legecyJournalWalUrl)
    }
    
    func resetDatabaseAndSharedCache() {
        
        let batchDeleteBlock: (NSFetchRequest<NSFetchRequestResult>, NSManagedObjectContext) throws -> Void = { [weak self] (fetchRequest, backgroundContext) in
            
            guard let self = self else {
                return
            }
            
            let batchRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            batchRequest.resultType = .resultTypeObjectIDs
            
            let result = try backgroundContext.execute(batchRequest) as? NSBatchDeleteResult
            let objectIDArray = result?.result as? [NSManagedObjectID]
            let changes: [AnyHashable : Any] = [NSDeletedObjectsKey : objectIDArray as Any]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self.viewContext])
        }
        
        let backgroundContext = newBackgroundContext()

        backgroundContext.perform {
            let request: NSFetchRequest<NSFetchRequestResult> = RemoteNotification.fetchRequest()
            let libraryRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest<NSFetchRequestResult>(entityName: "WMFKeyValue")
            
            do {
                // batch delete all notification managed objects from Core Data
                try batchDeleteBlock(request, backgroundContext)
                
                // batch delete all library values from Core Data
                try batchDeleteBlock(libraryRequest, backgroundContext)
                
                // remove notifications from shared cache (referenced by the NotificationsService extension)
                let sharedCache = SharedContainerCache.init(fileName: SharedContainerCacheCommonNames.pushNotificationsCache)
                var cache = sharedCache.loadCache() ?? PushNotificationsCache(settings: .default, notifications: [])
                cache.notifications = []
                cache.currentUnreadCount = 0
                sharedCache.saveCache(cache)
            } catch {
                DDLogError("Error resetting notifications database: \(error)")
            }
        }

    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        let backgroundContext = persistentContainer.newBackgroundContext()
        backgroundContext.name = "RemoteNotificationsBackgroundContext"
        backgroundContext.automaticallyMergesChangesFromParent = true
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return backgroundContext
    }
    
    // MARK: Count convenience helpers
    
    func numberOfUnreadNotifications() throws -> Int {
        assert(Thread.isMainThread)
        let fetchRequest = RemoteNotification.fetchRequest()
        fetchRequest.predicate = unreadNotificationsPredicate
        return try viewContext.count(for: fetchRequest)
    }
    
    func numberOfAllNotifications() throws -> Int {
        assert(Thread.isMainThread)
        let fetchRequest = RemoteNotification.fetchRequest()
        return try viewContext.count(for: fetchRequest)
    }
    
    // MARK: Fetch and create
    
    func fetchNotifications(fetchLimit: Int = 50, fetchOffset: Int = 0, predicate: NSPredicate?) throws -> [RemoteNotification] {
        assert(Thread.isMainThread)
        
        let fetchRequest = RemoteNotification.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        fetchRequest.fetchLimit = fetchLimit
        fetchRequest.fetchOffset = fetchOffset
        fetchRequest.predicate = predicate
        
        return try viewContext.fetch(fetchRequest)
    }

    func createNewNotifications(moc: NSManagedObjectContext, notificationsFetchedFromTheServer: Set<RemoteNotificationsAPIController.NotificationsResult.Notification>, completion: @escaping ((Result<Void, Error>) -> Void)) {
        moc.perform { [weak self] in
            
            guard let self = self else {
                return
            }
            
            for notification in notificationsFetchedFromTheServer {
                try? self.createNewNotification(moc: moc, notification: notification)
            }

            do {
                try self.save(moc: moc)
                NotificationCenter.default.post(name: Notification.Name.NotificationsCenterBadgeNeedsUpdate, object: nil)
                completion(.success(()))
            } catch let error {
                completion(.failure(error))
            }
            
        }
    }
    
    // MARK: Mark as read
    
    func markAllAsRead(moc: NSManagedObjectContext, project: WikimediaProject, completion: @escaping (Result<Void, Error>) -> Void) {
        
        moc.perform { [weak self] in
            
            guard let self = self else {
                return
            }
            
            let unreadPredicate = self.unreadNotificationsPredicate
            let wikiPredicate = NSPredicate(format: "wiki == %@", project.notificationsApiWikiIdentifier)
            let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [unreadPredicate, wikiPredicate])
            
            do {
                
                let notifications = try self.notifications(moc: moc, predicate: compoundPredicate)
                
                guard !notifications.isEmpty else {
                    completion(.failure(ReadWriteError.missingNotifications))
                    return
                }
                
                notifications.forEach { notification in
                    notification.isRead = true
                }
                
                try self.save(moc: moc)
                
                NotificationCenter.default.post(name: Notification.Name.NotificationsCenterBadgeNeedsUpdate, object: nil)
                completion(.success(()))
            } catch let error {
                completion(.failure(error))
            }
        }
        
    }

    func markAsReadOrUnread(moc: NSManagedObjectContext, identifierGroups: Set<RemoteNotification.IdentifierGroup>, shouldMarkRead: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        
        let keys = identifierGroups.compactMap { $0.key }
        moc.perform { [weak self] in
            
            guard let self = self else {
                return
            }
            
            let predicate = NSPredicate(format: "key IN %@", keys)
            do {
                let notifications = try self.notifications(moc: moc, predicate: predicate)
                
                notifications.forEach { notification in
                    notification.isRead = shouldMarkRead
                }
                
                try self.save(moc: moc)
                
                NotificationCenter.default.post(name: Notification.Name.NotificationsCenterBadgeNeedsUpdate, object: nil)
                completion(.success(()))
                
            } catch let error {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: Fetch Distinct Wikis

    func distinctWikisWithUnreadNotifications() throws -> Set<String> {
        return try distinctWikis(predicate: unreadNotificationsPredicate)
    }
    
    func distinctWikis(predicate: NSPredicate?) throws -> Set<String> {
        assert(Thread.isMainThread)
        return try distinctWikis(moc: viewContext, predicate: predicate)
    }
    
    func distinctWikis(backgroundContext: NSManagedObjectContext, predicate: NSPredicate?, completion: @escaping (Result<Set<String>, Error>) -> Void) {
        backgroundContext.perform { [weak self] in
            
            guard let self = self else {
                return
            }
            
            do {
                let results = try self.distinctWikis(moc: backgroundContext, predicate: predicate)
                completion(.success(results))
            } catch let error {
                completion(.failure(error))
            }
            
        }
    }
    
    // MARK: Filter Settings
    
    func getFilterSettingsFromLibrary() -> NSDictionary? {
        return libraryValue(forKey: LibraryKey.filterSettings.rawValue) as? NSDictionary
    }
    
    func setFilterSettingsToLibrary(dictionary: NSDictionary?) {
        setLibraryValue(dictionary, forKey: LibraryKey.filterSettings.rawValue)
    }
    
    // MARK: WMFLibraryValue Helpers
    func libraryValue(forKey key: String) -> NSCoding? {
        var result: NSCoding? = nil
        let backgroundContext = newBackgroundContext()
        backgroundContext.performAndWait {
            result = backgroundContext.wmf_keyValue(forKey: key)?.value
        }
        
        return result
    }
    
    func setLibraryValue(_ value: NSCoding?, forKey key: String) {
        let backgroundContext = newBackgroundContext()
        backgroundContext.perform {
            backgroundContext.wmf_setValue(value, forKey: key)
            do {
                try backgroundContext.save()
            } catch let error {
                DDLogError("Error saving RemoteNotifications backgroundContext for library keys: \(error)")
            }
        }
    }
    
    func isProjectAlreadyImported(project: WikimediaProject) -> Bool {
        
        let key = LibraryKey.completedImportFlags.fullKeyForProject(project)
        guard let nsNumber = libraryValue(forKey: key) as? NSNumber else {
            return false
        }
        
        return nsNumber.boolValue
    }
    
    // MARK: Private
    
    private var unreadNotificationsPredicate: NSPredicate {
        return NSPredicate(format: "isRead == %@", NSNumber(value: false))
    }

    private func createNewNotification(moc: NSManagedObjectContext, notification: RemoteNotificationsAPIController.NotificationsResult.Notification) throws {
        guard let date = notification.date else {
            assertionFailure("Notification should have a date")
            throw ReadWriteError.missingDateInNotification
        }

        let isRead = notification.readString == nil ? NSNumber(booleanLiteral: false) : NSNumber(booleanLiteral: true)
        moc.wmf_create(entityNamed: "RemoteNotification",
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
                                                    "revisionID": notification.revisionID,
                                                    "messageHeader": notification.message?.header,
                                                    "messageBody": notification.message?.body,
                                                    "messageLinks": notification.message?.links])
    }
    
    private func notifications(moc: NSManagedObjectContext, predicate: NSPredicate? = nil) throws -> [RemoteNotification] {
        let fetchRequest = RemoteNotification.fetchRequest()
        fetchRequest.predicate = predicate
        return try moc.fetch(fetchRequest)
    }
    
    private func distinctWikis(moc: NSManagedObjectContext, predicate: NSPredicate?) throws -> Set<String> {
        guard let entityName = RemoteNotification.entity().name else {
            throw ReadWriteError.unexpectedResultsForDistinctWikis
        }

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = predicate
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.propertiesToFetch = ["wiki"]
        fetchRequest.returnsDistinctResults = true
        
        let result = try moc.fetch(fetchRequest)
        guard let dictionaries = result as? [[String: String]] else {
            throw ReadWriteError.unexpectedResultsForDistinctWikis
        }
        
        let results = dictionaries.flatMap { $0.values }
        return Set(results)
    }

    private func save(moc: NSManagedObjectContext) throws {
        if moc.hasChanges {
            try moc.save()
            NotificationCenter.default.post(name: Notification.Name.NotificationsCenterContextDidSave, object: nil)
        }
    }
}
