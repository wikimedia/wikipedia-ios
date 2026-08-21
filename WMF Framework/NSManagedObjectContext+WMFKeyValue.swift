import CoreData
import CocoaLumberjackSwift

/// Key-value storage on a managed object context, backed by the WMFKeyValue entity.
/// Converted from Objective-C so managed-object access here is visible to the Swift
/// strict-concurrency checker. All methods must be called on the context's queue
/// (inside perform/performAndWait or on the context's thread), same as before.
extension NSManagedObjectContext {

    private func wmf_keyValues(forKey key: String, fetchLimit: Int) -> [WMFKeyValue] {
        let request = NSFetchRequest<WMFKeyValue>(entityName: "WMFKeyValue")
        request.predicate = NSPredicate(format: "key == %@", key)
        if fetchLimit > 0 {
            request.fetchLimit = fetchLimit
        }
        do {
            return try fetch(request)
        } catch {
            DDLogError("Error fetching key value: \(error)")
            return []
        }
    }

    @objc(wmf_keyValueForKey:)
    public func wmf_keyValue(forKey key: String) -> WMFKeyValue? {
        return wmf_keyValues(forKey: key, fetchLimit: 1).first
    }

    private func wmf_value<T>(of type: T.Type, forKey key: String) -> T? {
        return wmf_keyValue(forKey: key)?.value as? T
    }

    @objc(wmf_numberValueForKey:)
    public func wmf_numberValue(forKey key: String) -> NSNumber? {
        return wmf_value(of: NSNumber.self, forKey: key)
    }

    @objc(wmf_stringValueForKey:)
    public func wmf_stringValue(forKey key: String) -> String? {
        return wmf_value(of: NSString.self, forKey: key) as String?
    }

    @objc(wmf_arrayValueForKey:)
    public func wmf_arrayValue(forKey key: String) -> NSArray? {
        return wmf_value(of: NSArray.self, forKey: key)
    }

    @discardableResult
    @objc(wmf_setValue:forKey:)
    public func wmf_setValue(_ value: NSCoding?, forKey key: String) -> WMFKeyValue {
        let results = wmf_keyValues(forKey: key, fetchLimit: 0)
        if results.count > 1 {
            // failsafe to delete extra key value objects
            for extraValue in results.dropFirst() {
                delete(extraValue)
            }
        }
        let keyValue: WMFKeyValue
        if let existing = results.first {
            keyValue = existing
        } else {
            keyValue = NSEntityDescription.insertNewObject(forEntityName: "WMFKeyValue", into: self) as! WMFKeyValue
            keyValue.key = key
        }
        keyValue.value = value
        return keyValue
    }
}
