
import Foundation

enum TalkPageError: Error {
    case createTaskURLFailure
    case fetchExistingLocalTalkPageFailure
    case updateExistingLocalTalkPageFailure
    case createLocalTalkPageFailure
    case fetchNetworkTalkPageFailure
    case fetchRevisionIDFailure
    case talkPageDatabaseKeyCreationFailure
    case revisionUrlCreationFailure
    case talkPageTitleCreationFailure
}

class TalkPageController {
    let talkPageFetcher: TalkPageFetcher
    let localHandler: TalkPageLocalHandler
    let articleRevisionFetcher: WMFArticleRevisionFetcher
    let title: String
    let host: String
    let titleIncludesPrefix: Bool
    let type: TalkPageType
    
    required init(talkPageFetcher: TalkPageFetcher = TalkPageFetcher(), articleRevisionFetcher: WMFArticleRevisionFetcher = WMFArticleRevisionFetcher(), localHandler: TalkPageLocalHandler? = nil, dataStore: MWKDataStore, title: String, host: String, titleIncludesPrefix: Bool, type: TalkPageType) {
        self.talkPageFetcher = talkPageFetcher
        self.articleRevisionFetcher = articleRevisionFetcher
        
        if let localHandler = localHandler {
            self.localHandler = localHandler
        } else {
            self.localHandler = TalkPageLocalHandler(dataStore: dataStore)
        }
        
        self.title = title
        self.host = host
        self.titleIncludesPrefix = titleIncludesPrefix
        self.type = type
    }
    
    func fetchTalkPage(completion: ((Result<TalkPage, Error>) -> Void)? = nil) {
        guard let title = type.urlTitle(for: title, titleIncludesPrefix: titleIncludesPrefix),
            let taskURL = talkPageFetcher.taskURL(for: title, host: host) else {
            completion?(.failure(TalkPageError.createTaskURLFailure))
            return
        }
        
        var existingLocalTalkPage: TalkPage?
        localHandler.dataStore.viewContext.performAndWait {
            do {
                existingLocalTalkPage = try localHandler.existingTalkPage(for: taskURL)
            } catch {
                completion?(.failure(TalkPageError.fetchExistingLocalTalkPageFailure))
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
            if let existingLocalTalkPage = existingLocalTalkPage,
                existingLocalTalkPage.revisionId == lastRevisionId {
                DispatchQueue.main.async {
                    completion?(.success(existingLocalTalkPage))
                }
            } else {
                self.fetchAndUpdate(existingLocalTalkPage:existingLocalTalkPage, revisionID: lastRevisionId, completion: completion)
            }
        }
        
        guard let revisionURL = Configuration.current.mediaWikiAPIURLForWikiLanguage("en", with: nil).url?.wmf_URL(withTitle: title) else {
            completion?(.failure(TalkPageError.revisionUrlCreationFailure))
                return
        }
        
        var revisionID: NSNumber?
        if let existingLocalRevisionId = existingLocalTalkPage?.revisionId {
            revisionID = NSNumber(value: existingLocalRevisionId)
        }
        let revisionFetcherTask = articleRevisionFetcher.fetchLatestRevisions(forArticleURL: revisionURL, resultLimit: 1, endingWithRevision: revisionID, failure: errorHandler, success: successIDHandler)
        
        //todo: task tracking
        revisionFetcherTask?.resume()
    }
    
    private func fetchAndUpdate(existingLocalTalkPage: TalkPage?, revisionID: Int64, completion: ((Result<TalkPage, Error>) -> Void)? = nil) {
        
        guard let title = type.urlTitle(for: title, titleIncludesPrefix: titleIncludesPrefix) else {
            completion?(.failure(TalkPageError.talkPageTitleCreationFailure))
            return
        }
        talkPageFetcher.fetchTalkPage(for: title, host: host, revisionID: revisionID) { (result) in
            
            DispatchQueue.main.async {
                self.localHandler.dataStore.viewContext.perform {
                    switch result {
                    case .success(let networkTalkPage):
                        if let existingLocalTalkPage = existingLocalTalkPage {
                            if let updatedLocalTalkPage = self.localHandler.updateExistingTalkPage(existingTalkPage: existingLocalTalkPage, with: networkTalkPage) {
                                completion?(.success(updatedLocalTalkPage))
                            } else {
                                completion?(.failure(TalkPageError.updateExistingLocalTalkPageFailure))
                            }
                        } else {
                            if let newLocalTalkPage = self.localHandler.createTalkPage(with: networkTalkPage) {
                                completion?(.success(newLocalTalkPage))
                            } else {
                                completion?(.failure(TalkPageError.createLocalTalkPageFailure))
                            }
                        }
                    case .failure:
                        completion?(.failure(TalkPageError.fetchNetworkTalkPageFailure))
                    }
                }
            }
        }
    }
}
