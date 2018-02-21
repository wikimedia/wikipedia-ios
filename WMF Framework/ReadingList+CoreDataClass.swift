import Foundation
import CoreData

public class ReadingList: NSManagedObject {
    
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
    
    public func updateCountOfEntries() {
        guard let entries = entries else {
            countOfEntries = 0
            return
        }
        countOfEntries = Int64(entries.filter({ (entry) -> Bool in
            return !entry.isDeletedLocally
        }).count)
    }
    
    public func updateArticlesAndEntries() {
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
            do {
                let articlesToAdd = try managedObjectContext?.wmf_fetch(objectsForEntityName: "WMFArticle", withValues: Array(articleKeysToAdd), forKey: "key") as? [WMFArticle] ?? []
                countOfEntries = Int64(validEntries.count)
                for article in articlesToAdd {
                    addToArticles(article)
                    article.readingListsDidChange()
                }
            } catch let error {
                DDLogError("error updating list: \(error)")
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
                guard article.imageURLString != nil else {
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
    }
}
