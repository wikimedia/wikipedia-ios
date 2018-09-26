class RemoteNotificationsOperationsController {
    private let apiController: RemoteNotificationsAPIController
    private let modelController: RemoteNotificationsModelController
    weak var viewContext: NSManagedObjectContext?

    private let syncTimeInterval: TimeInterval = 10
    private var syncTimer: Timer?
    private let operationQueue: OperationQueue

    required init(with viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        
        apiController = RemoteNotificationsAPIController()
        modelController = RemoteNotificationsModelController()

        operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
    }

    let startTimeKey = "WMFRemoteNotificationsOperationsStartTime"
    let deadline: TimeInterval = 86400 // 24 hours
    private var now: CFAbsoluteTime {
        return CFAbsoluteTimeGetCurrent()
    }
    private func setStartTime() {
        assertMainThreadAndViewContext()
        viewContext?.wmf_setValue(NSNumber(value: now), forKey: startTimeKey)
    }
    private func getStartTime() -> CFAbsoluteTime? {
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

    private func assertMainThreadAndViewContext() {
        assert(Thread.isMainThread)
        assert(viewContext != nil)
    }

    public func start() {
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
        if let startTime = getStartTime() {
            guard now - startTime < deadline else {
                return
            }
        } else {
            setStartTime()
        }
        let markAsReadOperation = RemoteNotificationsMarkAsReadOperation(with: apiController, modelController: modelController)
        let fetchOperation = RemoteNotificationsFetchOperation(with: apiController, modelController: modelController)
        fetchOperation.addDependency(markAsReadOperation)
        operationQueue.addOperation(markAsReadOperation)
        operationQueue.addOperation(fetchOperation)
    }
}
