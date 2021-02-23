import Foundation
import CoreData

public class ReadingListEntry: NSManagedObject {
    public var inMemoryKey: WMFInMemoryURLKey? {
        guard let key = articleKey else {
            return nil
        }
        return WMFInMemoryURLKey(databaseKey: key, languageVariantCode: variant)
    }
    
    public var APIError: APIReadingListError? {
        guard let errorCode = errorCode else {
            return nil
        }
        return APIReadingListError(rawValue: errorCode)
    }
}
