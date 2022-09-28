import Foundation
import WMF

/// Class that coordinates network fetches for talk pages.
/// Leans on file persistence for offline mode as-needed.
class TalkPageDataController {
    
    private let pageType: TalkPageType
    private let pageTitle: String
    private let siteURL: URL
    private let talkPageFetcher = TalkPageFetcher()
    private let articleSummaryController: ArticleSummaryController
    
    init(pageType: TalkPageType, pageTitle: String, siteURL: URL, articleSummaryController: ArticleSummaryController) {
        self.pageType = pageType
        self.pageTitle = pageTitle
        self.siteURL = siteURL
        self.articleSummaryController = articleSummaryController
    }
    
    // MARK: Public
    
    typealias TalkPageResult = Result<(articleSummary: WMFArticle?, items: [TalkPageItem], subscribedTopicNames: [String]), Error>
    
    func fetchTalkPage(completion: @escaping (TalkPageResult) -> Void) {
        
        assert(Thread.isMainThread)

        let group = DispatchGroup()
        
        var finalErrors: [Error] = []
        var finalItems: [TalkPageItem] = []
        var finalArticleSummary: WMFArticle?
        var finalSubscribedTopics: [String] = []
        
        fetchTalkPageItems(dispatchGroup: group) { items, errors in
            finalItems = items
            finalErrors.append(contentsOf: errors)
        }
        
        fetchArticleSummaryIfNeeded(dispatchGroup: group) { articleSummary, errors in
            finalArticleSummary = articleSummary
            finalErrors.append(contentsOf: errors)
        }
        
        
        group.notify(queue: DispatchQueue.main, execute: {
            
            if let firstError = finalErrors.first {
                completion(.failure(firstError))
                return
            }
            self.fetchTopicSubscriptions(for: finalItems, dispatchGroup: group) { items, errors in
                finalSubscribedTopics = items
                finalErrors.append(contentsOf: errors)
                completion(.success((finalArticleSummary, finalItems, finalSubscribedTopics)))
            }
            
        })

    }
    
    func postReply(commentId: String, comment: String, completion: @escaping(Result<Void, Error>) -> Void) {
        
        talkPageFetcher.postReply(talkPageTitle: pageTitle, siteURL: siteURL, commentId: commentId, comment: comment.signed) { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    func postTopic(topicTitle: String, topicBody: String, completion: @escaping(Result<Void, Error>) -> Void) {
        
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

    private func fetchTalkPageItems(dispatchGroup group: DispatchGroup, completion: @escaping ([TalkPageItem], [Error]) -> Void) {
        
        let sharedCache = SharedContainerCache<TalkPageCache>.init(pathComponent: .talkPageCache, defaultCache: {
            TalkPageCache(talkPages: [])
        })
        var cache = sharedCache.loadCache(for: pageTitle.replacingOccurrences(of: ":", with: " "))
        
        group.enter()
        talkPageFetcher.fetchTalkPageContent(talkPageTitle: pageTitle, siteURL: siteURL) { result in
            DispatchQueue.main.async {
                
                defer {
                    group.leave()
                }
                
                switch result {
                case .success(let items):
                    cache.talkPages = items
                    sharedCache.saveCache(to: self.pageTitle.replacingOccurrences(of: ":", with: " "), cache)
                    completion(items, [])
                case .failure(let error):
                    completion([], [error])
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
}

private extension String {
    var signed: String {
        return UserDefaults.standard.autoSignTalkPageDiscussions ? self + " ~~~~" : self
    }
}
