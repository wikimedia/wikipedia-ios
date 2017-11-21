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
    
}
