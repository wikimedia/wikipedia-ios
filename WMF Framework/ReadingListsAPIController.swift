import Foundation
import CocoaLumberjackSwift

internal let APIReadingListUpdateLimitForFullSyncFallback = 1000 // if we receive over this # of updated items, fall back to full sync

public enum APIReadingListError: String, Error, Equatable {
    case generic = "readinglists-client-error-generic"
    case notLoggedIn = "notloggedin"
    case badtoken = "badtoken"
    case notSetup = "readinglists-db-error-not-set-up"
    case alreadySetUp = "readinglists-db-error-already-set-up"
    case listLimit = "readinglists-db-error-list-limit"
    case entryLimit = "readinglists-db-error-entry-limit"
    case duplicateEntry = "readinglists-db-error-duplicate-page"
    case needsFullSync = "readinglists-client-error-needs-full-sync"
    case listDeleted = "readinglists-db-error-list-deleted"
    case listEntryDeleted = "readinglists-db-error-list-entry-deleted"
    case defaultListCannotBeUpdated = "readinglists-db-error-cannot-update-default-list"
    case defaultListCannotBeDeleted = "readinglists-db-error-cannot-delete-default-list"
    case noSuchProject = "readinglists-db-error-no-such-project"
    case noSuchListEntry = "readinglists-db-error-no-such-list-entry"
    case noSuchList = "readinglists-db-error-no-such-list"
    case duplicateList = "readinglists-db-error-duplicate-list"
    
    public var localizedDescription: String {
        switch self {
        case .listLimit:
            return WMFLocalizedString("reading-list-api-error-list-limit", value: "This list is not synced because you have reached the limit for the number of synced lists.", comment: "You have too many lists.")
        case .entryLimit:
            return WMFLocalizedString("reading-list-api-error-entry-limit", value: "This entry is not synced because you have reached the limit for the number of entries in this list.", comment: "You have too many entries in this list.")
        default:
            return WMFLocalizedString("reading-list-api-error-generic", value: "An unexpected error occurred while syncing your reading lists.", comment: "An unexpected error occurred while syncing your reading lists.")
        }
    }
}

struct APIReadingLists: Codable {
    let lists: [APIReadingList]
    let next: String?
    let since: String?
    enum CodingKeys: String, CodingKey {
        case lists
        case next
        case since = "continue-from"
    }
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
    let since: String?
    enum CodingKeys: String, CodingKey {
        case lists
        case entries
        case next
        case since = "continue-from"
    }
}

struct APIReadingListErrorResponse: Codable {
    let type: String?
    let title: String
    let method: String?
    let detail: String?
}

enum APIReadingListRequestType: String {
    case setup, teardown
}

/* Note that because the reading list API does not support language variants,
 * the articleURL will always have a nil language variant.
 *
 * The RemoteReadingListArticleKey type is a type alias for String.
 * Since ReadingListsSyncOperation handles remote entries that don't have a variant,
 * and local entries that do have a variant, this type makes it more clear when
 * a non-variant aware key is being used.
 *
 * Also, if the remote API adds variant support, it should be straightforward to
 * update the type alias from String to WMFInMemoryURLKey.
*/
typealias RemoteReadingListArticleKey = String
extension APIReadingListEntry {
    var articleURL: URL? {
        guard let site = URL(string: project) else {
            return nil
        }
        return site.wmf_URL(withTitle: title)
    }
    
    var articleKey: RemoteReadingListArticleKey? {
        return articleURL?.wmf_databaseKey
    }
}

class ReadingListsAPIController: Fetcher {
    private let api = Configuration.current.pageContentServiceAPIURLComponentsBuilderFactory("en.wikipedia.org")
    private let basePathComponents = ["data", "lists"]
    public var lastRequestType: APIReadingListRequestType?

    fileprivate func get<T: Codable>(path: [String], queryParameters: [String: Any]? = nil, completionHandler: @escaping (T?, URLResponse?, Error?) -> Swift.Void) {
        let key = UUID().uuidString
        let components = api.components(byAppending: basePathComponents + path, queryParameters: queryParameters)
        guard
            let task = session.jsonDecodableTaskWithDecodableError(with: components.url, method: .get, completionHandler: { (result: T?, errorResult: APIReadingListErrorResponse?, response, error) in
            if let errorResult = errorResult, let error = APIReadingListError(rawValue: errorResult.title) {
                completionHandler(nil, nil, error)
            } else {
                completionHandler(result, response, error)
            }
            self.untrack(taskFor: key)
        }) else {
            return
        }
        track(task: task, for: key)
        task.resume()
    }
    
    fileprivate func requestWithCSRF(path: [String], method: Session.Request.Method, bodyParameters: [String: Any]? = nil, completion: @escaping ([String: Any]?, URLResponse?, Error?) -> Void) {
        let components = api.components(byAppending: basePathComponents + path)
        requestMediaWikiAPIAuthToken(for: components.url, type: .csrf) { (result) in
            switch result {
            case .failure(let error):
                completion(nil, nil, error)
            case .success(let token):
                let tokenQueryParameters = ["csrf_token": token.value]
                var componentsWithToken = components
                componentsWithToken.appendQueryParametersToPercentEncodedQuery(tokenQueryParameters)
                let identifier =  UUID().uuidString
                let task = self.session.jsonDictionaryTask(with: componentsWithToken.url, method: method, bodyParameters: bodyParameters, completionHandler: { (result, response, error) in
                    defer {
                        self.untrack(taskFor: identifier)
                    }
                    if let apiErrorType = result?["title"] as? String, let apiError = APIReadingListError(rawValue: apiErrorType), apiError != .alreadySetUp {
                        DDLogDebug("RLAPI FAILED: \(method.stringValue) \(path) \(apiError)")
                    } else {
                        #if DEBUG
                        if let error = error {
                            DDLogDebug("RLAPI FAILED: \(method.stringValue) \(path) \(error)")
                        } else {
                            DDLogDebug("RLAPI: \(method.stringValue) \(path)")
                        }
                        #endif
                    }
                    completion(result, response, error)
                })
                self.track(task: task, for: identifier)
                task?.resume()
            }
        }
    }
    
    fileprivate func post(path: [String], bodyParameters: [String: Any]? = nil, completion: @escaping ([String: Any]?, URLResponse?, Error?) -> Void) {
        requestWithCSRF(path: path, method: .post, bodyParameters: bodyParameters, completion: completion)
    }
    
    fileprivate func delete(path: [String], completion: @escaping ([String: Any]?, URLResponse?, Error?) -> Void) {
        requestWithCSRF(path: path, method: .delete, completion: completion)
    }
    
    fileprivate func put(path: [String], bodyParameters: [String: Any]? = nil, completion: @escaping ([String: Any]?, URLResponse?, Error?) -> Void) {
        requestWithCSRF(path: path, method: .put, bodyParameters: bodyParameters, completion: completion)
    }
    
    @objc func setupReadingLists(completion: @escaping (Error?) -> Void) {
        let requestType = APIReadingListRequestType.setup
        post(path: [requestType.rawValue]) { (result, response, error) in
            self.lastRequestType = requestType
            completion(error)
        }
    }
    
    @objc func teardownReadingLists(completion: @escaping (Error?) -> Void) {
        let requestType = APIReadingListRequestType.teardown
        post(path: [requestType.rawValue]) { (result, response, error) in
            self.lastRequestType = requestType
            completion(error)
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
    func createList(name: String, description: String?, completion: @escaping (_ listID: Int64?,_ error: Error?) -> Swift.Void ) {
        let bodyParams = ["name": name.precomposedStringWithCanonicalMapping, "description": description ?? ""]
        // empty string path is required to add the trailing slash, server 404s otherwise
        post(path: [""], bodyParameters: bodyParams) { (result, response, error) in
            guard let id = result?["id"] as? Int64 else {
                completion(nil, error ?? ReadingListError.unableToCreateList)
                return
            }
            completion(id, nil)
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
    func createLists(_ lists: [(name: String, description: String?)], completion: @escaping (_ listIDs: [(Int64?, Error?)]?,_ error: Error?) -> Swift.Void ) {
        guard !lists.isEmpty else {
            completion([], nil)
            return
        }
        let bodyParams = ["batch": lists.map { ["name": $0.name.precomposedStringWithCanonicalMapping, "description": $0.description ?? ""] } ]
        post(path: ["batch"], bodyParameters: bodyParams) { (result, response, error) in
            guard let batch = result?["batch"] as? [[String: Any]] else {
                guard lists.count > 1 else {
                    completion([(nil, error ?? APIReadingListError.generic)], nil)
                    return
                }
                DispatchQueue.global().async {
                    let taskGroup = WMFTaskGroup()
                    var listsByName: [String: (Int64?, Error?)] = [:]
                    for list in lists {
                        taskGroup.enter()
                        self.createList(name: list.name, description: list.description, completion: { (listID, error) in
                            taskGroup.leave()
                            listsByName[list.name] = (listID, error)
                        })
                    }
                    taskGroup.wait()
                    var listsOrErrors: [(Int64?, Error?)] = []
                    for list in lists {
                        guard let list = listsByName[list.name] else {
                            completion(nil, ReadingListError.unableToCreateList)
                            return
                        }
                        listsOrErrors.append(list)
                    }
                    completion(listsOrErrors, nil)
                }
                return
            }
            completion(batch.compactMap {
                let id = $0["id"] as? Int64
                var error: Error? = nil
                if let errorString = $0["error"] as? String {
                    error = APIReadingListError(rawValue: errorString) ?? APIReadingListError.generic
                }
                return (id, error)
            }, nil)
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
        // "" for trailing slash is required, server 404s otherwise
        post(path: ["\(listID)", "entries", ""], bodyParameters: bodyParams) { (result, response, error) in
            if let apiError = error as? APIReadingListError {
                switch apiError {
                case .duplicateEntry:
                    // TODO: Remove when error response returns ID
                    self.getAllEntriesForReadingListWithID(readingListID: listID, completion: { (entries, error) in
                        guard let entry = entries.first(where: { (entry) -> Bool in entry.title == title && entry.project == project }) else {
                            completion(nil, error ?? ReadingListError.unableToAddEntry)
                            return
                        }
                        completion(entry.id, nil)
                    })
                default:
                    completion(nil, apiError)
                }
                return
            } else if let error = error {
                completion(nil, error)
                return
            }
            
            guard let id = result?["id"] as? Int64 else {
                completion(nil, ReadingListError.unableToAddEntry)
                return
            }
            
            completion(id, nil)
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
    func addEntriesToList(withListID listID: Int64, entries: [(project: String, title: String)], completion: @escaping (_ entryIDs: [(Int64?, Error?)]?,_ error: Error?) -> Swift.Void ) {
        guard !entries.isEmpty else {
            completion([], nil)
            return
        }
        let bodyParams = ["batch": entries.map { ["project": $0.project.precomposedStringWithCanonicalMapping, "title": $0.title.precomposedStringWithCanonicalMapping] } ]
        post(path: ["\(listID)", "entries", "batch"], bodyParameters: bodyParams) { (result, response, error) in
            if let apiError = error as? APIReadingListError, apiError != .listDeleted {
                guard entries.count > 1 else {
                    completion([(nil, apiError)], nil)
                    return
                }
                self.getAllEntriesForReadingListWithID(readingListID: listID, completion: { (remoteEntries, getAllEntriesError) in
                    var remoteEntriesByProjectAndTitle: [String: [String: APIReadingListEntry]] = [:]
                    for remoteEntry in remoteEntries {
                        remoteEntriesByProjectAndTitle[remoteEntry.project.precomposedStringWithCanonicalMapping, default: [:]][remoteEntry.title.precomposedStringWithCanonicalMapping] = remoteEntry
                    }
                    let results: [(Int64?, Error?)] = entries.map {
                        let project = $0.project.precomposedStringWithCanonicalMapping
                        let title = $0.title.precomposedStringWithCanonicalMapping
                        guard let remoteEntry = remoteEntriesByProjectAndTitle[project]?[title] else {
                            return (nil, apiError == .entryLimit ? apiError : APIReadingListError.generic)
                        }
                        return (remoteEntry.id, nil)
                    }
                    completion(results, nil)
                })
                return
            } else if let error = error {
                completion(nil, error)
                return
            }

            guard let result = result else {
                completion(nil, ReadingListError.unableToAddEntry)
                return
            }
            
            guard let batch = result["batch"] as? [[String: Any]] else {
                DDLogError("Unexpected result: \(result)")
                completion(nil, ReadingListError.unableToAddEntry)
                return
            }

            completion(batch.compactMap {
                let id = $0["id"] as? Int64
                var error: Error? = nil
                if let errorString = $0["error"] as? String {
                    error = APIReadingListError(rawValue: errorString) ?? APIReadingListError.generic
                }
                return (id, error)
            }, nil)
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

        delete(path: ["\(listID)", "entries", "\(entryID)"]) { (result, response, error) in
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
        delete(path: ["\(listID)"]) { (result, response, error) in
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
        put(path: ["\(listID)"], bodyParameters: ["name": name, "description": description ?? ""]) { (result, response, error) in
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
        - since: The continuation token for this whole list of updates. Lets the server know the current state of the device. Currently an ISO 8601 date string
        - next: The continuation within this whole list of updates (since is the start of the whole list, next is the next page)
        - nextSince: The paramater to use for "since" the next time you call this method to get the updates that have happened since this update.
        - lists: Lists to append to the results
        - entries: Entries to append to the results
        - lists: All updated lists
        - entries: All updated entries
        - since: The date to use for the next update call
        - error: Any error
     */
    func updatedListsAndEntries(since: String, next: String? = nil, nextSince: String? = nil, lists: [APIReadingList] = [], entries: [APIReadingListEntry] = [], completion: @escaping (_ lists: [APIReadingList], _ entries: [APIReadingListEntry], _ since: String?, _ error: Error?) -> Swift.Void ) {
        var queryParameters: [String: Any]? = nil
        if let next = next {
            queryParameters = ["next": next]
        }
        get(path: ["changes", "since", "\(since)"], queryParameters: queryParameters) { (result: APIReadingListChanges?, response, error) in
            guard let result = result, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion([], [], nil, error ?? ReadingListError.generic)
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
            let nextSince = nextSince ?? result.since
            if let next = result.next {
                if combinedLists.count + combinedEntries.count > APIReadingListUpdateLimitForFullSyncFallback {
                    completion([], [], nil, APIReadingListError.needsFullSync)
                } else {
                    self.updatedListsAndEntries(since: since, next: next, nextSince: nextSince, lists: combinedLists, entries: combinedEntries, completion: completion)
                }
            } else {
                completion(combinedLists, combinedEntries, nextSince, nil)
            }
        }
    }
    
    /**
     Gets all reading lists from the API
         - parameters:
         - next: Optional continuation token for this list of results
         - lists: Lists to append to the results
         - lists: All lists
         - since: The string to use for the next /changes/since call
         - error: Any error
     */
    func getAllReadingLists(next: String? = nil, nextSince: String? = nil, lists: [APIReadingList] = [], completion: @escaping ([APIReadingList], String?, Error?) -> Swift.Void ) {
        var queryParameters: [String: Any]? = nil
        if let next = next {
            queryParameters = ["next": next]
        }
        // empty string path is required to add the trailing slash, server 404s otherwise
        get(path: [""], queryParameters: queryParameters) { (apiListsResponse: APIReadingLists?, response, error) in
            guard let apiListsResponse = apiListsResponse else {
                completion([], nil, error)
                return
            }
            var combinedList = lists
            combinedList.append(contentsOf: apiListsResponse.lists)
            let nextSince = nextSince ?? apiListsResponse.since
            if let next = apiListsResponse.next {
                self.getAllReadingLists(next: next, nextSince: nextSince, lists: combinedList, completion: completion)
            } else {
                completion(combinedList, nextSince, nil)
            }
        }
    }
    
    func getAllEntriesForReadingListWithID(next: String? = nil, entries: [APIReadingListEntry] = [], readingListID: Int64, completion: @escaping ([APIReadingListEntry], Error?) -> Swift.Void ) {
        var queryParameters: [String: Any]? = nil
        if let next = next {
            queryParameters = ["next": next]
        }
        // "" for trailing slash is required, server 404s otherwise
        get(path: ["\(readingListID)", "entries", ""], queryParameters: queryParameters) { (apiEntriesResponse: APIReadingListEntries?, response, error) in
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
