import CocoaLumberjackSwift

//TODO: clean up this file. only operations-related methods should call into operations controller, otherwise most other things should be calling straight to the model controller
@objc public final class RemoteNotificationsController: NSObject {
    private let operationsController: RemoteNotificationsOperationsController
    
    public var viewContext: NSManagedObjectContext? {
        return operationsController.viewContext
    }
    
    public let configuration: Configuration
    
    @objc public required init(session: Session, configuration: Configuration, languageLinkController: MWKLanguageLinkController) {
        operationsController = RemoteNotificationsOperationsController(session: session, configuration: configuration, languageLinkController: languageLinkController)
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
        if let filterSavedState = filterSavedState {
            fetchRequest.predicate = predicateForFilterSavedState(filterSavedState)
        }
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
    
    public func listAllProjectsFromLocalNotifications(languageLinkController: MWKLanguageLinkController, completion: @escaping ([RemoteNotificationsProject]) -> Void) {
        operationsController.listAllProjectsFromLocalNotifications(languageLinkController: languageLinkController, completion: completion)
    }
    
    public var areFiltersEnabled: Bool {
        
        return countOfAllFilters > 0
    }
    
    public var areInboxFiltersEnabled: Bool {

        return cachedShowingInboxProjects.count < cachedAllInboxProjects.count
    }
    
    public var countOfAllFilters: Int {
        
        guard let savedState = filterSavedState else {
            return 0
        }
        
        var countOfFilters = countOfTypeFilters
        
        if savedState.readStatusSetting == .read || savedState.readStatusSetting == .unread {
            countOfFilters = 1
        }
        
        return countOfFilters
    }
    
    public var countOfTypeFilters: Int {
        
        guard let savedState = filterSavedState else {
            return 0
        }
        
        return savedState.filterTypeSetting.count
    }
    
    public var filterSavedState: RemoteNotificationsFiltersSavedState? {
        didSet {
            
            //save to library
            operationsController.setFilterSettingsToLibrary(dictionary: filterSavedState?.serialize())
            if let filterSavedState = filterSavedState {
                cachedShowingInboxProjects = cachedAllInboxProjects.subtracting(filterSavedState.projectsSetting)
            } else {
                cachedShowingInboxProjects = cachedAllInboxProjects
            }
        }
    }
    
    public private(set) var cachedAllInboxProjects: Set<RemoteNotificationsProject> = []
    public private(set) var cachedShowingInboxProjects: Set<RemoteNotificationsProject> = []
    
    public func allInboxProjects(languageLinkController: MWKLanguageLinkController, completion: @escaping ([RemoteNotificationsProject]) -> Void) {
        
        let sideProjects: Set<RemoteNotificationsProject> = [.commons, .wikidata]
        
        let appLanguageProjects =  languageLinkController.preferredLanguages.map { RemoteNotificationsProject.wikipedia($0.languageCode, $0.localizedName, $0.languageVariantCode) }
        
        var inboxProjects = sideProjects.union(appLanguageProjects)
        
        listAllProjectsFromLocalNotifications(languageLinkController: languageLinkController) { localProjects in
            
            for localProject in localProjects {
                inboxProjects.insert(localProject)
            }
            
            DispatchQueue.main.async {
                self.cachedAllInboxProjects = inboxProjects
                completion(Array(inboxProjects))
            }
        }
        
    }
    
    public func setupInitialFilters(languageLinkController: MWKLanguageLinkController, completion: @escaping () -> Void) {
        
        //populate inbox project cache properties
        allInboxProjects(languageLinkController: languageLinkController) { project in
            //first try to populate in-memory state from persistance. otherwise set up default filters
            if let persistentFiltersDict = self.operationsController.getFilterSettingsFromLibrary(),
               let persistentFilters = RemoteNotificationsFiltersSavedState(nsDictionary: persistentFiltersDict, languageLinkController: languageLinkController) {
                self.filterSavedState = persistentFilters
                self.cachedShowingInboxProjects = self.cachedAllInboxProjects.subtracting(persistentFilters.projectsSetting)
                
            } else {
                self.filterSavedState = RemoteNotificationsFiltersSavedState(readStatusSetting: .all, filterTypeSetting: [], projectsSetting: [])
                self.cachedShowingInboxProjects = self.cachedAllInboxProjects
            }
            
            completion()
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
        
        let projectsSetting = filterSavedState.projectsSetting
        let projectPredicates: [NSPredicate] = projectsSetting.compactMap { return NSPredicate(format: "NOT (wiki == %@)", $0.notificationsApiWikiIdentifier) }
        
        guard readStatusPredicate != nil || filterTypePredicates.count > 0 || projectPredicates.count > 0 else {
            return nil
        }
        
        var combinedFilterTypePredicate: NSPredicate? = nil
        if filterTypePredicates.count > 0 {
            combinedFilterTypePredicate = NSCompoundPredicate(andPredicateWithSubpredicates: filterTypePredicates)
        }
        
        var combinedProjectPredicate: NSPredicate? = nil
        if projectPredicates.count > 0 {
            combinedProjectPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: projectPredicates)
        }
        
        
        let finalPredicates = [readStatusPredicate, combinedFilterTypePredicate, combinedProjectPredicate].compactMap { $0 }
        
        return finalPredicates.count > 0 ? NSCompoundPredicate(andPredicateWithSubpredicates: finalPredicates) : nil
    }

    @objc public func updateCacheWithCurrentUnreadNotificationsCount() {
        let currentCount = numberOfUnreadNotifications
        let sharedCache = SharedContainerCache<PushNotificationsCache>(pathComponent: .pushNotificationsCache, defaultCache: { PushNotificationsCache(settings: .default, notifications: []) })
        var pushCache = sharedCache.loadCache()
        pushCache.currentUnreadCount = currentCount
        sharedCache.saveCache(pushCache)
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
    
    func serialize() -> NSDictionary? {
        let mutableDictionary = NSMutableDictionary()
        let numReadStatus = NSNumber(value: readStatusSetting.rawValue)
        mutableDictionary.setValue(numReadStatus, forKey: "readStatusSetting")
        let typeIdentifiers = filterTypeSetting.compactMap { $0.filterIdentifier as NSString? }
        mutableDictionary.setValue(NSArray(array: typeIdentifiers), forKey: "filterTypeSetting")
        let projectIdentifiers = projectsSetting.compactMap { $0.notificationsApiWikiIdentifier as NSString? }
        mutableDictionary.setValue(NSArray(array: projectIdentifiers), forKey: "projectsSetting")
        
        return mutableDictionary.copy() as? NSDictionary
    }
    
    init?(nsDictionary: NSDictionary, languageLinkController: MWKLanguageLinkController) {
        
        guard let dictionary = nsDictionary as? [String: AnyObject] else {
            return nil
        }
        
        guard let numReadStatus = dictionary["readStatusSetting"] as? NSNumber,
              let readStatus = ReadStatus(rawValue: numReadStatus.intValue),
              let typeIdentifiers = dictionary["filterTypeSetting"] as? [NSString],
              let projectApiIdentifiers = dictionary["projectsSetting"] as? [NSString] else {
                  return nil
              }
        
        let types = typeIdentifiers.compactMap { RemoteNotificationType(from: $0 as String) }
        let projects = projectApiIdentifiers.compactMap { RemoteNotificationsProject(apiIdentifier: $0 as String, languageLinkController: languageLinkController) }
        
        
        self.readStatusSetting = readStatus
        self.filterTypeSetting = types
        self.projectsSetting = projects
    }
}
