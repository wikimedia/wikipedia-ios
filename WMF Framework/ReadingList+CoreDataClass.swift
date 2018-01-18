import Foundation
import CoreData

public class ReadingList: NSManagedObject {
    
    open var articleKeys: [String] {
        let entries = self.entries ?? []
        let existingKeys = entries.flatMap { (entry) -> String? in
            guard let entry = entry as? ReadingListEntry, entry.isDeletedLocally == false else {
                return nil
            }
            return entry.article?.key
        }
        return existingKeys
    }
    
    public var isDefaultList: Bool {
        return self.isDefault?.boolValue ?? false
    }
}
