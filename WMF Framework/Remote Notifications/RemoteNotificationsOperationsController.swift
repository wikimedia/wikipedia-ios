class RemoteNotificationsOperationsController {
    private let apiController: RemoteNotificationsAPIController
    private let modelController: RemoteNotificationsModelController
    weak var viewContext: NSManagedObjectContext?

    private let syncTimeInterval: TimeInterval = 15
    private var syncTimer: Timer?
    private let operationQueue: OperationQueue
    private var isLocked: Bool = false {
        didSet {
            if isLocked {
                stop()
            }
        }
    }

    required init(with viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        
        apiController = RemoteNotificationsAPIController()
        modelController = RemoteNotificationsModelController()

        operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1

        NotificationCenter.default.addObserver(self, selector: #selector(didMakeAuthorizedWikidataDescriptionEdit), name: WikidataDescriptionEditingController.DidMakeAuthorizedWikidataDescriptionEditNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(modelControllerDidLoadPersistentStores(_:)), name: RemoteNotificationsModelController.ModelControllerDidLoadPersistentStoresNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    let startTimeKey = "WMFRemoteNotificationsOperationsStartTime"
    let deadline: TimeInterval = 86400 // 24 hours
    private var now: CFAbsoluteTime {
        return CFAbsoluteTimeGetCurrent()
    }

    private var startTime: CFAbsoluteTime? {
        set {
            assertMainThreadAndViewContext()
            if let newValue = newValue {
                viewContext?.wmf_setValue(NSNumber(value: newValue), forKey: startTimeKey)
            } else {
                viewContext?.wmf_setValue(nil, forKey: startTimeKey)
            }
        }
        get {
            assertMainThreadAndViewContext()
            let keyValue = viewContext?.wmf_keyValue(forKey: startTimeKey)
            guard let value = keyValue?.value else {
                return nil
            }
            guard let number = value as? NSNumber else {
                assertionFailure("Expected keyValue \(startTimeKey) to be of type NSNumber")
                return nil
            }
            return number.doubleValue
        }
    }

    private func assertMainThreadAndViewContext() {
        assert(Thread.isMainThread)
        assert(viewContext != nil)
    }

    public func start() {
        guard !isLocked else {
            return
        }
        guard syncTimer == nil else {
            assertionFailure("Timer should be nil; stop the controller before restarting it")
            return
        }
        syncTimer = Timer.scheduledTimer(timeInterval: syncTimeInterval, target: self, selector: #selector(sync), userInfo: nil, repeats: true)
    }

    public func stop() {
        syncTimer?.invalidate()
        syncTimer = nil
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
        if let startTime = startTime {
            guard now - startTime < deadline else {
                return
            }
        } else {
            startTime = now
        }
        let markAsReadOperation = RemoteNotificationsMarkAsReadOperation(with: apiController, modelController: modelController)
        let fetchOperation = RemoteNotificationsFetchOperation(with: apiController, modelController: modelController)
        fetchOperation.addDependency(markAsReadOperation)
        operationQueue.addOperation(markAsReadOperation)
        operationQueue.addOperation(fetchOperation)
    }


    // MARK: Notifications

    @objc private func didMakeAuthorizedWikidataDescriptionEdit(_ note: Notification) {
        startTime = now
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
