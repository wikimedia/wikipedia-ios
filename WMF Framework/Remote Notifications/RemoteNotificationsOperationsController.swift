class RemoteNotificationsOperationsController: NSObject {
    private let apiController: RemoteNotificationsAPIController
    private let modelController: RemoteNotificationsModelController?
    private let deadlineController: RemoteNotificationsOperationsDeadlineController?
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

        NotificationCenter.default.addObserver(self, selector: #selector(didMakeAuthorizedWikidataDescriptionEdit), name: WikidataDescriptionEditingController.DidMakeAuthorizedWikidataDescriptionEditNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(modelControllerDidLoadPersistentStores(_:)), name: RemoteNotificationsModelController.didLoadPersistentStoresNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    public func stop() {
        operationQueue.cancelAllOperations()
    }

    @objc private func sync(_ completion: @escaping () -> Void) {
        let completeEarly = {
            self.operationQueue.addOperation(completion)
        }

        guard !isLocked else {
            completeEarly()
            return
        }

        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(sync), object: nil)

        guard operationQueue.operationCount == 0 else {
            completeEarly()
            return
        }

        guard WMFAuthenticationManager.sharedInstance.isLoggedIn else {
            stop()
            completeEarly()
            return
        }
        deadlineController?.performIfBeforeDeadline(completeEarly) { [weak self] in
            guard
                let modelController = self?.modelController,
                let apiController = self?.apiController,
                let operationQueue = self?.operationQueue else {
                    completeEarly()
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

    @objc private func didMakeAuthorizedWikidataDescriptionEdit(_ note: Notification) {
        deadlineController?.resetDeadline()
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

    public func performIfBeforeDeadline(_ eventHandler: @escaping () -> Void, completion: () -> Void) {
        guard let startTime = startTime else {
            completion()
            return
        }
        guard now - startTime < deadline else {
            completion()
            return
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
