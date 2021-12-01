import CocoaLumberjackSwift

//TODO: clean up this file. only operations-related methods should call into operations controller, otherwise most other things should be calling straight to the model controller
@objc public final class RemoteNotificationsController: NSObject {
    private let operationsController: RemoteNotificationsOperationsController
    
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
    
    public func markAsReadOrUnread(identifierGroups: Set<RemoteNotification.IdentifierGroup>, shouldMarkRead: Bool, languageLinkController: MWKLanguageLinkController) {
        operationsController.markAsReadOrUnread(identifierGroups: identifierGroups, shouldMarkRead: shouldMarkRead, languageLinkController: languageLinkController)
    }
    
    public func markAllAsRead(languageLinkController: MWKLanguageLinkController) {
        operationsController.markAllAsRead(languageLinkController: languageLinkController)
    }
    
    public func fetchNotifications(fetchLimit: Int = 50, fetchOffset: Int = 0) -> [RemoteNotification] {
        assert(Thread.isMainThread)
        
        guard let viewContext = self.viewContext else {
            DDLogError("Failure fetching notifications from persistence: missing viewContext")
            return []
        }
        
        let fetchRequest: NSFetchRequest<RemoteNotification> = RemoteNotification.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        fetchRequest.predicate = predicateForFilterSavedState(filterSavedState)
        fetchRequest.fetchLimit = fetchLimit
        fetchRequest.fetchOffset = fetchOffset
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            DDLogError("Failure fetching notifications from persistence: \(error)")
            return []
        }
    }
    
    @objc public var numberOfUnreadNotifications: Int {
        return self.operationsController
            .numberOfUnreadNotifications ?? 0
    }
    
    public func listAllProjectsFromLocalNotifications(completion: @escaping ([RemoteNotificationsProject]) -> Void) {
        operationsController.listAllProjectsFromLocalNotifications(completion: completion)
    }
    
    public var areFiltersEnabled: Bool {
        return countOfFilters > 0
    }
    
    public var countOfFilters: Int {
        let savedState = filterSavedState
        
        var countOfFilters = 0
        if savedState.readStatusSetting == .read || savedState.readStatusSetting == .unread {
            countOfFilters = 1
        }
        
        countOfFilters += savedState.filterTypeSetting.count
        
        return countOfFilters
    }
    
    public lazy var filterSavedState: RemoteNotificationsFiltersSavedState = {
        //todo: extract from persistence
        return RemoteNotificationsFiltersSavedState(readStatusSetting: .all, filterTypeSetting: [], projectsSetting: [])
    }() {
        didSet {
            //todo: save to persistence
        }
    }
    
    private func predicateForFilterSavedState(_ filterSavedState: RemoteNotificationsFiltersSavedState) -> NSPredicate? {
        
        var readStatusPredicate: NSPredicate?
        let readStatusSetting = filterSavedState.readStatusSetting
        
        switch readStatusSetting {
        case .all:
            readStatusPredicate = nil
        case .read:
            readStatusPredicate = NSPredicate(format: "isRead == %@", NSNumber(value: true))
        case .unread:
            readStatusPredicate = NSPredicate(format: "isRead == %@", NSNumber(value: false))
        }
        
        let filterTypeSetting = filterSavedState.filterTypeSetting
        let filterTypePredicates: [NSPredicate] = filterTypeSetting.compactMap { settingType in
            let categoryStrings = RemoteNotification.categoryStringsForRemoteNotificationType(type: settingType)
            let typeStrings = RemoteNotification.typeStringsForRemoteNotificationType(type: settingType)
            
            guard categoryStrings.count > 0 && typeStrings.count > 0 else {
                return nil
            }
            
            return NSPredicate(format: "NOT (categoryString IN %@ AND typeString IN %@)", categoryStrings, typeStrings)
        }
        
        guard readStatusPredicate != nil || filterTypePredicates.count > 0 else {
            return nil
        }
        
        let combinedFilterTypePredicate = NSCompoundPredicate(andPredicateWithSubpredicates: filterTypePredicates)
        
        if let readStatusPredicate = readStatusPredicate {
            return filterTypePredicates.count > 0 ? NSCompoundPredicate(andPredicateWithSubpredicates: [readStatusPredicate, combinedFilterTypePredicate]) : readStatusPredicate
        }
        
        return combinedFilterTypePredicate
    }
}

public struct RemoteNotificationsFiltersSavedState {
    
    public enum ReadStatus: Int, CaseIterable {
        case all
        case read
        case unread
    }
    
    public let readStatusSetting: ReadStatus
    public let filterTypeSetting: [RemoteNotificationType]
    public let projectsSetting: [RemoteNotificationsProject]
    
    public init(readStatusSetting: ReadStatus, filterTypeSetting: [RemoteNotificationType], projectsSetting: [RemoteNotificationsProject]) {
        self.readStatusSetting = readStatusSetting
        self.filterTypeSetting = filterTypeSetting
        self.projectsSetting = projectsSetting
    }
}
