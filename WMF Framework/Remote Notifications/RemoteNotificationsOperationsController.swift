import CocoaLumberjackSwift

enum RemoteNotificationsProject {
    case language(String)
    case commons
    case wikidata
    
    var notificationsApiWikiIdentifier: String {
        switch self {
        case .language(let languageCode):
            return languageCode + "wiki"
        case .commons:
            return "commonswiki"
        case .wikidata:
            return "wikidatawiki"
        }
    }
}

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
    
    func deleteLegacyDatabaseFiles() throws {
        modelController?.deleteLegacyDatabaseFiles()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    public func stop() {
        operationQueue.cancelAllOperations()
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

            var projects: [RemoteNotificationsProject] = []
            for languageCode in preferredLanguageCodes {
                projects.append(.language(languageCode))
            }
            projects.append(.commons)
            projects.append(.wikidata)
            
            var operations: [RemoteNotificationsFetchFirstPageOperation] = []
            for project in projects {
                
                let operation = RemoteNotificationsFetchFirstPageOperation(with: self.apiController, modelController: modelController, project: project, cookieDomain: self.cookieDomainForProject(project))
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
    
    private func cookieDomainForProject(_ project: RemoteNotificationsProject) -> String {
        switch project {
        case .wikidata:
            return Configuration.current.wikidataCookieDomain
        case .commons:
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
