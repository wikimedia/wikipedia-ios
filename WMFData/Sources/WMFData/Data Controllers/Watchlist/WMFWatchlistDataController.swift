import Foundation
import UIKit

public class WMFWatchlistDataController {
    
    var service = WMFDataEnvironment.current.mediaWikiService
    private let sharedCacheStore = WMFDataEnvironment.current.sharedCacheStore
    private let userDefaultsStore = WMFDataEnvironment.current.userDefaultsStore

    public init() { }
    
    // MARK: Multiselect Helpers
    
    public func allWatchlistProjects() -> [WMFProject] {
        let appLanguages = WMFDataEnvironment.current.appData.appLanguages
        guard !appLanguages.isEmpty else {
           return []
        }
        
        var projects = WMFProject.projectsFromLanguages(languages:appLanguages)
        projects.append(.commons)
        projects.append(.wikidata)
        
        return projects
    }
    
    public func onWatchlistProjects() -> [WMFProject] {
        let allProjects = allWatchlistProjects()
        let filterSettings = loadFilterSettings()
        return allProjects.filter { !filterSettings.offProjects.contains($0) }
    }
    
    public func offWatchlistProjects() -> [WMFProject] {
        let allProjects = allWatchlistProjects()
        let filterSettings = loadFilterSettings()
        return filterSettings.offProjects.filter { allProjects.contains($0) }
    }
    
    public func allChangeTypes() -> [WMFWatchlistFilterSettings.ChangeType] {
        return WMFWatchlistFilterSettings.ChangeType.allCases
    }
    
    public func offChangeTypes() -> [WMFWatchlistFilterSettings.ChangeType] {
        let filterSettings = loadFilterSettings()
        return filterSettings.offTypes.filter { allChangeTypes().contains($0) }
    }
    
    // MARK: Filter Settings
    
    public func loadFilterSettings() -> WMFWatchlistFilterSettings {
        let key = WMFUserDefaultsKey.watchlistFilterSettings.rawValue
        return (try? userDefaultsStore?.load(key: key)) ?? WMFWatchlistFilterSettings()
    }
    
    public func saveFilterSettings(_ filterSettings: WMFWatchlistFilterSettings) {
        let key = WMFUserDefaultsKey.watchlistFilterSettings.rawValue
        try? userDefaultsStore?.save(key: key, value: filterSettings)
    }
    
    public func activeFilterCount() -> Int {
        
        let filterSettings = loadFilterSettings()
        
        var numFilters = 0
        numFilters += offWatchlistProjects().count
        
        if filterSettings.latestRevisions == .latestRevision {
            numFilters += 1
        }
        
        if filterSettings.activity != .all {
            numFilters += 1
        }
        
        if filterSettings.automatedContributions != .all {
            numFilters += 1
        }
        
        if filterSettings.significance != .all {
            numFilters += 1
        }
        
        if filterSettings.userRegistration != .all {
            numFilters += 1
        }
        
        let allTypes = WMFWatchlistFilterSettings.ChangeType.allCases
        let offTypes = filterSettings.offTypes.filter { allTypes.contains($0) }
        numFilters += offTypes.count
        
        return numFilters
    }
    
    // MARK: GET Watchlist Items

    public func fetchWatchlist(completion: @escaping (Result<WMFWatchlist, Error>) -> Void) {
        
        guard let service else {
            completion(.failure(WMFDataControllerError.mediaWikiServiceUnavailable))
            return
        }
        
        let activeFilterCount = self.activeFilterCount()
        
        let projects = onWatchlistProjects()
        guard !projects.isEmpty else {
            completion(.success(WMFWatchlist(items: [], activeFilterCount: activeFilterCount)))
            return
        }
        
        let filterSettings = loadFilterSettings()
        
        var parameters = [
                    "action": "query",
                    "list": "watchlist",
                    "wllimit": "500",
                    "wlprop": "ids|title|flags|comment|parsedcomment|timestamp|sizes|user|loginfo",
                    "errorsuselocal": "1",
                    "errorformat": "html",
                    "format": "json",
                    "formatversion": "2"
                ]
        
        apply(filterSettings: filterSettings, to: &parameters)
        
        let group = DispatchGroup()
        var items: [WMFWatchlist.Item] = []
        var errors: [WMFProject: [WMFDataControllerError]] = [:]
        projects.forEach { project in
            errors[project] = []
        }
        
        for project in projects {
            
            guard let url = URL.mediaWikiAPIURL(project: project) else {
                return
            }
            
            parameters["variant"] = project.languageVariantCode
            
            group.enter()
            let request = WMFMediaWikiServiceRequest(url: url, method: .GET, backend: .mediaWiki, parameters: parameters)
            service.performDecodableGET(request: request) { [weak self] (result: Result<WatchlistAPIResponse, Error>) in
                
                guard let self else {
                    return
                }
                
                defer {
                    group.leave()
                }
                
                switch result {
                case .success(let apiResponse):
                    
                    if let apiResponseErrors = apiResponse.errors,
                       !apiResponseErrors.isEmpty {
                        
                        let mediaWikiResponseErrors = apiResponseErrors.map { WMFDataControllerError.mediaWikiResponseError($0) }
                        errors[project, default: []].append(contentsOf: mediaWikiResponseErrors)
                        return
                    }
                    
                    guard let query = apiResponse.query else {
                        errors[project, default: []].append(WMFDataControllerError.unexpectedResponse)
                        return
                    }
                    
                    items.append(contentsOf: self.watchlistItems(from: query, project: project))
                    
                    try? sharedCacheStore?.save(key: WMFSharedCacheDirectoryNames.watchlists.rawValue, project.id, value: apiResponse)
                    
                case .failure(let error):
                    var usedCache = false
                    
                    if (error as NSError).isInternetConnectionError {
                        
                        let cachedResult: WatchlistAPIResponse? = try? sharedCacheStore?.load(key: WMFSharedCacheDirectoryNames.watchlists.rawValue, project.id)
                        
                        if let query = cachedResult?.query {
                            items.append(contentsOf: self.watchlistItems(from: query, project: project))
                            usedCache = true
                        }
                    }
                    
                    if !usedCache {
                        errors[project, default: []].append(WMFDataControllerError.serviceError(error))
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
        
            let successProjects = errors.filter { $0.value.isEmpty }
            let failureProjects = errors.filter { !$0.value.isEmpty }
            
            if !successProjects.isEmpty {
                completion(.success(WMFWatchlist(items: items, activeFilterCount: activeFilterCount)))
                return
            }
            
            if let error = failureProjects.first?.value.first {
                completion(.failure(error))
                return
            }
            
            completion(.success(WMFWatchlist(items: items, activeFilterCount: activeFilterCount)))
        }
    }
    
    private func watchlistItems(from apiResponseQuery: WatchlistAPIResponse.Query, project: WMFProject) -> [WMFWatchlist.Item] {
        
        var items: [WMFWatchlist.Item] = []
        for item in apiResponseQuery.watchlist {
            
            guard let timestamp = DateFormatter.mediaWikiAPIDateFormatter.date(from: item.timestampString) else {
                continue
            }
            
            let item = WMFWatchlist.Item(
                title: item.title,
                revisionID: item.revisionID,
                oldRevisionID: item.oldRevisionID,
                username: item.username,
                isAnon: item.isAnon,
                isBot: item.isBot,
                timestamp: timestamp,
                commentWikitext: item.commentWikitext ?? "",
                commentHtml: item.commentHtml ?? "",
                byteLength: item.byteLength,
                oldByteLength: item.oldByteLength,
                project: project)
            items.append(item)
        }
        
        return items
    }
    
    private func apply(filterSettings: WMFWatchlistFilterSettings, to parameters: inout [String: String]) {
        switch filterSettings.latestRevisions {
        case .notTheLatestRevision:
            parameters["wlallrev"] = "1"
        case .latestRevision:
            break
        }
        
        var wlshow: [String] = []
        var wltype: [String] = []
        
        switch filterSettings.activity {
        case .unseenChanges:
            wlshow.append("unread")
        case .seenChanges:
            wlshow.append("!unread")
        case .all:
            break
        }
        
        switch filterSettings.automatedContributions {
        case .bot:
            wlshow.append("bot")
        case .human:
            wlshow.append("!bot")
        case .all:
            break
        }
        
        switch filterSettings.significance {
        case .minorEdits:
            wlshow.append("minor")
        case .nonMinorEdits:
            wlshow.append("!minor")
        case .all:
            break
        }
        
        switch filterSettings.userRegistration {
        case .unregistered:
            wlshow.append("anon")
        case .registered:
            wlshow.append("!anon")
        case .all:
            break
        }
        
        if !filterSettings.offTypes.contains(.pageEdits) {
            wltype.append("edit")
        }
        
        if !filterSettings.offTypes.contains(.pageCreations) {
            wltype.append("new")
        }
        
        if !filterSettings.offTypes.contains(.categoryChanges) {
            wltype.append("categorize")
        }
        
        if !filterSettings.offTypes.contains(.loggedActions) {
            wltype.append("log")
        }
        
        if !filterSettings.offTypes.contains(.wikidataEdits) {
            wltype.append("external")
        }
        
        parameters["wlshow"] = wlshow.joined(separator: "|")
        parameters["wltype"] = wltype.joined(separator: "|")
    }
    
    // MARK: POST Watch Item
     
     public func watch(title: String, project: WMFProject, expiry: WMFWatchlistExpiryType, completion: @escaping (Result<Void, Error>) -> Void) {

         guard let service else {
             completion(.failure(WMFDataControllerError.mediaWikiServiceUnavailable))
             return
         }

         let parameters = [
             "action": "watch",
             "titles": title,
             "expiry": expiry.rawValue,
             "format": "json",
             "formatversion": "2",
             "errorformat": "html",
             "errorsuselocal": "1"
         ]

         guard let url = URL.mediaWikiAPIURL(project: project) else {
             completion(.failure(WMFDataControllerError.failureCreatingRequestURL))
             return
         }

         let request = WMFMediaWikiServiceRequest(url: url, method: .POST, backend: .mediaWiki, tokenType: .watch, parameters: parameters)
         service.perform(request: request) { result in
             switch result {
             case .success(let response):
                 guard let watched = (response?["watch"] as? [[String: Any]])?.first?["watched"] as? Bool,
                 watched == true else {
                     completion(.failure(WMFDataControllerError.unexpectedResponse))
                     return
                 }

                 completion(.success(()))
             case .failure(let error):
                 completion(.failure(WMFDataControllerError.serviceError(error)))
             }
         }
     }

     // MARK: POST Unwatch Item
     
     public func unwatch(title: String, project: WMFProject, completion: @escaping (Result<Void, Error>) -> Void) {

         guard let service else {
             completion(.failure(WMFDataControllerError.mediaWikiServiceUnavailable))
             return
         }

         let parameters = [
             "action": "watch",
             "unwatch": "1",
             "titles": title,
             "format": "json",
             "formatversion": "2",
             "errorformat": "html",
             "errorsuselocal": "1"
         ]

         guard let url = URL.mediaWikiAPIURL(project: project) else {
             completion(.failure(WMFDataControllerError.failureCreatingRequestURL))
             return
         }

         let request = WMFMediaWikiServiceRequest(url: url, method: .POST, backend: .mediaWiki, tokenType: .watch, parameters: parameters)
         service.perform(request: request) { result in
             switch result {
             case .success(let response):
                 guard let unwatched = (response?["watch"] as? [[String: Any]])?.first?["unwatched"] as? Bool,
                       unwatched == true else {
                     completion(.failure(WMFDataControllerError.unexpectedResponse))
                     return
                 }

                 completion(.success(()))
             case .failure(let error):
                 completion(.failure(WMFDataControllerError.serviceError(error)))
             }
         }
     }
    
    // MARK: GET Watch Status and Rollback Rights
     
     public func fetchWatchStatus(title: String, project: WMFProject, needsRollbackRights: Bool = false, completion: @escaping (Result<WMFPageWatchStatus, Error>) -> Void) {
         guard let service else {
             completion(.failure(WMFDataControllerError.mediaWikiServiceUnavailable))
             return
         }

         var parameters = [
                     "action": "query",
                     "prop": "info",
                     "inprop": "watched",
                     "titles": title,
                     "errorsuselocal": "1",
                     "errorformat": "html",
                     "format": "json",
                     "formatversion": "2"
                 ]

         if needsRollbackRights {
             parameters["meta"] = "userinfo"
             parameters["uiprop"] = "rights"
         }

         guard let url = URL.mediaWikiAPIURL(project: project) else {
             return
         }

         let request = WMFMediaWikiServiceRequest(url: url, method: .GET, backend: .mediaWiki, parameters: parameters)

         service.performDecodableGET(request: request) { (result: Result<PageWatchStatusAndRollbackResponse, Error>) in
             switch result {
             case .success(let response):

                guard let firstPage = response.query.pages.first else {
                 completion(.failure(WMFDataControllerError.unexpectedResponse))
                 return
                }

                let watched = firstPage.watched
                let userHasRollbackRights = response.query.userinfo?.rights.contains("rollback")
                 
                var watchlistExpiry: Date? = nil
                if let watchlistExpiryString = firstPage.watchlistexpiry {
                  watchlistExpiry = DateFormatter.mediaWikiAPIDateFormatter.date(from: watchlistExpiryString)
                }

                let status = WMFPageWatchStatus(watched: watched, watchlistExpiry: watchlistExpiry, userHasRollbackRights: userHasRollbackRights)
                 completion(.success(status))
             case .failure(let error):
                 completion(.failure(WMFDataControllerError.serviceError(error)))
             }
         }
     }
    
    // MARK: POST Rollback Page
    
    public func rollback(title: String, project: WMFProject, username: String, completion: @escaping (Result<WMFUndoOrRollbackResult, Error>) -> Void) {
        
        guard let service else {
            completion(.failure(WMFDataControllerError.mediaWikiServiceUnavailable))
            return
        }

        let parameters = [
            "action": "rollback",
            "title": title,
            "user": username,
            "matags": WMFEditTag.appRollback.rawValue,
            "format": "json",
            "formatversion": "2",
            "errorformat": "html",
            "errorsuselocal": "1"
        ]

        guard let url = URL.mediaWikiAPIURL(project: project) else {
            completion(.failure(WMFDataControllerError.failureCreatingRequestURL))
            return
        }

        let request = WMFMediaWikiServiceRequest(url: url, method: .POST, backend: .mediaWiki, tokenType: .rollback, parameters: parameters)
        service.perform(request: request) { result in
            switch result {
            case .success(let response):
                guard let rollback = (response?["rollback"] as? [String: Any]),
                    let newRevisionID = rollback["revid"] as? Int,
                    let oldRevisionID = rollback["old_revid"] as? Int else {
                    completion(.failure(WMFDataControllerError.unexpectedResponse))
                    return
                }

                completion(.success(WMFUndoOrRollbackResult(newRevisionID: newRevisionID, oldRevisionID: oldRevisionID)))
            case .failure(let error):
                completion(.failure(WMFDataControllerError.serviceError(error)))
            }
        }
    }
    
    // MARK: POST Undo Revision
    
    public func undo(title: String, revisionID: UInt, summary: String, username: String, project: WMFProject, completion: @escaping (Result<WMFUndoOrRollbackResult, Error>) -> Void) {

        guard let service else {
            completion(.failure(WMFDataControllerError.mediaWikiServiceUnavailable))
            return
        }
        
        fetchUndoRevisionSummaryPrefixText(revisionID: revisionID, username: username, project: project) { result in
            switch result {
            case .success(let summaryPrefix):
                
                let finalSummary = summaryPrefix + " " + summary
                
                let parameters = [
                    "action": "edit",
                    "title": title,
                    "summary": finalSummary,
                    "undo": String(revisionID),
                    "matags": WMFEditTag.appUndo.rawValue,
                    "format": "json",
                    "formatversion": "2",
                    "errorformat": "html",
                    "errorsuselocal": "1"
                ]

                guard let url = URL.mediaWikiAPIURL(project: project) else {
                    completion(.failure(WMFDataControllerError.failureCreatingRequestURL))
                    return
                }

                let request = WMFMediaWikiServiceRequest(url: url, method: .POST, backend: .mediaWiki, tokenType: .csrf, parameters: parameters)
                service.perform(request: request) { result in
                    switch result {
                    case .success(let response):
                        guard let edit = (response?["edit"] as? [String: Any]),
                              let result = edit["result"] as? String,
                              result == "Success",
                              let newRevisionID = edit["newrevid"] as? Int,
                              let oldRevisionID = edit["oldrevid"] as? Int else {
                            completion(.failure(WMFDataControllerError.unexpectedResponse))
                            return
                        }

                        completion(.success(WMFUndoOrRollbackResult(newRevisionID: newRevisionID, oldRevisionID: oldRevisionID)))
                    case .failure(let error):
                        completion(.failure(WMFDataControllerError.serviceError(error)))
                    }
                }
                
            case .failure(let error):
                completion(.failure(WMFDataControllerError.serviceError(error)))
            }
        }
    }
    
    private func fetchUndoRevisionSummaryPrefixText(revisionID: UInt, username: String, project: WMFProject, completion: @escaping (Result<String, Error>) -> Void) {
        
        guard let service else {
            completion(.failure(WMFDataControllerError.mediaWikiServiceUnavailable))
            return
        }

        let parameters = [
                    "action": "query",
                    "meta": "allmessages",
                    "amenableparser": "1",
                    "ammessages": "undo-summary",
                    "amargs": "\(revisionID)|\(username)",
                    "errorsuselocal": "1",
                    "errorformat": "html",
                    "format": "json",
                    "formatversion": "2"
                ]

        guard let url = URL.mediaWikiAPIURL(project: project) else {
            return
        }

        let request = WMFMediaWikiServiceRequest(url: url, method: .GET, backend: .mediaWiki, parameters: parameters)

        service.performDecodableGET(request: request) { (result: Result<UndoRevisionSummaryTextResponse, Error>) in
            switch result {
            case .success(let response):
                
                guard let undoSummaryMessage = response.query.messages.first(where: { message in
                    message.name == "undo-summary"
                }) else {
                    completion(.failure(WMFDataControllerError.unexpectedResponse))
                    return
                }
                
                completion(.success(undoSummaryMessage.content))
            case .failure(let error):
                completion(.failure(WMFDataControllerError.serviceError(error)))
            }
        }
    }
}

// MARK: - Private Models

private extension WMFWatchlistDataController {
    struct WatchlistAPIResponse: Codable {
        
        struct Query: Codable {
            
            struct Item: Codable {
                let title: String
                let revisionID: UInt
                let oldRevisionID: UInt
                let username: String
                let isAnon: Bool
                let isBot: Bool
                let timestampString: String
                let commentWikitext: String?
                let commentHtml: String?
                let byteLength: UInt
                let oldByteLength: UInt
                
                enum CodingKeys: String, CodingKey {
                    case title
                    case revisionID = "revid"
                    case oldRevisionID = "old_revid"
                    case username = "user"
                    case isAnon = "anon"
                    case isBot = "bot"
                    case timestampString = "timestamp"
                    case commentWikitext = "comment"
                    case commentHtml = "parsedcomment"
                    case byteLength = "newlen"
                    case oldByteLength = "oldlen"
                }
            }
            
            let watchlist: [Item]
        }
        
        let query: Query?
        let errors: [WMFMediaWikiError]?
    }

    struct PageWatchStatusAndRollbackResponse: Codable {

        struct Query: Codable {

            struct Page: Codable {
                let title: String
                let watched: Bool
                let watchlistexpiry: String?
            }

            struct UserInfo: Codable {
                let name: String
                let rights: [String]
            }

            let pages: [Page]
            let userinfo: UserInfo?
        }

        let query: Query
    }

    struct UndoRevisionSummaryTextResponse: Codable {
        
        struct Query: Codable {
            
            struct Messages: Codable {
                let name: String
                let content: String
            }
            
            let messages: [Messages]
            
            enum CodingKeys: String, CodingKey {
                case messages = "allmessages"
            }
        }
        
        let query: Query
    }
}
