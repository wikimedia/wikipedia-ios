import Foundation
import WMF

class WikiWrappedFetcher: Fetcher {
    
    func fetchWikiWrapped(completion: @escaping (Result<WikiWrappedAPIResponse, Error>) -> Void) {
        
        completion(.success(WikiWrappedAPIResponse.mockResponse))
    }
}
