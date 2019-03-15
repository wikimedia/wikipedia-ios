import Foundation

@objc(WMFRelatedSearchFetcher)
final class RelatedSearchFetcher: Fetcher {
    @objc func fetchRelatedArticles(forArticleWithURL articleURL: URL?, completion: @escaping (Error?, ArticleSummariesByKey?) -> Void) {
        guard
            let articleURL = articleURL,
            let articleTitle = articleURL.wmf_titleWithUnderscores?.addingPercentEncoding(withAllowedCharacters: .wmf_articleTitlePathComponentAllowed)
        else {
            completion(Fetcher.invalidParametersError, nil)
            return
        }

        let pathComponents = ["page", "related", articleTitle]
        guard let taskURL = configuration.wikipediaMobileAppsServicesAPIURLComponentsForHost(articleURL.host, appending: pathComponents).url else {
            completion(Fetcher.invalidParametersError, nil)
            return
        }
        
        session.getJSONDictionary(from: taskURL) { (result, response, error) in
            if let error = error {
                completion(error, nil)
                return
            }

            guard let response = response else {
                completion(Fetcher.unexpectedResponseError, nil)
                return
            }

            guard response.statusCode == 200 else {
                let error = response.statusCode == 302 ? Fetcher.noNewDataError : Fetcher.unexpectedResponseError
                completion(error, nil)
                return
            }

            guard let summaries = result?["pages"] as? [[String: Any]] else {
                completion(Fetcher.unexpectedResponseError, nil)
                return
            }
            
            completion(nil, summaries.articleSummariesByKey)
        }
    }
}
