import CocoaLumberjackSwift

@objc public final class RemoteNotificationsController: NSObject {
    private let operationsController: RemoteNotificationsOperationsController

    public static let didUpdateFilterStateNotification = NSNotification.Name(rawValue: "RemoteNotificationsControllerDidUpdateFilterState")
    
    public var viewContext: NSManagedObjectContext? {
        return operationsController.viewContext
    }
    
    public let configuration: Configuration
    
    @objc public required init(session: Session, configuration: Configuration, preferredLanguageCodesProvider: WMFPreferredLanguageInfoProvider) {
        operationsController = RemoteNotificationsOperationsController(session: session, configuration: configuration, preferredLanguageCodesProvider: preferredLanguageCodesProvider)
        self.configuration = configuration
        super.init()
    }
    
    @objc func deleteLegacyDatabaseFiles() {
        do {
            try operationsController.deleteLegacyDatabaseFiles()
        } catch (let error) {
            DDLogError("Failure deleting legacy RemoteNotifications database files: \(error)")
        }
    }
        
    public func importNotificationsIfNeeded(_ completion: @escaping (RemoteNotificationsOperationsError?) -> Void) {
        operationsController.importNotificationsIfNeeded(completion)
    }
    
    public func refreshNotifications(_ completion: @escaping (RemoteNotificationsOperationsError?) -> Void) {
        operationsController.refreshNotifications(completion)
    }

    public func markAsReadOrUnread(identifierGroups: Set<RemoteNotification.IdentifierGroup>, shouldMarkRead: Bool) {
        operationsController.markAsReadOrUnread(identifierGroups: identifierGroups, shouldMarkRead: shouldMarkRead)
    }
    
    public func markAllAsRead() {
        operationsController.markAllAsRead()
    }

    public func fetchNotifications(fetchLimit: Int = 50, fetchOffset: Int = 0) -> [RemoteNotification] {
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

    public lazy var filterState: RemoteNotificationsFilterState = {
        return RemoteNotificationsFilterState(readStatus: .all, types: [], projects: [])
    }() {
        didSet {
            NotificationCenter.default.post(name: RemoteNotificationsController.didUpdateFilterStateNotification, object: nil)
        }
    }

}

public struct RemoteNotificationsFilterState {

    public enum ReadStatus: Int, CaseIterable {
        case all
        case read
        case unread
    }

    public let readStatus: ReadStatus
    public let types: [RemoteNotificationType]
    public let projects: [RemoteNotificationsProject]

    public init(readStatus: ReadStatus, types: [RemoteNotificationType], projects: [RemoteNotificationsProject]) {
        self.readStatus = readStatus
        self.types = types
        self.projects = projects
    }
    
}
