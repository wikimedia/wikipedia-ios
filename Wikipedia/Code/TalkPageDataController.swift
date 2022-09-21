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
    
    typealias TalkPageResult = Result<(articleSummary: WMFArticle?, items: [TalkPageItem]), Error>
    
    func fetchTalkPage(completion: @escaping (TalkPageResult) -> Void) {
        
        assert(Thread.isMainThread)

        let group = DispatchGroup()
        
        var finalErrors: [Error] = []
        var finalItems: [TalkPageItem] = []
        var finalArticleSummary: WMFArticle?
        
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

            completion(.success((finalArticleSummary, finalItems)))
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
        talkPageFetcher.subscribeToTopic(talkPageTitle: pageTitle, siteURL: siteURL, topic: topicName, shouldSubscribe: shouldSubscribe, completion: completion)
    }
    
    func fetchSubscriptions(for topics: [String], completion: @escaping (Result<[String], Error>) -> Void) {
        talkPageFetcher.getSubscribedTopics(siteURL: siteURL, topics: topics) { result in
            switch result {
            case let .success(result):
                completion(.success(result))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: Private
    
    private func fetchTalkPageItems(dispatchGroup group: DispatchGroup, completion: @escaping ([TalkPageItem], [Error]) -> Void) {
        
        let sharedCache = SharedContainerCache<TalkPageCache>.init(pathComponent: .talkPageCache, defaultCache: {
            TalkPageCache(talkPages: [])
        })
        var cache = sharedCache.loadCache()
        
        group.enter()
        talkPageFetcher.fetchTalkPageContent(talkPageTitle: pageTitle, siteURL: siteURL) { result in
            DispatchQueue.main.async {
                
                defer {
                    group.leave()
                }
                
                switch result {
                case .success(let items):
                    cache.talkPages.insert(items)
                    sharedCache.saveCache(to: self.pageTitle, cache)
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
