import Foundation


public enum ReadingListError: Error, Equatable {
    case listExistsWithTheSameName(name: String)
    case unableToCreateList
    case unableToDeleteList
    case unableToUpdateList
    case unableToAddEntry
    case listWithProvidedNameNotFound(name: String)
    
    public var localizedDescription: String {
        switch self {
        // TODO: WMFAlertManager can't display this string
        case .listExistsWithTheSameName(let name):
            let format = WMFLocalizedString("reading-list-exists-with-same-name", value: "A reading list already exists with the name ‟%1$@”", comment: "Informs the user that a reading list exists with the same name.")
            return String.localizedStringWithFormat(format, name)
        case .listWithProvidedNameNotFound(let name):
            let format = WMFLocalizedString("reading-list-with-provided-name-not-found", value: "A reading list with the name ‟%1$@” was not found. Please make sure you have the correct name.", comment: "Informs the user that a reading list with the name they provided was not found.")
            return String.localizedStringWithFormat(format, name)
        case .unableToCreateList:
            return WMFLocalizedString("reading-list-unable-to-create", value: "An unexpected error occured while creating your reading list. Please try again later.", comment: "Informs the user that an error occurred while creating their reading list.")
        case .unableToDeleteList:
            return WMFLocalizedString("reading-list-unable-to-delete", value: "An unexpected error occured while deleting your reading list. Please try again later.", comment: "Informs the user that an error occurred while deleting their reading list.")
        case .unableToUpdateList:
            return WMFLocalizedString("reading-list-unable-to-update", value: "An unexpected error occured while updating your reading list. Please try again later.", comment: "Informs the user that an error occurred while updating their reading list.")
        case .unableToAddEntry:
            return WMFLocalizedString("reading-list-unable-to-add-entry", value: "An unexpected error occured while adding an entry to your reading list. Please try again later.", comment: "Informs the user that an error occurred while adding an entry to their reading list.")
        }
    }
    
    public static func ==(lhs: ReadingListError, rhs: ReadingListError) -> Bool {
        return lhs.localizedDescription == rhs.localizedDescription //shrug
    }
}


fileprivate class ReadingListSyncOperation: AsyncOperation {
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
        //readingListsController.apiController
        readingListsController.apiController.getAllReadingLists { (allAPIReadingLists, getAllAPIReadingListsError) in
            if let error = getAllAPIReadingListsError {
                self.finish(with: error)
                return
            }
            var readingListsByID: [Int64: APIReadingList] = [:]
            for apiReadingList in allAPIReadingLists {
                guard !apiReadingList.isDefault else {
                    continue
                }
                readingListsByID[apiReadingList.id] = apiReadingList
            }
            DispatchQueue.main.async {
                self.dataStore.performBackgroundCoreDataOperation(onATemporaryContext: { (moc) in
                    let group = WMFTaskGroup()
                    let localReadingListsFetchRequest: NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
                    localReadingListsFetchRequest.predicate = NSPredicate(format: "isDefault == NO")
                    do {
                        let localReadingLists = try moc.fetch(localReadingListsFetchRequest)
                        var listIDsToUpdate: [(Int64, ReadingList)] = []
                        var localReadingListsToDelete: [Int64: ReadingList] = [:]

                        for list in localReadingLists {
                            guard let listID = list.readingListID?.int64Value else {
                                continue
                            }
                            localReadingListsToDelete[listID] = list
                        }
                        
                        var localReadingListsToMarkLocallyUpdatedFalse: [Int64: ReadingList] = [:]
                        
                        for localReadingList in localReadingLists {
                            guard let readingListID = localReadingList.readingListID?.int64Value else {
                                group.enter()
                                self.apiController.createList(name: localReadingList.name ?? "", description: localReadingList.readingListDescription ?? "", completion: { (listID, error) in
                                    if let listID = listID {
                                        listIDsToUpdate.append((listID, localReadingList))
                                    }
                                    group.leave()
                                })
                                continue
                            }
                            
                            guard let remoteList = readingListsByID[readingListID] else {
                                continue
                            }
                            
                            readingListsByID.removeValue(forKey: readingListID)
                            
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
                                localReadingListsToMarkLocallyUpdatedFalse[readingListID] = localReadingList
                                self.apiController.updateList(withListID: readingListID, name: localReadingList.name ?? "", description: localReadingList.readingListDescription ?? "", completion: { (error) in
                                    if let error = error {
                                        DDLogError("error updating list with id: \(readingListID) error: \(error)")
                                        localReadingListsToMarkLocallyUpdatedFalse.removeValue(forKey: readingListID)
                                    }
                                    group.leave()
                                })
                                localReadingList.isUpdatedLocally = false
                            } else {
                                localReadingList.update(with: remoteList)
                            }
                        }
                        
                        group.wait()
                        for update in listIDsToUpdate {
                            update.1.readingListID = NSNumber(value: update.0)
                        }
                        
                        for (_, list) in readingListsByID {
                            guard let localList = NSEntityDescription.insertNewObject(forEntityName: "ReadingList", into: moc) as? ReadingList else {
                                continue
                            }
                            localList.update(with: list)
                        }
                        
                        for (_, list) in localReadingListsToMarkLocallyUpdatedFalse {
                            list.isUpdatedLocally = false
                        }
                        
                        for (_, list) in localReadingListsToDelete {
                            moc.delete(list)
                        }
                        
                        guard moc.hasChanges else {
                            return
                        }
                        try moc.save()
                        
                    } catch let error {
                        DDLogError("Error fetching: \(error)")
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
        let moc = dataStore.viewContext
        let existingListRequest: NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
        existingListRequest.predicate = NSPredicate(format: "name MATCHES[c] %@", name)
        existingListRequest.fetchLimit = 1
        let result = try moc.fetch(existingListRequest).first
        guard result == nil else {
            throw ReadingListError.listExistsWithTheSameName(name: name)
        }
        
        guard let list = moc.wmf_create(entityNamed: "ReadingList", withKeysAndValues: ["name": name, "readingListDescription": description]) as? ReadingList else {
            throw ReadingListError.unableToCreateList
        }
        
        try add(articles: articles, to: list)
        
        if moc.hasChanges {
            try moc.save()
        }
        
        return list
    }
    
    public func delete(readingLists: [ReadingList]) throws {
        
        let moc = dataStore.viewContext
        let readingListsToDeleteRequest: NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
        
        let names = readingLists.flatMap({ $0.name })
        readingListsToDeleteRequest.predicate = NSPredicate(format: "name IN %@", names)
        
        let readingListsToDelete = try moc.fetch(readingListsToDeleteRequest)
        
        for readingList in readingListsToDelete {
            moc.delete(readingList)
        }
        
        if moc.hasChanges {
            try moc.save()
        }
    }
    
    public func add(articles: [WMFArticle], to readingList: ReadingList) throws {
        guard !readingList.isDefaultList else {
            return
        }
        
        assert(Thread.isMainThread)

        let moc = dataStore.viewContext
        
        let existingKeys = Set(readingList.articleKeys)
        
        for article in articles {
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
        
        if moc.hasChanges {
            try moc.save()
        }

    }
    
    @objc public func setupReadingLists() {
        let op = ReadingListSyncOperation(readingListsController: self)
        operationQueue.addOperation(op)
    }
    
    public func remove(articles: [WMFArticle], readingList: ReadingList) throws {
        assert(Thread.isMainThread)
        let moc = dataStore.viewContext
        let _ = try fetch(readingList: readingList)
        
        let entriesRequest: NSFetchRequest<ReadingListEntry> = ReadingListEntry.fetchRequest()
        entriesRequest.predicate = NSPredicate(format: "list == %@ && article IN %@", readingList, articles)
        let entriesToDelete = try moc.fetch(entriesRequest)
        
        entriesToDelete.forEach({ moc.delete($0) })
        if moc.hasChanges {
            try moc.save()
        }
    }
    
    public func remove(entries: [ReadingListEntry]) throws {
        assert(Thread.isMainThread)
        let moc = dataStore.viewContext
        entries.forEach({ moc.delete($0) })
        if moc.hasChanges {
            try moc.save()
        }
    }
    
    
    fileprivate func fetch(readingList: ReadingList) throws -> ReadingList? {
        guard let name = readingList.name else {
            return nil
        }
        let moc = dataStore.viewContext
        let readingListRequest: NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
        readingListRequest.predicate = NSPredicate(format: "name MATCHES[c] %@", name)
        readingListRequest.fetchLimit = 1
        guard let readingList = try moc.fetch(readingListRequest).first else {
            throw ReadingListError.listWithProvidedNameNotFound(name: name)
        }
        return readingList
    }
    
}
