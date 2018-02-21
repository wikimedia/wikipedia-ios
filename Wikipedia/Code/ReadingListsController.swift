import Foundation

internal let WMFReadingListSyncStateKey = "WMFReadingListsSyncState"

internal let WMFReadingListUpdateKey = "WMFReadingListUpdateKey"

internal let WMFReadingListBatchRequestLimit = 8 // currently this waits until all requests are done before firing off new ones, could be optimized to add new requests as old ones finish

internal let WMFReadingListBatchSizePerRequestLimit = 500

internal let WMFReadingListCoreDataBatchSize = 500

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
    static let needsRandomEntries = ReadingListSyncState(rawValue: 1 << 8) // for debugging, populate with random entries
    
    static let needsEnable: ReadingListSyncState = [.needsRemoteEnable, .needsSync]
    static let needsLocalClear: ReadingListSyncState = [.needsLocalArticleClear, .needsLocalListClear]
    static let needsClearAndEnable: ReadingListSyncState = [.needsLocalClear, .needsRemoteEnable, .needsSync]

    static let needsDisable: ReadingListSyncState = [.needsRemoteDisable, .needsLocalReset]
}

public enum ReadingListError: Error, Equatable {
    case listExistsWithTheSameName(name: String)
    case unableToCreateList
    case generic
    case unableToDeleteList
    case unableToUpdateList
    case unableToAddEntry
    case unableToRemoveEntry
    case listWithProvidedNameNotFound(name: String)
    
    public var localizedDescription: String {
        switch self {
        // TODO: WMFAlertManager can't display this string
        case .generic:
            return WMFLocalizedString("reading-list-generic-error", value: "An unexpected error occurred while updating your reading lists.", comment: "An unexpected error occurred while updating your reading lists.")
        case .listExistsWithTheSameName(let name):
            let format = WMFLocalizedString("reading-list-exists-with-same-name", value: "A reading list already exists with the name %1$@", comment: "Informs the user that a reading list exists with the same name.")
            return String.localizedStringWithFormat(format, name)
        case .listWithProvidedNameNotFound(let name):
            let format = WMFLocalizedString("reading-list-with-provided-name-not-found", value: "A reading list with the name %1$@ was not found. Please make sure you have the correct name.", comment: "Informs the user that a reading list with the name they provided was not found.")
            return String.localizedStringWithFormat(format, name)
        case .unableToCreateList:
            return WMFLocalizedString("reading-list-unable-to-create", value: "An unexpected error occured while creating your reading list. Please try again later.", comment: "Informs the user that an error occurred while creating their reading list.")
        case .unableToDeleteList:
            return WMFLocalizedString("reading-list-unable-to-delete", value: "An unexpected error occured while deleting your reading list. Please try again later.", comment: "Informs the user that an error occurred while deleting their reading list.")
        case .unableToUpdateList:
            return WMFLocalizedString("reading-list-unable-to-update", value: "An unexpected error occured while updating your reading list. Please try again later.", comment: "Informs the user that an error occurred while updating their reading list.")
        case .unableToAddEntry:
            return WMFLocalizedString("reading-list-unable-to-add-entry", value: "An unexpected error occured while adding an entry to your reading list. Please try again later.", comment: "Informs the user that an error occurred while adding an entry to their reading list.")
        case .unableToRemoveEntry:
            return WMFLocalizedString("reading-list-unable-to-remove-entry", value: "An unexpected error occured while removing an entry from your reading list. Please try again later.", comment: "Informs the user that an error occurred while removing an entry from their reading list.")
        }
    }
    
    public static func ==(lhs: ReadingListError, rhs: ReadingListError) -> Bool {
        return lhs.localizedDescription == rhs.localizedDescription //shrug
    }
}

@objc(WMFReadingListsController)
public class ReadingListsController: NSObject {
    @objc public static let syncStateDidChangeNotification = NSNotification.Name(rawValue: "WMFReadingListsSyncStateDidChangeNotification")

    internal weak var dataStore: MWKDataStore!
    internal let apiController = ReadingListsAPIController()
    private let operationQueue = OperationQueue()
    private var updateTimer: Timer?
    
    @objc init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
        operationQueue.maxConcurrentOperationCount = 1
        super.init()
    }
    
    // User-facing actions. Everything is performed on the main context
    public func createReadingList(named name: String, description: String? = nil, with articles: [WMFArticle] = []) throws -> ReadingList {
        assert(Thread.isMainThread)
        let moc = dataStore.viewContext
        let list = try createReadingList(named: name, description: description, with: articles, in: moc)

        if moc.hasChanges {
            try moc.save()
        }
        
        sync()
        return list
    }
    
    public func createReadingList(named name: String, description: String? = nil, with articles: [WMFArticle] = [], in moc: NSManagedObjectContext) throws -> ReadingList {
        let name = name.precomposedStringWithCanonicalMapping
        let existingListRequest: NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
        existingListRequest.predicate = NSPredicate(format: "canonicalName MATCHES %@", name)
        existingListRequest.fetchLimit = 1
        let result = try moc.fetch(existingListRequest).first
        guard result == nil else {
            throw ReadingListError.listExistsWithTheSameName(name: name)
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
    
    public func updateReadingList(_ readingList: ReadingList, with newName: String?, newDescription: String?) {
        assert(Thread.isMainThread)
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
            for entry in readingList.entries ?? [] {
                entry.isDeletedLocally = true
                entry.isUpdatedLocally = true
            }
            let articles = readingList.articles ?? []
            readingList.articles = []
            for article in articles {
                article.readingListsDidChange()
            }
        }
    }
    
    /// Marks that reading list entries were deleted locally and updates associated objects. Doesn't delete them from the NSManagedObjectContext - that should happen only with confirmation from the server that they were deleted.
    ///
    /// - Parameters:
    ///   - readingListEntriess: the reading lists to delete
    internal func markLocalDeletion(for readingListEntries: [ReadingListEntry]) throws {
        guard readingListEntries.count > 0 else {
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
            list.updateArticlesAndEntries()
        }
    }
    
    public func delete(readingLists: [ReadingList]) throws {
        let moc = dataStore.viewContext
        
        try markLocalDeletion(for: readingLists)
        
        if moc.hasChanges {
            try moc.save()
        }
        
        sync()
    }
    
    internal func add(articles: [WMFArticle], to readingList: ReadingList, in moc: NSManagedObjectContext) throws {
        guard articles.count > 0 else {
            return
        }

        let existingKeys = Set(readingList.articleKeys)
        
        for article in articles {
            guard let key = article.key, !existingKeys.contains(key) else {
                continue
            }
            guard let entry = moc.wmf_create(entityNamed: "ReadingListEntry", withValue: key, forKey: "articleKey") as? ReadingListEntry else {
                return
            }
            entry.createdDate = NSDate()
            entry.updatedDate = entry.createdDate
            entry.isUpdatedLocally = true
            let url = URL(string: key)
            entry.displayTitle = url?.wmf_title
            entry.list = readingList
        }
        readingList.updateArticlesAndEntries()
    }
    
    public func add(articles: [WMFArticle], to readingList: ReadingList) throws {
        assert(Thread.isMainThread)
        let moc = dataStore.viewContext
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
    
    public func debugSync(createLists: Bool, listCount: Int64, addEntries: Bool, entryCount: Int64, deleteLists: Bool, deleteEntries: Bool, doFullSync: Bool, completion: @escaping () -> Void) {
        dataStore.viewContext.wmf_setValue(NSNumber(value: listCount), forKey: "WMFCountOfListsToCreate")
        dataStore.viewContext.wmf_setValue(NSNumber(value: entryCount), forKey: "WMFCountOfEntriesToCreate")
        let oldValue = syncState
        var newValue = oldValue
        if createLists {
            newValue.insert(.needsRandomLists)
        } else {
            newValue.remove(.needsRandomLists)
        }
        if addEntries {
            newValue.insert(.needsRandomEntries)
        } else {
            newValue.remove(.needsRandomEntries)
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
        
        
        operationQueue.cancelAllOperations()
        operationQueue.addOperation {
            DispatchQueue.main.async {
                self.syncState = newValue
                if doFullSync {
                    self.fullSync(completion)
                } else {
                    self.backgroundUpdate(completion)
                }
            }
        }
        
       
    }
        
    @objc public var isSyncEnabled: Bool {
        assert(Thread.isMainThread)
        let state = syncState
        return state.contains(.needsSync) || state.contains(.needsUpdate)
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
        NotificationCenter.default.post(name: ReadingListsController.syncStateDidChangeNotification, object: self)
    }
    
    @objc public func start() {
        guard updateTimer == nil else {
            return
        }
        assert(Thread.isMainThread)
        updateTimer = Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(sync), userInfo: nil, repeats: true)
        sync()
    }
    
    @objc public func stop(_ completion: @escaping () -> Void) {
        assert(Thread.isMainThread)
        updateTimer?.invalidate()
        updateTimer = nil
        operationQueue.cancelAllOperations()
        operationQueue.addOperation(completion)
    }
    
    @objc public func backgroundUpdate(_ completion: @escaping () -> Void) {
        #if TEST
        #else
        let sync = ReadingListsSyncOperation(readingListsController: self)
        operationQueue.addOperation(sync)
        operationQueue.addOperation(completion)
        #endif
    }
    
    @objc public func fullSync(_ completion: @escaping () -> Void) {
        #if TEST
        #else
            var newValue = self.syncState
            if newValue.contains(.needsUpdate) {
                newValue.remove(.needsUpdate)
                newValue.insert(.needsSync)
                self.syncState = newValue
            }
            let sync = ReadingListsSyncOperation(readingListsController: self)
            operationQueue.addOperation(sync)
            operationQueue.addOperation(completion)
        #endif
    }
    
    @objc private func _sync() {
        guard operationQueue.operationCount == 0 else {
            return
        }
        let sync = ReadingListsSyncOperation(readingListsController: self)
        operationQueue.addOperation(sync)
    }
    
    @objc public func sync() {
        #if TEST
        #else
            assert(Thread.isMainThread)
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_sync), object: nil)
            perform(#selector(_sync), with: nil, afterDelay: 0.5)
        #endif
    }
    
    public func remove(articles: [WMFArticle], readingList: ReadingList) throws {
        assert(Thread.isMainThread)
        let moc = dataStore.viewContext
        
        let articleKeys = articles.flatMap { $0.key }
        for article in articles {
            readingList.removeFromArticles(article)
            article.readingListsDidChange()
        }
        
        let entriesRequest: NSFetchRequest<ReadingListEntry> = ReadingListEntry.fetchRequest()
        entriesRequest.predicate = NSPredicate(format: "list == %@ && articleKey IN %@", readingList, articleKeys)
        let entriesToDelete = try moc.fetch(entriesRequest)
        for entry in entriesToDelete {
            entry.isDeletedLocally = true
            entry.isUpdatedLocally = true
        }

        readingList.updateCountOfEntries()

        if moc.hasChanges {
            try moc.save()
        }
        sync()
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
    
    @objc public func save(_ article: WMFArticle) {
        assert(Thread.isMainThread)
        do {
            let moc = dataStore.viewContext
            if article.savedDate == nil {
                article.savedDate = Date()
            }
            try article.addToDefaultReadingList()
            if moc.hasChanges {
                try moc.save()
            }
            sync()
        } catch let error {
            DDLogError("Error adding article to default list: \(error)")
        }
    }
    
    @objc public func addArticleToDefaultReadingList(_ article: WMFArticle) throws {
        try article.addToDefaultReadingList()
    }
    
    @objc(unsaveArticle:inManagedObjectContext:) public func unsaveArticle(_ article: WMFArticle, in moc: NSManagedObjectContext) {
        unsave([article], in: moc)
    }
    
    @objc(unsaveArticles:inManagedObjectContext:) public func unsave(_ articles: [WMFArticle], in moc: NSManagedObjectContext) {
        do {
            for article in articles {
                article.savedDate = nil
            }
            let keys = articles.flatMap { $0.key }
            let entryFetchRequest: NSFetchRequest<ReadingListEntry> = ReadingListEntry.fetchRequest()
            entryFetchRequest.predicate = NSPredicate(format: "articleKey IN %@", keys)
            let entries = try moc.fetch(entryFetchRequest)
            try markLocalDeletion(for: entries)
        } catch let error {
            DDLogError("Error removing article from default list: \(error)")
        }
    }
    
    
    @objc public func removeArticlesWithURLsFromDefaultReadingList(_ articleURLs: [URL]) {
        assert(Thread.isMainThread)
        do {
            let moc = dataStore.viewContext
            for url in articleURLs {
                guard let article = dataStore.fetchArticle(with: url) else {
                    continue
                }
                unsave([article], in: moc)
            }
            if moc.hasChanges {
                try moc.save()
            }
            sync()
        } catch let error {
            DDLogError("Error removing all articles from default list: \(error)")
        }
    }
    
    @objc public func unsaveAllArticles()  {
        assert(Thread.isMainThread)
        let oldSyncState = self.syncState
        var newSyncState = oldSyncState
        newSyncState.insert(.needsLocalArticleClear)
        guard newSyncState != oldSyncState else {
            return
        }
        self.syncState = newSyncState
        sync()
    }
}

public extension NSManagedObjectContext {
    @objc func wmf_fetchDefaultReadingList() -> ReadingList? {
        var defaultList = wmf_fetch(objectForEntityName: "ReadingList", withValue: NSNumber(value: true), forKey: "isDefault") as? ReadingList
        if defaultList == nil { // failsafe
            defaultList = wmf_fetch(objectForEntityName: "ReadingList", withValue: ReadingList.defaultListCanonicalName, forKey: "canonicalName") as? ReadingList
            defaultList?.isDefault = true
        }
        return defaultList
    }
}

internal extension WMFArticle {
    func fetchReadingListEntries() throws -> [ReadingListEntry] {
        guard let moc = managedObjectContext, let key = key else {
            return []
        }
        let entryFetchRequest: NSFetchRequest<ReadingListEntry> = ReadingListEntry.fetchRequest()
        entryFetchRequest.predicate = NSPredicate(format: "articleKey == %@", key)
        return try moc.fetch(entryFetchRequest)
    }
    
    func fetchDefaultListEntry() throws -> ReadingListEntry? {
        let readingListEntries = try fetchReadingListEntries()
        return readingListEntries.first(where: { (entry) -> Bool in
            return (entry.list?.isDefault ?? false) && !entry.isDeletedLocally
        })
    }
    
    func addToDefaultReadingList() throws {
        guard let moc = self.managedObjectContext else {
            return
        }
        
        guard try fetchDefaultListEntry() == nil else {
            return
        }
        
        guard let defaultReadingList = moc.wmf_fetchDefaultReadingList() else {
            return
        }
        
        guard let defaultListEntry = NSEntityDescription.insertNewObject(forEntityName: "ReadingListEntry", into: moc) as? ReadingListEntry else {
            return
        }
        defaultListEntry.createdDate = NSDate()
        defaultListEntry.updatedDate = defaultListEntry.createdDate
        defaultListEntry.articleKey = self.key
        defaultListEntry.list = defaultReadingList
        defaultListEntry.displayTitle = displayTitle
        defaultListEntry.isUpdatedLocally = true
        defaultReadingList.updateArticlesAndEntries()
    }
    
    func removeFromDefaultReadingList() throws {
        let entries = try fetchReadingListEntries()
        for entry in entries {
            guard let list = entry.list, list.isDefault else {
                return
            }
            entry.isDeletedLocally = true
            entry.isUpdatedLocally = true
            entry.list?.updateCountOfEntries()
            list.removeFromArticles(self)
            readingListsDidChange()
        }
    }
    
    func readingListsDidChange() {
        let readingLists = self.readingLists ?? []
        if readingLists.count == 0 && savedDate != nil {
            savedDate = nil
        } else if readingLists.count > 0 && savedDate == nil {
            savedDate = Date()
        }
    }
}

extension WMFArticle {
    @objc public var isInDefaultList: Bool {
        guard let readingLists = self.readingLists else {
            return false
        }
        return readingLists.filter { $0.isDefault }.count > 0
    }
    
    @objc public var isOnlyInDefaultList: Bool {
        return (readingLists ?? []).count == 1 && isInDefaultList
    }
    
    @objc public var readingListsCount: Int {
        return (readingLists ?? []).count
    }
    
    @objc public var userCreatedReadingLists: [ReadingList] {
        return (readingLists ?? []).filter { !$0.isDefault }
    }
    
    @objc public var userCreatedReadingListsCount: Int {
        return userCreatedReadingLists.count
    }
}
