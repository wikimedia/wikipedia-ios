import CocoaLumberjackSwift

//TODO: clean up this file. only operations-related methods should call into operations controller, otherwise most other things should be calling straight to the model controller
@objc public final class RemoteNotificationsController: NSObject {
    private let operationsController: RemoteNotificationsOperationsController
    private let refreshDeadlineController = RemoteNotificationsRefreshDeadlineController()
    private let authManager: WMFAuthenticationManager

    public static let didUpdateFilterStateNotification = NSNotification.Name(rawValue: "RemoteNotificationsControllerDidUpdateFilterState")
    
    public var viewContext: NSManagedObjectContext? {
        return operationsController.viewContext
    }
    
    public let configuration: Configuration
    
    @objc public required init(session: Session, configuration: Configuration, languageLinkController: MWKLanguageLinkController, authManager: WMFAuthenticationManager) {
        operationsController = RemoteNotificationsOperationsController(session: session, configuration: configuration, languageLinkController: languageLinkController, authManager: authManager)
        self.configuration = configuration
        self.authManager = authManager
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(authManagerDidLogIn), name:WMFAuthenticationManager.didLogInNotification, object: nil)
    }
    
    @objc private func applicationDidBecomeActive() {
        refreshNotifications(force: false) { _ in
            //
        }
    }
    
    @objc private func authManagerDidLogIn() {
        importNotificationsIfNeeded { _ in
            //
        }
    }
    
    @objc func deleteLegacyDatabaseFiles() {
        do {
            try operationsController.deleteLegacyDatabaseFiles()
        } catch (let error) {
            DDLogError("Failure deleting legacy RemoteNotifications database files: \(error)")
        }
    }
        
    public func importNotificationsIfNeeded(_ completion: @escaping (Error?) -> Void) {
        
        guard authManager.isLoggedIn else {
            completion(RequestError.unauthenticated)
            return
        }
        
        operationsController.importNotificationsIfNeeded(completion)
    }
    
    public func refreshNotifications(force: Bool, completion: @escaping (Error?) -> Void) {
        
        guard authManager.isLoggedIn else {
            completion(RequestError.unauthenticated)
            return
        }
        
        if !force && !refreshDeadlineController.shouldRefresh {
            completion(nil)
            return
        }
        
        operationsController.refreshNotifications(completion)
        refreshDeadlineController.reset()
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
        fetchRequest.predicate = predicateForFilterSavedState(filterState)
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
        
        var countOfFilters = countOfTypeFilters
        
        if filterState.readStatus == .read || filterState.readStatus == .unread {
            countOfFilters = 1
        }
        
        return countOfFilters
    }
    
    public var countOfTypeFilters: Int {
        return filterState.types.count
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
               let persistentFilters = RemoteNotificationsFilterState(nsDictionary: persistentFiltersDict, languageLinkController: languageLinkController) {
                self.filterState = persistentFilters
                self.cachedShowingInboxProjects = self.cachedAllInboxProjects.subtracting(persistentFilters.projects)
                
            } else {
                self.filterState = RemoteNotificationsFilterState(readStatus: .all, types: [], projects: [])
                self.cachedShowingInboxProjects = self.cachedAllInboxProjects
            }
            
            completion()
        }
        
        
    }
    
    private func predicateForFilterSavedState(_ filterState: RemoteNotificationsFilterState) -> NSPredicate? {
        
        var readStatusPredicate: NSPredicate?
        let readStatus = filterState.readStatus
        
        switch readStatus {
        case .all:
            readStatusPredicate = nil
        case .read:
            readStatusPredicate = NSPredicate(format: "isRead == %@", NSNumber(value: true))
        case .unread:
            readStatusPredicate = NSPredicate(format: "isRead == %@", NSNumber(value: false))
        }
        
        let types = filterState.types
        let filterTypePredicates: [NSPredicate] = types.compactMap { settingType in
            let categoryStrings = RemoteNotification.categoryStringsForRemoteNotificationType(type: settingType)
            let typeStrings = RemoteNotification.typeStringsForRemoteNotificationType(type: settingType)
            
            guard categoryStrings.count > 0 && typeStrings.count > 0 else {
                return nil
            }
            
            return NSPredicate(format: "NOT (categoryString IN %@ AND typeString IN %@)", categoryStrings, typeStrings)
        }
        
        let projects = filterState.projects
        let projectPredicates: [NSPredicate] = projects.compactMap { return NSPredicate(format: "NOT (wiki == %@)", $0.notificationsApiWikiIdentifier) }
        
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

    public func inboxCount() -> Int {
        assert(Thread.isMainThread)
        
        guard let viewContext = self.viewContext else {
            DDLogError("Failure fetching notifications from persistence: missing viewContext")
            return 0
        }
        
        let fetchRequest: NSFetchRequest<RemoteNotification> = RemoteNotification.fetchRequest()
        
        do {
            return try viewContext.count(for: fetchRequest)
        } catch {
            DDLogError("Failure fetching notifications from persistence: \(error)")
            return 0
        }
    }

    public lazy var filterState: RemoteNotificationsFilterState = {
        return RemoteNotificationsFilterState(readStatus: .all, types: [], projects: [])
    }() {
        didSet {
            
            //save to library
            operationsController.setFilterSettingsToLibrary(dictionary: filterState.serialize())
            cachedShowingInboxProjects = cachedAllInboxProjects.subtracting(filterState.projects)
            
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
    
    func serialize() -> NSDictionary? {
        let mutableDictionary = NSMutableDictionary()
        let numReadStatus = NSNumber(value: readStatus.rawValue)
        mutableDictionary.setValue(numReadStatus, forKey: "readStatus")
        let typeIdentifiers = types.compactMap { $0.filterIdentifier as NSString? }
        mutableDictionary.setValue(NSArray(array: typeIdentifiers), forKey: "types")
        let projectIdentifiers = projects.compactMap { $0.notificationsApiWikiIdentifier as NSString? }
        mutableDictionary.setValue(NSArray(array: projectIdentifiers), forKey: "projects")
        
        return mutableDictionary.copy() as? NSDictionary
    }
    
    init?(nsDictionary: NSDictionary, languageLinkController: MWKLanguageLinkController) {
        
        guard let dictionary = nsDictionary as? [String: AnyObject] else {
            return nil
        }
        
        guard let numReadStatus = dictionary["readStatus"] as? NSNumber,
              let readStatus = ReadStatus(rawValue: numReadStatus.intValue),
              let typeIdentifiers = dictionary["types"] as? [NSString],
              let projectApiIdentifiers = dictionary["projects"] as? [NSString] else {
                  return nil
              }
        
        let types = typeIdentifiers.compactMap { RemoteNotificationType(from: $0 as String) }
        let projects = projectApiIdentifiers.compactMap { RemoteNotificationsProject(apiIdentifier: $0 as String, languageLinkController: languageLinkController) }
        
        
        self.readStatus = readStatus
        self.types = types
        self.projects = projects
    }
}
