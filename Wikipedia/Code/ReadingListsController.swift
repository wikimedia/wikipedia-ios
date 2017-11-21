import Foundation


public enum ReadingListError: Error, Equatable {
    case listExistsWithTheSameName(name: String)
    case unableToCreateList
    case listWithProvidedNameNotFound(name: String)
    
    public var localizedDescription: String {
        switch self {
        case .listExistsWithTheSameName(let name):
            let format = WMFLocalizedString("reading-list-exists-with-same-name", value: "A reading list already exists with the name ‟%1$@”", comment: "Informs the user that a reading list exists with the same name.")
            return String.localizedStringWithFormat(format, name)
        case .listWithProvidedNameNotFound(let name):
            let format = WMFLocalizedString("reading-list-with-provided-name-not-found", value: "A reading list with the name ‟%1$@” was not found. Please make sure you have the correct name.", comment: "Informs the user that a reading list with the name they provided was not found.")
            return String.localizedStringWithFormat(format, name)
        case .unableToCreateList:
            return WMFLocalizedString("reading-list-unable-to-create", value: "An unexpected error occured while creating your reading list. Please try again later.", comment: "Informs the user that an error occurred while creating their reading list.")
        }
    }
    
    public static func ==(lhs: ReadingListError, rhs: ReadingListError) -> Bool {
        return lhs.localizedDescription == rhs.localizedDescription //shrug
    }
}


@objc(WMFReadingListsController)
public class ReadingListsController: NSObject {
    fileprivate weak var dataStore: MWKDataStore!
    fileprivate let apiController = ReadingListsAPIController()
    
    @objc init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
        super.init()
    }
    
    // User-facing actions. Everything is performed on the main context
    
    public func createReadingList(named name: String, with articles: [WMFArticle] = []) throws -> ReadingList {
        assert(Thread.isMainThread)
        let moc = dataStore.viewContext
        let existingListRequest: NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
        existingListRequest.predicate = NSPredicate(format: "name MATCHES[cd] %@", name)
        existingListRequest.fetchLimit = 1
        let result = try moc.fetch(existingListRequest).first
        guard result == nil else {
            throw ReadingListError.listExistsWithTheSameName(name: name)
        }
        guard let list = moc.wmf_create(entityNamed: "ReadingList", withValue: name, forKey: "name") as? ReadingList else {
            throw ReadingListError.unableToCreateList
        }
        
        try add(articles: articles, to: list)
        
        if moc.hasChanges {
            try moc.save()
        }
        
        return list
    }
    
    public func delete(readingLists: [ReadingList]) throws -> [ReadingList] {
        
        let moc = dataStore.viewContext
        let readingListsToDeleteRequest: NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
        
        let readingListNamesToDelete = readingLists.flatMap { (readingList) -> String? in
            readingList.name
        }
        
        readingListsToDeleteRequest.predicate = NSPredicate(format: "!(name MATCHES[cd] IN %@)", readingListNamesToDelete)
        readingListsToDeleteRequest.fetchLimit = 1
        
        let readingListsToDelete = try moc.fetch(readingListsToDeleteRequest)
        
        var deletedReadingLists: [ReadingList] = []
        
        for readingList in readingListsToDelete {
            moc.delete(readingList)
            deletedReadingLists.append(readingList)
        }
        
        if moc.hasChanges {
            try moc.save()
        }
        
        return deletedReadingLists
    }
    
    public func add(articles: [WMFArticle], to readingList: ReadingList) throws {
        assert(Thread.isMainThread)

        let moc = dataStore.viewContext
        
        let keys = articles.flatMap { (article) -> String? in
            return article.key
        }
        
        let entries = readingList.entries ?? []
        let existingKeys = entries.flatMap { (entry) -> String? in
            guard let entry = entry as? ReadingListEntry else {
                return nil
            }
            return entry.articleKey
        }
        
        var keysToAdd = Set(existingKeys)
        keysToAdd.subtract(keys)
        
        for key in keysToAdd {
            guard let entry = moc.wmf_create(entityNamed: "Entry", withValue: key, forKey: "articleKey") as? ReadingListEntry else {
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
    
    public func remove(articles: [WMFArticle], fromReadingListNamed readingListName: String) throws {
        assert(Thread.isMainThread)
        
        let moc = dataStore.viewContext
        let existingReadingListRequest: NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
        
        existingReadingListRequest.predicate = NSPredicate(format: "name MATCHES[cd] %@", readingListName)
        existingReadingListRequest.fetchLimit = 1
        
        let existingReadingList = try moc.fetch(existingReadingListRequest).first
        
        guard existingReadingList != nil else {
            throw ReadingListError.listWithProvidedNameNotFound(name: readingListName)
        }
        
        let keysToDelete = articles.flatMap { (article) -> String? in
            return article.key
        }
        
        let entriesToDeleteRequest: NSFetchRequest<ReadingListEntry> = ReadingListEntry.fetchRequest()
        entriesToDeleteRequest.predicate = NSPredicate(format: "list.name MATCHES[cd] %@ && !(articleKey IN %@)", readingListName, keysToDelete)
        
        let entriesToDelete = try moc.fetch(entriesToDeleteRequest)
        
        for entry in entriesToDelete {
            moc.delete(entry)
        }
        
        if moc.hasChanges {
            try moc.save()
        }
    }
    
}
