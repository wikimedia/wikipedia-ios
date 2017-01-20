import Foundation

@objc class ArticleLocationController: NSObject {

    func migrate(managedObjectContext: NSManagedObjectContext, completion: @escaping (Error?) -> Void) {

        do {
            let migrationKey = "WMFDidCompleteQuadKeyMigration"
            let keyValueRequest = WMFKeyValue.fetchRequest()
            keyValueRequest.predicate = NSPredicate(format: "key == %@", migrationKey)
            
            let keyValueResult = try managedObjectContext.fetch(keyValueRequest)
            if keyValueResult.count > 0 && (keyValueResult[0].value != nil) {
                completion(nil)
                return
            }
            
            let request = WMFArticle.fetchRequest()
            request.predicate = NSPredicate(format: "latitude != NULL && latitude != 0 && longitude != NULL && longitude != 0 && signedQuadKey == NULL")
            request.fetchLimit = 500
            
            let results = try managedObjectContext.fetch(request)
            
            if results.count == 0 {
                let kv = NSEntityDescription.insertNewObject(forEntityName: "WMFKeyValue", into: managedObjectContext) as! WMFKeyValue
                kv.key = migrationKey
                kv.value = NSNumber(value: true)
                try managedObjectContext.save()
                completion(nil)
                return
            }
            
            for result in results {
                let lat = QuadKeyDegrees(result.latitude)
                let lon = QuadKeyDegrees(result.longitude)
                if lat != 0 && lon != 0 {
                    let quadKey = QuadKey(latitude: lat, longitude: lon)
                    let signedQuadKey = Int64(quadKey: quadKey)
                    result.signedQuadKey = NSNumber(value: signedQuadKey)
                }
            }
            
            try managedObjectContext.save()
        } catch let error {
            completion(error)
            return
        }
    
        dispatchOnMainQueue { 
            self.migrate(managedObjectContext: managedObjectContext, completion: completion)
        }
    }
}
