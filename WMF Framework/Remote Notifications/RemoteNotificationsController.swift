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
        guard shouldStart else {
            return
        }
        toggle(on: true)
    }

    private var shouldStart: Bool {
        let isLoggedIn = WMFAuthenticationManager.sharedInstance.isLoggedIn
        let madeAuthorizedWikidataEdit = SessionSingleton.sharedInstance()?.dataStore.wikidataDescriptionEditingController.madeAuthorizedWikidataDescriptionEdit ?? false
        return isLoggedIn && madeAuthorizedWikidataEdit
    }
}
