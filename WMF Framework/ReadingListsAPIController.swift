import Foundation

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
        case isDefault = "default"
    }
    
    let id: Int64
    let name: String
    let description: String
    let created: String
    let updated: String
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
}

extension APIReadingListEntry {
    var articleURL: URL? {
        guard let site = URL(string: project) else {
            return nil
        }
        return site.wmf_URL(withTitle: title)
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
                return
        }
        
        let fullPath = basePath.appending(path)
        tokenFetcher.fetchToken(ofType: .csrf, siteURL: siteURL, success: { (token) in
            self.session.jsonDictionaryTask(host: self.host, method: method, path: fullPath, queryParameters: ["csrf_token": token.token], bodyParameters: bodyParameters) { (result , response, error) in
                completion(result, response, error)
                }?.resume()
        }) { (failure) in
            completion(nil, nil, failure)
        }
    }
    
    fileprivate func post(path: String, bodyParameters: [String: Any]? = nil, completion: @escaping ([String: Any]?, URLResponse?, Error?) -> Void) {
        requestWithCSRF(path: path, method: .post, bodyParameters: bodyParameters, completion: completion)
    }
    
    fileprivate func get<T>(path: String, queryParameters: [String: Any]? = nil, completionHandler: @escaping (T?, URLResponse?, Error?) -> Swift.Void) where T : Codable  {
        let fullPath = basePath.appending(path)
        session.jsonCodableTask(host: host, method: .get, path: fullPath, queryParameters: queryParameters, completionHandler: completionHandler)?.resume()
    }
    
    fileprivate func delete(path: String, completion: @escaping ([String: Any]?, URLResponse?, Error?) -> Void) {
        requestWithCSRF(path: path, method: .delete, completion: completion)
    }
    
    fileprivate func put(path: String, bodyParameters: [String: Any]? = nil, completion: @escaping ([String: Any]?, URLResponse?, Error?) -> Void) {
        requestWithCSRF(path: path, method: .put, bodyParameters: bodyParameters, completion: completion)
    }
    
    @objc func setupReadingLists() {
        post(path: "setup") { (result, response, error) in
            
        }
    }
    
    @objc func teardownReadingLists() {
        post(path: "teardown") { (result, response, error) in
            
        }
    }
    
    /**
     Creates a new reading list using the reading list API
     - parameters:
        - name: The name for the new list
        - description: The description for the new list
        - completion: Called after the request completes
        - listID: The list ID if it was created
        - error: Any error preventing list creation
    */
    func createList(name: String, description: String, completion: @escaping (_ listID: Int64?,_ error: Error?) -> Swift.Void ) {
        let bodyParams = ["name": name.precomposedStringWithCanonicalMapping, "description": description]
        post(path: "", bodyParameters: bodyParams) { (result, response, error) in
            guard let result = result, let id = result["id"] as? Int64 else {
                completion(nil, error ?? ReadingListError.unableToCreateList)
                return
            }
            completion(id, nil)
        }
    }
    
    
    /**
     Adds a new entry to a reading list using the reading list API
     - parameters:
        - listID: The list ID of the list that is getting an entry
        - project: The project name of the new entry
        - title: The title of the new entry
        - completion: Called after the request completes
        - entryID: The entry ID if it was created
        - error: Any error preventing entry creation
     */
    func addEntryToList(withListID listID: Int64, project: String, title: String, completion: @escaping (_ entryID: Int64?,_ error: Error?) -> Swift.Void ) {
        let title = title.precomposedStringWithCanonicalMapping
        let project = project.precomposedStringWithCanonicalMapping
        let bodyParams = ["project": project, "title": title]
        post(path: "\(listID)/entries/", bodyParameters: bodyParams) { (result, response, error) in
            guard let result = result else {
                completion(nil, error ?? ReadingListError.unableToAddEntry)
                return
            }
            guard let id = result["id"] as? Int64 else {
                if let errorType = result["title"] as? String, errorType == "readinglists-db-error-duplicate-page" {
                    // TODO: Remove when error response returns ID
                    self.getAllEntriesForReadingListWithID(readingListID: listID, completion: { (entries, error) in
                        guard let entry = entries.first(where: { (entry) -> Bool in entry.title == title && entry.project == project }) else {
                            completion(nil, error ?? ReadingListError.unableToAddEntry)
                            return
                        }
                        completion(entry.id, nil)
                    })
                } else {
                    completion(nil, error ?? ReadingListError.unableToAddEntry)
                }
                return
            }
            completion(id, nil)
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
    func updateList(withListID listID: Int64, name: String, description: String, completion: @escaping (_ error: Error?) -> Swift.Void ) {
        put(path: "\(listID)", bodyParameters: ["name": name, "description": description]) { (result, response, error) in
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(error ?? ReadingListError.unableToDeleteList)
                return
            }
            completion(nil)
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
