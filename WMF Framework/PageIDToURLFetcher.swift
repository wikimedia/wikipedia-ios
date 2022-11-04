import Foundation

public final class PageIDToURLFetcher: Fetcher {
    public func fetchPageURLs(_ siteURL: URL, pageIDs: [Int], failure: @escaping WMFErrorHandler, success: @escaping ([URL]) -> Void) {
        var params: [String: AnyObject] = [
            "action": "query" as AnyObject,
            "prop": "info" as AnyObject,
            "inprop": "url" as AnyObject,
            "format": "json" as AnyObject
        ]
        
        let stringPageIDs = pageIDs.map { String($0) }
        // TODO: is there a max number of these?
        params["pageids"] = stringPageIDs.joined(separator: "|") as AnyObject
        
        performMediaWikiAPIGET(for: siteURL, with: params, cancellationKey: nil) { (result, response, error) in
            if let error = error {
                failure(error)
                return
            }
            guard let result = result else {
                failure(RequestError.unexpectedResponse)
                return
            }
            
            guard let query = result["query"] as? [String: Any], let pages = query["pages"] as? [String: AnyObject] else {
                failure(RequestError.unexpectedResponse)
                return
            }
            
            var finalURLs: [URL] = []
            for (_, value) in pages {
                guard let fullURLString = value["fullurl"] as? String,
                        let url = URL(string: fullURLString) else {
                    continue
                }
                finalURLs.append(url)
            }
            
            success(finalURLs)
        }
    }
}
