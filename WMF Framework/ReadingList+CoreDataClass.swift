import Foundation
import CoreData

public class ReadingList: NSManagedObject {
    
    @objc public static let entriesLimitReachedNotification = NSNotification.Name(rawValue:"WMFEntriesLimitReachedNotification")
    @objc public static let entriesLimitReachedReadingListKey = "readingList"
    
    open var articleKeys: [String] {
        let entries = self.entries ?? []
        let existingKeys = entries.flatMap { (entry) -> String? in
            guard entry.isDeletedLocally == false else {
                return nil
            }
            return entry.articleKey
        }
        return existingKeys
    }
    
    private var previousCountOfEntries: Int64 = 0
    
    public var isEntriesLimitReached: Bool = false {
        didSet {
            guard isEntriesLimitReached, countOfEntries > previousCountOfEntries else {
                return
            }
            let userInfo: [String: Any] = [ReadingList.entriesLimitReachedReadingListKey: self]
            NotificationCenter.default.post(name: ReadingList.entriesLimitReachedNotification, object: nil, userInfo: userInfo)
        }
    }
    
    // if this is true, it means that we received an error from the API indicating that the list limit was exceeded
    public var isListLimitExceededRemotely: Bool {
        guard let error = APIError else {
            return false
        }
        return error == .listLimit
    }
    
    // if this is true, it means that we received an error from the API indicating that the entry limit was exceeded
    public var isEntryLimitExceededRemotely: Bool {
        guard let error = APIError else {
            return false
        }
        return error == .entryLimit
    }
    
    // if this is true, it means that the count of local lists >= list limit
    public var isListLimitExceededLocally: Bool {
        guard let moc = managedObjectContext, let readingListsCount = try? moc.countOfAllReadingLists() else {
            return false
        }
        return readingListsCount >= moc.wmf_readingListsConfigMaxListsPerUser
    }
    
    // if this is true, it means that the count of local entries >= list limit
    public var isEntryLimitExceededLocally: Bool {
        guard let moc = managedObjectContext else {
            return false
        }
        return Int(countOfEntries) >= moc.wmf_readingListsConfigMaxEntriesPerList.intValue
    }
    
    // if this is true, it means that the list limit was exceeded remotely or locally
    public var isListLimitExceeded: Bool {
        return isListLimitExceededLocally || isListLimitExceededRemotely
    }
    
    // if this is true, it means that the entry limit was exceeded remotely or locally
    public var isEntryLimitExceeded: Bool {
        return isEntryLimitExceededRemotely || isEntryLimitExceededLocally
    }
    
    public func updateArticlesAndEntries() throws {
        previousCountOfEntries = countOfEntries
        
        let previousArticles = articles ?? []
        let previousKeys = Set<String>(previousArticles.flatMap { $0.key })
        let validEntries = (entries ?? []).filter { !$0.isDeletedLocally }
        let validArticleKeys = Set<String>(validEntries.flatMap { $0.articleKey })
        for article in previousArticles {
            guard let key = article.key, validArticleKeys.contains(key) else {
                removeFromArticles(article)
                article.readingListsDidChange()
                continue
            }
        }
        if validArticleKeys.count > 0 {
            let articleKeysToAdd = validArticleKeys.subtracting(previousKeys)
            let articlesToAdd = try managedObjectContext?.wmf_fetch(objectsForEntityName: "WMFArticle", withValues: Array(articleKeysToAdd), forKey: "key") as? [WMFArticle] ?? []
            countOfEntries = Int64(validEntries.count)
            for article in articlesToAdd {
                addToArticles(article)
                article.readingListsDidChange()
            }
            let sortedArticles = articles?.sorted(by: { (a, b) -> Bool in
                guard let aDate = a.savedDate else {
                    return false
                }
                guard let bDate = b.savedDate else {
                    return true
                }
                return aDate.compare(bDate) == .orderedDescending
            }) ?? []
            let updatedPreviewArticles = NSMutableOrderedSet()
            for article in sortedArticles {
                guard updatedPreviewArticles.count < 4 else {
                    break
                }
                guard article.imageURLString != nil || article.thumbnailURLString != nil else {
                    continue
                }
                updatedPreviewArticles.add(article)
            }
            previewArticles = updatedPreviewArticles
        } else {
            countOfEntries = 0
            articles = []
            previewArticles = []
        }
        
        if let moc = managedObjectContext {
            isEntriesLimitReached = countOfEntries >= moc.wmf_readingListsConfigMaxEntriesPerList.int64Value
        }
    }
}
