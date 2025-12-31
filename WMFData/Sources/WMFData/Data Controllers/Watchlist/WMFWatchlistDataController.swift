import Foundation
import UIKit

public actor WMFWatchlistDataController {
    
    private var service = WMFDataEnvironment.current.mediaWikiService
    private let sharedCacheStore = WMFDataEnvironment.current.sharedCacheStore
    private let userDefaultsStore = WMFDataEnvironment.current.userDefaultsStore

    public init() { }
    
    public func setService(_ service: WMFService) {
        self.service = service
    }
    
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

    public func fetchWatchlist() async throws -> WMFWatchlist {
        
        guard let service else {
            throw WMFDataControllerError.mediaWikiServiceUnavailable
        }
        
        let activeFilterCount = self.activeFilterCount()
        
        let projects = onWatchlistProjects()
        guard !projects.isEmpty else {
            return WMFWatchlist(items: [], activeFilterCount: activeFilterCount)
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
        
        // Use an actor to protect shared mutable state
        actor ResultAccumulator {
            var items: [WMFWatchlist.Item] = []
            var errors: [WMFProject: [WMFDataControllerError]] = [:]
            
            func addItems(_ newItems: [WMFWatchlist.Item]) {
                items.append(contentsOf: newItems)
            }
            
            func addError(_ error: WMFDataControllerError, for project: WMFProject) {
                errors[project, default: []].append(error)
            }
            
            func addErrors(_ newErrors: [WMFDataControllerError], for project: WMFProject) {
                errors[project, default: []].append(contentsOf: newErrors)
            }
            
            func initializeProject(_ project: WMFProject) {
                errors[project] = []
            }
            
            func getResults() -> (items: [WMFWatchlist.Item], errors: [WMFProject: [WMFDataControllerError]]) {
                return (items, errors)
            }
        }
        
        let accumulator = ResultAccumulator()
        
        for project in projects {
            await accumulator.initializeProject(project)
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let group = DispatchGroup()
            
            for project in projects {
                
                guard let url = URL.mediaWikiAPIURL(project: project) else {
                    continue
                }
                
                var projectParameters = parameters
                projectParameters["variant"] = project.languageVariantCode
                
                group.enter()
                let request = WMFMediaWikiServiceRequest(url: url, method: .GET, backend: .mediaWiki, parameters: projectParameters)
                service.performDecodableGET(request: request) { (result: Result<WatchlistAPIResponse, Error>) in
                    
                    Task {
                        defer {
                            group.leave()
                        }
                        
                        switch result {
                        case .success(let apiResponse):
                            
                            if let apiResponseErrors = apiResponse.errors,
                               !apiResponseErrors.isEmpty {
                                
                                let mediaWikiResponseErrors = apiResponseErrors.map { WMFDataControllerError.mediaWikiResponseError($0) }
                                await accumulator.addErrors(mediaWikiResponseErrors, for: project)
                                return
                            }
                            
                            guard let query = apiResponse.query else {
                                await accumulator.addError(WMFDataControllerError.unexpectedResponse, for: project)
                                return
                            }
                            
                            let items = await self.watchlistItems(from: query, project: project)
                            await accumulator.addItems(items)
                            
                            try? self.sharedCacheStore?.save(key: WMFSharedCacheDirectoryNames.watchlists.rawValue, project.id, value: apiResponse)
                            
                        case .failure(let error):
                            var usedCache = false
                            
                            if (error as NSError).isInternetConnectionError {
                                
                                let cachedResult: WatchlistAPIResponse? = try? self.sharedCacheStore?.load(key: WMFSharedCacheDirectoryNames.watchlists.rawValue, project.id)
                                
                                if let query = cachedResult?.query {
                                    let items = await self.watchlistItems(from: query, project: project)
                                    await accumulator.addItems(items)
                                    usedCache = true
                                }
                            }
                            
                            if !usedCache {
                                await accumulator.addError(WMFDataControllerError.serviceError(error), for: project)
                            }
                        }
                    }
                }
            }
            
            group.notify(queue: .main) {
                Task {
                    let (items, errors) = await accumulator.getResults()
                    
                    let successProjects = errors.filter { $0.value.isEmpty }
                    let failureProjects = errors.filter { !$0.value.isEmpty }
                    
                    if !successProjects.isEmpty {
                        continuation.resume(returning: WMFWatchlist(items: items, activeFilterCount: activeFilterCount))
                        return
                    }
                    
                    if let error = failureProjects.first?.value.first {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    continuation.resume(returning: WMFWatchlist(items: items, activeFilterCount: activeFilterCount))
                }
            }
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
                isTemp: item.isTemp,
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
    
    public func watch(title: String, project: WMFProject, expiry: WMFWatchlistExpiryType) async throws {

        guard let service else {
            throw WMFDataControllerError.mediaWikiServiceUnavailable
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
            throw WMFDataControllerError.failureCreatingRequestURL
        }

        let request = WMFMediaWikiServiceRequest(url: url, method: .POST, backend: .mediaWiki, tokenType: .watch, parameters: parameters)
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            service.perform(request: request) { result in
                // Extract Sendable data before resuming
                switch result {
                case .success(let response):
                    let watched = (response?["watch"] as? [[String: Any]])?.first?["watched"] as? Bool
                    
                    if watched == true {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: WMFDataControllerError.unexpectedResponse)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func unwatch(title: String, project: WMFProject) async throws {

        guard let service else {
            throw WMFDataControllerError.mediaWikiServiceUnavailable
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
            throw WMFDataControllerError.failureCreatingRequestURL
        }

        let request = WMFMediaWikiServiceRequest(url: url, method: .POST, backend: .mediaWiki, tokenType: .watch, parameters: parameters)
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            service.perform(request: request) { result in
                // Extract Sendable data before resuming
                switch result {
                case .success(let response):
                    let unwatched = (response?["watch"] as? [[String: Any]])?.first?["unwatched"] as? Bool
                    
                    if unwatched == true {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: WMFDataControllerError.unexpectedResponse)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func rollback(title: String, project: WMFProject, username: String) async throws -> WMFUndoOrRollbackResult {
        
        guard let service else {
            throw WMFDataControllerError.mediaWikiServiceUnavailable
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
            throw WMFDataControllerError.failureCreatingRequestURL
        }

        let request = WMFMediaWikiServiceRequest(url: url, method: .POST, backend: .mediaWiki, tokenType: .rollback, parameters: parameters)
        
        return try await withCheckedThrowingContinuation { continuation in
            service.perform(request: request) { result in
                // Extract Sendable data before resuming
                switch result {
                case .success(let response):
                    guard let rollbackDict = response?["rollback"] as? [String: Any],
                          let newRevisionID = rollbackDict["revid"] as? Int,
                          let oldRevisionID = rollbackDict["old_revid"] as? Int else {
                        continuation.resume(throwing: WMFDataControllerError.unexpectedResponse)
                        return
                    }
                    
                    let result = WMFUndoOrRollbackResult(newRevisionID: newRevisionID, oldRevisionID: oldRevisionID)
                    continuation.resume(returning: result)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func undo(title: String, revisionID: UInt, summary: String, username: String, project: WMFProject) async throws -> WMFUndoOrRollbackResult {

        guard let service else {
            throw WMFDataControllerError.mediaWikiServiceUnavailable
        }
        
        let summaryPrefix = try await fetchUndoRevisionSummaryPrefixText(revisionID: revisionID, username: username, project: project)
        
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
            throw WMFDataControllerError.failureCreatingRequestURL
        }

        let request = WMFMediaWikiServiceRequest(url: url, method: .POST, backend: .mediaWiki, tokenType: .csrf, parameters: parameters)
        
        return try await withCheckedThrowingContinuation { continuation in
            service.perform(request: request) { result in
                // Extract Sendable data before resuming
                switch result {
                case .success(let response):
                    guard let editDict = response?["edit"] as? [String: Any],
                          let resultString = editDict["result"] as? String,
                          resultString == "Success",
                          let newRevisionID = editDict["newrevid"] as? Int,
                          let oldRevisionID = editDict["oldrevid"] as? Int else {
                        continuation.resume(throwing: WMFDataControllerError.unexpectedResponse)
                        return
                    }
                    
                    let result = WMFUndoOrRollbackResult(newRevisionID: newRevisionID, oldRevisionID: oldRevisionID)
                    continuation.resume(returning: result)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func fetchUndoRevisionSummaryPrefixText(revisionID: UInt, username: String, project: WMFProject) async throws -> String {
        
        guard let service else {
            throw WMFDataControllerError.mediaWikiServiceUnavailable
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
            throw WMFDataControllerError.failureCreatingRequestURL
        }

        let request = WMFMediaWikiServiceRequest(url: url, method: .GET, backend: .mediaWiki, parameters: parameters)

        let response: UndoRevisionSummaryTextResponse = try await withCheckedThrowingContinuation { continuation in
            service.performDecodableGET(request: request) { (result: Result<UndoRevisionSummaryTextResponse, Error>) in
                continuation.resume(with: result)
            }
        }
        
        guard let undoSummaryMessage = response.query.messages.first(where: { message in
            message.name == "undo-summary"
        }) else {
            throw WMFDataControllerError.unexpectedResponse
        }
        
        return undoSummaryMessage.content
    }
}

// MARK: - Sync Bridge Extension

extension WMFWatchlistDataController {
    
    nonisolated public func fetchWatchlistSyncBridge(completion: @escaping @Sendable (Result<WMFWatchlist, Error>) -> Void) {
        Task {
            do {
                let watchlist = try await self.fetchWatchlist()
                completion(.success(watchlist))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    nonisolated public func rollbackSyncBridge(title: String, project: WMFProject, username: String, completion: @escaping @Sendable (Result<WMFUndoOrRollbackResult, Error>) -> Void) {
        Task {
            do {
                let result = try await self.rollback(title: title, project: project, username: username)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    nonisolated public func undoSyncBridge(title: String, revisionID: UInt, summary: String, username: String, project: WMFProject, completion: @escaping @Sendable (Result<WMFUndoOrRollbackResult, Error>) -> Void) {
        Task {
            do {
                let result = try await self.undo(title: title, revisionID: revisionID, summary: summary, username: username, project: project)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    nonisolated public func allWatchlistProjectsSyncBridge() -> [WMFProject] {
        var result: [WMFProject] = []
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            result = await self.allWatchlistProjects()
            semaphore.signal()
        }
        
        semaphore.wait()
        return result
    }
    
    nonisolated public func offWatchlistProjectsSyncBridge() -> [WMFProject] {
        var result: [WMFProject] = []
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            result = await self.offWatchlistProjects()
            semaphore.signal()
        }
        
        semaphore.wait()
        return result
    }
    
    nonisolated public func allChangeTypesSyncBridge() -> [WMFWatchlistFilterSettings.ChangeType] {
        var result: [WMFWatchlistFilterSettings.ChangeType] = []
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            result = await self.allChangeTypes()
            semaphore.signal()
        }
        
        semaphore.wait()
        return result
    }
    
    nonisolated public func offChangeTypesSyncBridge() -> [WMFWatchlistFilterSettings.ChangeType] {
        var result: [WMFWatchlistFilterSettings.ChangeType] = []
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            result = await self.offChangeTypes()
            semaphore.signal()
        }
        
        semaphore.wait()
        return result
    }
    
    nonisolated public func loadFilterSettingsSyncBridge() -> WMFWatchlistFilterSettings {
        var result: WMFWatchlistFilterSettings = WMFWatchlistFilterSettings()
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            result = await self.loadFilterSettings()
            semaphore.signal()
        }
        
        semaphore.wait()
        return result
    }
}

// MARK: - Private Models

private extension WMFWatchlistDataController {
    struct WatchlistAPIResponse: Codable, Sendable {
        
        struct Query: Codable, Sendable {
            
            struct Item: Codable, Sendable {
                let title: String
                let revisionID: UInt
                let oldRevisionID: UInt
                let username: String
                let isAnon: Bool
                let isBot: Bool
                let isTemp: Bool
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
                    case isTemp = "temp"
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

    struct UndoRevisionSummaryTextResponse: Codable, Sendable {
        
        struct Query: Codable, Sendable {
            
            struct Messages: Codable, Sendable {
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
