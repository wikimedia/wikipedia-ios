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
    
    public func fetchFirstPageNotifications(_ completion: @escaping () -> Void) {
        operationsController.fetchFirstPageNotifications(completion)
    }
    
    public func fetchedResultsController() -> NSFetchedResultsController<RemoteNotification>? {
        
        guard let viewContext = self.viewContext else {
            return nil
        }
        
        let fetchRequest: NSFetchRequest<RemoteNotification> = RemoteNotification.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: viewContext, sectionNameKeyPath: nil, cacheName: nil)

        return fetchedResultsController
    }
}
