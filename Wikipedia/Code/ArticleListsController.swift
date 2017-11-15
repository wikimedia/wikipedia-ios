import Foundation

@objc(WMFArticleListsController)
class ArticleListsController: NSObject {
    fileprivate let managedObjectContext: NSManagedObjectContext
    fileprivate let session = Session.shared
    fileprivate let tokenFetcher = WMFAuthTokenFetcher()
    fileprivate let basePath = "/api/rest_v1/data/lists/"
    fileprivate let host = "readinglists.wmflabs.org"
    fileprivate let scheme = "https"

    @objc init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        super.init()
    }


    fileprivate func post(path: String, completion: @escaping (Error?) -> Void) {
        var components = URLComponents()
        components.host = host
        components.scheme = scheme
        guard
            let siteURL = components.url
        else {
            return
        }

        let fullPath = basePath.appending(path)
        tokenFetcher.fetchToken(ofType: .csrf, siteURL: siteURL, success: { (token) in
            self.session.jsonDictionaryTask(host: self.host, method: .post, path: fullPath, queryParameters: ["csrf_token": token.token]) { (result , response, error) in
                completion(error)
                }?.resume()
        }) { (failure) in
            completion(failure)
        }
    }

    fileprivate func get(path: String, completion: (Error?)) {
        guard
            let siteURL = MWKLanguageLinkController.sharedInstance().appLanguage?.siteURL(),
            let host = siteURL.host
            else {
                return
        }

        let fullPath = basePath.appending(path)
        session.jsonDictionaryTask(host: host, method: .post, path: fullPath) { (result , response, error) in
            }?.resume()
    }


    @objc func setup() {
        post(path: "setup") { (error) in

        }
    }

    @objc func teardown() {
        post(path: "teardown") { (error) in

        }
    }

}


extension NSManagedObjectContext {
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

