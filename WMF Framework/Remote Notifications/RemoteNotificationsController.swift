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
    
    public var filterState: RemoteNotificationsFilterState = RemoteNotificationsFilterState(readStatus: .all, types: [], projects: []) {
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

        var localizedDescription: String {
            switch self {
            case .all:
                return CommonStrings.notificationsCenterAllNotificationsStatus
            case .read:
                return CommonStrings.notificationsCenterReadNotificationsStatus
            case .unread:
                return CommonStrings.notificationsCenterUnreadNotificationsStatus
            }
        }
    }
    
    public let readStatus: ReadStatus
    public let types: [RemoteNotificationType]
    public let projects: [RemoteNotificationsProject]
    
    public init(readStatus: ReadStatus, types: [RemoteNotificationType], projects: [RemoteNotificationsProject]) {
        self.readStatus = readStatus
        self.types = types
        self.projects = projects
    }

    private var isReadStatusOrTypeFiltered: Bool {
        return (readStatus != .all || !types.isEmpty)
    }

    public var stateDescription: String {
        let filteredBy = WMFLocalizedString("notifications-center-status-filtered-by", value: "Filtered by", comment: "Status header text in Notifications Center displayed when filtering notifications.")

        let allNotifications = WMFLocalizedString("notifications-center-status-all-notifications", value: "All notifications", comment: "Status header text in Notifications Center displayed when viewing unfiltered list of notifications.")

        let headerText = isReadStatusOrTypeFiltered ? filteredBy : allNotifications
        return headerText
    }

    public static var detailDescriptionHighlightDelineator = "**"

    public func detailDescription(totalProjectCount: Int, showingProjectCount: Int) -> String? {
        // Generic templates

        let doubleConcatenationTemplate = WMFLocalizedString("notifications-center-status-double-concatenation", value: "%1$@ in %2$@", comment: "Notifications Center status description. %1$@ is replaced with the currently applied filters and %2$@ is replaced with the count of projects/inboxes.")

        let tripleConcatenationTemplate = WMFLocalizedString("notifications-center-status-triple-concatenation", value: "%1$@ and %2$@ in %3$@", comment: "Notifications Center status description. %1$@ is replaced with the currently applied read status filter, %2$@ is replaced with the count of notification type filters, and %3$@ is replaced with the count of projects/inboxes.")

        // Specific plurals

        let inProjects = WMFLocalizedString("notifications-center-status-in-projects", value: "{{PLURAL:%1$d|1=In 1 project|In %1$d projects}}", comment: "Notifications Center status description when filtering by projects/inboxes. %1$d is replaced by the count of local projects.")

        let projectsPlain = WMFLocalizedString("notifications-center-status-in-projects-plain", value: "{{PLURAL:%1$d|1=1 project|%1$d projects}}", comment: "Notifications Center status description when filtering by projects/inboxes, without preposition. %1$d is replaced by the count of local projects.")

        let typesPlain = WMFLocalizedString("notifications-center-status-in-types", value: "{{PLURAL:%1$d|1=1 type|%1$d types}}", comment: "Notifications Center status description when filtering by types. %1$d is replaced by the count of filtered types.")

        var descriptionString: String?

        switch (readStatus, types.count, projects.count) {
        case (.all, 0, 0):
            // No filtering
            descriptionString = String.localizedStringWithFormat(inProjects, totalProjectCount)
        case (.all, 1..., 0):
            // Only filtering by type
            let typesString = String.localizedStringWithFormat(typesPlain, types.count).highlightDelineated
            let totalProjectString = String.localizedStringWithFormat(projectsPlain, totalProjectCount)
            descriptionString = String.localizedStringWithFormat(doubleConcatenationTemplate, typesString, totalProjectString)
        case (.all, 0, 1...):
            // Only filtering by project/inbox
            descriptionString = String.localizedStringWithFormat(inProjects, showingProjectCount).highlightDelineated
        case (.read, 0, 0), (.unread, 0, 0):
            // Only filtering by read status
            let totalProjectString = String.localizedStringWithFormat(projectsPlain, totalProjectCount)
            descriptionString = String.localizedStringWithFormat(doubleConcatenationTemplate, readStatus.localizedDescription.highlightDelineated, totalProjectString)
        case (.read, 1..., 0), (.unread, 1..., 0):
            // Filtering by read status and type
            let typesString = String.localizedStringWithFormat(typesPlain, types.count).highlightDelineated
            let totalProjectString = String.localizedStringWithFormat(projectsPlain, totalProjectCount)
            descriptionString = String.localizedStringWithFormat(tripleConcatenationTemplate, readStatus.localizedDescription.highlightDelineated, typesString, totalProjectString)
        case (.read, 0, 1...), (.unread, 0, 1...):
            // Filtering by read status and project/inbox
            let projectString = String.localizedStringWithFormat(projectsPlain, showingProjectCount).highlightDelineated
            descriptionString = String.localizedStringWithFormat(doubleConcatenationTemplate, readStatus.localizedDescription.highlightDelineated, projectString)
        case (let readStatus, 1..., 1...):
            // Filtering by type, project/inbox, and potentially read status
            switch readStatus {
            case .all:
                // Filtering by type and project/inbox
                let typesString = String.localizedStringWithFormat(typesPlain, types.count).highlightDelineated
                let projectString = String.localizedStringWithFormat(projectsPlain, showingProjectCount).highlightDelineated
                descriptionString = String.localizedStringWithFormat(doubleConcatenationTemplate, typesString, projectString)
            case .read, .unread:
                // Filtering by read status, type, and project/inbox
                let readString = readStatus.localizedDescription.highlightDelineated
                let typesString = String.localizedStringWithFormat(typesPlain, types.count).highlightDelineated
                let projectString = String.localizedStringWithFormat(projectsPlain, showingProjectCount).highlightDelineated
                descriptionString = String.localizedStringWithFormat(tripleConcatenationTemplate, readString, typesString, projectString)
            }
        default:
            break
        }

        return descriptionString
    }
    
    private let readStatusKey = "readStatus"
    private let typesKey = "types"
    private let projectsKey = "projects"
    
    func serialize() -> NSDictionary? {
        let mutableDictionary = NSMutableDictionary()
        let numReadStatus = NSNumber(value: readStatus.rawValue)
        mutableDictionary.setValue(numReadStatus, forKey: readStatusKey)
        let typeIdentifiers = types.compactMap { $0.filterIdentifier as NSString? }
        mutableDictionary.setValue(NSArray(array: typeIdentifiers), forKey: typesKey)
        let projectIdentifiers = projects.compactMap { $0.notificationsApiWikiIdentifier as NSString? }
        mutableDictionary.setValue(NSArray(array: projectIdentifiers), forKey: projectsKey)
        
        return mutableDictionary.copy() as? NSDictionary
    }
    
    init?(nsDictionary: NSDictionary, languageLinkController: MWKLanguageLinkController) {
        
        guard let dictionary = nsDictionary as? [String: AnyObject] else {
            return nil
        }
        
        guard let numReadStatus = dictionary[readStatusKey] as? NSNumber,
              let readStatus = ReadStatus(rawValue: numReadStatus.intValue),
              let typeIdentifiers = dictionary[typesKey] as? [NSString],
              let projectApiIdentifiers = dictionary[projectsKey] as? [NSString] else {
                  return nil
              }
        
        let types = typeIdentifiers.compactMap { RemoteNotificationType(from: $0 as String) }
        let projects = projectApiIdentifiers.compactMap { RemoteNotificationsProject(apiIdentifier: $0 as String, languageLinkController: languageLinkController) }
        
        self.readStatus = readStatus
        self.types = types
        self.projects = projects
    }
}

fileprivate extension String {

    /// Delineated section of string to be highlighted in attributed string
    var highlightDelineated: String {
        return RemoteNotificationsFilterState.detailDescriptionHighlightDelineator + self + RemoteNotificationsFilterState.detailDescriptionHighlightDelineator
    }

}
