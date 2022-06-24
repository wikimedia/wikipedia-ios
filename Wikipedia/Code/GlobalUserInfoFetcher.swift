import Foundation

enum GlobalUserInfoFetcherError: Error {
    case cannotExtractMergedGroups
    case unableToFindEditCount
}

class GlobalUserInfoFetcher: Fetcher {
    
    func fetchEditCount(guiUser: String, siteURL: URL, completion: @escaping ((Result<Int, Error>) -> Void)) {
        
        let parameters = [
            "action": "query",
            "meta": "globaluserinfo",
            "guiuser": guiUser,
            "guiprop": "groups|merged|unattached",
            "format": "json"
        ]
        
        performMediaWikiAPIGET(for: siteURL, with: parameters, cancellationKey: nil) { (result, response, error) in
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard
                let query = result?["query"] as? [String : Any],
                let userinfo = query["globaluserinfo"] as? [String : Any],
                let merged = userinfo["merged"] as? [[String: Any]] else {
                    completion(.failure(GlobalUserInfoFetcherError.cannotExtractMergedGroups))
                    return
            }
            
            for dict in merged {
                if let responseURLString = dict["url"] as? String,
                    let responseURL = URL(string: responseURLString),
                    siteURL == responseURL,
                    let editCount = dict["editcount"] as? Int {
                    
                    completion(.success(editCount))
                    return
                }
            }
            
            completion(.failure(GlobalUserInfoFetcherError.unableToFindEditCount))
        }
    }
}
