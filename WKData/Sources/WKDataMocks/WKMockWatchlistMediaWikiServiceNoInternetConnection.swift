import Foundation
import WKData

#if DEBUG

public class WKMockWatchlistMediaWikiServiceNoInternetConnection: WKService {

    public init() {
        
    }
    
    public func perform<R: WKServiceRequest>(request: R, completion: @escaping (Result<[String: Any]?, Error>) -> Void) {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        completion(.failure(error))
    }
    
    public func performDecodableGET<R: WKServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        completion(.failure(error))
    }
    
}

#endif
