@objc public final class RemoteNotificationsController: NSObject {
    private let operationsController: RemoteNotificationsOperationsController

    @objc public required init(viewContext: NSManagedObjectContext) {
        operationsController = RemoteNotificationsOperationsController(with: viewContext)
        super.init()
    }

    @objc(toggleOn:)
    public func toggle(on: Bool) {
        if on {
            operationsController.start()
        } else {
            operationsController.stop()
        }
    }

    @objc public func stop() {
        toggle(on: false)
    }

    @objc public func start() {
        toggle(on: true)
    }
}
