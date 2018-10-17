class RemoteNotificationsOperationsController: NSObject {
    private let apiController: RemoteNotificationsAPIController
    private let modelController: RemoteNotificationsModelController?
    private let deadlineController: RemoteNotificationsOperationsDeadlineController?
    private let operationQueue: OperationQueue
    private var didMakeAuthorizedTitleDescriptionEditObserver: NSKeyValueObservation?

    private var isLocked: Bool = false {
        didSet {
            if isLocked {
                stop()
            }
        }
    }

    required init(with session: Session) {
        apiController = RemoteNotificationsAPIController(with: session)
        var modelControllerInitializationError: Error?
        modelController = RemoteNotificationsModelController(&modelControllerInitializationError)
        deadlineController = RemoteNotificationsOperationsDeadlineController(with: modelController?.managedObjectContext)
        if let modelControllerInitializationError = modelControllerInitializationError {
            DDLogError("Failed to initialize RemoteNotificationsModelController and RemoteNotificationsOperationsDeadlineController: \(modelControllerInitializationError)")
            isLocked = true
        }

        operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1

        super.init()

        didMakeAuthorizedTitleDescriptionEditObserver = UserDefaults.wmf.observe(\.didMakeAuthorizedTitleDescriptionEdit, options: [.new], changeHandler: { (userDefaults, change) in
            self.deadlineController?.resetDeadline()
        })

        NotificationCenter.default.addObserver(self, selector: #selector(modelControllerDidLoadPersistentStores(_:)), name: RemoteNotificationsModelController.didLoadPersistentStoresNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        didMakeAuthorizedTitleDescriptionEditObserver = nil
    }

    public func stop() {
        operationQueue.cancelAllOperations()
    }

    @objc private func sync(_ completion: @escaping () -> Void) {
        guard !isLocked else {
            return
        }
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(sync), object: nil)
        guard operationQueue.operationCount == 0 else {
            return
        }
        guard WMFAuthenticationManager.sharedInstance.isLoggedIn else {
            stop()
            return
        }
        guard UserDefaults.wmf.didMakeAuthorizedTitleDescriptionEdit else {
            return
        }
        deadlineController?.performIfBeforeDeadline { [weak self] in
            guard
                let modelController = self?.modelController,
                let apiController = self?.apiController,
                let operationQueue = self?.operationQueue else {
                    return
            }
            let markAsReadOperation = RemoteNotificationsMarkAsReadOperation(with: apiController, modelController: modelController)
            let fetchOperation = RemoteNotificationsFetchOperation(with: apiController, modelController: modelController)
            let completionOperation = BlockOperation(block: completion)
            fetchOperation.addDependency(markAsReadOperation)
            completionOperation.addDependency(fetchOperation)
            operationQueue.addOperation(markAsReadOperation)
            operationQueue.addOperation(fetchOperation)
            operationQueue.addOperation(completionOperation)
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

extension RemoteNotificationsOperationsController: PeriodicWorker {
    func doPeriodicWork(_ completion: @escaping () -> Void) {
        sync(completion)
    }
}

extension RemoteNotificationsOperationsController: BackgroundFetcher {
    func performBackgroundFetch(_ completion: @escaping (UIBackgroundFetchResult) -> Void) {
        doPeriodicWork {
            completion(.noData)
        }
    }
}

// MARK: RemoteNotificationsOperationsDeadlineController

final class RemoteNotificationsOperationsDeadlineController {
    private let remoteNotificationsContext: NSManagedObjectContext

    init?(with remoteNotificationsContext: NSManagedObjectContext?) {
        guard let remoteNotificationsContext = remoteNotificationsContext else {
            return nil
        }
        self.remoteNotificationsContext = remoteNotificationsContext
    }

    let startTimeKey = "WMFRemoteNotificationsOperationsStartTime"
    let deadline: TimeInterval = 86400 // 24 hours
    private var now: CFAbsoluteTime {
        return CFAbsoluteTimeGetCurrent()
    }

    private func save() {
        guard remoteNotificationsContext.hasChanges else {
            return
        }
        do {
            try remoteNotificationsContext.save()
        } catch let error {
            DDLogError("Error saving managedObjectContext: \(error)")
        }
    }

    public func performIfBeforeDeadline(_ eventHandler: @escaping () -> Void) {
        if let startTime = startTime {
            guard now - startTime < deadline else {
                return
            }
        } else {
            startTime = now
        }
        eventHandler()
    }

    private var startTime: CFAbsoluteTime? {
        set {
            let moc = remoteNotificationsContext
            moc.perform {
                if let newValue = newValue {
                    moc.wmf_setValue(NSNumber(value: newValue), forKey: self.startTimeKey)
                } else {
                    moc.wmf_setValue(nil, forKey: self.startTimeKey)
                }
                self.save()
            }
        }
        get {
            let moc = remoteNotificationsContext
            let value: CFAbsoluteTime? = moc.performWaitAndReturn {
                let keyValue = remoteNotificationsContext.wmf_keyValue(forKey: startTimeKey)
                guard let value = keyValue?.value else {
                    return nil
                }
                guard let number = value as? NSNumber else {
                    assertionFailure("Expected keyValue \(startTimeKey) to be of type NSNumber")
                    return nil
                }
                return number.doubleValue
            }
            return value
        }
    }

    public func resetDeadline() {
        startTime = now
    }
}

private extension NSManagedObjectContext {
    func performWaitAndReturn<T>(_ block: () -> T?) -> T? {
        var result: T? = nil
        performAndWait {
            result = block()
        }
        return result
    }
}
