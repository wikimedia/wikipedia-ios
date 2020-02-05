import Foundation

@objc(WMFArticleSummaryController)
public class ArticleSummaryController: NSObject {
    @objc public let fetcher: ArticleSummaryFetcher
    weak var dataStore: MWKDataStore?
    
    @objc required init(fetcher: ArticleSummaryFetcher, dataStore: MWKDataStore) {
        self.dataStore = dataStore
        self.fetcher = fetcher
    }
    
    @discardableResult public func updateOrCreateArticleSummaryForArticle(withKey articleKey: String, completion: ((WMFArticle?, Error?) -> Void)? = nil) -> URLSessionTask? {
        return fetcher.fetchSummaryForArticle(with: articleKey) { [weak self] (articleSummary, urlResponse, error) in
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
    
    @discardableResult public func updateOrCreateArticleSummariesForArticles(withKeys articleKeys: [String], completion: (([String: WMFArticle], Error?) -> Void)? = nil) -> [URLSessionTask] {

        return fetcher.fetchArticleSummaryResponsesForArticles(withKeys: articleKeys) { [weak self] (summaryResponses) in
            DispatchQueue.main.async {
                self?.processSummaryResponses(with: summaryResponses, completion: completion)
            }
        }
    }
    
    private func processSummaryResponses(with summaryResponses: [String: ArticleSummary], completion: (([String: WMFArticle], Error?) -> Void)? = nil) {
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
