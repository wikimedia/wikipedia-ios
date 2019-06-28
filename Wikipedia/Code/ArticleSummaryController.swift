import Foundation

@objc(WMFArticleSummaryController)
public class ArticleSummaryController: NSObject {
    let fetcher: ArticleSummaryFetcher
    weak var dataStore: MWKDataStore?
    
    @objc required init(fetcher: ArticleSummaryFetcher, dataStore: MWKDataStore) {
        self.dataStore = dataStore
        self.fetcher = fetcher
    }
    
    public func updateOrCreateArticleSummaryForArticle(withURL articleURL: URL, completion: ((WMFArticle?, Error?) -> Void)? = nil) {
        updateOrCreateArticleSummariesForArticles(withURLs: [articleURL], completion: { (byKey, error) in
            completion?(byKey.first?.value, error)
        })
    }
    
    public func updateOrCreateArticleSummariesForArticles(withURLs articleURLs: [URL], completion: (([String: WMFArticle], Error?) -> Void)? = nil) {
        guard let moc = dataStore?.viewContext else {
            completion?([:], RequestError.invalidParameters)
            return
        }
        fetcher.fetchArticleSummaryResponsesForArticles(withURLs: articleURLs) { (summaryResponses) in
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
}
