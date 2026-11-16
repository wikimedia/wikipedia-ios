import Foundation
import os
import WMFData

/// A service that records the parameters of every request and fails each one at once. A test uses
/// it to check what a data controller asks the API for.
public final class WMFRecordingBasicService: WMFService {

    private let recordedParameters = OSAllocatedUnfairLock(initialState: [[String: Any]]())

    public init() {}

    /// The parameters of every request so far, in request order. A request without parameters records an empty dictionary.
    public var parameters: [[String: Any]] {
        recordedParameters.withLock { $0 }
    }

    private func record<R: WMFServiceRequest>(_ request: R) {
        let parameters = request.parameters ?? [:]
        recordedParameters.withLock { $0.append(parameters) }
    }

    // MARK: - WMFService

    public func perform<R: WMFServiceRequest>(request: R, completion: @escaping @Sendable (Result<Data, Error>) -> Void) {
        record(request)
        completion(.failure(URLError(.cancelled)))
    }

    public func perform<R: WMFServiceRequest>(request: R, completion: @escaping @Sendable (Result<[String: Any]?, Error>) -> Void) {
        record(request)
        completion(.failure(URLError(.cancelled)))
    }

    public func performDecodableGET<R: WMFServiceRequest, T: Decodable & Sendable>(request: R, completion: @escaping @Sendable (Result<T, Error>) -> Void) {
        record(request)
        completion(.failure(URLError(.cancelled)))
    }

    public func performCancellableDecodableGET<R: WMFServiceRequest, T: Decodable & Sendable>(request: R, completion: @escaping @Sendable (Result<T, Error>) -> Void) -> WMFURLSessionDataTask? {
        record(request)
        completion(.failure(URLError(.cancelled)))
        return nil
    }

    public func performDecodablePOST<R: WMFServiceRequest, T: Decodable & Sendable>(request: R, completion: @escaping @Sendable (Result<T, Error>) -> Void) {
        record(request)
        completion(.failure(URLError(.cancelled)))
    }

    public func clearCachedData() {}
}
