import Foundation
import CoreData

public class ReadingList: NSManagedObject {
    
    @objc public static let entriesLimitReachedNotification = NSNotification.Name(rawValue:"WMFEntriesLimitReachedNotification")
    @objc public static let entriesLimitReachedReadingListKey = "readingList"
    
    // Note that this returns articleKey strings that do not take language variant into account.
    // This allows clients to check if an article of any variant is an entry in the list.
    // This is intentional.
    public var articleKeys: [String] {
        let entries = self.entries ?? []
        let existingKeys = entries.compactMap { (entry) -> String? in
            guard entry.isDeletedLocally == false else {
                return nil
            }
            return entry.articleKey
        }
        return existingKeys
    }
    
    private var previousCountOfEntries: Int64 = 0
    private var isEntriesLimitReached: Bool = false {
        didSet {
            guard isEntriesLimitReached, countOfEntries > previousCountOfEntries else {
                return
            }
            let userInfo: [String: Any] = [ReadingList.entriesLimitReachedReadingListKey: self]
            NotificationCenter.default.post(name: ReadingList.entriesLimitReachedNotification, object: nil, userInfo: userInfo)
        }
    }
    
    public func updateArticlesAndEntries() throws {
        previousCountOfEntries = countOfEntries
        
        let previousArticles = articles ?? []
        let previousKeys = Set<WMFInMemoryURLKey>(previousArticles.compactMap { $0.inMemoryKey })
        let validEntries = (entries ?? []).filter { !$0.isDeletedLocally }
        let validArticleKeys = Set<WMFInMemoryURLKey>(validEntries.compactMap { $0.inMemoryKey })
        for article in previousArticles {
            guard let key = article.inMemoryKey, validArticleKeys.contains(key) else {
                removeFromArticles(article)
                article.readingListsDidChange()
                continue
            }
        }
        if !validArticleKeys.isEmpty {
            let articleKeysToAdd = validArticleKeys.subtracting(previousKeys)
            let articlesToAdd = try managedObjectContext?.fetchArticlesWithInMemoryURLKeys(Array(articleKeysToAdd)) ?? []
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
