import Foundation
import WMFData

#if DEBUG

public final class WMFMockServiceNoInternetConnection: WMFService {

    public init() {
        
    }
    
    public func perform<R: WMFServiceRequest>(request: R, completion: @escaping @Sendable (Result<Data, any Error>) -> Void) {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        completion(.failure(error))
    }
    
    public func perform<R: WMFServiceRequest>(request: R, completion: @escaping @Sendable (Result<[String: Any]?, Error>) -> Void) {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        completion(.failure(error))
    }
    
    public func performDecodableGET<R: WMFServiceRequest, T: Decodable & Sendable>(request: R, completion: @escaping @Sendable (Result<T, Error>) -> Void) {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        completion(.failure(error))
    }
    
    public func performDecodablePOST<R, T>(request: R, completion: @escaping @Sendable (Result<T, Error>) -> Void) where R : WMFData.WMFServiceRequest, T : Decodable {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        completion(.failure(error))
    }
    
    public func clearCachedData() {
        // no-op
    }
    
}

#endif
