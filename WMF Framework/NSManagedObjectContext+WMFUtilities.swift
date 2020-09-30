import CocoaLumberjackSwift

public extension NSManagedObjectContext {
    func wmf_create<T: NSManagedObject>(entityNamed entityName: String, withValue value: Any, forKey key: String) -> T? {
        let object = NSEntityDescription.insertNewObject(forEntityName: entityName, into: self) as? T
        object?.setValue(value, forKey: key)
        return object
    }
    
    func wmf_create<T: NSManagedObject>(entityNamed entityName: String, withKeysAndValues dictionary: [String: Any?]) -> T? {
        let object = NSEntityDescription.insertNewObject(forEntityName: entityName, into: self) as? T
        for (key, value) in dictionary {
            object?.setValue(value, forKey: key)
        }
        return object
    }
    
    
    func wmf_fetch<T: NSManagedObject>(objectForEntityName entityName: String, withValue value: Any, forKey key: String) -> T? {
        let fetchRequest = NSFetchRequest<T>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "\(key) == %@", argumentArray: [value])
        fetchRequest.fetchLimit = 1
        var results: [T] = []
        do {
            results = try fetch(fetchRequest)
        } catch let error {
            DDLogError("Error fetching: \(error)")
        }
        
        return results.first
    }
    
    func wmf_fetchOrCreate<T: NSManagedObject>(objectForEntityName entityName: String, withValue value: Any, forKey key: String) -> T? {
        return wmf_fetch(objectForEntityName: entityName, withValue: value, forKey: key) ?? wmf_create(entityNamed: entityName, withValue: value, forKey: key)
    }
    
    func wmf_fetch<T: NSManagedObject, V: Hashable>(objectsForEntityName entityName: String, withValues values: [V], forKey key: String) throws -> [T]? {
        let fetchRequest = NSFetchRequest<T>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "\(key) IN %@", argumentArray: [values])
        fetchRequest.fetchLimit = values.count
        return try fetch(fetchRequest)
    }
    
    func wmf_fetchOrCreate<T: NSManagedObject, V: Hashable>(objectsForEntityName entityName: String, withValues values: [V], forKey key: String) throws -> [T]? {
        var results = try wmf_fetch(objectsForEntityName: entityName, withValues: values, forKey: key) as? [T] ?? []
        var missingValues = Set(values)
        for result in results {
            guard let value = result.value(forKey: key) as? V else {
                continue
            }
            missingValues.remove(value)
        }
        for value in missingValues {
            guard let object = wmf_create(entityNamed: entityName, withValue: value, forKey: key) as? T else {
                continue
            }
            results.append(object)
        }
        return results
    }
    
    func wmf_batchProcessObjects<T: NSManagedObject>(matchingPredicate: NSPredicate? = nil, resetAfterSave: Bool = false, handler: (T) throws -> Void) throws {
        let fetchRequest = T.fetchRequest()
        let batchSize = 500
        fetchRequest.predicate = matchingPredicate
        fetchRequest.fetchBatchSize = batchSize
        let results = try fetch(fetchRequest)
        
        for (index, result) in results.enumerated() {
            if let result = result as? T {
                try handler(result)
            }
            let count = index + 1
            if count % batchSize == 0 || count == results.count {
                if hasChanges {
                    try save()
                }
                if resetAfterSave {
                    reset()
                }
            }
        }
    }
    
    func wmf_batchProcess<T: NSManagedObject>(matchingPredicate: NSPredicate? = nil, resetAfterSave: Bool = false, handler: ([T]) throws -> Void) throws {
        let fetchRequest = T.fetchRequest()
        let batchSize = 500
        fetchRequest.predicate = matchingPredicate
        fetchRequest.fetchBatchSize = batchSize
        let results = try fetch(fetchRequest) as? [T] ?? []
        
        var start: Int = 0
        var end: Int = 0
        while start < results.count {
            end = min(start + batchSize, results.count)
            try handler(Array<T>(results[start..<end]))
            if hasChanges {
                try save()
            }
            if resetAfterSave {
                reset()
            }
            start = end
        }
    }
    
    func performWaitAndReturn<T>(_ block: () -> T?) -> T? {
        var result: T? = nil
        performAndWait {
            result = block()
        }
        return result
    }
}

