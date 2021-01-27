
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
    case freshFetchTaskGroupFailure
    case topicMissingTalkPageRelationship
    case unableToDetermineAbsoluteURL

    var localizedDescription: String {
        return CommonStrings.genericErrorDescription
    }
}

enum TalkPageAppendSuccessResult {
    case missingRevisionIDInResult
    case refreshFetchFailed
    case success
}

class TalkPageController {
    let fetcher: TalkPageFetcher
    let articleRevisionFetcher: WMFArticleRevisionFetcher
    let moc: NSManagedObjectContext
    let title: String
    let siteURL: URL
    let type: TalkPageType
    
    var displayTitle: String {
        return type.titleWithoutNamespacePrefix(title: title)
    }
    
    required init(fetcher: TalkPageFetcher = TalkPageFetcher(), articleRevisionFetcher: WMFArticleRevisionFetcher = WMFArticleRevisionFetcher(), moc: NSManagedObjectContext, title: String, siteURL: URL, type: TalkPageType) {
        self.fetcher = fetcher
        self.articleRevisionFetcher = articleRevisionFetcher
        self.moc = moc
        self.title = title
        self.siteURL = siteURL
        self.type = type
        assert(title.contains(":"), "Title must already be prefixed with namespace.")
    }
    
    struct FetchResult {
        let objectID: NSManagedObjectID
        let isInitialLocalResult: Bool
    }
    
    func fetchTalkPage(completion: ((Result<FetchResult, Error>) -> Void)? = nil) {
        guard let urlTitle = type.urlTitle(for: title),
            let taskURL = fetcher.getURL(for: urlTitle, siteURL: siteURL) else {
            completion?(.failure(TalkPageError.createTaskURLFailure))
            return
        }
        moc.perform {
            do {
                guard let localTalkPage = try self.moc.talkPage(for: taskURL) else {
                    
                    self.fetchAndCreateLocalTalkPage(with: urlTitle, taskURL: taskURL, in: self.moc, completion: { (result) in
                        
                        switch result {
                        case .success(let response):
                            let fetchResult = FetchResult(objectID: response, isInitialLocalResult: false)
                            completion?(.success(fetchResult))
                        case .failure(let error):
                            completion?(.failure(error))
                        }
                    })
                    return
                }
                
                //fixes bug where revisionID fetch fails due to missing talk page
                if localTalkPage.isMissing {
                    let fetchResult = FetchResult(objectID: localTalkPage.objectID, isInitialLocalResult: false)
                    completion?(.success(fetchResult))
                    return
                }
                
                //return initial local result early to display data while API is being called
                let fetchResult = FetchResult(objectID: localTalkPage.objectID, isInitialLocalResult: true)
                completion?(.success(fetchResult))
                
                let localObjectID = localTalkPage.objectID
                let localRevisionID = localTalkPage.revisionId?.intValue
                self.fetchLatestRevisionID(endingWithRevision: localRevisionID, urlTitle: urlTitle) { (result) in
                    switch result {
                    case .success(let lastRevisionID):
                        //if latest revision ID is the same return local talk page. else forward revision ID onto talk page fetcher
                        if localRevisionID == lastRevisionID {
                            let fetchResult = FetchResult(objectID: localObjectID, isInitialLocalResult: false)
                            completion?(.success(fetchResult))
                        } else {
                            self.fetchAndUpdateLocalTalkPage(with: localObjectID, revisionID: lastRevisionID, completion: { (result) in
                                switch result {
                                case .success(let response):
                                    let fetchResult = FetchResult(objectID: response, isInitialLocalResult: false)
                                    completion?(.success(fetchResult))
                                case .failure(let error):
                                    completion?(.failure(error))
                                }
                            })
                        }
                    case .failure(let error):
                        completion?(.failure(error))
                    }
                }
                
            } catch {
                completion?(.failure(TalkPageError.fetchLocalTalkPageFailure))
                return
            }
        }
    }

    private var signatureIfAutoSignEnabled: String {
        return UserDefaults.standard.autoSignTalkPageDiscussions ? " ~~~~" : ""
    }
    
    func addTopic(toTalkPageWith talkPageObjectID: NSManagedObjectID, title: String, siteURL: URL, subject: String, body: String, completion: @escaping (Result<TalkPageAppendSuccessResult, Error>) -> Void) {
        
        guard let title = type.urlTitle(for: title) else {
            completion(.failure(TalkPageError.createUrlTitleStringFailure))
            return
        }
        
        let wrappedBody = "\n\n" + body + "\(signatureIfAutoSignEnabled)"
        fetcher.addTopic(to: title, siteURL: siteURL, subject: subject, body: wrappedBody) { (result) in
            switch result {
            case .success(let result):
                guard let newRevisionID = result["newrevid"] as? Int else {
                    completion(.success(.missingRevisionIDInResult))
                    return
                }
                
                self.fetchAndUpdateLocalTalkPage(with: talkPageObjectID, revisionID: newRevisionID, completion: { (result) in
                    self.moc.perform {
                        // Mark new topic as read since the user created it
                        let talkPage = self.moc.talkPage(with: talkPageObjectID)
                        let probablyNewTopic = talkPage?.topics?.sortedArray(using: [NSSortDescriptor(key: "sort", ascending: true)]).last as? TalkPageTopic
                        probablyNewTopic?.isRead = true
                        switch result {
                        case .success:
                            completion(.success(.success))
                        case .failure:
                            completion(.success(.refreshFetchFailed))
                        }
                    }
                    

                })
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func addReply(to topic: TalkPageTopic, title: String, siteURL: URL, body: String, completion: @escaping (Result<TalkPageAppendSuccessResult, Error>) -> Void) {
        
        guard let title = type.urlTitle(for: title) else {
            completion(.failure(TalkPageError.createUrlTitleStringFailure))
            return
        }

        let wrappedBody = "\n\n" + body + "\(signatureIfAutoSignEnabled)"
        let talkPageTopicID = topic.objectID
        guard let talkPageObjectID = topic.talkPage?.objectID else {
            completion(.failure(TalkPageError.topicMissingTalkPageRelationship))
            return
        }
        
        fetcher.addReply(to: topic, title: title, siteURL: siteURL, body: wrappedBody) { (result) in
            switch result {
            case .success(let result):
                guard let newRevisionID = result["newrevid"] as? Int else {
                    completion(.success(.missingRevisionIDInResult))
                    return
                }
                self.fetchAndUpdateLocalTalkPage(with: talkPageObjectID, revisionID: newRevisionID, completion: { (result) in
                    self.moc.perform {
                        // Mark updated topic as read since the user added to it
                        let topic = self.moc.talkPageTopic(with: talkPageTopicID)
                        topic?.isRead = true
                        switch result {
                        case .success:
                            completion(.success(.success))
                        case .failure:
                            completion(.success(.refreshFetchFailed))
                        }
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
    
    func fetchLatestRevisionID(endingWithRevision revisionID: Int?, urlTitle: String, completion: @escaping (Result<Int, Error>) -> Void) {
        
        guard siteURL.host != nil,
            let mediaWikiURL = Configuration.current.mediaWikiAPIURLForURL(siteURL, with: nil),
            let revisionURL = mediaWikiURL.wmf_URL(withTitle: urlTitle) else {
            completion(.failure(TalkPageError.revisionUrlCreationFailure))
            return
        }
        
        let errorHandler: (Error) -> Void = { error in
            completion(.failure(TalkPageError.fetchRevisionIDFailure))
        }
        
        let successIDHandler: (Any) -> Void = { object in
            
            let queryResults = (object as? [WMFRevisionQueryResults])?.first ?? (object as? WMFRevisionQueryResults)
            
            guard let lastRevisionId = queryResults?.revisions.first?.revisionId.intValue else {
                completion(.failure(TalkPageError.fetchRevisionIDFailure))
                return
            }
            
            completion(.success(lastRevisionId))
        }
        
        let revisionIDNumber: NSNumber? = revisionID != nil ? NSNumber(value: revisionID!) : nil
        let revisionFetcherTask = articleRevisionFetcher.fetchLatestRevisions(forArticleURL: revisionURL, resultLimit: 1, startingWithRevision: nil, endingWithRevision: revisionIDNumber, failure: errorHandler, success: successIDHandler)
        
        //todo: task tracking
        revisionFetcherTask?.resume()
    }
    
    func fetchTalkPage(revisionID: Int?, completion: @escaping ((Result<NetworkTalkPage, Error>) -> Void)) {
        guard let urlTitle = type.urlTitle(for: title) else {
            completion(.failure(TalkPageError.talkPageTitleCreationFailure))
            return
        }
        
        fetcher.fetchTalkPage(urlTitle: urlTitle, displayTitle: displayTitle, siteURL: siteURL, revisionID: revisionID, completion: completion)
    }
    
    func fetchAndCreateLocalTalkPage(with urlTitle: String, taskURL: URL, in moc: NSManagedObjectContext, completion: ((Result<NSManagedObjectID, Error>) -> Void)? = nil) {
        //If no local talk page to reference, fetch latest revision ID & latest talk page in grouped calls.
        //Update network talk page with latest revision & save to db
        
        let taskGroup = WMFTaskGroup()
        
        taskGroup.enter()
        
        var revisionID: Int?
        
        fetchLatestRevisionID(endingWithRevision: nil, urlTitle: urlTitle) { (result) in
            
            switch result {
            case .success(let resultRevisionID):
                revisionID = resultRevisionID
            case .failure:
                break
            }
            
            taskGroup.leave()
        }
        
        taskGroup.enter()
        
        var networkTalkPage: NetworkTalkPage?
        var talkPageDoesNotExist: Bool = false
        fetchTalkPage(revisionID: nil) { (result) in
            switch result {
            case .success(let resultNetworkTalkPage):
                networkTalkPage = resultNetworkTalkPage
            case .failure(let error):
                if let talkPageFetcherError = error as? TalkPageFetcherError,
                    talkPageFetcherError == .talkPageDoesNotExist {
                    talkPageDoesNotExist = true
                }
            }
            
            taskGroup.leave()
        }
        
        taskGroup.waitInBackground {
            moc.perform {
                if talkPageDoesNotExist {
                    if let newLocalTalkPage = moc.createMissingTalkPage(with: taskURL, displayTitle: self.displayTitle) {
                        completion?(.success(newLocalTalkPage.objectID))
                    } else {
                        completion?(.failure(TalkPageError.createLocalTalkPageFailure))
                    }
                } else {
                    
                    guard let revisionID = revisionID,
                        let networkTalkPage = networkTalkPage else {
                            completion?(.failure(TalkPageError.freshFetchTaskGroupFailure))
                            return
                    }
                    
                    networkTalkPage.revisionId = revisionID
                    if let newLocalTalkPage = moc.createTalkPage(with: networkTalkPage) {
                        completion?(.success(newLocalTalkPage.objectID))
                    } else {
                        completion?(.failure(TalkPageError.createLocalTalkPageFailure))
                    }
                }
            }
        }
    }
    
    func fetchAndUpdateLocalTalkPage(with moid: NSManagedObjectID, revisionID: Int, completion: ((Result<NSManagedObjectID, Error>) -> Void)? = nil) {
        fetchTalkPage(revisionID: revisionID) { (result) in
            self.moc.perform {
                do {
                    guard let localTalkPage = try self.moc.existingObject(with: moid) as? TalkPage else {
                        completion?(.failure(TalkPageError.fetchLocalTalkPageFailure))
                        return
                    }
                    
                    switch result {
                    case .success(let networkTalkPage):
                        assert(networkTalkPage.revisionId != nil, "Expecting network talk page to have a revision ID here so it can pass it into the local talk page.")
                        if let updatedLocalTalkPageID = self.moc.updateTalkPage(localTalkPage, with: networkTalkPage)?.objectID {
                            completion?(.success(updatedLocalTalkPageID))
                        } else {
                            completion?(.failure(TalkPageError.updateLocalTalkPageFailure))
                        }
                    case .failure(let error):
                        completion?(.failure(error))
                    }
                    
                } catch {
                    completion?(.failure(TalkPageError.fetchLocalTalkPageFailure))
                }
            }
        }
    }
}

extension TalkPage {
    var isMissing: Bool {
        return revisionId == nil
    }
    
    func userDidAccess() {
        dateAccessed = Date()
    }
}
