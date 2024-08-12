import Foundation

public protocol WMFService {
    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<Data, Error>) -> Void)
    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<[String: Any]?, Error>) -> Void)
    func performDecodableGET<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void)
    func performDecodablePOST<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void)
}
