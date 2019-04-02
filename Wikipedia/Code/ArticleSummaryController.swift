import Foundation

@objc(WMFArticleSummaryController)
public class ArticleSummaryController: NSObject {
    let fetcher: ArticleSummaryFetcher
    weak var dataStore: MWKDataStore?
    
    @objc required init(fetcher: ArticleSummaryFetcher, dataStore: MWKDataStore) {
        self.dataStore = dataStore
        self.fetcher = fetcher
    }
    
    public func updateOrCreateArticleSummariesForArticles(withURLs articleURLs: [URL], completion: (([WMFArticle], Error?) -> Void)? = nil) {
        guard let moc = dataStore?.viewContext else {
            completion?([], RequestError.invalidParameters)
            return
        }
        fetcher.fetchArticleSummaryResponsesForArticles(withURLs: articleURLs) { (summaryResponses) in
            moc.perform {
                do {
                    let articles = try moc.wmf_createOrUpdateArticleSummmaries(withSummaryResponses: summaryResponses)
                    completion?(articles, nil)
                } catch let error {
                    DDLogError("Error fetching article summary responses: \(error.localizedDescription)")
                    completion?([], error)
                }
            }
        }
    }
}
