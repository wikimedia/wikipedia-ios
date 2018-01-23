import Foundation


public enum ReadingListError: Error, Equatable {
    case listExistsWithTheSameName(name: String)
    case unableToCreateList
    case unableToDeleteList
    case unableToUpdateList
    case unableToAddEntry
    case unableToRemoveEntry
    case listWithProvidedNameNotFound(name: String)
    
    public var localizedDescription: String {
        switch self {
        // TODO: WMFAlertManager can't display this string
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


fileprivate class ReadingListSyncOperation: AsyncOperation {
    weak var readingListsController: ReadingListsController!
    let readingListID: Int64
    
    init(readingListsController: ReadingListsController, readingListID: Int64) {
        self.readingListsController = readingListsController
        self.readingListID = readingListID
        super.init()
    }
    
    
}
    
fileprivate class ReadingListsSyncOperation: AsyncOperation {
    weak var readingListsController: ReadingListsController!
    
    var apiController: ReadingListsAPIController {
        return readingListsController.apiController
    }
    
    var dataStore: MWKDataStore {
        return readingListsController.dataStore
    }
    
    init(readingListsController: ReadingListsController) {
        self.readingListsController = readingListsController
        super.init()
    }
    
    override func execute() {
        readingListsController.apiController.getAllReadingLists { (allAPIReadingLists, getAllAPIReadingListsError) in
            if let error = getAllAPIReadingListsError {
                self.finish(with: error)
                return
            }
            var remoteReadingListsByID: [Int64: APIReadingList] = [:]
            var remoteReadingListsToCreateLocally: [Int64: APIReadingList] = [:]
            var remoteReadingListsByName: [String: APIReadingList] = [:]
            var remoteDefaultReadingList: APIReadingList?
            for apiReadingList in allAPIReadingLists {
                if apiReadingList.isDefault {
                    remoteDefaultReadingList = apiReadingList
                }
                remoteReadingListsByID[apiReadingList.id] = apiReadingList
                remoteReadingListsToCreateLocally[apiReadingList.id] = apiReadingList
                remoteReadingListsByName[apiReadingList.name.precomposedStringWithCanonicalMapping] = apiReadingList
            }
            DispatchQueue.main.async {
                self.dataStore.performBackgroundCoreDataOperation(onATemporaryContext: { (moc) in
                    let group = WMFTaskGroup()
                    let localReadingListsFetchRequest: NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
                    do {
                        let localReadingLists = try moc.fetch(localReadingListsFetchRequest)
                        var localReadingListsToDelete: [Int64: ReadingList] = [:]
                        var localReadingListsToSync: [Int64: [ReadingList]] = [:]
                        var localReadingListsIdsToMarkLocallyUpdatedFalse: Set<Int64> = []
                        var localDefaultReadingList: ReadingList? = nil
                        for localReadingList in localReadingLists {
                            guard !(localReadingList.isDefault?.boolValue ?? false) else {
                                if localDefaultReadingList != nil {
                                    moc.delete(localReadingList)
                                } else{
                                    localDefaultReadingList = localReadingList
                                    if let defaultReadingListID = remoteDefaultReadingList?.id {
                                        localReadingListsToSync[defaultReadingListID, default: []].append(localReadingList)
                                        remoteReadingListsToCreateLocally.removeValue(forKey: defaultReadingListID)
                                    }
                                }
                                continue
                            }
                            guard let readingListID = localReadingList.readingListID?.int64Value else {
                                let name = localReadingList.name ?? ""
                                if let remoteReadingListWithTheSameName = remoteReadingListsByName[name.precomposedStringWithCanonicalMapping] {
                                    localReadingListsToSync[remoteReadingListWithTheSameName.id, default: []].append(localReadingList)
                                } else {
                                    group.enter()
                                    self.apiController.createList(name: name, description: localReadingList.readingListDescription ?? "", completion: { (listID, error) in
                                        if let listID = listID {
                                            localReadingListsToSync[listID, default: []].append(localReadingList)
                                        }
                                        group.leave()
                                    })
                                }
                                continue
                            }
                            

                            guard let remoteList = remoteReadingListsByID[readingListID] else {
                                localReadingListsToDelete[readingListID] = localReadingList
                                continue
                            }
                            
                            localReadingListsToSync[readingListID, default: []].append(localReadingList)
                            remoteReadingListsToCreateLocally.removeValue(forKey: readingListID)
                            
                            guard !localReadingList.isDeletedLocally else {
                                group.enter()
                                self.apiController.deleteList(withListID: readingListID, completion: { (error) in
                                    if let error = error {
                                        DDLogError("error deleting list with id: \(readingListID) error: \(error)")
                                        localReadingListsToDelete.removeValue(forKey: readingListID)
                                    }
                                    group.leave()
                                })
                                continue
                            }
                            
                            localReadingListsToDelete.removeValue(forKey: readingListID)
                            
                            if localReadingList.isUpdatedLocally {
                                group.enter()
                                self.apiController.updateList(withListID: readingListID, name: localReadingList.name ?? "", description: localReadingList.readingListDescription ?? "", completion: { (error) in
                                    if let error = error {
                                        DDLogError("error updating list with id: \(readingListID) error: \(error)")
                                    } else {
                                        localReadingListsIdsToMarkLocallyUpdatedFalse.insert(readingListID)
                                    }
                                    group.leave()
                                })
                                localReadingList.isUpdatedLocally = false
                            } else {
                                localReadingList.update(with: remoteList)
                            }
                        }
                        
                        group.wait()
                        
                        for (_, list) in remoteReadingListsToCreateLocally {
                            guard let localList = NSEntityDescription.insertNewObject(forEntityName: "ReadingList", into: moc) as? ReadingList else {
                                continue
                            }
                            localList.update(with: list)
                            localReadingListsToSync[list.id, default: []].append(localList)
                        }
                        
                        for (_, list) in localReadingListsToDelete {
                            moc.delete(list)
                        }

                        
                        var entriesByReadingListID: [Int64: [APIReadingListEntry]] = [:]
                        
                        for (readingListID, readingLists) in localReadingListsToSync {
                            guard let readingList = readingLists.first else {
                                continue
                            }
                            if readingList.readingListID == nil {
                                readingList.readingListID = NSNumber(value: readingListID)
                            }
                            
                            if localReadingListsIdsToMarkLocallyUpdatedFalse.contains(readingListID) {
                                readingList.isUpdatedLocally = false
                            }

                            for duplicateReadingList in readingLists[1..<readingLists.count] {
                                if let entries = duplicateReadingList.entries {
                                    readingList.addToEntries(entries)
                                }
                                moc.delete(duplicateReadingList)
                            }

                            group.enter()
                            self.apiController.getAllEntriesForReadingListWithID(readingListID: readingListID, completion: { (entries, error) in
                                if error == nil {
                                    entriesByReadingListID[readingListID] = entries
                                }
                                group.leave()
                            })
                        }
                        
                        group.wait()
                        
                        var localEntriesToSync: [Int64: ReadingListEntry] = [:]
                        var localEntriesToDelete: [ReadingListEntry] = []
                        var remoteEntriesToCreateLocally: [Int64: (APIReadingListEntry, ReadingList)] = [:]

                        for (readingListID, readingLists) in localReadingListsToSync {
                            guard let readingList = readingLists.first else {
                                continue
                            }
                            guard let localEntries = readingList.entries else {
                                continue
                            }
                            let remoteEntries = entriesByReadingListID[readingListID] ?? []
                            //print("List \(readingList.name) has remote entries: \(remoteEntries)")
                            for entry in remoteEntries {
                                remoteEntriesToCreateLocally[entry.id] = (entry, readingList)
                            }
                            for localEntry in localEntries {
                                guard let article = localEntry.article, let articleURL = article.url, let articleSite = articleURL.wmf_site, let articleTitle = articleURL.wmf_title else {
                                    moc.delete(localEntry)
                                    continue
                                }
                                
                                guard !localEntry.isDeletedLocally else {
                                    // the entry has been deleted locally
                                    guard let entryID = localEntry.readingListEntryID?.int64Value else {
                                        localEntriesToDelete.append(localEntry)  // the entry has been deleted locally but doesn't have an entry ID, so just delete it
                                        continue
                                    }
                                    
                                    remoteEntriesToCreateLocally.removeValue(forKey: entryID)
                                    
                                    group.enter()
                                    self.apiController.removeEntry(withEntryID: entryID, fromListWithListID: readingListID, completion: { (error) in
                                        defer {
                                            group.leave()
                                        }
                                        guard error == nil else {
                                            DDLogError("Error deleting entry withEntryID: \(entryID) fromListWithListID: \(readingListID) error: \(String(describing: error))")
                                            return
                                        }
                                        localEntriesToDelete.append(localEntry)
                                    })
                                    continue
                                }

                                guard let entryID = localEntry.readingListEntryID?.int64Value else {
                                    group.enter()
                                    self.apiController.addEntryToList(withListID: readingListID, project: articleSite.absoluteString, title: articleTitle, completion: { (entryID, error) in
                                        if let entryID = entryID {
                                            localEntriesToSync[entryID] = localEntry
                                        } else {
                                            DDLogError("Missing entryID for entry: \(articleSite) \(articleTitle) in list: \(readingListID)")
                                        }
                                        group.leave()
                                    })
                                    continue
                                }
                                
                                remoteEntriesToCreateLocally.removeValue(forKey: entryID)
                            }
                        }
                        
                        var remoteEntriesToCreateLocallyByArticleKey: [String: APIReadingListEntry] = [:]
                        var requestedArticleKeys: Set<String> = []
                        var articleSummariesByArticleKey: [String: [String: Any]] = [:]
                        for (_, (remoteEntry, _)) in remoteEntriesToCreateLocally {
                            guard let articleURL = remoteEntry.articleURL, let articleKey = articleURL.wmf_articleDatabaseKey else {
                                continue
                            }
                            remoteEntriesToCreateLocallyByArticleKey[articleKey] = remoteEntry
                            guard !requestedArticleKeys.contains(articleKey) else {
                                continue
                            }
                            requestedArticleKeys.insert(articleKey)
                            group.enter()
                            URLSession.shared.wmf_fetchSummary(with: articleURL, completionHandler: { (result, response, error) in
                                guard let result = result else {
                                    group.leave()
                                    return
                                }
                                articleSummariesByArticleKey[articleKey] = result
                                group.leave()
                            })
                        }
                        
                        group.wait()
                        
                        
                        let articles = try moc.wmf_createOrUpdateArticleSummmaries(withSummaryResponses: articleSummariesByArticleKey)
                        var articlesByKey: [String: WMFArticle] = [:]
                        for article in articles {
                            guard let articleKey = article.key else {
                                continue
                            }
                            articlesByKey[articleKey] = article
                        }
                        
                        for (entryID, (remoteEntry, readingList)) in remoteEntriesToCreateLocally {
                            guard let articleURL = remoteEntry.articleURL, let articleKey = articleURL.wmf_articleDatabaseKey, let article = articlesByKey[articleKey] else {
                                continue
                            }
                            guard let entry = NSEntityDescription.insertNewObject(forEntityName: "ReadingListEntry", into: moc) as? ReadingListEntry else {
                                continue
                            }
                            entry.readingListEntryID = NSNumber(value: entryID)
                            entry.list = readingList
                            entry.article = article
                            entry.displayTitle = article.displayTitle
                            article.savedDate = DateFormatter.wmf_iso8601().date(from: remoteEntry.created)
                            article.addToDefaultReadingList()
                        }

                        for (entryID, entry) in localEntriesToSync {
                            if entry.readingListEntryID == nil {
                                entry.readingListEntryID = NSNumber(value: entryID)
                            }
                        }
                        
                        for entry in localEntriesToDelete {
                            moc.delete(entry)
                        }
                        
                        guard moc.hasChanges else {
                            return
                        }
                        try moc.save()
                        
                    } catch let error {
                        DDLogError("Error during reading list sync: \(error)")
                    }
                    self.finish()
                })
            }
        }
    }
    
    
}


@objc(WMFReadingListsController)
public class ReadingListsController: NSObject {
    fileprivate weak var dataStore: MWKDataStore!
    fileprivate let apiController = ReadingListsAPIController()
    fileprivate let operationQueue = OperationQueue()
    
    @objc init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
        operationQueue.maxConcurrentOperationCount = 1
        super.init()
    }
    
    // User-facing actions. Everything is performed on the main context
    
    public func createReadingList(named name: String, description: String? = nil, with articles: [WMFArticle] = []) throws -> ReadingList {
        assert(Thread.isMainThread)
        let name = name.precomposedStringWithCanonicalMapping
        let moc = dataStore.viewContext
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
        
        try add(articles: articles, to: list)
        
        if moc.hasChanges {
            try moc.save()
        }
        
        sync()
        
        return list
    }
    
    public func delete(readingLists: [ReadingList]) throws {
        let moc = dataStore.viewContext
        
        for readingList in readingLists {
            readingList.isDeletedLocally = true
        }
        
        if moc.hasChanges {
            try moc.save()
        }
        
        sync()
    }
    
    public func add(articles: [WMFArticle], to readingList: ReadingList) throws {
        guard !readingList.isDefaultList else {
            return
        }
        guard articles.count > 0 else {
            return
        }
        assert(Thread.isMainThread)
        let moc = dataStore.viewContext
        let existingKeys = Set(readingList.articleKeys)
        for article in articles {
            article.removeFromDefaultReadingList()
            guard let key = article.key, !existingKeys.contains(key) else {
                continue
            }
            guard let entry = moc.wmf_create(entityNamed: "ReadingListEntry", withValue: article, forKey: "article") as? ReadingListEntry else {
                return
            }
            let url = URL(string: key)
            entry.displayTitle = url?.wmf_title
            entry.list = readingList
        }
        
        readingList.updateCountOfEntries()
        
        if moc.hasChanges {
            try moc.save()
        }
        sync()
    }

    fileprivate let isSyncEnabledKey = "WMFIsReadingListSyncEnabled"

    @objc var isSyncEnabled: Bool {
        get {
            assert(Thread.isMainThread)
            return dataStore.viewContext.wmf_numberValue(forKey: isSyncEnabledKey)?.boolValue ?? false
        }
        set {
            assert(Thread.isMainThread)
            dataStore.viewContext.wmf_setValue(NSNumber(value: newValue), forKey: isSyncEnabledKey)
            if newValue {
                apiController.setupReadingLists(completion: { (error) in
                    if let error = error {
                        DDLogError("Error enabling sync: \(error)")
                        DispatchQueue.main.async {
                            self.dataStore.viewContext.wmf_setValue(NSNumber(value: false), forKey: self.isSyncEnabledKey)
                        }
                        return
                    }
                })
            } else {
                apiController.teardownReadingLists(completion: { (error) in
                    if let error = error {
                        DDLogError("Error disabling sync: \(error)")
                        DispatchQueue.main.async {
                            self.dataStore.viewContext.wmf_setValue(NSNumber(value: true), forKey: self.isSyncEnabledKey)
                        }
                        return
                    }
                })
            }
        }
    }
    
    
    @objc func _sync() {
        let op = ReadingListsSyncOperation(readingListsController: self)
        operationQueue.addOperation(op)
    }
    
    fileprivate func sync() {
        assert(Thread.isMainThread)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_sync), object: nil)
        perform(#selector(_sync), with: nil, afterDelay: 0.5)
    }
    
    public func remove(articles: [WMFArticle], readingList: ReadingList) throws {
        assert(Thread.isMainThread)
        let moc = dataStore.viewContext
        
        let entriesRequest: NSFetchRequest<ReadingListEntry> = ReadingListEntry.fetchRequest()
        entriesRequest.predicate = NSPredicate(format: "list == %@ && article IN %@", readingList, articles)
        let entriesToDelete = try moc.fetch(entriesRequest)
        for entry in entriesToDelete {
            entry.isDeletedLocally = true
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
        for entry in entries {
            entry.isDeletedLocally = true
            entry.article = nil
        }
        if moc.hasChanges {
            try moc.save()
        }
        sync()
    }
    
    @objc public func save(_ article: WMFArticle) {
        assert(Thread.isMainThread)
        do {
            let moc = dataStore.viewContext
            article.savedDate = Date()
            article.addToDefaultReadingList()
            if moc.hasChanges {
                try moc.save()
            }
            sync()
        } catch let error {
            DDLogError("Error adding article to default list: \(error)")
        }
    }
    
    @objc public func unsave(_ article: WMFArticle) {
        assert(Thread.isMainThread)
        do {
            let moc = dataStore.viewContext
            article.savedDate = nil
            for entry in article.readingListEntries ?? [] {
                entry.isDeletedLocally = true
                entry.list?.updateCountOfEntries()
            }
            if moc.hasChanges {
                try moc.save()
            }
            sync()
        } catch let error {
            DDLogError("Error removing article from default list: \(error)")
        }
    }
    
    
    @objc public func removeArticlesWithURLsFromDefaultReadingList(_ articleURLS: [URL]) {
        assert(Thread.isMainThread)
        do {
            let moc = dataStore.viewContext
            for url in articleURLS {
                guard let article = dataStore.fetchArticle(with: url) else {
                    continue
                }
                article.savedDate = nil
                article.removeFromDefaultReadingList()
            }
            if moc.hasChanges {
                try moc.save()
            }
            sync()
        } catch let error {
            DDLogError("Error removing all articles from default list: \(error)")
        }
    }
    
    @objc public func removeAllArticlesFromDefaultReadingList()  {
        assert(Thread.isMainThread)
        do {
            let moc = dataStore.viewContext
            let defaultList = moc.wmf_defaultReadingList
            for entry in defaultList.entries ?? [] {
                entry.article?.removeFromDefaultReadingList()
                entry.article?.savedDate = nil
                entry.isDeletedLocally = true
            }
            if moc.hasChanges {
                try moc.save()
            }
            sync()
        } catch let error {
            DDLogError("Error removing all articles from default list: \(error)")
        }
    }


    /// Fetches n articles with lead images for a given reading list.
    ///
    /// - Parameters:
    ///   - readingList: reading list that the articles belong to.
    ///   - limit: number of articles with lead images to fetch.
    /// - Returns: array of articles with lead images.
    public func articlesWithLeadImages(for readingList: ReadingList, limit: Int) throws -> [WMFArticle] {
        assert(Thread.isMainThread)
        let moc = dataStore.viewContext
        let request: NSFetchRequest<ReadingListEntry> = ReadingListEntry.fetchRequest()
        request.predicate = NSPredicate(format: "list == %@ && isDeletedLocally != YES && article.imageURLString != NULL", readingList)
        request.fetchLimit = limit
        return (try moc.fetch(request)).flatMap { $0.article }
    }
    
}


fileprivate extension NSManagedObjectContext {
    var wmf_defaultReadingList: ReadingList {
        guard let defaultReadingList = wmf_fetch(objectForEntityName: "ReadingList", withValue: NSNumber(value: true), forKey: "isDefault") as? ReadingList else {
            DDLogError("Missing default reading list")
            assert(false)
            return wmf_create(entityNamed: "ReadingList", withValue: NSNumber(value: true), forKey: "isDefault") as! ReadingList
        }
        return defaultReadingList
    }
}

public extension NSManagedObjectContext {
    @objc func wmf_fetchDefaultReadingList() -> ReadingList? {
        return  wmf_fetch(objectForEntityName: "ReadingList", withValue: NSNumber(value: true), forKey: "isDefault") as? ReadingList
    }
}

fileprivate extension WMFArticle {
    
    func fetchDefaultListEntry() -> ReadingListEntry? {
        return readingListEntries?.first(where: { (entry) -> Bool in
            return (entry.list?.isDefault?.boolValue ?? false) && !entry.isDeletedLocally
        })
    }
    
    func addToDefaultReadingList() {
        guard let moc = self.managedObjectContext else {
            return
        }
        
        guard fetchDefaultListEntry() == nil else {
            return
        }
        
        let defaultReadingList = moc.wmf_defaultReadingList
        let defaultListEntry = NSEntityDescription.insertNewObject(forEntityName: "ReadingListEntry", into: moc) as? ReadingListEntry
        defaultListEntry?.article = self
        defaultListEntry?.list = defaultReadingList
        defaultListEntry?.displayTitle = displayTitle
        defaultReadingList.updateCountOfEntries()
    }
    
    func removeFromDefaultReadingList() {
        for entry in readingListEntries ?? [] {
            guard entry.list?.isDefaultList ?? true else {
                return
            }
            entry.isDeletedLocally = true
            entry.list?.updateCountOfEntries()
        }
    }
}

