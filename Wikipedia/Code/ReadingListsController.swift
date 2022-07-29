import Foundation
import CocoaLumberjackSwift

// Sync keys
let WMFReadingListSyncStateKey = "WMFReadingListsSyncState"
private let WMFReadingListSyncRemotelyEnabledKey = "WMFReadingListSyncRemotelyEnabled"
let WMFReadingListUpdateKey = "WMFReadingListUpdateKey"

// Default list key
private let WMFReadingListDefaultListEnabledKey = "WMFReadingListDefaultListEnabled"

// Batch size keys
let WMFReadingListBatchSizePerRequestLimit = 500
let WMFReadingListCoreDataBatchSize = 500

// Reading lists config keys
let WMFReadingListsConfigMaxEntriesPerList = "WMFReadingListsConfigMaxEntriesPerList"
let WMFReadingListsConfigMaxListsPerUser = "WMFReadingListsConfigMaxListsPerUser"

struct ReadingListSyncState: OptionSet {
    let rawValue: Int64
    
    static let needsRemoteEnable    = ReadingListSyncState(rawValue: 1 << 0)
    static let needsSync  = ReadingListSyncState(rawValue: 1 << 1)
    static let needsUpdate      = ReadingListSyncState(rawValue: 1 << 2)
    static let needsRemoteDisable    = ReadingListSyncState(rawValue: 1 << 3)
    
    static let needsLocalReset    = ReadingListSyncState(rawValue: 1 << 4) // mark all as unsynced, remove remote IDs
    static let needsLocalArticleClear    = ReadingListSyncState(rawValue: 1 << 5) // remove all saved articles
    static let needsLocalListClear    = ReadingListSyncState(rawValue: 1 << 6) // remove all lists
    
    static let needsRandomLists = ReadingListSyncState(rawValue: 1 << 7) // for debugging, populate random lists
    static let needsRandomEntries = ReadingListSyncState(rawValue: 1 << 8) // for debugging, populate with random entries in any language
    static let needsRandomEnEntries = ReadingListSyncState(rawValue: 1 << 9) // for debugging, populate with random english wikipedia entries
    
    static let needsEnable: ReadingListSyncState = [.needsRemoteEnable, .needsSync]
    static let needsLocalClear: ReadingListSyncState = [.needsLocalArticleClear, .needsLocalListClear]
    static let needsClearAndEnable: ReadingListSyncState = [.needsLocalClear, .needsRemoteEnable, .needsSync]

    static let needsDisable: ReadingListSyncState = [.needsRemoteDisable, .needsLocalReset]
}

public enum ReadingListError: Error, Equatable {
    case listExistsWithTheSameName
    case unableToCreateList
    case generic
    case unableToDeleteList
    case unableToUpdateList
    case unableToAddEntry
    case unableToRemoveEntry
    case entryLimitReached(name: String, count: Int, limit: Int)
    case listWithProvidedNameNotFound(name: String)
    case listLimitReached(limit: Int)
    case listEntryLimitsReached(name: String, count: Int, listLimit: Int, entryLimit: Int)
    
    public var localizedDescription: String {
        switch self {
        case .generic:
            return WMFLocalizedString("reading-list-generic-error", value: "An unexpected error occurred while updating your reading lists.", comment: "An unexpected error occurred while updating your reading lists.")
        case .listExistsWithTheSameName:
            return WMFLocalizedString("reading-list-exists-with-same-name", value: "Reading list name already in use", comment: "Informs the user that a reading list exists with the same name.")
        case .listWithProvidedNameNotFound(let name):
            let format = WMFLocalizedString("reading-list-with-provided-name-not-found", value: "A reading list with the name “%1$@” was not found. Please make sure you have the correct name.", comment: "Informs the user that a reading list with the name they provided was not found. %1$@ will be replaced with the name of the reading list which could not be found")
            return String.localizedStringWithFormat(format, name)
        case .unableToCreateList:
            return WMFLocalizedString("reading-list-unable-to-create", value: "An unexpected error occurred while creating your reading list. Please try again later.", comment: "Informs the user that an error occurred while creating their reading list.")
        case .unableToDeleteList:
            return WMFLocalizedString("reading-list-unable-to-delete", value: "An unexpected error occurred while deleting your reading list. Please try again later.", comment: "Informs the user that an error occurred while deleting their reading list.")
        case .unableToUpdateList:
            return WMFLocalizedString("reading-list-unable-to-update", value: "An unexpected error occurred while updating your reading list. Please try again later.", comment: "Informs the user that an error occurred while updating their reading list.")
        case .unableToAddEntry:
            return WMFLocalizedString("reading-list-unable-to-add-entry", value: "An unexpected error occurred while adding an entry to your reading list. Please try again later.", comment: "Informs the user that an error occurred while adding an entry to their reading list.")
        case .entryLimitReached(let name, let count, let limit):
            return String.localizedStringWithFormat(CommonStrings.readingListsEntryLimitReachedFormat, count, limit, name)
        case .unableToRemoveEntry:
            return WMFLocalizedString("reading-list-unable-to-remove-entry", value: "An unexpected error occurred while removing an entry from your reading list. Please try again later.", comment: "Informs the user that an error occurred while removing an entry from their reading list.")
        case .listLimitReached(let limit):
            return String.localizedStringWithFormat(CommonStrings.readingListsListLimitReachedFormat, limit)
        case .listEntryLimitsReached(let name, let count, let listLimit, let entryLimit):
            let entryLimitReached = String.localizedStringWithFormat(CommonStrings.readingListsEntryLimitReachedFormat, count, entryLimit, name)
            let listLimitReached = String.localizedStringWithFormat(CommonStrings.readingListsListLimitReachedFormat, listLimit)
            return "\(entryLimitReached)\n\n\(listLimitReached)"
        }
    }
    
    public static func ==(lhs: ReadingListError, rhs: ReadingListError) -> Bool {
        return lhs.localizedDescription == rhs.localizedDescription // shrug
    }
}

public typealias ReadingListsController = WMFReadingListsController

@objc public class WMFReadingListsController: NSObject {
    @objc public static let readingListsServerDidConfirmSyncWasEnabledForAccountNotification = NSNotification.Name("WMFReadingListsServerDidConfirmSyncWasEnabledForAccount")
    @objc public static let readingListsServerDidConfirmSyncWasEnabledForAccountWasSyncEnabledKey = NSNotification.Name("wasSyncEnabledForAccount")
    @objc public static let readingListsServerDidConfirmSyncWasEnabledForAccountWasSyncEnabledOnDeviceKey = NSNotification.Name("wasSyncEnabledOnDevice")
    @objc public static let readingListsServerDidConfirmSyncWasEnabledForAccountWasSyncDisabledOnDeviceKey = NSNotification.Name("wasSyncDisabledOnDevice")
    
    @objc public static let syncDidStartNotification = NSNotification.Name(rawValue: "WMFSyncDidStartNotification")
    
    @objc public static let readingListsWereSplitNotification = NSNotification.Name("WMFReadingListsWereSplit")
    @objc public static let readingListsWereSplitNotificationEntryLimitKey = NSNotification.Name("WMFReadingListsWereSplitNotificationEntryLimitKey")
    
    @objc public static let syncDidFinishNotification = NSNotification.Name(rawValue: "WMFSyncFinishedNotification")
    @objc public static let syncDidFinishErrorKey = NSNotification.Name(rawValue: "error")
    @objc public static let syncDidFinishSyncedReadingListsCountKey = NSNotification.Name(rawValue: "syncedReadingLists")
    @objc public static let syncDidFinishSyncedReadingListEntriesCountKey = NSNotification.Name(rawValue: "syncedReadingListEntries")

    @objc public static let userDidSaveOrUnsaveArticleNotification = NSNotification.Name(rawValue: "WMFUserDidSaveOrUnsaveArticleNotification")

    internal weak var dataStore: MWKDataStore!
    public let apiController: ReadingListsAPIController
        
    private let operationQueue = OperationQueue()
    
    private var observedOperations: [Operation: NSKeyValueObservation] = [:]
    private var isSyncing = false {
        didSet {
            guard oldValue != isSyncing, isSyncing else {
                return
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: ReadingListsController.syncDidStartNotification, object: nil)
            }
        }
    }
    
    @objc init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
        self.apiController = ReadingListsAPIController(session: dataStore.session, configuration: dataStore.configuration)
        super.init()
        operationQueue.maxConcurrentOperationCount = 1
    }
    
    private func addOperation(_ operation: ReadingListsOperation) {
        observedOperations[operation] = operation.observe(\.state, changeHandler: { (operation, change) in
            if operation.isFinished {
                self.observedOperations.removeValue(forKey: operation)?.invalidate()
                DispatchQueue.main.async {
                    var userInfo: [Notification.Name: Any] = [:]
                    if let error = operation.error {
                        userInfo[ReadingListsController.syncDidFinishErrorKey] = error
                    }
                    if let syncOperation = operation as? ReadingListsSyncOperation {
                        userInfo[ReadingListsController.syncDidFinishSyncedReadingListsCountKey] = syncOperation.syncedReadingListsCount
                        userInfo[ReadingListsController.syncDidFinishSyncedReadingListEntriesCountKey] = syncOperation.syncedReadingListEntriesCount
                    }
                    NotificationCenter.default.post(name: ReadingListsController.syncDidFinishNotification, object: nil, userInfo: userInfo)
                    self.isSyncing = false
                }
            } else if operation.isExecuting {
                self.isSyncing = true
            }
        })
        operationQueue.addOperation(operation)
    }
    
    // User-facing actions. Everything is performed on the main context
    public func createReadingList(named name: String, description: String? = nil, with articles: [WMFArticle] = []) throws -> ReadingList {
        assert(Thread.isMainThread)
        let moc = dataStore.viewContext
        let list = try createReadingList(named: name, description: description, with: articles, in: moc)

        if moc.hasChanges {
            try moc.save()
        }
        
        let listLimit = moc.wmf_readingListsConfigMaxListsPerUser
        let readingListsCount = try moc.allReadingListsCount()
        guard readingListsCount + 1 <= listLimit else {
            throw ReadingListError.listLimitReached(limit: listLimit)
        }
        
        try throwLimitErrorIfNecessary(for: nil, articles: [], in: moc)
        sync()
        return list
    }
    
    private func throwLimitErrorIfNecessary(for readingList: ReadingList?, articles: [WMFArticle], in moc: NSManagedObjectContext) throws {
        let listLimit = moc.wmf_readingListsConfigMaxListsPerUser
        let entryLimit = moc.wmf_readingListsConfigMaxEntriesPerList.intValue
        let readingListsCount = try moc.allReadingListsCount()
        let countOfEntries = Int(readingList?.countOfEntries ?? 0)

        let willExceedListLimit = readingListsCount + 1 > listLimit
        let didExceedListLimit = readingListsCount > listLimit
        let willExceedEntryLimit = countOfEntries + articles.count > entryLimit
        
        if let name = readingList?.name {
            if didExceedListLimit && willExceedEntryLimit {
                throw ReadingListError.listEntryLimitsReached(name: name, count: articles.count, listLimit: listLimit, entryLimit: entryLimit)
            } else if willExceedEntryLimit {
                throw ReadingListError.entryLimitReached(name: name, count: articles.count, limit: entryLimit)
            }
        } else if willExceedListLimit {
            throw ReadingListError.listLimitReached(limit: listLimit)
        }
    }
    
    public func createReadingList(named name: String, description: String? = nil, with articles: [WMFArticle] = [], in moc: NSManagedObjectContext) throws -> ReadingList {
        let listExistsWithTheSameName = try listExists(with: name, in: moc)
        guard !listExistsWithTheSameName else {
            throw ReadingListError.listExistsWithTheSameName
        }
        
        guard let list = moc.wmf_create(entityNamed: "ReadingList", withKeysAndValues: ["canonicalName": name, "readingListDescription": description]) as? ReadingList else {
            throw ReadingListError.unableToCreateList
        }
        
        list.createdDate = NSDate()
        list.updatedDate = list.createdDate
        list.isUpdatedLocally = true
        
        try add(articles: articles, to: list, in: moc)
        return list
    }
    
    func listExists(with name: String, in moc: NSManagedObjectContext) throws -> Bool {
        let name = name.precomposedStringWithCanonicalMapping
        let existingOrDefaultListRequest: NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
        existingOrDefaultListRequest.predicate = NSPredicate(format: "(canonicalName MATCHES %@ OR isDefault == YES) AND isDeletedLocally == NO", name)
        existingOrDefaultListRequest.fetchLimit = 2
        let lists = try moc.fetch(existingOrDefaultListRequest)
        return lists.first(where: { $0.name == name }) != nil
    }
    
    public func updateReadingList(_ readingList: ReadingList, with newName: String?, newDescription: String?) {
        assert(Thread.isMainThread)
        guard !readingList.isDefault else {
            assertionFailure("Default reading list cannot be updated")
            return
        }
        let moc = dataStore.viewContext
        if let newName = newName, !newName.isEmpty {
            readingList.name = newName
        }
        readingList.readingListDescription = newDescription
        readingList.isUpdatedLocally = true
        if moc.hasChanges {
            do {
                try moc.save()
            } catch let error {
                DDLogError("Error updating name or description for reading list: \(error)")
            }
        }
        sync()
    }
    
    /// Marks that reading lists were deleted locally and updates associated objects. Doesn't delete them from the NSManagedObjectContext - that should happen only with confirmation from the server that they were deleted.
    ///
    /// - Parameters:
    ///   - readingLists: the reading lists to delete
    func markLocalDeletion(for readingLists: [ReadingList]) throws {
        for readingList in readingLists {
            readingList.isDeletedLocally = true
            readingList.isUpdatedLocally = true
            try markLocalDeletion(for: Array(readingList.entries ?? []))
        }
    }
    
    /// Marks that reading list entries were deleted locally and updates associated objects. Doesn't delete them from the NSManagedObjectContext - that should happen only with confirmation from the server that they were deleted.
    ///
    /// - Parameters:
    ///   - readingListEntriess: the reading lists to delete
    internal func markLocalDeletion(for readingListEntries: [ReadingListEntry]) throws {
        guard !readingListEntries.isEmpty else {
            return
        }
        var lists: Set<ReadingList> = []
        for entry in readingListEntries {
            entry.isDeletedLocally = true
            entry.isUpdatedLocally = true
            guard let list = entry.list else {
                continue
            }
            lists.insert(list)
        }
        for list in lists {
            try list.updateArticlesAndEntries()
        }
    }
    
    public func delete(readingLists: [ReadingList]) throws {
        assert(Thread.isMainThread)
        
        let moc = dataStore.viewContext
        
        try markLocalDeletion(for: readingLists)
        
        if moc.hasChanges {
            try moc.save()
        }
        
        sync()
    }
    
    internal func add(articles: [WMFArticle], to readingList: ReadingList, in moc: NSManagedObjectContext) throws {
        guard !articles.isEmpty else {
            return
        }
        
        // We should not add the same article in multiple variants.
        // Keying on articleKey instead of inMemoryKey matches any variant of an article
        var existingKeys = Set(readingList.articleKeys)
        
        for article in articles {
            guard let key = article.key, !existingKeys.contains(key) else {
                continue
            }

            // Need this to add to default reading list, otherwise article doesn't show up in "All articles" on SavedVC
            if !article.isSaved, let articleUrl = article.url {
                dataStore.savedPageList.toggleSavedPage(for: articleUrl)
            }

            guard let entry = moc.wmf_create(entityNamed: "ReadingListEntry", withValue: key, forKey: "articleKey") as? ReadingListEntry else {
                return
            }
            existingKeys.insert(key)
            entry.variant = article.variant
            entry.createdDate = NSDate()
            entry.updatedDate = entry.createdDate
            entry.isUpdatedLocally = true
            entry.displayTitle = article.displayTitle
            entry.list = readingList
        }
        try readingList.updateArticlesAndEntries()
    }
    
    public func add(articles: [WMFArticle], to readingList: ReadingList) throws {
        assert(Thread.isMainThread)
        let moc = dataStore.viewContext
        try throwLimitErrorIfNecessary(for: readingList, articles: articles, in: moc)
        try add(articles: articles, to: readingList, in: moc)
        if moc.hasChanges {
            try moc.save()
        }
        sync()
    }

    var syncState: ReadingListSyncState {
        get {
            assert(Thread.isMainThread)
            let rawValue = dataStore.viewContext.wmf_numberValue(forKey: WMFReadingListSyncStateKey)?.int64Value ?? 0
            return ReadingListSyncState(rawValue: rawValue)
        }
        set {
            assert(Thread.isMainThread)
            let moc = dataStore.viewContext
            moc.wmf_setValue(NSNumber(value: newValue.rawValue), forKey: WMFReadingListSyncStateKey)
            do {
                try moc.save()
            } catch let error {
                DDLogError("Error saving after sync state update: \(error)")
            }
        }
    }
    
    public func debugSync(createLists: Bool, listCount: Int64, addEntries: Bool, randomizeLanguageEntries: Bool, entryCount: Int64, deleteLists: Bool, deleteEntries: Bool, doFullSync: Bool, completion: @escaping () -> Void) {
        dataStore.viewContext.wmf_setValue(NSNumber(value: listCount), forKey: "WMFCountOfListsToCreate")
        dataStore.viewContext.wmf_setValue(NSNumber(value: entryCount), forKey: "WMFCountOfEntriesToCreate")
        let oldValue = syncState
        var newValue = oldValue
        if createLists {
            newValue.insert(.needsRandomLists)
        } else {
            newValue.remove(.needsRandomLists)
        }
        if randomizeLanguageEntries {
            newValue.insert(.needsRandomEntries)
        } else if addEntries {
            newValue.insert(.needsRandomEnEntries)
        } else {
            newValue.remove(.needsRandomEntries)
            newValue.remove(.needsRandomEnEntries)
        }
        
        if deleteLists {
            newValue.insert(.needsLocalListClear)
        } else {
            newValue.remove(.needsLocalListClear)
        }
        if deleteEntries {
            newValue.insert(.needsLocalArticleClear)
        } else {
            newValue.remove(.needsLocalArticleClear)
        }
        
        cancelSync {
            self.syncState = newValue
            if doFullSync {
                self.fullSync(completion)
            } else {
                self._sync(completion)
            }
        }
    }
    
    // is sync enabled for this user
    @objc public var isSyncEnabled: Bool {
        assert(Thread.isMainThread)
        let state = syncState
        return state.contains(.needsSync) || state.contains(.needsUpdate)
    }
    
    // is sync available or is it shut down server-side
    @objc public var isSyncRemotelyEnabled: Bool {
        get {
            assert(Thread.isMainThread)
            let moc = dataStore.viewContext
            return moc.wmf_isSyncRemotelyEnabled
        }
        set {
            assert(Thread.isMainThread)
            let moc = dataStore.viewContext
            moc.wmf_isSyncRemotelyEnabled = newValue
        }
    }
    
    // should the default list be shown to the user
    @objc public var isDefaultListEnabled: Bool {
        get {
            assert(Thread.isMainThread)
            let moc = dataStore.viewContext
            return moc.wmf_numberValue(forKey: WMFReadingListDefaultListEnabledKey)?.boolValue ?? false
        }
        set {
            assert(Thread.isMainThread)
            let moc = dataStore.viewContext
            moc.wmf_setValue(NSNumber(value: newValue), forKey: WMFReadingListDefaultListEnabledKey)
            do {
                try moc.save()
            } catch let error {
                DDLogError("Error saving after sync state update: \(error)")
            }
        }
    }

    @objc public var maxEntriesPerList: NSNumber {
        get {
            assert(Thread.isMainThread)
            let moc = dataStore.viewContext
            return moc.wmf_readingListsConfigMaxEntriesPerList
        }
        set {
            assert(Thread.isMainThread)
            let moc = dataStore.viewContext
            moc.wmf_readingListsConfigMaxEntriesPerList = newValue
        }
    }

    @objc public var maxListsPerUser: Int {
        get {
            assert(Thread.isMainThread)
            let moc = dataStore.viewContext
            return moc.wmf_readingListsConfigMaxListsPerUser
        }
        set {
            assert(Thread.isMainThread)
            let moc = dataStore.viewContext
            moc.wmf_readingListsConfigMaxListsPerUser = newValue
        }
    }
    
    func postReadingListsServerDidConfirmSyncWasEnabledForAccountNotification(_ wasSyncEnabledForAccount: Bool) {
        // we want to know if sync was ever enabled on this device
        let wasSyncEnabledOnDevice = apiController.lastRequestType == .setup
        let wasSyncDisabledOnDevice = apiController.lastRequestType == .teardown
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: ReadingListsController.readingListsServerDidConfirmSyncWasEnabledForAccountNotification, object: nil, userInfo: [ReadingListsController.readingListsServerDidConfirmSyncWasEnabledForAccountWasSyncEnabledKey: NSNumber(value: wasSyncEnabledForAccount), ReadingListsController.readingListsServerDidConfirmSyncWasEnabledForAccountWasSyncEnabledOnDeviceKey: NSNumber(value: wasSyncEnabledOnDevice), ReadingListsController.readingListsServerDidConfirmSyncWasEnabledForAccountWasSyncDisabledOnDeviceKey: NSNumber(value: wasSyncDisabledOnDevice)])
        }
    }

    public func eraseAllSavedArticlesAndReadingLists() {
        assert(Thread.isMainThread)

        let oldSyncState = syncState
        var newSyncState = oldSyncState

        if isSyncEnabled {
            // Since there is no batch delete on the server,
            // we remove local and remote reading lists
            // by disabling and then enabling the service.
            // Otherwise, we'd have to delete everything via single requests.
            newSyncState.insert(.needsRemoteDisable)
            newSyncState.insert(.needsRemoteEnable)
            newSyncState.insert(.needsSync)
        } else {
            newSyncState.insert(.needsLocalClear)
            newSyncState.remove(.needsSync)
        }

        newSyncState.remove(.needsUpdate)

        guard newSyncState != oldSyncState else {
            return
        }
        syncState = newSyncState
        sync()
    }

    @objc public func setSyncEnabled(_ isSyncEnabled: Bool, shouldDeleteLocalLists: Bool, shouldDeleteRemoteLists: Bool) {
        
        let oldSyncState = self.syncState
        var newSyncState = oldSyncState

        if shouldDeleteLocalLists {
            newSyncState.insert(.needsLocalClear)
        } else {
            newSyncState.insert(.needsLocalReset)
        }

        if isSyncEnabled {
            newSyncState.insert(.needsRemoteEnable)
            newSyncState.insert(.needsSync)
            newSyncState.remove(.needsUpdate)
            newSyncState.remove(.needsRemoteDisable)
        } else {
            if shouldDeleteRemoteLists {
                newSyncState.insert(.needsRemoteDisable)
            }
            newSyncState.remove(.needsSync)
            newSyncState.remove(.needsUpdate)
            newSyncState.remove(.needsRemoteEnable)
        }
        
        guard newSyncState != oldSyncState else {
            return
        }
        
        self.syncState = newSyncState
        
        sync()
    }
    
    @objc public func start() {
        assert(Thread.isMainThread)
        sync()
    }
    
    private func cancelSync(_ completion: @escaping () -> Void) {
        operationQueue.cancelAllOperations()
        apiController.cancelAllTasks()
        operationQueue.addOperation {
            DispatchQueue.main.async(execute: completion)
        }
    }
    
    @objc public func stop(_ completion: @escaping () -> Void) {
        assert(Thread.isMainThread)
        cancelSync(completion)
    }
    
    @objc public func fullSync(_ completion: (() -> Void)? = nil) {
        #if TEST
        #else
            var newValue = self.syncState
            if newValue.contains(.needsUpdate) {
                newValue.remove(.needsUpdate)
                newValue.insert(.needsSync)
                self.syncState = newValue
            }
            _sync({
                if let completion = completion {
                    DispatchQueue.main.async(execute: completion)
                }
            })
        #endif
    }
    
    @objc private func _sync(_ completion: (() -> Void)? = nil) {
        let sync = ReadingListsSyncOperation(readingListsController: self)
        addOperation(sync)
        if let completion = completion {
            let completionBlockOp = BlockOperation(block: completion)
            completionBlockOp.addDependency(sync)
            operationQueue.addOperation(completionBlockOp)
        }
    }
    
    @objc private func _syncIfNotSyncing() {
        assert(Thread.isMainThread)
        guard operationQueue.operationCount == 0 else {
            return
        }
        _sync()
    }
    
    @objc public func sync() {
        guard !Bundle.main.isAppExtension else {
            return
        }
        #if TEST
        #else
            assert(Thread.isMainThread)
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_syncIfNotSyncing), object: nil)
            perform(#selector(_syncIfNotSyncing), with: nil, afterDelay: 0.5)
        #endif
    }
    
    /// Note that the predicate does not take the article language variant into account. This is intentional.
    /// Only one variant of an article can be added to a reading list. However *all* variants of the same article appear saved in the user interface.
    /// The 'unsave' button can be tapped by the user on *any* variant of the article.
    /// By only searching for article key, the saved article variant is removed regardless of which variant of the article was tapped.
    public func remove(articles: [WMFArticle], readingList: ReadingList) throws {
        assert(Thread.isMainThread)
        let moc = dataStore.viewContext
        
        let articleKeys = articles.compactMap { $0.key }
        let entriesRequest: NSFetchRequest<ReadingListEntry> = ReadingListEntry.fetchRequest()
        entriesRequest.predicate = NSPredicate(format: "list == %@ && articleKey IN %@", readingList, articleKeys)
        let entriesToDelete = try moc.fetch(entriesRequest)
        try remove(entries: entriesToDelete)
    }
    
    public func remove(entries: [ReadingListEntry]) throws {
        assert(Thread.isMainThread)
        let moc = dataStore.viewContext
        try markLocalDeletion(for: entries)
        if moc.hasChanges {
            try moc.save()
        }
        sync()
    }
    
    @objc public func addArticleToDefaultReadingList(_ article: WMFArticle) throws {
        try article.addToDefaultReadingList()
    }
    
    @objc public func userSave(_ article: WMFArticle) {
        assert(Thread.isMainThread)
        do {
            let moc = dataStore.viewContext
            try article.addToDefaultReadingList()
            if moc.hasChanges {
                try moc.save()
            }
            NotificationCenter.default.post(name: WMFReadingListsController.userDidSaveOrUnsaveArticleNotification, object: article)
            sync()
        } catch let error {
            DDLogError("Error saving article: \(error)")
        }
    }

    @objc public func userUnsave(_ article: WMFArticle) {
        assert(Thread.isMainThread)
        do {
            let moc = dataStore.viewContext
            guard let savedArticleVariant = article.savedVariant else {
                assertionFailure("An article without a saved variant should never be passed to \(#function).")
                return
            }
            unsave([savedArticleVariant], in: moc)
            if moc.hasChanges {
                try moc.save()
            }
            // The notification needs to include the exact article acted on.
            // Getting the savedVariant ensures we pass the correct variant.
            NotificationCenter.default.post(name: WMFReadingListsController.userDidSaveOrUnsaveArticleNotification, object: savedArticleVariant)
            sync()
        } catch let error {
            DDLogError("Error unsaving article: \(error)")
        }
    }
    
    /// Note that the predicate does not take the article language variant into account. This is intentional.
    /// Only one variant of an article can be saved. However *all* variants of the same article appear saved in the user interface.
    /// The 'unsave' button can be tapped by the user on *any* variant of the article.
    /// By only searching for article key, the saved article variant is removed regardless of which variant of the article was tapped.
    public func unsave(_ articles: [WMFArticle], in moc: NSManagedObjectContext) {
        do {
            let keys = articles.compactMap { $0.key }
            let entryFetchRequest: NSFetchRequest<ReadingListEntry> = ReadingListEntry.fetchRequest()
            entryFetchRequest.predicate = NSPredicate(format: "articleKey IN %@", keys)
            let entries = try moc.fetch(entryFetchRequest)
            try markLocalDeletion(for: entries)
        } catch let error {
            DDLogError("Error removing article from default list: \(error)")
        }
    }
}

extension WMFArticle {
    fileprivate func addToDefaultReadingList() throws {
        guard let moc = self.managedObjectContext else {
            return
        }
        
        guard try fetchDefaultListEntry() == nil else {
            return
        }
        
        guard let defaultReadingList = moc.fetchOrCreateDefaultReadingList() else {
            assert(false, "Default reading list should exist")
            return
        }
        
        guard let defaultListEntry = NSEntityDescription.insertNewObject(forEntityName: "ReadingListEntry", into: moc) as? ReadingListEntry else {
            return
        }
        defaultListEntry.createdDate = NSDate()
        defaultListEntry.updatedDate = defaultListEntry.createdDate
        defaultListEntry.articleKey = self.key
        defaultListEntry.variant = self.variant
        defaultListEntry.list = defaultReadingList
        defaultListEntry.displayTitle = displayTitle
        defaultListEntry.isUpdatedLocally = true
        try defaultReadingList.updateArticlesAndEntries()
    }
    
    /// The purpose of these two methods is to answer the question 'is included in default reading list?'.
    /// Since only one language variant per article can be included, searching for articleKey will
    /// find any variant of the article that is on the default reading list.
    /// This is the intended behavior.
    private func fetchReadingListEntries() throws -> [ReadingListEntry] {
        guard let moc = managedObjectContext, let key = key else {
            return []
        }
        let entryFetchRequest: NSFetchRequest<ReadingListEntry> = ReadingListEntry.fetchRequest()
        entryFetchRequest.predicate = NSPredicate(format: "articleKey == %@", key)
        return try moc.fetch(entryFetchRequest)
    }
    
    private func fetchDefaultListEntry() throws -> ReadingListEntry? {
        let readingListEntries = try fetchReadingListEntries()
        return readingListEntries.first(where: { (entry) -> Bool in
            return (entry.list?.isDefault ?? false) && !entry.isDeletedLocally
        })
    }
    
    func readingListsDidChange() {
        let readingLists = self.readingLists ?? []
        if readingLists.isEmpty && savedDate != nil {
            savedDate = nil
        } else if !readingLists.isEmpty && savedDate == nil {
            savedDate = Date()
        }
    }

    private var isInDefaultList: Bool {
        guard let readingLists = self.readingLists else {
            return false
        }
        return !readingLists.filter { $0.isDefault }.isEmpty
    }
    
    @objc public var isOnlyInDefaultList: Bool {
        return (readingLists ?? []).count == 1 && isInDefaultList
    }
    
    private var userCreatedReadingLists: [ReadingList] {
        return (readingLists ?? []).filter { !$0.isDefault }
    }
    
    @objc public var userCreatedReadingListsCount: Int {
        return userCreatedReadingLists.count
    }
}

public extension NSManagedObjectContext {
    // use with caution, fetching is expensive
    @objc(wmf_fetchOrCreateDefaultReadingList)
    @discardableResult func fetchOrCreateDefaultReadingList() -> ReadingList? {
        assert(Thread.isMainThread, "Only create the default reading list on the view context to avoid duplicates")
        var defaultList = defaultReadingList
        if defaultList == nil { // failsafe
            defaultList = wmf_fetchOrCreate(objectForEntityName: "ReadingList", withValue: ReadingList.defaultListCanonicalName, forKey: "canonicalName") as? ReadingList
            defaultList?.isDefault = true
            do {
                try save()
            } catch let error {
                DDLogError("Error creating default reading list: \(error)")
            }
        }
        return defaultList
    }
    
    var defaultReadingList: ReadingList? {
        return wmf_fetch(objectForEntityName: "ReadingList", withValue: NSNumber(value: true), forKey: "isDefault") as? ReadingList
    }
    
    // is sync available or is it shut down server-side
    @objc var wmf_isSyncRemotelyEnabled: Bool {
        get {
            return wmf_numberValue(forKey: WMFReadingListSyncRemotelyEnabledKey)?.boolValue ?? true
        }
        set {
            guard newValue != wmf_isSyncRemotelyEnabled else {
                return
            }
            wmf_setValue(NSNumber(value: newValue), forKey: WMFReadingListSyncRemotelyEnabledKey)
            do {
                try save()
            } catch let error {
                DDLogError("Error saving after sync state update: \(error)")
            }
        }
    }
    
    // MARK: - Reading lists config
    
    @objc var wmf_readingListsConfigMaxEntriesPerList: NSNumber {
        get {
            return wmf_numberValue(forKey: WMFReadingListsConfigMaxEntriesPerList) ?? 5000
        }
        set {
            wmf_setValue(newValue, forKey: WMFReadingListsConfigMaxEntriesPerList)
            do {
                try save()
            } catch let error {
                DDLogError("Error saving new value for WMFReadingListsConfigMaxEntriesPerList: \(error)")
            }
        }
    }
    
    @objc var wmf_readingListsConfigMaxListsPerUser: Int {
        get {
            return wmf_numberValue(forKey: WMFReadingListsConfigMaxListsPerUser)?.intValue ?? 100
        }
        set {
            wmf_setValue(NSNumber(value: newValue), forKey: WMFReadingListsConfigMaxListsPerUser)
            do {
                try save()
            } catch let error {
                DDLogError("Error saving new value for WMFReadingListsConfigMaxListsPerUser: \(error)")
            }
        }
    }
    
    func allReadingListsCount() throws -> Int {
        assert(Thread.isMainThread)
        let request: NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
        request.predicate = NSPredicate(format: "isDeletedLocally == NO")
        return try self.count(for: request)
    }
}

extension ReadingListsController: PeriodicWorker {
    public func doPeriodicWork(_ completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            self._sync(completion)
        }
    }
}

extension ReadingListsController: BackgroundFetcher {
    public func performBackgroundFetch(_ completion: @escaping (UIBackgroundFetchResult) -> Void) {
        doPeriodicWork {
            completion(.newData)
        }
    }
}
