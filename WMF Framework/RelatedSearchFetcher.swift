import Foundation

@objc(WMFRelatedSearchFetcher)
final class RelatedSearchFetcher: Fetcher {
    private struct RelatedPages: Decodable {
        let pages: [ArticleSummary]?
    }
    
    @objc func fetchRelatedArticles(forArticleWithURL articleURL: URL?, completion: @escaping (Error?, [WMFInMemoryURLKey: ArticleSummary]?) -> Void) {
        guard
            let articleURL = articleURL,
            let articleTitle = articleURL.percentEncodedPageTitleForPathComponents
        else {
            completion(Fetcher.invalidParametersError, nil)
            return
        }

        let pathComponents = ["page", "related", articleTitle]
        guard let taskURL = configuration.pageContentServiceAPIURLForURL(articleURL, appending: pathComponents) else {
            completion(Fetcher.invalidParametersError, nil)
            return
        }
        session.jsonDecodableTask(with: taskURL) { (relatedPages: RelatedPages?, response, error) in
            if let error = error {
                completion(error, nil)
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                completion(Fetcher.unexpectedResponseError, nil)
                return
            }
            
            guard response.statusCode == 200 else {
                let error = response.statusCode == 302 ? Fetcher.noNewDataError : Fetcher.unexpectedResponseError
                completion(error, nil)
                return
            }
            

            guard let summaries = relatedPages?.pages, summaries.count > 0 else {
                completion(Fetcher.unexpectedResponseError, nil)
                return
            }
            
            let summaryKeysWithValues: [(WMFInMemoryURLKey, ArticleSummary)] = summaries.compactMap { (summary) -> (WMFInMemoryURLKey, ArticleSummary)? in
                summary.languageVariantCode = articleURL.wmf_languageVariantCode
                guard let articleKey = summary.key else {
                    return nil
                }
                return (articleKey, summary)
            }
            
            completion(nil, Dictionary(uniqueKeysWithValues: summaryKeysWithValues))
        }
    }
}
