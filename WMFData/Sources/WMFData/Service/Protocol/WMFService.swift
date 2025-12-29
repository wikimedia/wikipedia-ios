import Foundation

public protocol WMFService: Sendable {
    func perform<R: WMFServiceRequest>(request: R, completion: @escaping @Sendable (Result<Data, Error>) -> Void)
    func perform<R: WMFServiceRequest>(request: R, completion: @escaping @Sendable (Result<[String: Any]?, Error>) -> Void)
    func performDecodableGET<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping @Sendable (Result<T, Error>) -> Void)
    func performDecodablePOST<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping @Sendable (Result<T, Error>) -> Void)
    func clearCachedData()
}
