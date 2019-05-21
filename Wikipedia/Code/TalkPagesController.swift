
import Foundation

enum TalkPageError: Error {
    case createTaskURLFailure
    case fetchLocalTalkPageFailure
    case updateLocalTalkPageFailure
    case createLocalTalkPageFailure
    case fetchNetworkTalkPageFailure
    case fetchRevisionIDFailure
    case talkPageDatabaseKeyCreationFailure
    case revisionUrlCreationFailure
    case talkPageTitleCreationFailure
    case createUrlTitleStringFailure
}

enum TalkPageAppendSuccessResult {
    case missingRevisionIDInResult
    case refreshFetchFailed
    case success
}

class TalkPageController {
    let fetcher: TalkPageFetcher
    let localHandler: TalkPageLocalHandler
    let articleRevisionFetcher: WMFArticleRevisionFetcher
    let title: String
    let host: String
    let languageCode: String
    let titleIncludesPrefix: Bool
    let type: TalkPageType
    
    required init(fetcher: TalkPageFetcher = TalkPageFetcher(), articleRevisionFetcher: WMFArticleRevisionFetcher = WMFArticleRevisionFetcher(), localHandler: TalkPageLocalHandler? = nil, dataStore: MWKDataStore, title: String, host: String, languageCode: String, titleIncludesPrefix: Bool, type: TalkPageType) {
        self.fetcher = fetcher
        self.articleRevisionFetcher = articleRevisionFetcher
        
        if let localHandler = localHandler {
            self.localHandler = localHandler
        } else {
            self.localHandler = TalkPageLocalHandler(dataStore: dataStore)
        }
        
        self.title = title
        self.host = host
        self.languageCode = languageCode
        self.titleIncludesPrefix = titleIncludesPrefix
        self.type = type
    }
    
    func fetchTalkPage(completion: ((Result<TalkPage, Error>) -> Void)? = nil) {
        
        guard let urlTitle = type.urlTitle(for: title, titleIncludesPrefix: titleIncludesPrefix),
            let taskURL = fetcher.taskURL(for: urlTitle, host: host) else {
            completion?(.failure(TalkPageError.createTaskURLFailure))
            return
        }
        
        var localTalkPage: TalkPage?
        localHandler.dataStore.viewContext.performAndWait {
            do {
                localTalkPage = try localHandler.talkPage(for: taskURL)
            } catch {
                completion?(.failure(TalkPageError.fetchLocalTalkPageFailure))
                return
            }
        }
        
        let errorHandler: (Error) -> Void = { error in
            completion?(.failure(TalkPageError.fetchRevisionIDFailure))
        }
        
        let successIDHandler: (Any) -> Void = { object in
            
            let queryResults = (object as? [WMFRevisionQueryResults])?.first ?? (object as? WMFRevisionQueryResults)
            
            guard let lastRevisionId = queryResults?.revisions.first?.revisionId.int64Value else {
                DispatchQueue.main.async {
                    completion?(.failure(TalkPageError.fetchRevisionIDFailure))
                }
                return
            }
            
            //if latest revision ID is the same return local talk page. else forward revision ID onto talk page fetcher
            if let localTalkPage = localTalkPage,
                localTalkPage.revisionId == lastRevisionId {
                DispatchQueue.main.async {
                    completion?(.success(localTalkPage))
                }
            } else {
                self.fetchAndUpdate(localTalkPage: localTalkPage, revisionID: lastRevisionId, completion: completion)
            }
        }
        
        guard let revisionURL = Configuration.current.mediaWikiAPIURLForWikiLanguage(languageCode, with: nil).url?.wmf_URL(withTitle: urlTitle) else {
            completion?(.failure(TalkPageError.revisionUrlCreationFailure))
                return
        }
        
        var revisionID: NSNumber?
        if let localRevisionId = localTalkPage?.revisionId {
            revisionID = NSNumber(value: localRevisionId)
        }
        
        let revisionFetcherTask = articleRevisionFetcher.fetchLatestRevisions(forArticleURL: revisionURL, resultLimit: 1, endingWithRevision: revisionID, failure: errorHandler, success: successIDHandler)
        
        //todo: task tracking
        revisionFetcherTask?.resume()
    }
    
    func addTopic(to talkPage: TalkPage, title: String, host: String, languageCode: String, subject: String, body: String, completion: @escaping (Result<TalkPageAppendSuccessResult, Error>) -> Void) {
        
        guard let title = type.urlTitle(for: title, titleIncludesPrefix: titleIncludesPrefix) else {
            completion(.failure(TalkPageError.createUrlTitleStringFailure))
            return
        }
        
        //todo: conditional signature
        let wrappedBody = "<p>\n\n" + body + " ~~~~</p>"
        
        fetcher.addTopic(to: title, host: host, languageCode: languageCode, subject: subject, body: wrappedBody) { (result) in
            switch result {
            case .success(let result):
                guard let newRevisionID = result["newrevid"] as? Int64 else {
                    completion(.success(.missingRevisionIDInResult))
                    return
                }
                
                self.fetchAndUpdate(localTalkPage: talkPage, revisionID: newRevisionID, completion: { (result) in
                    switch result {
                    case .success:
                        completion(.success(.success))
                    case .failure:
                        completion(.success(.refreshFetchFailed))
                    }
                })
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func addReply(to topic: TalkPageTopic, title: String, host: String, languageCode: String, body: String, completion: @escaping (Result<TalkPageAppendSuccessResult, Error>) -> Void) {
        
        guard let title = type.urlTitle(for: title, titleIncludesPrefix: titleIncludesPrefix) else {
            completion(.failure(TalkPageError.createUrlTitleStringFailure))
            return
        }
        
        //todo: conditional signature
        let wrappedBody = "<p>\n\n" + body + " ~~~~</p>"
        
        fetcher.addReply(to: topic, title: title, host: host, languageCode: languageCode, body: wrappedBody) { (result) in
            switch result {
            case .success(let result):
                guard let newRevisionID = result["newrevid"] as? Int64 else {
                    completion(.success(.missingRevisionIDInResult))
                    return
                }
                
                self.fetchAndUpdate(localTalkPage: topic.talkPage, revisionID: newRevisionID, completion: { (result) in
                    switch result {
                    case .success:
                        completion(.success(.success))
                    case .failure:
                        completion(.success(.refreshFetchFailed))
                    }
                })
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

//MARK: Private

private extension TalkPageController {
    
    func fetchAndUpdate(localTalkPage: TalkPage?, revisionID: Int64, completion: ((Result<TalkPage, Error>) -> Void)? = nil) {
        
        guard let urlTitle = type.urlTitle(for: title, titleIncludesPrefix: titleIncludesPrefix) else {
            completion?(.failure(TalkPageError.talkPageTitleCreationFailure))
            return
        }
        let displayTitle = TalkPageType.user.displayTitle(for: title, titleIncludesPrefix: titleIncludesPrefix)
        fetcher.fetchTalkPage(urlTitle: urlTitle, displayTitle: displayTitle, host: host, languageCode: languageCode, revisionID: revisionID) { (result) in
            
            DispatchQueue.main.async {
                self.localHandler.dataStore.viewContext.perform {
                    switch result {
                    case .success(let networkTalkPage):
                        if let localTalkPage = localTalkPage {
                            if let updatedLocalTalkPage = self.localHandler.updateTalkPage(localTalkPage, with: networkTalkPage) {
                                completion?(.success(updatedLocalTalkPage))
                            } else {
                                completion?(.failure(TalkPageError.updateLocalTalkPageFailure))
                            }
                        } else {
                            if let newLocalTalkPage = self.localHandler.createTalkPage(with: networkTalkPage) {
                                completion?(.success(newLocalTalkPage))
                            } else {
                                completion?(.failure(TalkPageError.createLocalTalkPageFailure))
                            }
                        }
                    case .failure(let error):
                        print(error)
                        completion?(.failure(TalkPageError.fetchNetworkTalkPageFailure))
                    }
                }
            }
        }
    }
}
