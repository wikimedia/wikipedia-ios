import CocoaLumberjackSwift

@objc public final class RemoteNotificationsController: NSObject {
    private let operationsController: RemoteNotificationsOperationsController
    
    public var viewContext: NSManagedObjectContext? {
        return operationsController.viewContext
    }
    
    @objc public required init(session: Session, configuration: Configuration, preferredLanguageCodesProvider: WMFPreferredLanguageInfoProvider) {
        operationsController = RemoteNotificationsOperationsController(session: session, configuration: configuration, preferredLanguageCodesProvider: preferredLanguageCodesProvider)
        super.init()
    }
    
    @objc func deleteLegacyDatabaseFiles() {
        do {
            try operationsController.deleteLegacyDatabaseFiles()
        } catch (let error) {
            DDLogError("Failure deleting legacy RemoteNotifications database files: \(error)")
        }
    }
    
    public func importNotificationsIfNeeded(primaryLanguageCompletion: @escaping () -> Void, allLanguagesCompletion: @escaping () -> Void) {
        operationsController.importNotificationsIfNeeded(primaryLanguageCompletion: primaryLanguageCompletion, allLanguagesCompletion: allLanguagesCompletion)
    }
    
    public func refreshNotifications(_ completion: @escaping () -> Void) {
        operationsController.refreshNotifications(completion)
    }
    
    public func fetchNotifications(fetchLimit: Int = 10, fetchOffset: Int = 0) -> [RemoteNotification] {
        assert(Thread.isMainThread)
        
        guard let viewContext = self.viewContext else {
            DDLogError("Failure fetching notifications from persistence: missing viewContext")
            return []
        }
        
        let fetchRequest: NSFetchRequest<RemoteNotification> = RemoteNotification.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        fetchRequest.fetchLimit = fetchLimit
        fetchRequest.fetchOffset = fetchOffset
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            DDLogError("Failure fetching notifications from persistence: \(error)")
            return []
        }
    }
}
