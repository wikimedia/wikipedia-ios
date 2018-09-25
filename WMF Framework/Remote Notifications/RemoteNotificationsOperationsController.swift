class RemoteNotificationsOperationsController {
    private let apiController: RemoteNotificationsAPIController
    private let modelController: RemoteNotificationsModelController

    private let syncTimeInterval: TimeInterval = 10
    private var syncTimer: Timer?
    private let operationQueue: OperationQueue

    required init() {
        apiController = RemoteNotificationsAPIController()
        modelController = RemoteNotificationsModelController()

        operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
    }

    public func start() {
        guard syncTimer == nil else {
            assertionFailure()
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

        let markAsReadOperation = RemoteNotificationsMarkAsReadOperation(with: apiController, modelController: modelController)
        let fetchOperation = RemoteNotificationsFetchOperation(with: apiController, modelController: modelController)
        fetchOperation.addDependency(markAsReadOperation)
        operationQueue.addOperation(markAsReadOperation)
        operationQueue.addOperation(fetchOperation)
    }
}
