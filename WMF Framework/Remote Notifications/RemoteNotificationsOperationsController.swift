class RemoteNotificationsOperationsController {
    private let apiController: RemoteNotificationsAPIController
    private let modelController: RemoteNotificationsModelController
    private let timeController: RemoteNotificationsOperationsTimeController

    private let operationQueue: OperationQueue
    private var isLocked: Bool = false {
        didSet {
            if isLocked {
                stop()
            }
        }
    }

    required init(with session: Session) {
        apiController = RemoteNotificationsAPIController(with: session)
        modelController = RemoteNotificationsModelController()
        timeController = RemoteNotificationsOperationsTimeController(with: modelController.managedObjectContext)

        operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1

        NotificationCenter.default.addObserver(self, selector: #selector(didMakeAuthorizedWikidataDescriptionEdit), name: WikidataDescriptionEditingController.DidMakeAuthorizedWikidataDescriptionEditNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(modelControllerDidLoadPersistentStores(_:)), name: RemoteNotificationsModelController.didLoadPersistentStoresNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    public func start() {
        guard !isLocked else {
            return
        }
        guard timeController.wasSyncTimerInvalidated else {
            stop()
            start()
            return
        }
        timeController.setSyncTimer(target: self, selector: #selector(sync))
    }

    public func stop() {
        timeController.invalidateSyncTimer()
        operationQueue.cancelAllOperations()
    }

    @objc private func sync() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(sync), object: nil)
        guard operationQueue.operationCount == 0 else {
            return
        }
        guard WMFAuthenticationManager.sharedInstance.isLoggedIn else {
            stop()
            return
        }
        guard timeController.validateTime() else {
            return
        }

        let markAsReadOperation = RemoteNotificationsMarkAsReadOperation(with: apiController, modelController: modelController)
        let fetchOperation = RemoteNotificationsFetchOperation(with: apiController, modelController: modelController)
        fetchOperation.addDependency(markAsReadOperation)
        operationQueue.addOperation(markAsReadOperation)
        operationQueue.addOperation(fetchOperation)
    }


    // MARK: Notifications

    @objc private func didMakeAuthorizedWikidataDescriptionEdit(_ note: Notification) {
        timeController.resetStartTime()
    }

    @objc private func modelControllerDidLoadPersistentStores(_ note: Notification) {
        if let object = note.object, let error = object as? Error {
            DDLogDebug("RemoteNotificationsModelController failed to load persistent stores with error \(error); stopping RemoteNotificationsOperationsController")
            isLocked = true
        } else {
            isLocked = false
        }
    }
}

final class RemoteNotificationsOperationsTimeController {
    private let remoteNotificationsContext: NSManagedObjectContext

    private let syncTimeInterval: TimeInterval = 15
    private var syncTimer: Timer?

    let startTimeKey = "WMFRemoteNotificationsOperationsStartTime"
    let deadline: TimeInterval = 86400 // 24 hours
    private var now: CFAbsoluteTime {
        return CFAbsoluteTimeGetCurrent()
    }

    init(with remoteNotificationsContext: NSManagedObjectContext) {
        self.remoteNotificationsContext = remoteNotificationsContext
    }

    public func setSyncTimer(target: Any, selector: Selector) {
        syncTimer = Timer.scheduledTimer(timeInterval: syncTimeInterval, target: target, selector: selector, userInfo: nil, repeats: true)
    }

    public var wasSyncTimerInvalidated: Bool {
        return syncTimer == nil
    }

    public func invalidateSyncTimer() {
        syncTimer?.invalidate()
        syncTimer = nil
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

    public func validateTime() -> Bool {
        if let startTime = startTime {
            guard now - startTime < deadline else {
                return false
            }
        } else {
            startTime = now
        }
        return true
    }

    public func resetStartTime() {
        startTime = now
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
