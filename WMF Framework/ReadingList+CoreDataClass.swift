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
    
    public var isDefaultList: Bool {
        return self.isDefault?.boolValue ?? false
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
        guard let entries = entries else {
            countOfEntries = 0
            articles = []
            return
        }
        let validEntries = entries.filter { !$0.isDeletedLocally }
        let validArticleKeys = validEntries.flatMap { $0.articleKey }
        if validArticleKeys.count > 0 {
            do {
                let validArticles = try managedObjectContext?.wmf_fetch(objectsForEntityName: "WMFArticle", withValues: validArticleKeys, forKey: "key") as? [WMFArticle] ?? []
                countOfEntries = Int64(validEntries.count)
                articles = Set<WMFArticle>(validArticles)
            } catch let error {
                DDLogError("error updating list: \(error)")
            }
        } else {
            countOfEntries = 0
            articles = []
        }
    }
}
