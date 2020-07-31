
import Foundation

class EPCStorageManager {
    
    private let persistentStoreCoordinator: NSPersistentStoreCoordinator
    private let managedObjectContext: NSManagedObjectContext
    
    private var semaphore = DispatchSemaphore(value: 1)
    
    private var libraryValueCache: [String: NSCoding] = [:]
    private let cachesLibraryValues: Bool
    
    private let pruningAge: TimeInterval = 60*60*24*30 // 30 days
    private let postBatchSize: Int
    
    private let legacyEventLoggingService: EventLoggingService
    
    public static let shared: EPCStorageManager? = {
        let fileManager = FileManager.default
        var permanentStorageDirectory = fileManager.wmf_containerURL().appendingPathComponent("Event Platform Client", isDirectory: true)
        var didGetDirectoryExistsError = false
        do {
            try fileManager.createDirectory(at: permanentStorageDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch let error {
            DDLogError("EPCStorageManager: Error creating Event Platform Client directory: \(error)")
        }
        do {
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try permanentStorageDirectory.setResourceValues(values)
        } catch let error {
            DDLogError("EPCStorageManager: Error excluding from backup: \(error)")
        }
        
        let permanentStorageURL = permanentStorageDirectory.appendingPathComponent("EventPlatformClient.sqlite")
        DDLogDebug("EPCStorageManager: Events persistent store: \(permanentStorageURL)")
        
        guard let legacyEventLoggingService = EventLoggingService.shared else {
            DDLogError("EPCStorageManager: Unable to get pull legacy EventLoggingService instance for instantiating EPCStorageManager")
            return nil
        }
        
        return EPCStorageManager(permanentStorageURL: permanentStorageURL, legacyEventLoggingService: legacyEventLoggingService)
    }()
    
    public init?(permanentStorageURL: URL, cachesLibraryValues: Bool = true, legacyEventLoggingService: EventLoggingService, postBatchSize: Int = 32) {
        let bundle = Bundle.wmf
        let modelURL = bundle.url(forResource: "EventPlatformClient", withExtension: "momd")!
        let model = NSManagedObjectModel(contentsOf: modelURL)!
        let psc = NSPersistentStoreCoordinator(managedObjectModel: model)
        let options = [NSMigratePersistentStoresAutomaticallyOption: NSNumber(booleanLiteral: true), NSInferMappingModelAutomaticallyOption: NSNumber(booleanLiteral: true)]
        do {
            try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: permanentStorageURL, options: options)
        } catch {
            do {
                try FileManager.default.removeItem(at: permanentStorageURL)
            } catch {
                
            }
            do {
                try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: permanentStorageURL, options: options)
            } catch {
                DDLogError("EPCStorageManager: adding persistent store to coordinator: \(error)")
                return nil
            }
        }
        
        self.persistentStoreCoordinator = psc
        self.managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        self.managedObjectContext.persistentStoreCoordinator = psc
        self.cachesLibraryValues = cachesLibraryValues
        self.legacyEventLoggingService = legacyEventLoggingService
        self.postBatchSize = postBatchSize
    }
}

//MARK: EPCStorageManaging

extension EPCStorageManager: EPCStorageManaging {
    
    func setPersisted(_ key: String, _ value: NSCoding) {
        setLibraryValue(value, for: key)
    }
    
    func deletePersisted(_ key: String) {
        deleteLibraryValue(for: key)
    }
    
    func getPersisted(_ key: String) -> NSCoding? {
        return libraryValue(for: key)
    }
    
    var deviceID: String? {
        return legacyEventLoggingService.appInstallID
    }
    
    func createAndSavePostItem(with url: URL, body: NSDictionary) {
        
        let now = Date()
        perform { moc in
            if let post = NSEntityDescription.insertNewObject(forEntityName: "EPCPost", into: self.managedObjectContext) as? EPCPost {
                post.body = body
                post.recorded = now
                post.userAgent = WikipediaAppUtils.versionedUserAgent()
                post.url = url
                
                DDLogDebug("EPCStorageManaager: \(post.objectID) recorded!")
                
                self.save(moc)
            }
        }
    }
    
    func updatePostItem(postItem: EPCPost, result: Result<Date, Error>) {
        
        perform { moc in
            switch result {
            case .success(let date):
                postItem.posted = date
            case .failure:
                postItem.failed = true
            }
            
            self.save(moc)
        }
        
    }
    
    func deleteStalePostItems() {
        
        perform { (moc) in
            
            let pruneFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "EPCPost")
            pruneFetch.returnsObjectsAsFaults = false
            
            let pruneDate = Date().addingTimeInterval(-(self.pruningAge)) as NSDate
            pruneFetch.predicate = NSPredicate(format: "(recorded < %@) OR (posted != nil) OR (failed == TRUE)", pruneDate)
            let delete = NSBatchDeleteRequest(fetchRequest: pruneFetch)
            delete.resultType = .resultTypeCount
            
            do {
                let result = try self.managedObjectContext.execute(delete)
                guard let deleteResult = result as? NSBatchDeleteResult else {
                    DDLogError("EPCStorageManager: Could not read NSBatchDeleteResult")
                    return
                }
                
                guard let count = deleteResult.result as? Int else {
                    DDLogError("EPCStorageManager: Could not read NSBatchDeleteResult count")
                    return
                }
                DDLogInfo("EPCStorageManager: Pruned \(count) events")
                
            } catch let error {
                DDLogError("EPCStorageManager: Error pruning events: \(error.localizedDescription)")
            }
            
        }
    }
    
    func fetchPostItemsToPost() -> [EPCPost] {
        
        var events: [EPCPost] = []
        performAndWait { (moc) in
            let fetch: NSFetchRequest<EPCPost> = EPCPost.fetchRequest()
            fetch.sortDescriptors = [NSSortDescriptor(keyPath: \EPCPost.recorded, ascending: true)]
            fetch.predicate = NSPredicate(format: "(posted == nil) AND (failed != TRUE)")
            fetch.fetchLimit = self.postBatchSize

            do {
                events = try moc.fetch(fetch)
            } catch let error {
                DDLogError(error.localizedDescription)
            }
        }
        
        return events
    }
}

//MARK: Utility methods duplicated from EventLoggingService

private extension EPCStorageManager {
    
    func save(_ moc: NSManagedObjectContext) {
        guard moc.hasChanges else {
            return
        }
        do {
            try moc.save()
        } catch let error {
            DDLogError("Error saving EPCStorageManager managedObjectContext: \(error)")
        }
    }
    
    func deleteLibraryValue(for key: String) {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        
        perform { moc in
            if let keyValue = self.managedObjectContext.wmf_keyValue(forKey: key) {
                moc.delete(keyValue)
                if self.cachesLibraryValues {
                    self.libraryValueCache.removeValue(forKey: key)
                }
                self.save(moc)
            }
            
        }
    }
    
    func libraryValue(for key: String) -> NSCoding? {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        
        var value: NSCoding?
                
        performAndWait { moc in
            
            if cachesLibraryValues {
                value = libraryValueCache[key]
                if value != nil {
                    return
                }
            }
            
            value = managedObjectContext.wmf_keyValue(forKey: key)?.value
            if value != nil {
                if cachesLibraryValues {
                    libraryValueCache[key] = value
                }
                return
            }
        }
    
        return value
    }
    
    func setLibraryValue(_ value: NSCoding?, for key: String) {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        
        if cachesLibraryValues {
            libraryValueCache[key] = value
        }
        
        perform { moc in
            self.managedObjectContext.wmf_setValue(value, forKey: key)
            self.save(moc)
        }
    }
    
    func performAndWait(_ block: (_ moc: NSManagedObjectContext) -> Void) {
        let moc = self.managedObjectContext
        moc.performAndWait {
            block(moc)
        }
    }
    
    func perform(_ block: @escaping (_ moc: NSManagedObjectContext) -> Void) {
        let moc = self.managedObjectContext
        moc.perform {
            block(moc)
        }
    }
}

#if TEST

extension EPCStorageManager {
    var managedObjectContextToTest: NSManagedObjectContext { return managedObjectContext }
    func testSave(_ moc: NSManagedObjectContext) {
        save(moc)
    }
}

#endif
