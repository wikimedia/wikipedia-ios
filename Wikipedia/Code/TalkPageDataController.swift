import Foundation
import WMF
import CocoaLumberjackSwift

/// Class that coordinates network fetches for talk pages.
/// Leans on file persistence for offline mode as-needed.
class TalkPageDataController {
    
    private let pageType: TalkPageType
    private(set) var pageTitle: String
    private(set) var siteURL: URL
    private let talkPageFetcher = TalkPageFetcher()
    let articleSummaryController: ArticleSummaryController
    private let articleRevisionFetcher = WMFArticleRevisionFetcher()

    init(pageType: TalkPageType, pageTitle: String, siteURL: URL, articleSummaryController: ArticleSummaryController) {
        self.pageType = pageType
        self.pageTitle = pageTitle
        self.siteURL = siteURL
        self.articleSummaryController = articleSummaryController
    }
    
    func resetToNewSiteURL(_ siteURL: URL, pageTitle: String) {
        self.siteURL = siteURL
        self.pageTitle = pageTitle
    }
    
    enum TalkPageError: Error {
        case unableToDetermineWikimediaProject
    }
    
    // MARK: Public
    
    typealias TalkPageResult = Result<(articleSummary: WMFArticle?, items: [TalkPageItem], subscribedTopicNames: [String], latestRevisionID: Int?), Error>
    
    func fetchTalkPage(completion: @escaping (TalkPageResult) -> Void) {
        
        assert(Thread.isMainThread)

        let group = DispatchGroup()
        
        var finalErrors: [Error] = []
        var finalItems: [TalkPageItem] = []
        var finalArticleSummary: WMFArticle?
        var latestRevisionID: Int?
        var finalSubscribedTopics: [String] = []
        
        fetchTalkPageItems(dispatchGroup: group) { items, errors in
            finalItems = items
            finalErrors.append(contentsOf: errors)
        }
        
        fetchArticleSummaryIfNeeded(dispatchGroup: group) { articleSummary, errors in
            finalArticleSummary = articleSummary
            if errors.count > 0 {
                DDLogError("Error fetching article summary for talk page header. Ignoring.")
            }
        }
        
        fetchLatestRevisionID(dispatchGroup: group) { revisionID in
            latestRevisionID = revisionID
        }
        
        group.notify(queue: DispatchQueue.main, execute: {
            
            if let firstError = finalErrors.first, finalItems.isEmpty {
                completion(.failure(firstError))
                return
            }
            self.fetchTopicSubscriptions(for: finalItems, dispatchGroup: group) { items, errors in
                finalSubscribedTopics = items
                finalErrors.append(contentsOf: errors)
                completion(.success((finalArticleSummary, finalItems, finalSubscribedTopics, latestRevisionID)))
            }
        })

    }
    
    func postReply(commentId: String, comment: String, completion: @escaping (Result<Void, Error>) -> Void) {
        
        talkPageFetcher.postReply(talkPageTitle: pageTitle, siteURL: siteURL, commentId: commentId, comment: comment.signed) { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    func postTopic(topicTitle: String, topicBody: String, completion: @escaping (Result<Void, Error>) -> Void) {
        
        talkPageFetcher.postTopic(talkPageTitle: pageTitle, siteURL: siteURL, topicTitle: topicTitle, topicBody: topicBody.signed) { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    func subscribeToTopic(topicName: String, shouldSubscribe: Bool, completion: @escaping (Result<Bool, Error>) -> Void) {
        
        talkPageFetcher.subscribeToTopic(talkPageTitle: pageTitle, siteURL: siteURL, topic: topicName, shouldSubscribe: shouldSubscribe) { result in 
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    // MARK: Private
    
    private func fetchTopicSubscriptions(for items: [TalkPageItem], dispatchGroup group: DispatchGroup, completion: @escaping  ([String], [Error]) -> Void) {
        
        var topicNames = [String]()
        for item in items {
            if let itemName = item.name {
                topicNames.append(itemName)
            }
        }

        talkPageFetcher.getSubscribedTopics(siteURL: siteURL, topics: topicNames) { result in
            DispatchQueue.main.async {
                switch result {
                case let .success(result):
                    completion(result, [])
                case let .failure(error):
                    completion([], [error])
                }
            }
        }
    }

    private func cachedFileName() -> String {
        let host = siteURL.host ?? ""
        let fileNameSuffix = pageTitle

        let fileNamePrefix: String
        if let languageVariantCode = siteURL.wmf_languageVariantCode {
            fileNamePrefix = "\(host)-\(languageVariantCode)"
        } else {
            fileNamePrefix = host
        }

        let unencodedFileName = "\(fileNamePrefix)-\(fileNameSuffix)"
        return unencodedFileName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? unencodedFileName
    }

    private func fetchTalkPageItems(dispatchGroup group: DispatchGroup, completion: @escaping ([TalkPageItem], [Error]) -> Void) {
        
        let sharedCache = SharedContainerCache.init(fileName: cachedFileName(), subdirectoryPathComponent: SharedContainerCacheCommonNames.talkPageCache)
        var cache = sharedCache.loadCache() ?? TalkPageCache(talkPages: [])
        
        group.enter()
        talkPageFetcher.fetchTalkPageContent(talkPageTitle: pageTitle, siteURL: siteURL) { result in
            DispatchQueue.main.async {
                
                defer {
                    group.leave()
                }
                
                switch result {
                case .success(let items):
                    cache.talkPageItems = items
                    sharedCache.saveCache(cache)
                    completion(items, [])
                case .failure(let error):
                    completion(cache.talkPageItems, [error])
                }
            }
        }
    }
    
    private func fetchArticleSummaryIfNeeded(dispatchGroup group: DispatchGroup, completion: @escaping (WMFArticle?, [Error]) -> Void) {
        
        guard pageType == .article,
        let languageCode = siteURL.wmf_languageCode else {
            completion(nil, [])
            return
        }
        
        let pageTitleMinusNamespace = pageTitle.namespaceAndTitleOfWikiResourcePath(with: languageCode).title
        
        guard let mainNamespacePageURL = siteURL.wmf_URL(withTitle: pageTitleMinusNamespace),
              let inMemoryKey = mainNamespacePageURL.wmf_inMemoryKey else {
            completion(nil, [])
            return
        }
        
        group.enter()
        articleSummaryController.updateOrCreateArticleSummaryForArticle(withKey: inMemoryKey) { article, error in
            DispatchQueue.main.async {
                defer {
                    group.leave()
                }
                
                if let article = article {
                    completion(article, [])
                    return
                }
                
                if let error = error {
                    completion(nil, [error])
                    return
                }
                
                completion(nil, [])
            }
        }
    }
    
    func fetchLatestRevisionID(dispatchGroup: DispatchGroup, completion: @escaping (Int?) -> Void) {
        
        guard let mediaWikiURL = Configuration.current.mediaWikiAPIURLForURL(siteURL, with: nil),
              let revisionURL = mediaWikiURL.wmf_URL(withTitle: pageTitle) else {
            completion(nil)
            return
        }
        
        let failureBlock: (Error) -> Void = { error in
            dispatchGroup.leave()
            completion(nil)
        }
        
        let successBlock: (Any) -> Void = { object in
            
            defer {
                dispatchGroup.leave()
            }
            
            let queryResults = (object as? [WMFRevisionQueryResults])?.first ?? (object as? WMFRevisionQueryResults)
            
            guard let lastRevisionId = queryResults?.revisions.first?.revisionId.intValue else {
                completion(nil)
                return
            }
            
            completion(lastRevisionId)
        }
        
        dispatchGroup.enter()
        articleRevisionFetcher.fetchLatestRevisions(forArticleURL: revisionURL, resultLimit: 1, startingWithRevision: nil, endingWithRevision: nil, failure: failureBlock, success: successBlock)

    }
}

private extension String {
    var signed: String {
        return UserDefaults.standard.autoSignTalkPageDiscussions ? self + " ~~~~" : self
    }
}
