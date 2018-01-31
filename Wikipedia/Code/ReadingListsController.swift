import Foundation

internal let WMFReadingListUpdateKey = "WMFReadingListUpdateKey"

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
    internal weak var dataStore: MWKDataStore!
    internal let apiController = ReadingListsAPIController()
    private let operationQueue = OperationQueue()
    
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
        
        list.isUpdatedLocally = true
        
        try add(articles: articles, to: list)
        
        if moc.hasChanges {
            try moc.save()
        }
        
        sync()
        
        return list
    }
    
    internal func locallyDelete(readingLists: [ReadingList], from managedObjectContext: NSManagedObjectContext) throws {
        for readingList in readingLists {
            readingList.isDeletedLocally = true
            readingList.isUpdatedLocally = true
            for entry in readingList.entries ?? [] {
                entry.isDeletedLocally = true
                entry.isUpdatedLocally = true
                entry.article?.updateReadingListEntries()
                entry.article = nil
            }
        }
    }
    
    public func delete(readingLists: [ReadingList]) throws {
        let moc = dataStore.viewContext
        
        try locallyDelete(readingLists: readingLists, from: moc)
        
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
            entry.isUpdatedLocally = true
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


    private let isSyncEnabledKey = "WMFIsReadingListSyncEnabled"

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
        let sync = ReadingListsSyncOperation(readingListsController: self)
        operationQueue.addOperation(sync)
//        let update = ReadingListsUpdateOperation(readingListsController: self)
//        operationQueue.addOperation(update)
    }
    
    private func sync() {
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
        for entry in entries {
            entry.isDeletedLocally = true
            entry.isUpdatedLocally = true
            entry.article?.updateReadingListEntries()
            entry.article = nil
            entry.list?.updateCountOfEntries()
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
                entry.isUpdatedLocally = true
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
                entry.isUpdatedLocally = true
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
    
    
    internal func createOrUpdate(remoteReadingLists: [APIReadingList], inManagedObjectContext moc: NSManagedObjectContext) throws -> Date {
        var sinceDate: Date = Date.distantPast

        // Arrange remote lists by ID and name for merging with local lists
        var remoteReadingListsByID: [Int64: APIReadingList] = [:]
        var remoteReadingListsByName: [String: APIReadingList] = [:]
        for remoteReadingList in remoteReadingLists {
            if let date = DateFormatter.wmf_iso8601().date(from: remoteReadingList.updated),
                date.compare(sinceDate) == .orderedDescending {
                sinceDate = date
            }
            remoteReadingListsByID[remoteReadingList.id] = remoteReadingList
            remoteReadingListsByName[remoteReadingList.name.precomposedStringWithCanonicalMapping] = remoteReadingList
        }
        
        let localReadingListsFetch: NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
        localReadingListsFetch.predicate = NSPredicate(format: "readingListID IN %@ || readingListName IN %@", Array(remoteReadingListsByID.keys), Array(remoteReadingListsByName.keys))
        let localReadingLists = try moc.fetch(localReadingListsFetch)
        for localReadingList in localReadingLists {
            var remoteReadingList: APIReadingList?
            if let localReadingListID = localReadingList.readingListID?.int64Value {
                // remove from the dictionary because we will create any lists left in the dictionary
                remoteReadingList = remoteReadingListsByID.removeValue(forKey: localReadingListID)
                if let remoteReadingListName = remoteReadingList?.name {
                    remoteReadingListsByName.removeValue(forKey: remoteReadingListName)
                }
            }
            
            if remoteReadingList == nil {
                if let localReadingListName = localReadingList.name?.precomposedStringWithCanonicalMapping {
                    remoteReadingList = remoteReadingListsByName.removeValue(forKey: localReadingListName)
                    if let remoteReadingListID = remoteReadingList?.id {
                        // remove from the dictionary because we will create any lists left in this dictionary
                        remoteReadingListsByID.removeValue(forKey: remoteReadingListID)
                    }
                }
            }

            guard let remoteReadingListForUpdate = remoteReadingList else {
                DDLogError("Fetch produced a list without a matching id or name: \(localReadingList)")
                assert(false)
                continue
            }
            
            let isDeleted = remoteReadingListForUpdate.deleted ?? false
            if isDeleted {
                try locallyDelete(readingLists: [localReadingList], from: moc)
                moc.delete(localReadingList) // object can be removed since we have the server-side update
            } else {
                localReadingList.update(with: remoteReadingListForUpdate)
            }
        }
        
        
        // create any list that wasn't matched by ID or name
        for (_, remoteReadingList) in remoteReadingListsByID {
            guard let localList = NSEntityDescription.insertNewObject(forEntityName: "ReadingList", into: moc) as? ReadingList else {
                continue
            }
            localList.update(with: remoteReadingList)
        }
        
        return sinceDate
    }
    
    internal func createOrUpdate(remoteReadingListEntries: [APIReadingListEntry], for readingListID: Int64?, inManagedObjectContext: NSManagedObjectContext) throws -> Date {
        var sinceDate: Date = Date.distantPast

        // Arrange remote list entries by ID and key for merging with local lists
        var remoteReadingListEntriesByID: [Int64: APIReadingListEntry] = [:]
        var remoteReadingListEntriesByListIDAndArticleKey: [Int64: [String: APIReadingListEntry]] = [:]
        for remoteReadingListEntry in remoteReadingListEntries {
            if let date = DateFormatter.wmf_iso8601().date(from: remoteReadingListEntry.updated),
                date.compare(sinceDate) == .orderedDescending {
                sinceDate = date
            }
            guard let listID = remoteReadingListEntry.listId ?? readingListID, let articleKey = remoteReadingListEntry.articleKey else {
                DDLogError("missing id or article key for remote entry: \(remoteReadingListEntry)")
                assert(false)
                continue
            }
            
            remoteReadingListEntriesByID[remoteReadingListEntry.id] = remoteReadingListEntry
            remoteReadingListEntriesByListIDAndArticleKey[listID, default: [:]][articleKey] = remoteReadingListEntry
        }

//        let localReadingListsFetch: NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
//        localReadingListsFetch.predicate = NSPredicate(format: "readingListID IN %@ || readingListName IN %@", Array(remoteReadingListsByID.keys), Array(remoteReadingListsByName.keys))
//        let localReadingLists = try moc.fetch(localReadingListsFetch)
//        for localReadingList in localReadingLists {
//            var remoteReadingList: APIReadingList?
//            if let localReadingListID = localReadingList.readingListID?.int64Value {
//                // remove from the dictionary because we will create any lists left in the dictionary
//                remoteReadingList = remoteReadingListsByID.removeValue(forKey: localReadingListID)
//                if let remoteReadingListName = remoteReadingList?.name {
//                    remoteReadingListsByName.removeValue(forKey: remoteReadingListName)
//                }
//            }
//
//            if remoteReadingList == nil {
//                if let localReadingListName = localReadingList.name?.precomposedStringWithCanonicalMapping {
//                    remoteReadingList = remoteReadingListsByName.removeValue(forKey: localReadingListName)
//                    if let remoteReadingListID = remoteReadingList?.id {
//                        // remove from the dictionary because we will create any lists left in this dictionary
//                        remoteReadingListsByID.removeValue(forKey: remoteReadingListID)
//                    }
//                }
//            }
//
//            guard let remoteReadingListForUpdate = remoteReadingList else {
//                DDLogError("Fetch produced a list without a matching id or name: \(localReadingList)")
//                assert(false)
//                continue
//            }
//
//            let isDeleted = remoteReadingListForUpdate.deleted ?? false
//            if isDeleted {
//                try locallyDelete(readingLists: [localReadingList], from: moc)
//                moc.delete(localReadingList) // object can be removed since we have the server-side update
//            } else {
//                localReadingList.update(with: remoteReadingListForUpdate)
//            }
//        }
//
//
//        // create any list that wasn't matched by ID or name
//        for (_, remoteReadingList) in remoteReadingListsByID {
//            guard let localList = NSEntityDescription.insertNewObject(forEntityName: "ReadingList", into: moc) as? ReadingList else {
//                continue
//            }
//            localList.update(with: remoteReadingList)
//        }

        return sinceDate
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

    func updateReadingListEntries() {
        guard let articleEntries = readingListEntries else {
            savedDate = nil
            return
        }
        if articleEntries.filter({ !$0.isDeletedLocally }).count == 0 {
            savedDate = nil
        }
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
            entry.isUpdatedLocally = true
            entry.list?.updateCountOfEntries()
        }
    }
}

