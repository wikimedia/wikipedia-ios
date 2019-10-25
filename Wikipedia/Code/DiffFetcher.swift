
import Foundation

class DiffFetcher: Fetcher {
    
    func fetchDiff(fromRevisionId: Int, toRevisionId: Int, completion: @escaping ((Result<Diff, Error>) -> Void)) {
        
        guard let url = compareURL(fromRevisionId: fromRevisionId, toRevisionId: toRevisionId) else {
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
            
            completion(.success(result.diff))
        }
    }
    
    private func compareURL(fromRevisionId: Int, toRevisionId: Int) -> URL? {

        var pathComponents = ["v1", "revision"]
        pathComponents.append("\(fromRevisionId)")
        pathComponents.append("compare")
        pathComponents.append("\(toRevisionId)")
        let components = configuration.mediaWikiRestAPIURLForHost("en.wikipedia.beta.wmflabs.org", appending: pathComponents)
        return components.url
    }
}
