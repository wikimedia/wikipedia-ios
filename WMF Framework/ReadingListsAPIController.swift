import Foundation

public enum APIReadingListError: String, Error, Equatable {
    case generic = "readinglists-client-error-generic"
    case notSetup = "readinglists-db-error-not-set-up"
    case listLimit = "readinglists-db-error-list-limit"
    case entryLimit = "readinglists-db-error-entry-limit"
    case duplicateEntry = "readinglists-db-error-duplicate-page"
}

struct APIReadingLists: Codable {
    let lists: [APIReadingList]
    let next: String?
}

struct APIReadingList: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case created
        case updated
        case deleted
        case isDefault = "default"
    }
    
    let id: Int64
    let name: String
    let description: String
    let created: String
    let updated: String
    let deleted: Bool?
    let isDefault: Bool
}

struct APIReadingListEntries: Codable {
    let entries: [APIReadingListEntry]
    let next: String?
}

struct APIReadingListEntry: Codable {
    let id: Int64
    let project: String
    let title: String
    let created: String
    let updated: String
    let listId: Int64?
    let deleted: Bool?
}

struct APIReadingListChanges: Codable {
    let lists: [APIReadingList]?
    let entries: [APIReadingListEntry]?
    let next: String?
    }

struct APIReadingListErrorResponse: Codable {
    let type: String?
    let title: String
    let method: String?
    let detail: String?
}

extension APIReadingListEntry {
    var articleURL: URL? {
        guard let site = URL(string: project) else {
            return nil
        }
        return site.wmf_URL(withTitle: title)
    }
    
    var articleKey: String? {
        return articleURL?.wmf_articleDatabaseKey
    }
}

class ReadingListsAPIController: NSObject {
    fileprivate let session = Session.shared
    fileprivate lazy var tokenFetcher: WMFAuthTokenFetcher = {
        return WMFAuthTokenFetcher()
    }()
    fileprivate let basePath = "/api/rest_v1/data/lists/"
    fileprivate let host = "en.wikipedia.org"
    fileprivate let scheme = "https"
    
    fileprivate func requestWithCSRF(path: String, method: Session.Request.Method, bodyParameters: [String: Any]? = nil, completion: @escaping ([String: Any]?, URLResponse?, Error?) -> Void) {
        var components = URLComponents()
        components.host = host
        components.scheme = scheme
        guard
            let siteURL = components.url
            else {
                completion(nil, nil, APIReadingListError.generic)
                return
        }
        
        let fullPath = basePath.appending(path)
        tokenFetcher.fetchToken(ofType: .csrf, siteURL: siteURL, success: { (token) in
            self.session.jsonDictionaryTask(host: self.host, method: method, path: fullPath, queryParameters: ["csrf_token": token.token], bodyParameters: bodyParameters) { (result , response, error) in
                if let apiErrorType = result?["title"] as? String, let apiError = APIReadingListError(rawValue: apiErrorType) {
                    completion(result, nil, apiError)
                } else {
                    completion(result, response, error)
                }
                }?.resume()
        }) { (failure) in
            completion(nil, nil, failure)
        }
    }
    
    fileprivate func post(path: String, bodyParameters: [String: Any]? = nil, completion: @escaping ([String: Any]?, URLResponse?, Error?) -> Void) {
        requestWithCSRF(path: path, method: .post, bodyParameters: bodyParameters, completion: completion)
    }
    
    fileprivate func get<T>(path: String, queryParameters: [String: Any]? = nil, completionHandler: @escaping (T?, URLResponse?, Error?) -> Swift.Void) where T : Codable {
        let fullPath = basePath.appending(path)
        session.jsonCodableTask(host: host, method: .get, path: fullPath, queryParameters: queryParameters, completionHandler: { (result: T?, errorResult: APIReadingListErrorResponse?, response, error) in
            if let errorResult = errorResult, let error = APIReadingListError(rawValue: errorResult.title) {
                completionHandler(nil, nil, error)
            } else {
                completionHandler(result, response, error)
            }
        })?.resume()
    }
    
    fileprivate func delete(path: String, completion: @escaping ([String: Any]?, URLResponse?, Error?) -> Void) {
        requestWithCSRF(path: path, method: .delete, completion: completion)
    }
    
    fileprivate func put(path: String, bodyParameters: [String: Any]? = nil, completion: @escaping ([String: Any]?, URLResponse?, Error?) -> Void) {
        requestWithCSRF(path: path, method: .put, bodyParameters: bodyParameters, completion: completion)
    }
    
    @objc func setupReadingLists(completion: @escaping (Error?) -> Void) {
        post(path: "setup") { (result, response, error) in
            completion(error)
        }
    }
    
    @objc func teardownReadingLists(completion: @escaping (Error?) -> Void) {
        post(path: "teardown") { (result, response, error) in
            completion(error)
        }
    }
    
    /**
     Creates a new reading list using the reading list API
     - parameters:
        - lists: The names and descriptions for the new lists
        - completion: Called after the request completes
        - listIDs: The list IDs if they were created
        - error: Any error preventing list creation
    */
    func createLists(_ lists: [(name: String, description: String?)], completion: @escaping (_ listIDs: [Int64]?,_ error: Error?) -> Swift.Void ) {
        guard lists.count > 0 else {
            completion([], nil)
            return
        }
        let bodyParams = ["batch": lists.map { ["name": $0.name.precomposedStringWithCanonicalMapping, "description": $0.description ?? ""] } ]
        post(path: "batch/", bodyParameters: bodyParams) { (result, response, error) in
            guard let result = result, let batch = result["batch"] as? [[String: Any]] else {
                completion(nil, ReadingListError.unableToCreateList)
                return
            }
            completion(batch.flatMap { $0["id"] as? Int64 }, nil)
        }
    }
    
    
    /**
     Adds a new entry to a reading list using the reading list API
     - parameters:
        - listID: The list ID of the list that is getting an entry
        - entries: The project and titles for each new entry
        - completion: Called after the request completes
        - entryIDs: The entry IDs if they were created
        - error: Any error preventing entry creation
     */
    func addEntriesToList(withListID listID: Int64, entries: [(project: String, title: String)], completion: @escaping (_ entryIDs: [Int64]?,_ error: Error?) -> Swift.Void ) {
        guard entries.count > 0 else {
            completion([], nil)
            return
        }
        let bodyParams = ["batch": entries.map { ["project": $0.project.precomposedStringWithCanonicalMapping, "title": $0.title.precomposedStringWithCanonicalMapping] } ]
        post(path: "\(listID)/entries/batch", bodyParameters: bodyParams) { (result, response, error) in
            if let apiError = error as? APIReadingListError {
                switch apiError {
//                case .duplicateEntry:
//                    // TODO: Remove when error response returns ID
//                    self.getAllEntriesForReadingListWithID(readingListID: listID, completion: { (entries, error) in
//                        guard let entry = entries.first(where: { (entry) -> Bool in entry.title == title && entry.project == project }) else {
//                            completion(nil, error ?? ReadingListError.unableToAddEntry)
//                            return
//                        }
//                        completion(entry.id, nil)
//                    })
                default:
                    completion(nil, apiError)
                }
                return
            } else if let error = error {
                completion(nil, error)
                return
            }

            guard let result = result else {
                completion(nil, error ?? ReadingListError.unableToAddEntry)
                return
            }
            
            guard let batch = result["batch"] as? [[String: Any]] else {
                completion(nil, ReadingListError.unableToAddEntry)
                return
            }
            
            
            completion(batch.flatMap { $0["id"] as? Int64 }, nil)
        }
    }
    
    
    /**
     Remove entry from reading list using the reading list API
     - parameters:
         - listID: The list ID of the list that will have an entry removed
         - entryID: The entry ID to remove from the list
         - completion: Called after the request completes
         - error: Any error preventing entry deletion
     */
    func removeEntry(withEntryID entryID: Int64, fromListWithListID listID: Int64, completion: @escaping (_ error: Error?) -> Swift.Void ) {

        delete(path: "\(listID)/entries/\(entryID)") { (result, response, error) in
            guard error == nil else {
                completion(error ?? ReadingListError.unableToRemoveEntry)
                return
            }
            completion(nil)
        }
    }
    
    /**
     Deletes a reading list using the reading list API
     - parameters:
         - listID: The list ID of the list to delete
         - completion: Called after the request completes
         - error: Any error preventing list deletion
     */
    func deleteList(withListID listID: Int64, completion: @escaping (_ error: Error?) -> Swift.Void ) {
        delete(path: "\(listID)") { (result, response, error) in
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(error ?? ReadingListError.unableToDeleteList)
                return
            }
            completion(nil)
        }
    }
    
    /**
     Updates a reading list using the reading list API
     - parameters:
        - listID: The list ID of the list to update
        - name: The name of the list
        - description: The description of the list
        - completion: Called after the request completes
        - error: Any error preventing list update
     */
    func updateList(withListID listID: Int64, name: String, description: String?, completion: @escaping (_ error: Error?) -> Swift.Void ) {
        put(path: "\(listID)", bodyParameters: ["name": name, "description": description ?? ""]) { (result, response, error) in
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(error ?? ReadingListError.unableToDeleteList)
                return
            }
            completion(nil)
        }
    }
    
    
    /**
     Gets updated lists and entries list API
     - parameters:
        - since: The continuation token. Lets the server know the current state of the device. Currently an ISO 8601 date string
        - next: Optional continuation token
        - lists: Lists to append to the results
        - entries: Entries to append to the results
        - lists: All updated lists
        - entries: All updated entries
        - error: Any error preventing list update
     */
    func updatedListsAndEntries(since: String, next: String? = nil, lists: [APIReadingList] = [], entries: [APIReadingListEntry] = [], completion: @escaping (_ lists: [APIReadingList], _ entries: [APIReadingListEntry], _ error: Error?) -> Swift.Void ) {
        var queryParameters: [String: Any]? = nil
        if let next = next {
            queryParameters = ["next": next]
        }
        get(path: "changes/since/\(since)", queryParameters: queryParameters) { (result: APIReadingListChanges?, response, error) in
            guard let result = result, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion([], [], error ?? ReadingListError.generic)
                return
            }
            var combinedLists = lists
            if let lists = result.lists {
                combinedLists.append(contentsOf: lists)
            }
            var combinedEntries = entries
            if let entries = result.entries {
                combinedEntries.append(contentsOf: entries)
            }
            if let next = result.next {
                self.updatedListsAndEntries(since: since, next: next, lists: combinedLists, entries: combinedEntries, completion: completion)
            } else {
                completion(combinedLists, combinedEntries, nil)
            }
        }
    }
    
    func getAllReadingLists(next: String? = nil, lists: [APIReadingList] = [], completion: @escaping ([APIReadingList], Error?) -> Swift.Void ) {
        var queryParameters: [String: Any]? = nil
        if let next = next {
            queryParameters = ["next": next]
        }
        get(path: "", queryParameters: queryParameters) { (apiListsResponse: APIReadingLists?, response, error) in
            guard let apiListsResponse = apiListsResponse else {
                completion([], error)
                return
            }
            var combinedList = lists
            combinedList.append(contentsOf: apiListsResponse.lists)
            if let next = apiListsResponse.next {
                self.getAllReadingLists(next: next, lists: combinedList, completion: completion)
            } else {
                completion(combinedList, nil)
            }
        }
    }
    
    func getAllEntriesForReadingListWithID(next: String? = nil, entries: [APIReadingListEntry] = [], readingListID: Int64, completion: @escaping ([APIReadingListEntry], Error?) -> Swift.Void ) {
        var queryParameters: [String: Any]? = nil
        if let next = next {
            queryParameters = ["next": next]
        }
        get(path: "\(readingListID)/entries/", queryParameters: queryParameters) { (apiEntriesResponse: APIReadingListEntries?, response, error) in
            guard let apiEntriesResponse = apiEntriesResponse else {
                completion([], error)
                return
            }
            var combinedList = entries
            combinedList.append(contentsOf: apiEntriesResponse.entries)
            if let next = apiEntriesResponse.next {
                self.getAllEntriesForReadingListWithID(next: next, entries: combinedList, readingListID: readingListID, completion: completion)
            } else {
                completion(combinedList, nil)
            }
        }
    }
}
