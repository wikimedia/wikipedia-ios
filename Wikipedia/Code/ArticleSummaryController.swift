import Foundation
import CocoaLumberjackSwift

@objc(WMFArticleSummaryController)
public class ArticleSummaryController: NSObject {
    private let fetcher: ArticleFetcher
    weak var dataStore: MWKDataStore?
    
    @objc required init(session: Session, configuration: Configuration, dataStore: MWKDataStore) {
        self.dataStore = dataStore
        self.fetcher = ArticleFetcher(session: session, configuration: configuration)
    }
    
    @discardableResult public func updateOrCreateArticleSummaryForArticle(withKey articleKey: WMFInMemoryURLKey, cachePolicy: URLRequest.CachePolicy? = nil, completion: ((WMFArticle?, Error?) -> Void)? = nil) -> URLSessionTask? {
        return fetcher.fetchSummaryForArticle(with: articleKey, cachePolicy: cachePolicy) { [weak self] (articleSummary, urlResponse, error) in
            DispatchQueue.main.async {
                guard let articleSummary = articleSummary,
                    error == nil else {
                    completion?(nil, error)
                    return
                }
                self?.processSummaryResponses(with: [articleKey: articleSummary]) { (result, error) in
                    completion?(result[articleKey], error)
                }
            }
        }
    }
    
    @discardableResult public func updateOrCreateArticleSummariesForArticles(withKeys articleKeys: [WMFInMemoryURLKey], cachePolicy: URLRequest.CachePolicy? = nil, completion: (([WMFInMemoryURLKey: WMFArticle], Error?) -> Void)? = nil) -> [URLSessionTask] {

        return fetcher.fetchArticleSummaryResponsesForArticles(withKeys: articleKeys, cachePolicy: cachePolicy) { [weak self] (summaryResponses) in
            DispatchQueue.main.async {
                self?.processSummaryResponses(with: summaryResponses, completion: completion)
            }
        }
    }
    
    private func processSummaryResponses(with summaryResponses: [WMFInMemoryURLKey: ArticleSummary], completion: (([WMFInMemoryURLKey: WMFArticle], Error?) -> Void)? = nil) {
        guard let moc = dataStore?.viewContext else {
            completion?([:], RequestError.invalidParameters)
            return
        }
        
        moc.perform {
            do {
                let articles = try moc.wmf_createOrUpdateArticleSummmaries(withSummaryResponses: summaryResponses)
                completion?(articles, nil)
            } catch let error {
                DDLogError("Error fetching article summary responses: \(error.localizedDescription)")
                completion?([:], error)
            }
        }
    }
}
