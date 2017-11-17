public extension NSManagedObjectContext {
    func wmf_create<T: NSManagedObject>(entityNamed entityName: String, withValue value: Any, forKey key: String) -> T? {
        let object = NSEntityDescription.insertNewObject(forEntityName: entityName, into: self) as? T
        object?.setValue(value, forKey: key)
        return object
    }
    
    func wmf_fetchOrCreate<T: NSManagedObject>(objectForEntityName entityName: String, withValue value: Any, forKey key: String) -> T? {
        let fetchRequest = NSFetchRequest<T>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "%@ == %@", argumentArray: [key, value])
        fetchRequest.fetchLimit = 1
        var results: [T] = []
        do {
            results = try fetch(fetchRequest)
        } catch let error {
            DDLogError("Error fetching: \(error)")
        }
        
        let result = results.first ?? wmf_create(entityNamed: entityName, withValue: value, forKey: key)
        return result
    }
    
    func wmf_fetchOrCreate<T: NSManagedObject, V: Hashable>(objectsForEntityName entityName: String, withValues values: [V], forKey key: String) -> [T]? {
        let fetchRequest = NSFetchRequest<T>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "%@ IN %@", argumentArray: [key, values])
        fetchRequest.fetchLimit = values.count
        var results: [T] = []
        do {
            results = try fetch(fetchRequest)
        } catch let error {
            DDLogError("Error fetching: \(error)")
        }
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
}

