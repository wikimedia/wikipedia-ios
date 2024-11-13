import CocoaLumberjackSwift
import Foundation

public enum RemoteNotificationsControllerError: LocalizedError {
    case databaseUnavailable
    case attemptingToRefreshBeforeDeadline
    case failurePullingAppLanguage
    
    public var errorDescription: String? {
        return CommonStrings.genericErrorDescription
    }
}

@objc public final class RemoteNotificationsController: NSObject {
    private let apiController: RemoteNotificationsAPIController
    private let refreshDeadlineController = RemoteNotificationsRefreshDeadlineController()
    private let languageLinkController: MWKLanguageLinkController
    private let authManager: WMFAuthenticationManager
    
    private var _modelController: RemoteNotificationsModelController?
    private var modelController: RemoteNotificationsModelController? {
        get {
            
            guard let modelController = _modelController else {
                DDLogError("Missing RemoteNotificationsModelController. Confirm Core Data stack was successfully set up.")
                return nil
            }
            
            return modelController
        }
        set {
            _modelController = newValue
        }
    }
    private var _operationsController: RemoteNotificationsOperationsController?
    private var operationsController: RemoteNotificationsOperationsController? {
        get {
            
            guard let operationsController = _operationsController else {
                DDLogError("Missing RemoteNotificationsOperationsController. Confirm Core Data stack was successfully set up in RemoteNotificationsModelController.")
                return nil
            }
            
            return operationsController
        }
        set {
            _operationsController = newValue
        }
    }
    
    public var isLoadingNotifications: Bool {
        return operationsController?.isLoadingNotifications ?? false
    }
    
    public var areFiltersEnabled: Bool {
        return filterState.readStatus != .all || filterState.offProjects.count != 0 || filterState.offTypes.count != 0
    }

    public static let didUpdateFilterStateNotification = NSNotification.Name(rawValue: "RemoteNotificationsControllerDidUpdateFilterState")
    
    public let configuration: Configuration
    
    @objc public required init(session: Session, configuration: Configuration, languageLinkController: MWKLanguageLinkController, authManager: WMFAuthenticationManager) {
        
        self.apiController = RemoteNotificationsAPIController(session: session, configuration: configuration)
        self.configuration = configuration
        self.authManager = authManager
        self.languageLinkController = languageLinkController
        
        super.init()
        
        do {
            modelController = try RemoteNotificationsModelController(containerURL: FileManager.default.wmf_containerURL())
        } catch let error {
            DDLogError("Failed to initialize RemoteNotificationsModelController: \(error)")
            modelController = nil
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(authManagerDidLogIn), name:WMFAuthenticationManager.didLogInNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(authManagerDidLogOut), name: WMFAuthenticationManager.didLogOutNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(modelControllerDidLoadPersistentStores(_:)), name: RemoteNotificationsModelController.didLoadPersistentStoresNotification, object: nil)
        
    }
    
    // MARK: NSNotification Listeners
    
    @objc private func modelControllerDidLoadPersistentStores(_ note: Notification) {
        
        guard let modelController = modelController else {
            return
        }
        
        if let object = note.object, let error = object as? Error {
            DDLogError("RemoteNotificationsModelController failed to load persistent stores with error \(error); not instantiating RemoteNotificationsOperationsController")
            return
        }
        
        operationsController = RemoteNotificationsOperationsController(languageLinkController: languageLinkController, authManager: authManager, apiController: apiController, modelController: modelController)
        
        populateFilterStateFromPersistence()
    }
    
    @objc private func applicationDidBecomeActive() {
        loadNotifications(force: false)
    }
    
    @objc private func authManagerDidLogOut() {
        do {
            filterState = RemoteNotificationsFilterState(readStatus: .all, offTypes: [], offProjects: [])
            allInboxProjects = []
            modelController?.resetDatabaseAndSharedCache()
        } catch let error {
            DDLogError("Error resetting notifications database on logout: \(error)")
        }
        
    }
    
    @objc private func authManagerDidLogIn() {
        loadNotifications(force: true)
    }
    
    // MARK: Public
    
    /// Fetches notifications from the server and saves them into the local database. Updates local database on a backgroundContext.
    /// - Parameters:
    ///   - force: Flag to force an API call, otherwise this will exit early if it's been less than 30 seconds since the last load attempt.
    ///   - completion: Completion block called once refresh attempt is complete.
    public func loadNotifications(force: Bool, completion: ((Result<Void, Error>) -> Void)? = nil) {
        
        guard let operationsController = operationsController else {
            completion?(.failure(RemoteNotificationsControllerError.databaseUnavailable))
            return
        }
        
        guard authManager.authStateIsPermanent else {
            completion?(.failure(RequestError.unauthenticated))
            return
        }
        
        if !force && !refreshDeadlineController.shouldRefresh {
            completion?(.failure(RemoteNotificationsControllerError.attemptingToRefreshBeforeDeadline))
            return
        }
        
        operationsController.loadNotifications { [weak self] result in
            
            guard let self = self else {
                return
            }
            
            switch result {
            case .success:
                do {
                    try self.updateAllInboxProjects()
                    completion?(.success(()))
                } catch let error {
                    completion?(.failure(error))
                }
            case .failure(let error):
                completion?(.failure(error))
            }
        }
        
        refreshDeadlineController.reset()
    }

    /// Triggers fetching notifications from the server and saving them into the local database with no completion handler. Used as a bridge for Objective-C use as the `Result` type is unavailable there.
    /// - Parameter force: Flag to force an API call, otherwise this will exit early if it's been less than 30 seconds since the last load attempt.
    @objc public func triggerLoadNotifications(force: Bool) {
        loadNotifications(force: force)
    }
    
    /// Marks notifications as read or unread in the local database and on the server. Errors are not returned. Updates local database on a backgroundContext.
    /// - Parameters:
    ///   - identifierGroups: Set of IdentifierGroup objects to identify the correct notification.
    ///   - shouldMarkRead: Boolean for marking as read or unread.
    public func markAsReadOrUnread(identifierGroups: Set<RemoteNotification.IdentifierGroup>, shouldMarkRead: Bool, completion: ((Result<Void, Error>) -> Void)? = nil) {
        
        guard let operationsController = operationsController else {
            completion?(.failure(RemoteNotificationsControllerError.databaseUnavailable))
            return
        }
        
        guard authManager.authStateIsPermanent else {
            completion?(.failure(RequestError.unauthenticated))
            return
        }
        
        operationsController.markAsReadOrUnread(identifierGroups: identifierGroups, shouldMarkRead: shouldMarkRead, languageLinkController: languageLinkController, completion: completion)
    }
    
    
    /// Asks server to mark all notifications as read for projects that contain local unread notifications. Errors are not returned. Updates local database on a backgroundContext.
    public func markAllAsRead(completion: ((Result<Void, Error>) -> Void)? = nil) {
        
        guard let operationsController = operationsController else {
            completion?(.failure(RemoteNotificationsControllerError.databaseUnavailable))
            return
        }
        
        guard authManager.authStateIsPermanent else {
            completion?(.failure(RequestError.unauthenticated))
            return
        }
        
        operationsController.markAllAsRead(languageLinkController: languageLinkController, completion: completion)
    }
    
    /// Asks server to mark all notifications as seen for the primary app language
    public func markAllAsSeen(completion: @escaping ((Result<Void, Error>) -> Void)) {
        
        guard authManager.authStateIsPermanent else {
            completion(.failure(RequestError.unauthenticated))
            return
        }
        
        guard let appLanguage = languageLinkController.appLanguage else {
            completion(.failure(RemoteNotificationsControllerError.failurePullingAppLanguage))
            return
        }
        
        let appLanguageProject =  WikimediaProject.wikipedia(appLanguage.languageCode, appLanguage.localizedName, appLanguage.languageVariantCode)
        apiController.markAllAsSeen(project: appLanguageProject, completion: completion)
    }
    
    /// Passthrough method to listen for NSManagedObjectContextObjectsDidChange notifications on the viewContext, in order to encapsulate viewContext within the WMF Framework.
    /// - Parameters:
    ///   - observer: NSNotification observer
    ///   - selector: Selector to call on the observer once the NSNotification fires
    public func addObserverForViewContextChanges(observer: AnyObject, selector:
    Selector) {
        
        guard let viewContext = modelController?.viewContext else {
            return
        }
        
        NotificationCenter.default.addObserver(observer, selector: selector, name: Notification.Name.NSManagedObjectContextObjectsDidChange, object: viewContext)
    }
    
    /// Fetches notifications from the local database. Uses the viewContext and must be called from the main thread
    /// - Parameters:
    ///   - fetchLimit: Number of notifications to fetch. Defaults to 50.
    ///   - fetchOffset: Offset for fetching notifications. Use when fetching later pages of data
    /// - Returns: Array of RemoteNotifications
    public func fetchNotifications(fetchLimit: Int = 50, fetchOffset: Int = 0, completion: @escaping (Result<[RemoteNotification], Error>) -> Void) {
        guard let modelController = modelController else {
            return completion(.failure(RemoteNotificationsControllerError.databaseUnavailable))
        }
        
        let fetchFromDatabase: () -> Void = { [weak self] in
            guard let self = self else {
                return
            }

            let predicate = self.predicateForFilterSavedState(self.filterState)

            do {
                let notifications = try modelController.fetchNotifications(fetchLimit: fetchLimit, fetchOffset: fetchOffset, predicate: predicate)
                completion(.success(notifications))
            } catch let error {
                completion(.failure(error))
            }
        }
            
            
        guard !isFullyImported else {
            fetchFromDatabase()
            return
        }

        loadNotifications(force: true) { result in
             
             switch result {
             case .success:
                 fetchFromDatabase()
             case .failure(let error):
                 completion(.failure(error))
             }
        }
    }
    
    /// Fetches a count of unread notifications from the local database. Uses the viewContext and must be called from the main thread
    @objc public func numberOfUnreadNotifications() throws -> NSNumber {
        
        guard let modelController = modelController else {
            throw RemoteNotificationsControllerError.databaseUnavailable
        }
        
        let count = try modelController.numberOfUnreadNotifications()
        return NSNumber(value: count)
    }
    
    /// Fetches a count of all notifications from the local database. Uses the viewContext and must be called from the main thread
    public func numberOfAllNotifications() throws -> Int {
        
        guard let modelController = modelController else {
            throw RemoteNotificationsControllerError.databaseUnavailable
        }
        
        return try modelController.numberOfAllNotifications()
    }
    
    /// List of all possible inbox projects available Notifications Center. Used for populating the Inbox screen and the project count toolbar
    public private(set) var allInboxProjects: Set<WikimediaProject> = []
    
    /// Convenience var to get a list of the inbox projects toggled on
    private var onProjects: Set<WikimediaProject> {
        return allInboxProjects.subtracting(filterState.offProjects)
    }
    
    /// A count of showing inbox projects (i.e. allInboxProjects minus those toggled off in the inbox filter screen)
    public var countOfShowingInboxProjects: Int {
        return onProjects.count
    }

    @objc public func updateCacheWithCurrentUnreadNotificationsCount() throws {
        let currentCount = try numberOfUnreadNotifications().intValue
        let sharedCache = SharedContainerCache(fileName: SharedContainerCacheCommonNames.pushNotificationsCache)
        var pushCache = sharedCache.loadCache() ?? PushNotificationsCache(settings: .default, notifications: [])
        pushCache.currentUnreadCount = currentCount
        sharedCache.saveCache(pushCache)
    }
    
    public var filterPredicate: NSPredicate? {
        predicateForFilterSavedState(filterState)
    }
    
    public var filterState: RemoteNotificationsFilterState = RemoteNotificationsFilterState(readStatus: .all, offTypes: [], offProjects: []) {
        didSet {
            
            guard let modelController = modelController else {
                return
            }
            
            // save to library
            modelController.setFilterSettingsToLibrary(dictionary: filterState.serialize())
            
            NotificationCenter.default.post(name: RemoteNotificationsController.didUpdateFilterStateNotification, object: nil)
        }
    }
    
    public var isFullyImported: Bool {
        
        guard let modelController = modelController else {
            return false
        }
        
        let appLanguageProjects =  languageLinkController.preferredLanguages.map { WikimediaProject.wikipedia($0.languageCode, $0.localizedName, $0.languageVariantCode) }
        for project in appLanguageProjects {
            if !modelController.isProjectAlreadyImported(project: project) {
                return false
            }
        }

        return true
    }
    
    // MARK: Internal
    
    @objc func deleteLegacyDatabaseFiles() throws {
        
        guard let modelController = modelController else {
            throw RemoteNotificationsControllerError.databaseUnavailable
        }
        
        try modelController.deleteLegacyDatabaseFiles()
    }
    
    // MARK: Private
    
    /// Pulls filter state from local persistence and saves it in memory
    private func populateFilterStateFromPersistence() {
        guard let modelController = modelController,
        let persistentFiltersDict = modelController.getFilterSettingsFromLibrary(),
           let persistentFilters = RemoteNotificationsFilterState(nsDictionary: persistentFiltersDict, languageLinkController: languageLinkController) else {
            return
        }
        
        self.filterState = persistentFilters
    }
    
    /// Fetches from the local database all projects that contain a local notification on device. Uses the viewContext and must be called from the main thread.
    /// - Returns: Array of WikimediaProject
    private func projectsFromLocalNotifications() throws -> Set<WikimediaProject> {
        guard let modelController = modelController else {
            return []
        }
        
        let wikis = try modelController.distinctWikis(predicate: nil)
        let projects = wikis.compactMap { WikimediaProject(notificationsApiIdentifier: $0, languageLinkController: languageLinkController) }
        return Set(projects)
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
        
        let offTypes = filterState.offTypes
        let onTypes = RemoteNotificationFilterType.orderingForFilters.filter {!offTypes.contains($0)}
        
        var typePredicates: [NSPredicate] = []
        let otherIsOff = offTypes.contains(.other)
        
        if onTypes.isEmpty {
            return NSPredicate(format: "FALSEPREDICATE")
        }
        
        if otherIsOff {
            typePredicates = onTypes.compactMap { settingType in
                let categoryStrings = RemoteNotificationFilterType.categoryStringsForFilterType(type: settingType)
                let typeStrings = RemoteNotificationFilterType.typeStringForFilterType(type: settingType)
                
                guard categoryStrings.count > 0 && typeStrings.count > 0 else {
                    return nil
                }
                
                return NSPredicate(format: "(categoryString IN %@ AND typeString IN %@)", categoryStrings, typeStrings)
            }
        } else {
            typePredicates = offTypes.compactMap { settingType in
                let categoryStrings = RemoteNotificationFilterType.categoryStringsForFilterType(type: settingType)
                let typeStrings = RemoteNotificationFilterType.typeStringForFilterType(type: settingType)
                
                guard categoryStrings.count > 0 && typeStrings.count > 0 else {
                    return nil
                }
                
                return NSPredicate(format: "NOT (categoryString IN %@ AND typeString IN %@)", categoryStrings, typeStrings)
            }
        }
        
        let offProjects = filterState.offProjects
        let filteredOffProjects = offProjects.filter(offProjectShouldFilter)
        
        let offProjectPredicates: [NSPredicate] = filteredOffProjects.compactMap { return NSPredicate(format: "NOT (wiki == %@)", $0.notificationsApiWikiIdentifier) }
        
        guard readStatusPredicate != nil || typePredicates.count > 0 || offProjectPredicates.count > 0 else {
            return nil
        }
        
        var combinedOffTypePredicate: NSPredicate? = nil
        if typePredicates.count > 0 {
            if otherIsOff {
                combinedOffTypePredicate = NSCompoundPredicate(orPredicateWithSubpredicates: typePredicates)
            } else {
                combinedOffTypePredicate = NSCompoundPredicate(andPredicateWithSubpredicates: typePredicates)
            }
        }
        
        var combinedOffProjectPredicate: NSPredicate? = nil
        if offProjectPredicates.count > 0 {
            combinedOffProjectPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: offProjectPredicates)
        }
        
        let finalPredicates = [readStatusPredicate, combinedOffTypePredicate, combinedOffProjectPredicate].compactMap { $0 }
        
        return finalPredicates.count > 0 ? NSCompoundPredicate(andPredicateWithSubpredicates: finalPredicates) : nil
    }
    
    private func offProjectShouldFilter(offProject: WikimediaProject) -> Bool {
        
        // Some offProjects have the same wiki ID (`zhwiki`) as an onProject
        // This could happen with Chinese language variants, if the user has multiple Chinese language variant projects selected as preferred app languages, then only toggled on one in Notifications Center Inbox.
        // In this case we want to ensure this project does not actually contribute to the filter predicate, because there is an onProject with the same language code.
        
        for onProject in onProjects {
            switch onProject {
            case .wikipedia(let languageCode, _, let languageVariantCode):
                if languageVariantCode != nil &&
                    offProject.languageCode == languageCode &&
                    offProject.languageVariantCode != languageVariantCode {
                    return false
                }
            default: break
            }
        }
        
        return true
    }
    
    /// Updates value of allInboxProjects by gathering list of static projects, app language projects, and local notifications projects. Involves a fetch to the local database. Uses the viewContext and must be called from the main thread
    private func updateAllInboxProjects() throws {
        let sideProjects: Set<WikimediaProject> = [.commons, .wikidata]
        
        let appLanguageProjects =  languageLinkController.preferredLanguages.map { WikimediaProject.wikipedia($0.languageCode, $0.localizedName, $0.languageVariantCode) }
        
        var inboxProjects = sideProjects.union(appLanguageProjects)
        let localProjects = try projectsFromLocalNotifications()
        
        for localProject in localProjects {
            inboxProjects.insert(localProject)
        }
        
        self.allInboxProjects = inboxProjects
    }
}

public struct RemoteNotificationsFilterState: Equatable {

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
    public let offTypes: Set<RemoteNotificationFilterType>
    public let offProjects: Set<WikimediaProject>
    
    public init(readStatus: ReadStatus, offTypes: Set<RemoteNotificationFilterType>, offProjects: Set<WikimediaProject>) {
        self.readStatus = readStatus
        self.offTypes = offTypes
        self.offProjects = offProjects
    }

    private var isReadStatusOrTypeFiltered: Bool {
        return (readStatus != .all || !offTypes.isEmpty)
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

        switch (readStatus, offTypes.count, offProjects.count) {
        case (.all, 0, 0):
            // No filtering
            descriptionString = String.localizedStringWithFormat(inProjects, totalProjectCount)
        case (.all, 1..., 0):
            // Only filtering by type
            let typesString = String.localizedStringWithFormat(typesPlain, offTypes.count).highlightDelineated
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
            let typesString = String.localizedStringWithFormat(typesPlain, offTypes.count).highlightDelineated
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
                let typesString = String.localizedStringWithFormat(typesPlain, offTypes.count).highlightDelineated
                let projectString = String.localizedStringWithFormat(projectsPlain, showingProjectCount).highlightDelineated
                descriptionString = String.localizedStringWithFormat(doubleConcatenationTemplate, typesString, projectString)
            case .read, .unread:
                // Filtering by read status, type, and project/inbox
                let readString = readStatus.localizedDescription.highlightDelineated
                let typesString = String.localizedStringWithFormat(typesPlain, offTypes.count).highlightDelineated
                let projectString = String.localizedStringWithFormat(projectsPlain, showingProjectCount).highlightDelineated
                descriptionString = String.localizedStringWithFormat(tripleConcatenationTemplate, readString, typesString, projectString)
            }
        default:
            break
        }

        return descriptionString
    }
    
    private let readStatusKey = "readStatus"
    private let offTypesKey = "offTypes"
    private let offProjectsKey = "offProjects"
    
    func serialize() -> NSDictionary? {
        let mutableDictionary = NSMutableDictionary()
        let numReadStatus = NSNumber(value: readStatus.rawValue)
        mutableDictionary.setValue(numReadStatus, forKey: readStatusKey)
        let offTypeIdentifiers = offTypes.compactMap { $0.filterIdentifier as NSString? }
        mutableDictionary.setValue(NSArray(array: offTypeIdentifiers), forKey: offTypesKey)
        let offProjectIdentifiers = offProjects.compactMap { $0.notificationsApiWikiIdentifier as NSString? }
        mutableDictionary.setValue(NSArray(array: offProjectIdentifiers), forKey: offProjectsKey)
        
        return mutableDictionary.copy() as? NSDictionary
    }
    
    init?(nsDictionary: NSDictionary, languageLinkController: MWKLanguageLinkController) {
        
        guard let dictionary = nsDictionary as? [String: AnyObject] else {
            return nil
        }
        
        guard let numReadStatus = dictionary[readStatusKey] as? NSNumber,
              let readStatus = ReadStatus(rawValue: numReadStatus.intValue),
              let offTypeIdentifiers = dictionary[offTypesKey] as? [NSString],
              let offProjectApiIdentifiers = dictionary[offProjectsKey] as? [NSString] else {
                  return nil
              }
        
        let offTypes = offTypeIdentifiers.compactMap { RemoteNotificationFilterType(from: $0 as String) }
        let offProjects = offProjectApiIdentifiers.compactMap { WikimediaProject(notificationsApiIdentifier: $0 as String, languageLinkController: languageLinkController) }
        
        self.readStatus = readStatus
        self.offTypes = Set(offTypes)
        self.offProjects = Set(offProjects)
    }
}

fileprivate extension String {

    /// Delineated section of string to be highlighted in attributed string
    var highlightDelineated: String {
        return RemoteNotificationsFilterState.detailDescriptionHighlightDelineator + self + RemoteNotificationsFilterState.detailDescriptionHighlightDelineator
    }

}
