import CocoaLumberjackSwift

class RemoteNotificationsOperationsController: NSObject {
    private let apiController: RemoteNotificationsAPIController
    private let modelController: RemoteNotificationsModelController?
    private let operationQueue: OperationQueue
    private let preferredLanguageCodesProvider: WMFPreferredLanguageInfoProvider
    
    var viewContext: NSManagedObjectContext? {
        return modelController?.viewContext
    }

    private var isLocked: Bool = false {
        didSet {
            if isLocked {
                stop()
            }
        }
    }

    required init(session: Session, configuration: Configuration, preferredLanguageCodesProvider: WMFPreferredLanguageInfoProvider) {
        apiController = RemoteNotificationsAPIController(session: session, configuration: configuration)
        var modelControllerInitializationError: Error?
        modelController = RemoteNotificationsModelController(&modelControllerInitializationError)
        if let modelControllerInitializationError = modelControllerInitializationError {
            DDLogError("Failed to initialize RemoteNotificationsModelController and RemoteNotificationsOperationsDeadlineController: \(modelControllerInitializationError)")
            isLocked = true
        }

        operationQueue = OperationQueue()
        
        self.preferredLanguageCodesProvider = preferredLanguageCodesProvider
        
        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(modelControllerDidLoadPersistentStores(_:)), name: RemoteNotificationsModelController.didLoadPersistentStoresNotification, object: nil)
    }
    
    func deleteOldDatabaseFiles() throws {
        let modelName = RemoteNotificationsModelController.modelName
        let sharedAppContainerURL = FileManager.default.wmf_containerURL()
        let legacyRemoteNotificationsStorageUrl = sharedAppContainerURL.appendingPathComponent(modelName)
        let legecyJournalShmUrl = sharedAppContainerURL.appendingPathComponent("\(modelName)-shm")
        let legecyJournalWalUrl = sharedAppContainerURL.appendingPathComponent("\(modelName)-wal")
        
        try FileManager.default.removeItem(at: legacyRemoteNotificationsStorageUrl)
        try FileManager.default.removeItem(at: legecyJournalShmUrl)
        try FileManager.default.removeItem(at: legecyJournalWalUrl)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    public func stop() {
        operationQueue.cancelAllOperations()
    }
    
    func fetchNewPushNotifications(_ completion: @escaping (Result<[RemoteNotificationsAPIController.NotificationsResult.Notification], Error>) -> Void) {
        
        guard Bundle.main.isAppExtension else {
            assertionFailure("This method only designed to fetch from the Notification Service Extension")
            completion(.failure(RequestError.invalidParameters))
            return
        }
        
        preferredLanguageCodesProvider.getPreferredLanguageCodes { [weak self] preferredLanguageCodes in
            
            guard let self = self else {
                return
            }
            
            //TODO: integrate this primary language into WMFPreferredLanguageInfoProvider rather than just grabbing the first preferredLanguageCode.
            guard let primaryLanguageCode = preferredLanguageCodes.first else {
                completion(.failure(RequestError.invalidParameters))
                return
            }
            
            self.apiController.getUnreadPushNotifications(from: primaryLanguageCode) { result, error in
                
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let fetchedNotifications = result?.list else {
                    completion(.failure(RequestError.unexpectedResponse))
                    return
                }
                
                //TODO: here pull persisted cache of keys already seen, save in variable
                //TODO: prune persisted keys of any > 1 day? ago.
                //TODO: here filter out new unread fetched notifications > 10mins ago.
                //TODO: filter out those new unread fetched notifications that are already in remaining persisted keys
                completion(.success(fetchedNotifications))
                //TODO: add whatever notification content we're showing to persisted keys, persist again for next time
            }
        }
        
        
    }
    
    func fetchFirstPageNotifications(_ completion: @escaping () -> Void) {
    
        let completeEarly = {
            self.operationQueue.addOperation(completion)
        }

        guard !isLocked else {
            completeEarly()
            return
        }
        
        guard let modelController = modelController else {
            assertionFailure("Failure setting up notifications core data stack.")
            return
        }
        
        preferredLanguageCodesProvider.getPreferredLanguageCodes({ [weak self] (preferredLanguageCodes) in
            
            guard let self = self else {
                return
            }
            
            let languageCodes = preferredLanguageCodes + ["wikidata", "commons"]
            var operations: [RemoteNotificationsFetchFirstPageOperation] = []
            for languageCode in languageCodes {
                
                let operation = RemoteNotificationsFetchFirstPageOperation(with: self.apiController, modelController: modelController, languageCode: languageCode, cookieDomain: self.cookieDomainForLanguageCode(languageCode))
                operations.append(operation)
            }
            
            let completionOperation = BlockOperation(block: completion)
            completionOperation.queuePriority = .veryHigh
            
            for operation in operations {
                completionOperation.addDependency(operation)
            }
            
            
            self.operationQueue.addOperations(operations + [completionOperation], waitUntilFinished: false)
        })
    }
    
    private func cookieDomainForLanguageCode(_ languageCode: String) -> String {
        switch languageCode {
        case "wikidata":
            return Configuration.current.wikidataCookieDomain
        case "commons":
            return Configuration.current.commonsCookieDomain
        default:
            return Configuration.current.wikipediaCookieDomain
        }
    }

    // MARK: Notifications
    
    @objc private func modelControllerDidLoadPersistentStores(_ note: Notification) {
        if let object = note.object, let error = object as? Error {
            DDLogDebug("RemoteNotificationsModelController failed to load persistent stores with error \(error); stopping RemoteNotificationsOperationsController")
            isLocked = true
        } else {
            isLocked = false
        }
    }
}
