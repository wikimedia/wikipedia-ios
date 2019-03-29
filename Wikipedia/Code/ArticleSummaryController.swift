import Foundation

@objc(WMFArticleSummaryController)
public class ArticleSummaryController: NSObject {
    let fetcher: ArticleSummaryFetcher
    weak var dataStore: MWKDataStore?
    
    @objc required init(fetcher: ArticleSummaryFetcher, dataStore: MWKDataStore) {
        self.dataStore = dataStore
        self.fetcher = fetcher
    }
    
    public func updateOrCreateArticleSummariesForArticles(withURLs articleURLs: [URL], failure: ((Error) -> Void)? = nil, finally: (() -> Void)? = nil, success: (([WMFArticle]) -> Void)? = nil) {
        defer {
            finally?()
        }
        guard let moc = dataStore?.viewContext else {
            failure?(RequestError.invalidParameters)
            return
        }
        fetcher.fetchArticleSummaryResponsesForArticles(withURLs: articleURLs) { (summaryResponses) in
            moc.perform {
                do {
                    let articles = try moc.wmf_createOrUpdateArticleSummmaries(withSummaryResponses: summaryResponses)
                    success?(articles)
                } catch let error {
                    DDLogError("Error fetching saved articles: \(error.localizedDescription)")
                    failure?(error)
                }
            }
        }
    }
}
