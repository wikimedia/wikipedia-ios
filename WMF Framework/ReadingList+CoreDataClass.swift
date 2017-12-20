import Foundation
import CoreData

public class ReadingList: NSManagedObject {
    
    open var articleKeys: [String] {
        let entries = self.entries ?? []
        let existingKeys = entries.flatMap { (entry) -> String? in
            guard let entry = entry as? ReadingListEntry else {
                return nil
            }
            return entry.article?.key
        }
        return existingKeys
    }
    
}
