import Foundation
import CoreData

public class ReadingList: NSManagedObject {
    
    open var articleKeys: [String] {
        let entries = self.entries ?? []
        let existingKeys = entries.flatMap { (entry) -> String? in
            guard entry.isDeletedLocally == false else {
                return nil
            }
            return entry.article?.key
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
}
