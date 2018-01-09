import Foundation

struct APIReadingLists: Codable {
    let lists: [APIReadingList]
    let next: String?
}

struct APIReadingList: Codable {
    let id: Int64
    let name: String
    let description: String
    let created: String
    let updated: String
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

class ReadingListsAPIController: NSObject {
    fileprivate let session = Session.shared
    fileprivate lazy var tokenFetcher: WMFAuthTokenFetcher = {
        return WMFAuthTokenFetcher()
    }()
    fileprivate let basePath = "/api/rest_v1/data/lists/"
    fileprivate let host = "en.wikipedia.org"
    fileprivate let scheme = "https"
    
    fileprivate func post(path: String, bodyParameters: [String: Any]? = nil, completion: @escaping ([String: Any]?, URLResponse?, Error?) -> Void) {
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
            self.session.jsonDictionaryTask(host: self.host, method: .post, path: fullPath, queryParameters: ["csrf_token": token.token], bodyParameters: bodyParameters) { (result , response, error) in
                completion(result, response, error)
                }?.resume()
        }) { (failure) in
            completion(nil, nil, failure)
        }
    }
    
    fileprivate func get<T>(path: String, queryParameters: [String: Any]? = nil, completionHandler: @escaping (T?, URLResponse?, Error?) -> Swift.Void) where T : Codable  {
        let fullPath = basePath.appending(path)
        session.jsonCodableTask(host: host, method: .get, path: fullPath, queryParameters: queryParameters, completionHandler: completionHandler)?.resume()
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
        let bodyParams = ["name": name, "description": description]
        post(path: "", bodyParameters: bodyParams) { (result, response, error) in
            guard let result = result, let id = result["id"] as? Int64 else {
                completion(nil, error ?? ReadingListError.unableToCreateList)
                return
            }
            completion(id, nil)
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
        get(path: "\(readingListID)/entries", queryParameters: queryParameters) { (apiEntriesResponse: APIReadingListEntries?, response, error) in
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
