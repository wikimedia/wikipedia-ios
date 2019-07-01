import Foundation

@objc(WMFArticleSummaryController)
public class ArticleSummaryController: NSObject {
    let fetcher: ArticleSummaryFetcher
    weak var dataStore: MWKDataStore?
    
    @objc required init(fetcher: ArticleSummaryFetcher, dataStore: MWKDataStore) {
        self.dataStore = dataStore
        self.fetcher = fetcher
    }
    
    public func updateOrCreateArticleSummaryForArticle(withKey articleKey: String, completion: ((WMFArticle?, Error?) -> Void)? = nil) {
        updateOrCreateArticleSummariesForArticles(withKeys: [articleKey], completion: { (byKey, error) in
            completion?(byKey.first?.value, error)
        })
    }
    
    public func updateOrCreateArticleSummariesForArticles(withKeys articleKeys: [String], completion: (([String: WMFArticle], Error?) -> Void)? = nil) {
        guard let moc = dataStore?.viewContext else {
            completion?([:], RequestError.invalidParameters)
            return
        }
        fetcher.fetchArticleSummaryResponsesForArticles(withKeys: articleKeys) { (summaryResponses) in
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
