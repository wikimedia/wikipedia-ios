import Foundation

@objc(WMFEventLoggingService)
class EventLoggingService : NSObject, URLSessionDelegate {
    
    public var pruningAge: TimeInterval = 60*60*24*30 // 30 days
    public var sendImmediatelyOnWWANThreshhold: TimeInterval = 30
    public var readBatchSize = 100
    public var postBatchSize = 100
    

    private static let LoggingEndpoint =
        // production
        "https://meta.wikimedia.org/beacon/event"
        // testing
        // "http://deployment.wikimedia.beta.wmflabs.org/beacon/event";
    
    private let reachabilityManager: AFNetworkReachabilityManager
    private let urlSessionConfiguration: URLSessionConfiguration
    private var urlSession: URLSession?
    private var networkQueue: OperationQueue
    private let postLock = NSLock()
    private var posting = false
    
    private var lastNetworkRequestTimestamp: TimeInterval?
    //private var eventQueue: [EventRecord] = []
    
    private let persistentStoreCoordinator: NSPersistentStoreCoordinator
    private let managedObjectContext: NSManagedObjectContext
    
    @objc(sharedInstance) public static let shared: EventLoggingService = {
//        let session = URLSession.shared
//        let cache = URLCache.shared
        let fileManager = FileManager.default
        var permanentStorageDirectory = fileManager.wmf_containerURL().appendingPathComponent("Event Logging", isDirectory: true)
        var didGetDirectoryExistsError = false
        do {
            try fileManager.createDirectory(at: permanentStorageDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch let error {
            DDLogError("Error creating permanent cache: \(error)")
        }
        do {
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try permanentStorageDirectory.setResourceValues(values)
        } catch let error {
            DDLogError("Error excluding from backup: \(error)")
        }
        
        let permanentStorageURL = permanentStorageDirectory.appendingPathComponent("Events.sqlite")
        DDLogDebug("Events persistent store: \(permanentStorageURL)")
        
        return EventLoggingService(permanentStorageURL: permanentStorageURL)
    }()
    
    private var shouldSendImmediately: Bool {
        
        if self.reachabilityManager.isReachableViaWiFi {
            return true
        }

        if self.reachabilityManager.isReachableViaWWAN,
            let lastNetworkRequestTimestamp = self.lastNetworkRequestTimestamp,
            Date.timeIntervalSinceReferenceDate < (lastNetworkRequestTimestamp + sendImmediatelyOnWWANThreshhold) {
            
            return true
        }
        
        return false
    }
    

    public init(permanentStorageURL: URL, urlSesssionConfiguration: URLSessionConfiguration, reachabilityManager: AFNetworkReachabilityManager) {
        
        self.reachabilityManager = reachabilityManager
        self.urlSessionConfiguration = urlSesssionConfiguration
        self.networkQueue = OperationQueue.main
        
//        self.urlSession = URLSession(configuration: urlSesssionConfiguration)
//        
//        self.urlSession.delegate = self
        
        let bundle = Bundle.wmf
        let modelURL = bundle.url(forResource: "EventLogging", withExtension: "momd")!
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
                abort()
            }
        }
        
        self.persistentStoreCoordinator = psc
        self.managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        self.managedObjectContext.persistentStoreCoordinator = psc
    }
    
    public convenience init(permanentStorageURL: URL) {
     
        let reachabilityManager = AFNetworkReachabilityManager.init(forDomain: URL(string: WMFLoggingEndpoint)!.host!)
        
        let urlSessionConfig = URLSessionConfiguration.default
        urlSessionConfig.httpShouldUsePipelining = true
        urlSessionConfig.allowsCellularAccess = true
        urlSessionConfig.httpMaximumConnectionsPerHost = 2
        urlSessionConfig.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        self.init(permanentStorageURL: permanentStorageURL, urlSesssionConfiguration: urlSessionConfig, reachabilityManager: reachabilityManager)
    }
    
    
    deinit {
        stop()
    }
    
    public func start() -> Void {
        
        self.reachabilityManager.startMonitoring()
        
        self.urlSession = URLSession(configuration: self.urlSessionConfiguration, delegate: self, delegateQueue: nil)
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.WMFNetworkRequestBegan, object: nil, queue: .main) { (note) in
            self.lastNetworkRequestTimestamp = Date.timeIntervalSinceReferenceDate
            //DDLogDebug("last network request: \(String(describing: self.lastNetworkRequestTimestamp))")
        }
        
        prune()

#if DEBUG
    
        self.managedObjectContext.perform {
            do {
                let countFetch: NSFetchRequest<EventRecord> = EventRecord.fetchRequest()
                countFetch.includesSubentities = false
                let count = try self.managedObjectContext.count(for: countFetch)
                DDLogInfo("There are \(count) queued events")
            } catch let error {
                DDLogError(error.localizedDescription)
            }
        }
#endif

    }
    
    public func stop() -> Void {
        self.reachabilityManager.stopMonitoring()
        
        self.urlSession?.finishTasksAndInvalidate()
        
        NotificationCenter.default.removeObserver(self)
        
        do {
            try self.managedObjectContext.save()
        } catch let error {
            DDLogError(error.localizedDescription)
        }
    }
    
    private func prune() -> Void {
        
        self.managedObjectContext.perform {
            let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "WMFEventRecord")
            fetch.returnsObjectsAsFaults = false
            
            let pruneDate = Date().addingTimeInterval(-(self.pruningAge)) as NSDate
            fetch.predicate = NSPredicate(format: "(recorded < %@) OR (posted != nil)", pruneDate)
            let delete = NSBatchDeleteRequest(fetchRequest: fetch)
            delete.resultType = .resultTypeCount

            do {
                let result = try self.managedObjectContext.execute(delete)
                guard let deleteResult = result as? NSBatchDeleteResult else {
                    DDLogError("Could not read NSBatchDeleteResult")
                    return
                }
                
                guard let count = deleteResult.result as? Int else {
                    DDLogError("Could not read NSBatchDeleteResult count")
                    return
                }
                DDLogInfo("Pruned \(count) events")
                
            } catch let error {
                DDLogError("Error pruning events: \(error.localizedDescription)")
            }
        }
    }
    
    public func logEvent(_ event: NSDictionary) -> Void {

        let now = NSDate()
        
        let moc = self.managedObjectContext
        moc.perform {
            let record = NSEntityDescription.insertNewObject(forEntityName: "WMFEventRecord", into: self.managedObjectContext) as! EventRecord
            record.event = event
            record.recorded = now
            
            //self.eventQueue.append(record)
            
            
            if self.shouldSendImmediately {
                //            postEvent(record)
                self.tryPostEvents()
            }
        }
    }
    
    private func tryPostEvents() {

        self.postLock.lock()
        guard !posting else {
            self.postLock.unlock()
            return
        }
        posting = true
        self.postLock.unlock()
        
//        var eventRecords: [EventRecord] = []
        


        let moc = self.managedObjectContext
        moc.perform {
            let fetch: NSFetchRequest<EventRecord> = EventRecord.fetchRequest()
            fetch.sortDescriptors = [NSSortDescriptor.init(key: "recorded", ascending: true)]
            fetch.fetchLimit = self.readBatchSize
            
            do {
                var eventRecords: [EventRecord] = []
                defer {
                    self.postEvents(eventRecords)
                }
                eventRecords = try moc.fetch(fetch)

                
            } catch let error {
                DDLogError(error.localizedDescription)
            }
        }
    }
    
    private func save() -> Void {
        let moc = self.managedObjectContext
        moc.perform {
            do {
                try moc.save()
            } catch let error {
                DDLogError(error.localizedDescription)
            }
        }
    }
    
    private func postEvents(_ eventRecords: [EventRecord]) -> Void {
        
        guard eventRecords.count > 0 else {
            self.postLock.lock()
            self.posting = false
            self.postLock.unlock()
            
            return
        }
        
        self.networkQueue.addOperation({
            
            defer {
                self.postLock.lock()
                self.posting = false
                self.postLock.unlock()
                
                self.prune()
                self.save()
            }

            do {
                for record in eventRecords {
                    try self.postEvent(record)
                }
            } catch let error {
                DDLogError(error.localizedDescription)
            }

        })
    }
    
    private func postEvent(_ eventRecord: EventRecord) throws -> Void {
        
        guard let urlSession = self.urlSession else {
            // TODO: error
            return
        }
        
        guard let payload = eventRecord.event else {
            // TODO: error
            return
        }
        
//        do {
            let payloadJsonData = try JSONSerialization.data(withJSONObject:payload, options: [])
            guard let payloadString = String(data: payloadJsonData, encoding: .utf8) else {
                DDLogError("Could not convert JSON data to string")
                return
            }
            let encodedPayloadJsonString = payloadString.wmf_UTF8StringWithPercentEscapes()
            let urlString = "\(EventLoggingService.LoggingEndpoint)?\(encodedPayloadJsonString)"
            guard let url = URL(string: urlString) else {
                DDLogError("Could not convert string '\(urlString)' to URL object")
                return
            }
            
            var request = URLRequest(url: url)
            request.setValue(WikipediaAppUtils.versionedUserAgent(), forHTTPHeaderField: "User-Agent")
            urlSession.dataTask(with: request).resume()
            urlSession.dataTask(with: request, completionHandler: { (_, response, error) in
                
                if error != nil {
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    return
                }
                
                if httpResponse.statusCode / 100 != 2 {
                    return
                }
                
                eventRecord.posted = NSDate()   
                
            }).resume()
            
//        } catch let error {
//            DDLogError(error.localizedDescription)
//        }
    }
}
