
import Foundation

enum DiffFetcherError: Error {
    case failureParsingRevisions
}

class DiffFetcher: Fetcher {
    
    enum SingleRevisionRequestDirection: String {
        case older
        case newer
    }
    
    func fetchDiff(fromRevisionId: Int, toRevisionId: Int, siteURL: URL, completion: @escaping ((Result<DiffResponse, Error>) -> Void)) {
        
        guard let url = compareURL(fromRevisionId: fromRevisionId, toRevisionId: toRevisionId, siteURL: siteURL) else {
            completion(.failure(DiffError.generateUrlFailure))
            return
        }
        
        session.jsonDecodableTask(with: url) { (result: DiffResponse?, urlResponse: URLResponse?, error: Error?) in
            
            guard let result = result else {
                completion(.failure(DiffError.missingDiffResponseFailure))
                return
            }
            
            guard let _ = urlResponse else {
                completion(.failure(DiffError.missingUrlResponseFailure))
                return
            }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            completion(.success(result))
        }
    }
    
    private func compareURL(fromRevisionId: Int, toRevisionId: Int, siteURL: URL) -> URL? {
        
        guard let host = siteURL.host else {
            return nil
        }

        var pathComponents = ["v1", "revision"]
        pathComponents.append("\(fromRevisionId)")
        pathComponents.append("compare")
        pathComponents.append("\(toRevisionId)")
        let components = configuration.mediaWikiRestAPIURLForHost(host, appending: pathComponents)
        return components.url
    }
    
    func fetchSingleRevisionInfo(_ siteURL: URL, sourceRevision: WMFPageHistoryRevision, title: String, direction: SingleRevisionRequestDirection, completion: @escaping ((Result<WMFPageHistoryRevision, Error>) -> Void)) -> Void {
        let parameters: [String: Any] = [
            "action": "query",
            "prop": "revisions",
            "rvprop": "ids|timestamp|user|size|parsedcomment|flags",
            "rvlimit": 2,
            "rvdir": direction.rawValue,
            "titles": title,
            "rvstartid": sourceRevision.revisionID,
            "format": "json"
        ]
        
        performMediaWikiAPIGET(for: siteURL, with: parameters, cancellationKey: nil) { (result, response, error) in
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard
                let query = result?["query"] as? [String : Any],
                let pages = query["pages"] as? [String : Any] else {
                    completion(.failure(DiffFetcherError.failureParsingRevisions))
                    return
            }
            
            for (_, value) in pages {
                
                guard let value = value as? [String: Any] else {
                    completion(.failure(DiffFetcherError.failureParsingRevisions))
                    return
                }
                
                let transformer = MTLJSONAdapter.arrayTransformer(withModelClass: WMFPageHistoryRevision.self)
                
                guard let val = value["revisions"],
                    let revisions = transformer?.transformedValue(val) as? [WMFPageHistoryRevision] else {
                    completion(.failure(DiffFetcherError.failureParsingRevisions))
                    return
                }
                
                let filteredRevisions = revisions.filter { $0.revisionID != sourceRevision.revisionID }
                guard let singleRevision = filteredRevisions.first else {
                                                                completion(.failure(DiffFetcherError.failureParsingRevisions))
                                                                return
                }
                
                completion(.success(singleRevision))
                return
            }
            
            completion(.failure(DiffFetcherError.failureParsingRevisions))
        }
    }
}
