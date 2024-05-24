import Foundation

public protocol WKService {
    func perform<R: WKServiceRequest>(request: R, completion: @escaping (Result<Data, Error>) -> Void)
    func perform<R: WKServiceRequest>(request: R, completion: @escaping (Result<[String: Any]?, Error>) -> Void)
    func performDecodableGET<R: WKServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void)
    func performDecodablePOST<R: WKServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void)
}
