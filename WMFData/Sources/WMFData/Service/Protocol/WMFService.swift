import Foundation

// Sendable: service instances are shared across concurrency domains by design —
// data controllers hold them and invoke them from arbitrary tasks and queues.
public protocol WMFService: Sendable {
    // Completions are @Sendable: implementations invoke them from URLSession's
    // delegate queue, so they cross a concurrency boundary by construction.
    func perform<R: WMFServiceRequest>(request: R, completion: @escaping @Sendable (Result<Data, Error>) -> Void)
    func perform<R: WMFServiceRequest>(request: R, completion: @escaping @Sendable (Result<[String: Any]?, Error>) -> Void)
    func performDecodableGET<R: WMFServiceRequest, T: Decodable & Sendable>(request: R, completion: @escaping @Sendable (Result<T, Error>) -> Void)

    /// Starts a GET request and returns the task, so that the caller can stop it.
    /// A service that cannot stop a request returns nil.
    func performCancellableDecodableGET<R: WMFServiceRequest, T: Decodable & Sendable>(request: R, completion: @escaping @Sendable (Result<T, Error>) -> Void) -> WMFURLSessionDataTask?
    func performDecodablePOST<R: WMFServiceRequest, T: Decodable & Sendable>(request: R, completion: @escaping @Sendable (Result<T, Error>) -> Void)
    func clearCachedData()
}

public extension WMFService {
    /// The default starts the request and returns nil. Thus the caller cannot stop it.
    func performCancellableDecodableGET<R: WMFServiceRequest, T: Decodable & Sendable>(request: R, completion: @escaping @Sendable (Result<T, Error>) -> Void) -> WMFURLSessionDataTask? {
        performDecodableGET(request: request, completion: completion)
        return nil
    }
}
