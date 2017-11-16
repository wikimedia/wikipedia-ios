import Foundation


public enum ReadingListError: Error, Equatable {
    case listExistsWithTheSameName(name: String)
    case unableToCreateList
    
    public var localizedDescription: String {
        switch self {
        case .listExistsWithTheSameName(let name):
            let format = WMFLocalizedString("reading-list-exists-with-same-name", value: "A reading list already exists with the name ‟%1$@”", comment: "Informs the user that a reading list exists with the same name.")
            return String.localizedStringWithFormat(format, name)
        case .unableToCreateList:
            return WMFLocalizedString("reading-list-unable-to-create", value: "An unexpected error occured while creating your reading list. Please try again later.", comment: "Informs the user that an error occurred while creating their reading list.")
        }
    }
    
    public static func ==(lhs: ReadingListError, rhs: ReadingListError) -> Bool {
        return lhs.localizedDescription == rhs.localizedDescription //shrug
    }
}


@objc(WMFReadingListsController)
public class ReadingListsController: NSObject {
    fileprivate weak var dataStore: MWKDataStore!
    fileprivate let session = Session.shared
    fileprivate lazy var tokenFetcher: WMFAuthTokenFetcher = {
        return WMFAuthTokenFetcher()
    }()
    fileprivate let basePath = "/api/rest_v1/data/lists/"
    fileprivate let host = "readinglists.wmflabs.org"
    fileprivate let scheme = "https"

    @objc init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
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
    
    // User-facing actions. Everything is performed on the main context
    
    public func createReadingList(named name: String, with articles: [WMFArticle] = []) throws -> ReadingList {
        assert(Thread.isMainThread)
        let moc = dataStore.viewContext
        let existingListRequest: NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
        existingListRequest.predicate = NSPredicate(format: "name MATCHES[c] %@", name)
        existingListRequest.fetchLimit = 1
        let result = try moc.fetch(existingListRequest).first
        guard result == nil else {
            throw ReadingListError.listExistsWithTheSameName(name: name)
        }
        guard let list = moc.wmf_create(entityNamed: "ReadingList", withValue: name, forKey: "name") as? ReadingList else {
            throw ReadingListError.unableToCreateList
        }
        return list
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

