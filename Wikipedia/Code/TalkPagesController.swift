
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
    let host: String
    let languageCode: String
    let titleIncludesPrefix: Bool
    let type: TalkPageType
    
    var displayTitle: String {
        return type.displayTitle(for: title, titleIncludesPrefix: titleIncludesPrefix)
    }
    
    required init(fetcher: TalkPageFetcher = TalkPageFetcher(), articleRevisionFetcher: WMFArticleRevisionFetcher = WMFArticleRevisionFetcher(), dataStore: MWKDataStore, title: String, host: String, languageCode: String, titleIncludesPrefix: Bool, type: TalkPageType) {
        self.fetcher = fetcher
        self.articleRevisionFetcher = articleRevisionFetcher
        self.moc = dataStore.viewContext
        self.title = title
        self.host = host
        self.languageCode = languageCode
        self.titleIncludesPrefix = titleIncludesPrefix
        self.type = type
    }
    
    func fetchTalkPage(completion: ((Result<NSManagedObjectID, Error>) -> Void)? = nil) {
        guard let urlTitle = type.urlTitle(for: title, titleIncludesPrefix: titleIncludesPrefix),
            let taskURL = fetcher.taskURL(for: urlTitle, host: host) else {
            completion?(.failure(TalkPageError.createTaskURLFailure))
            return
        }
        moc.perform {
            do {
                guard let localTalkPage = try self.moc.talkPage(for: taskURL) else {
                    self.createTalkPage(with: urlTitle, taskURL: taskURL, in: self.moc, completion: { (result) in
                        DispatchQueue.main.async {
                            completion?(result)
                        }
                    })
                    return
                }
                let localObjectID = localTalkPage.objectID
                let localRevisionID = localTalkPage.revisionId?.intValue
                self.fetchLatestRevisionID(endingWithRevision: localRevisionID, urlTitle: urlTitle) { (result) in
                    switch result {
                    case .success(let lastRevisionID):
                        //if latest revision ID is the same return local talk page. else forward revision ID onto talk page fetcher
                        if localRevisionID == lastRevisionID {
                            DispatchQueue.main.async {
                                completion?(.success(localObjectID))
                            }
                        } else {
                            self.fetchAndUpdateLocalTalkPage(with: localObjectID, revisionID: lastRevisionID, completion: completion)
                        }
                    case .failure(let error):
                        DispatchQueue.main.async {
                            completion?(.failure(error))
                        }
                    }
                }
                
            } catch {
                DispatchQueue.main.async {
                    completion?(.failure(TalkPageError.fetchLocalTalkPageFailure))
                }
                return
            }
        }
    }
    
    func createTalkPage(with urlTitle: String, taskURL: URL, in moc: NSManagedObjectContext, completion: ((Result<NSManagedObjectID, Error>) -> Void)? = nil) {
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
                    if let newLocalTalkPage = moc.createEmptyTalkPage(with: taskURL, languageCode: self.languageCode, displayTitle: self.displayTitle) {
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
    
    func addTopic(toTalkPageWith talkPageObjectID: NSManagedObjectID, title: String, host: String, languageCode: String, subject: String, body: String, completion: @escaping (Result<TalkPageAppendSuccessResult, Error>) -> Void) {
        
        guard let title = type.urlTitle(for: title, titleIncludesPrefix: titleIncludesPrefix) else {
            completion(.failure(TalkPageError.createUrlTitleStringFailure))
            return
        }
        
        //todo: conditional signature
        let wrappedBody = "<p>\n\n" + body + " ~~~~</p>"
        fetcher.addTopic(to: title, host: host, languageCode: languageCode, subject: subject, body: wrappedBody) { (result) in
            switch result {
            case .success(let result):
                guard let newRevisionID = result["newrevid"] as? Int else {
                    DispatchQueue.main.async {
                        completion(.success(.missingRevisionIDInResult))
                    }
                    return
                }
                
                self.fetchAndUpdateLocalTalkPage(with: talkPageObjectID, revisionID: newRevisionID, completion: { (result) in
                    self.moc.perform {
                        // Mark new topic as read since the user created it
                        let talkPage = self.moc.talkPage(with: talkPageObjectID)
                        let probablyNewTopic = talkPage?.topics?.sortedArray(using: [NSSortDescriptor(key: "sort", ascending: true)]).last as? TalkPageTopic
                        probablyNewTopic?.isRead = true
                        DispatchQueue.main.async {
                            switch result {
                            case .success:
                                completion(.success(.success))
                            case .failure:
                                completion(.success(.refreshFetchFailed))
                            }
                        }
                    }
                    

                })
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
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
        let talkPageTopicID = topic.objectID
        guard let talkPageObjectID = topic.talkPage?.objectID else {
            DispatchQueue.main.async {
                completion(.failure(TalkPageError.topicMissingTalkPageRelationship))
            }
            return
        }
        
        fetcher.addReply(to: topic, title: title, host: host, languageCode: languageCode, body: wrappedBody) { (result) in
            switch result {
            case .success(let result):
                guard let newRevisionID = result["newrevid"] as? Int else {
                    DispatchQueue.main.async {
                        completion(.success(.missingRevisionIDInResult))
                    }
                    return
                }
                self.fetchAndUpdateLocalTalkPage(with: talkPageObjectID, revisionID: newRevisionID, completion: { (result) in
                    self.moc.perform {
                        // Mark updated topic as read since the user added to it
                        let topic = self.moc.talkPageTopic(with: talkPageTopicID)
                        topic?.isRead = true
                        DispatchQueue.main.async {
                            switch result {
                            case .success:
                                completion(.success(.success))
                            case .failure:
                                completion(.success(.refreshFetchFailed))
                            }
                        }
                    }
                    
                })
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}

//MARK: Private

private extension TalkPageController {
    
    func fetchLatestRevisionID(endingWithRevision revisionID: Int?, urlTitle: String, completion: @escaping (Result<Int, Error>) -> Void) {
        
        guard let revisionURL = Configuration.current.mediaWikiAPIURLForWikiLanguage(languageCode, with: nil).url?.wmf_URL(withTitle: urlTitle) else {
            completion(.failure(TalkPageError.revisionUrlCreationFailure))
            return
        }
        
        let errorHandler: (Error) -> Void = { error in
            completion(.failure(TalkPageError.fetchRevisionIDFailure))
        }
        
        let successIDHandler: (Any) -> Void = { object in
            
            let queryResults = (object as? [WMFRevisionQueryResults])?.first ?? (object as? WMFRevisionQueryResults)
            
            guard let lastRevisionId = queryResults?.revisions.first?.revisionId.intValue else {
                DispatchQueue.main.async {
                    completion(.failure(TalkPageError.fetchRevisionIDFailure))
                }
                return
            }
            
            completion(.success(lastRevisionId))
        }
        
        let revisionIDNumber: NSNumber? = revisionID != nil ? NSNumber(value: revisionID!) : nil
        let revisionFetcherTask = articleRevisionFetcher.fetchLatestRevisions(forArticleURL: revisionURL, resultLimit: 1, endingWithRevision: revisionIDNumber, failure: errorHandler, success: successIDHandler)
        
        //todo: task tracking
        revisionFetcherTask?.resume()
    }
    
    func fetchTalkPage(revisionID: Int?, completion: @escaping ((Result<NetworkTalkPage, Error>) -> Void)) {
        guard let urlTitle = type.urlTitle(for: title, titleIncludesPrefix: titleIncludesPrefix) else {
            completion(.failure(TalkPageError.talkPageTitleCreationFailure))
            return
        }
        
        fetcher.fetchTalkPage(urlTitle: urlTitle, displayTitle: displayTitle, host: host, languageCode: languageCode, revisionID: revisionID, completion: completion)
    }
    
    func fetchAndUpdateLocalTalkPage(with moid: NSManagedObjectID, revisionID: Int, completion: ((Result<NSManagedObjectID, Error>) -> Void)? = nil) {
        fetchTalkPage(revisionID: revisionID) { (result) in
            self.moc.perform {
                do {
                    guard let localTalkPage = try self.moc.existingObject(with: moid) as? TalkPage else {
                        DispatchQueue.main.async {
                            completion?(.failure(TalkPageError.fetchLocalTalkPageFailure))
                        }
                        return
                    }
                    
                    switch result {
                    case .success(let networkTalkPage):
                        assert(networkTalkPage.revisionId != nil, "Expecting network talk page to have a revision ID here so it can pass it into the local talk page.")
                        if let updatedLocalTalkPageID = self.moc.updateTalkPage(localTalkPage, with: networkTalkPage)?.objectID {
                            DispatchQueue.main.async {
                                completion?(.success(updatedLocalTalkPageID))
                            }
                        } else {
                            DispatchQueue.main.async {
                                completion?(.failure(TalkPageError.updateLocalTalkPageFailure))
                            }
                        }
                    case .failure(let error):
                        DispatchQueue.main.async {
                            completion?(.failure(error))
                        }
                    }
                    
                } catch {
                    DispatchQueue.main.async {
                        completion?(.failure(TalkPageError.fetchLocalTalkPageFailure))
                    }
                }
            }
        }
    }
}
