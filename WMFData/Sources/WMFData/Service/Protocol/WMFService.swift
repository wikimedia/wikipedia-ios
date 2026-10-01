import Foundation

// Sendable: service instances are shared across concurrency domains by design —
// data controllers hold them and invoke them from arbitrary tasks and queues.
public protocol WMFService: Sendable {
    // Completions are @Sendable: implementations invoke them from URLSession's
    // delegate queue, so they cross a concurrency boundary by construction.
    func perform<R: WMFServiceRequest>(request: R, completion: @escaping @Sendable (Result<Data, Error>) -> Void)
    func perform<R: WMFServiceRequest>(request: R, completion: @escaping @Sendable (Result<[String: Any]?, Error>) -> Void)
    func performDecodableGET<R: WMFServiceRequest, T: Decodable & Sendable>(request: R, completion: @escaping @Sendable (Result<T, Error>) -> Void)
    func performDecodablePOST<R: WMFServiceRequest, T: Decodable & Sendable>(request: R, completion: @escaping @Sendable (Result<T, Error>) -> Void)
    func clearCachedData()
}
