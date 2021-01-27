import Foundation

@objc(WMFRandomArticleFetcher)
public final class RandomArticleFetcher: Fetcher {
    @objc public func fetchRandomArticle(withSiteURL siteURL: URL, completion: @escaping (Error?, URL?, ArticleSummary?) -> Void) {
        let pathComponents = ["page", "random", "summary"]
        guard let taskURL = configuration.pageContentServiceAPIURLForURL(siteURL, appending: pathComponents) else {
            completion(Fetcher.invalidParametersError, nil, nil)
            return
        }
        session.jsonDecodableTask(with: taskURL) { (summary: ArticleSummary?, response, error) in
            if let error = error {
                completion(error, nil, nil)
                return
            }
            guard var articleURL = summary?.articleURL else {
                completion(Fetcher.unexpectedResponseError, nil, nil)
                return
            }
            // Temporary shim until ArticleSummary propagates language variants.
            // Ensures Random cards display content when variants are turned on.
            articleURL.wmf_languageVariantCode = siteURL.wmf_languageVariantCode
            completion(nil, articleURL, summary)
        }
    }
}
