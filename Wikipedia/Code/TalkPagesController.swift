
import Foundation

enum TalkPageError: Error {
    case createTaskURLFailure
    case fetchExistingLocalTalkPageFailure
    case updateExistingLocalTalkPageFailure
    case createLocalTalkPageFailure
    case fetchNetworkTalkPageFailure
    case fetchRevisionIDFailure
    case talkPageDatabaseKeyCreationFailure
}

class TalkPageController {
    let talkPageFetcher: TalkPageFetcher
    let localHandler: TalkPageLocalHandler
    let articleRevisionFetcher: WMFArticleRevisionFetcher
    let name: String
    let host: String
    
    required init(talkPageFetcher: TalkPageFetcher = TalkPageFetcher(), articleRevisionFetcher: WMFArticleRevisionFetcher = WMFArticleRevisionFetcher(), localHandler: TalkPageLocalHandler? = nil, dataStore: MWKDataStore, name: String, host: String) {
        self.talkPageFetcher = talkPageFetcher
        self.articleRevisionFetcher = articleRevisionFetcher
        
        if let localHandler = localHandler {
            self.localHandler = localHandler
        } else {
            self.localHandler = TalkPageLocalHandler(dataStore: dataStore)
        }
        
        self.name = name
        self.host = host
    }
    
    func fetchTalkPage(completion: ((Result<TalkPage, Error>) -> Void)? = nil) {
        guard let taskURL = talkPageFetcher.taskURL(for: name, host: host) else {
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
            guard let revisionQueryResults = object as? [WMFRevisionQueryResults],
            let lastRevisionId = revisionQueryResults.first?.revisions.first?.revisionId.int64Value else {
                completion?(.failure(TalkPageError.fetchRevisionIDFailure))
                return
            }
            
            //if latest revision ID is the same return local talk page. Else forward revision ID onto talk page fetcher
            if let existingLocalTalkPage = existingLocalTalkPage,
                existingLocalTalkPage.revisionId == lastRevisionId {
                completion?(.success(existingLocalTalkPage))
            } else {
                self.fetchAndUpdate(existingLocalTalkPage:existingLocalTalkPage, revisionID: lastRevisionId, completion: completion)
            }
        }
        
        //todo: does UInt.max work? I just need the last ID...
        let revisionFetcherTask = articleRevisionFetcher.fetchLatestRevisions(forArticleURL: taskURL, resultLimit: 1, endingWithRevision: UInt.max, failure: errorHandler, success: successIDHandler)
        
        //todo: task tracking
        revisionFetcherTask?.resume()
    }
    
    private func fetchAndUpdate(existingLocalTalkPage: TalkPage?, revisionID: Int64, completion: ((Result<TalkPage, Error>) -> Void)? = nil) {
        
        talkPageFetcher.fetchTalkPage(for: name, host: host, revisionID: revisionID) { (result) in
            
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
