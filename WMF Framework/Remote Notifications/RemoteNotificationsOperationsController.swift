import CocoaLumberjackSwift

class RemoteNotificationsOperationsController: NSObject {
    private let apiController: RemoteNotificationsAPIController
    private let modelController: RemoteNotificationsModelController?
    private let operationQueue: OperationQueue
    private let preferredLanguageCodesProvider: WMFPreferredLanguageInfoProvider
    private var isImporting = false
    private var isRefreshing = false
    
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
    
    private var isAvailableForPagingOperations: Bool {
        return !isLocked && !isImporting && !isRefreshing
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
    
    /// Kicks off operations to fetch and persist read and unread history of notifications from app languages, Commons, and Wikidata. Designed to fully import once per installation. Will not attempt if import is already in progress or refreshing is in progress.
    /// - Parameter completion: Block to run once operations have completed. Dispatched to main thread.
    func importNotificationsIfNeeded(_ completion: @escaping () -> Void) {
        
        kickoffPagingOperations(operationType: RemoteNotificationsImportOperation.self, willRunOperationsBlock:{ [weak self] in
                self?.isImporting = true
            }, didRunOperationsBlock: { [weak self] in
                self?.isImporting = false
                completion()
        })
    }
    
    /// Kicks off operations to fetch and persist any new read and unread notifications from app languages, Commons, and Wikidata. Will not attempt if import is already in progress or refreshing is in progress.
    /// - Parameter completion: Block to run once operations have completed. Dispatched to main thread.
    func refreshNotifications(_ completion: @escaping () -> Void) {
        
        kickoffPagingOperations(operationType: RemoteNotificationsRefreshOperation.self,
            willRunOperationsBlock: { [weak self] in
                self?.isRefreshing = true
            }, didRunOperationsBlock: { [weak self] in
                self?.isRefreshing = false
                completion()
        })
    }
    
    /// Method that instantiates the appropriate paging operations for fetching & persisting remote notifications and adds them to the operation queue. Must be called from main thread.
    /// - Parameters:
    ///   - operationType: RemoteNotificationsPagingOperation class to instantiate. Can be an Import or Refresh type.
    ///   - willRunOperationsBlock: Block to run after passing initial common validation, but before operations kick off. Helps with setting gatekeeping flags like isImporting or isRefreshing.
    ///   - didRunOperationsBlock: Block to run after operations have completed. Dispatched to main thread.
    private func kickoffPagingOperations(operationType: RemoteNotificationsPagingOperation.Type, willRunOperationsBlock: () -> Void, didRunOperationsBlock: @escaping () -> Void) {
        
        assert(Thread.isMainThread)
        
        guard isAvailableForPagingOperations else {
            self.operationQueue.addOperation(didRunOperationsBlock)
            return
        }
        
        guard let modelController = modelController else {
            assertionFailure("Failure setting up notifications core data stack.")
            self.operationQueue.addOperation(didRunOperationsBlock)
            return
        }
        
        willRunOperationsBlock()
        
        preferredLanguageCodesProvider.getPreferredLanguageCodes({ [weak self] (preferredLanguageCodes) in
            
            guard let self = self else {
                return
            }

            var projects: [RemoteNotificationsProject] = preferredLanguageCodes.map { .language($0, nil, nil) }
            projects.append(.commons)
            projects.append(.wikidata)
            
            let operations = projects.map { operationType.init(with: self.apiController, modelController: modelController, project: $0) }
            
            let completionOperation = BlockOperation {
                DispatchQueue.main.async {
                    didRunOperationsBlock()
                }
            }
            
            for operation in operations {
                completionOperation.addDependency(operation)
            }
            
            self.operationQueue.addOperations(operations + [completionOperation], waitUntilFinished: false)
        })
    }
    
    func markAsReadOrUnread(notifications: Set<RemoteNotification>, shouldMarkRead: Bool) {
        guard !isLocked,
              let modelController = modelController else {
            return
        }
        
        let operation = RemoteNotificationsMarkReadOrUnreadOperation(with: apiController, modelController: modelController, notifications: notifications, shouldMarkRead: shouldMarkRead)
        
        operationQueue.addOperation(operation)
    }

    
    func markAllAsRead() {
        guard !isLocked,
              let modelController = modelController else {
            return
        }
        
        let operation = RemoteNotificationsMarkAllAsReadOperation(with: apiController, modelController: modelController)
        operationQueue.addOperation(operation)
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
