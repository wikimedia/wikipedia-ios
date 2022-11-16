import Foundation

public final class PageIDToURLFetcher: Fetcher {
    
    private let maxNumPageIDs = 50
    
    /// Fetches equivalent page URLs for every pageID passed in. Automatically makes additional calls if number of pageIDs is greater than API maximum (50).
    public func fetchPageURLs(_ siteURL: URL, pageIDs: [Int], failure: @escaping WMFErrorHandler, success: @escaping ([URL]) -> Void) {

        guard !pageIDs.isEmpty else {
            failure(RequestError.invalidParameters)
            return
        }

        let pageIDChunks = pageIDs.chunked(into: maxNumPageIDs)

        var finalURLs: [URL] = []
        var errors: [Error] = []

        let group = DispatchGroup()

        for pageIDChunk in pageIDChunks {

            group.enter()
            fetchMaximumPageURLs(siteURL, pageIDs: pageIDChunk) { error in
                DispatchQueue.main.async {
                    errors.append(error)
                    group.leave()
                }
            } success: { urls in
                DispatchQueue.main.async {
                    finalURLs.append(contentsOf: urls)
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            if let error = errors.first {
                failure(error)
            } else if finalURLs.isEmpty {
                failure(RequestError.unexpectedResponse)
            } else {
                success(finalURLs)
            }
        }

    }

    /// Fetches equivalent page URLs for every pageID passed in. Maximum of 50 page IDs allowed. Use fetchPageURLs(siteURL:pageID:failure:success) method if requesting > 50 pageIDs.
    private func fetchMaximumPageURLs(_ siteURL: URL, pageIDs: [Int], failure: @escaping WMFErrorHandler, success: @escaping ([URL]) -> Void) {
        
        guard pageIDs.count <= maxNumPageIDs else {
            failure(RequestError.invalidParameters)
            return
        }

        var params: [String: AnyObject] = [
            "action": "query" as AnyObject,
            "prop": "info" as AnyObject,
            "inprop": "url" as AnyObject,
            "format": "json" as AnyObject
        ]

        let stringPageIDs = pageIDs.map { String($0) }
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

            guard let query = result["query"] as? [String: Any],
                  let pages = query["pages"] as? [String: AnyObject] else {
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
