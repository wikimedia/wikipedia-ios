
import Foundation

class DiffFetcher: Fetcher {
    
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
}
