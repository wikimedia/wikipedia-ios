import Foundation
import CoreData

public class ReadingListEntry: NSManagedObject {
    var articleURL: URL? {
        guard let key = articleKey else {
            return nil
        }
        return URL(string: key)
    }
}
