import Foundation

@objc(WMFFeedDidYouKnowFetcher)
public final class WMFFeedDidYouKnowFetcher: Fetcher {

    @objc public func fetchDidYouKnow(withSiteURL siteURL: URL, completion: @escaping (Error?, [WMFFeedDidYouKnow]?) -> Void) {
        let pathComponents = ["feed", "did-you-know"]
        
        guard let taskURL = configuration.feedContentAPIURLForURL(siteURL, appending: pathComponents) else {
            completion(Fetcher.invalidParametersError, nil)
            return
        }

        session.jsonDecodableTask(with: taskURL) { (facts: [WMFFeedDidYouKnow]?, response, error) in
            if let error = error {
                completion(error, nil)
                return
            }

            guard let facts else {
                completion(Fetcher.unexpectedResponseError, nil)
                return
            }

            completion(nil, facts)
        }
    }
}
