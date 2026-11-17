import Foundation
import WMFData

#if DEBUG

/// A service that answers every request with the same JSON text. Use it when a test needs a
/// response that is not worth a resource file, for example one short API payload.
public final class WMFMockJSONService: WMFService, @unchecked Sendable {

    private let json: String
    private let lock = NSLock()
    private var _requestedURLs: [URL] = []

    /// The URL of every request, in order.
    public var requestedURLs: [URL] {
        lock.lock()
        defer { lock.unlock() }
        return _requestedURLs
    }

    public init(json: String) {
        self.json = json
    }

    private func record(_ request: WMFServiceRequest) {
        guard let url = request.url else {
            return
        }
        lock.lock()
        _requestedURLs.append(url)
        lock.unlock()
    }

    private var data: Data? {
        json.data(using: .utf8)
    }

    public func perform<R: WMFServiceRequest>(request: R, completion: @escaping @Sendable (Result<Data, Error>) -> Void) {
        record(request)
        guard let data else {
            completion(.failure(WMFMockError.unableToPullData))
            return
        }
        completion(.success(data))
    }

    public func perform<R: WMFServiceRequest>(request: R, completion: @escaping @Sendable (Result<[String: Any]?, Error>) -> Void) {
        record(request)
        guard let data,
              let dictionary = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            completion(.failure(WMFMockError.unableToDeserialize))
            return
        }
        completion(.success(dictionary))
    }

    public func performDecodableGET<R: WMFServiceRequest, T: Decodable & Sendable>(request: R, completion: @escaping @Sendable (Result<T, Error>) -> Void) {
        record(request)
        decode(completion: completion)
    }

    public func performDecodablePOST<R: WMFServiceRequest, T: Decodable & Sendable>(request: R, completion: @escaping @Sendable (Result<T, Error>) -> Void) {
        record(request)
        decode(completion: completion)
    }

    private func decode<T: Decodable>(completion: (Result<T, Error>) -> Void) {
        guard let data else {
            completion(.failure(WMFMockError.unableToPullData))
            return
        }
        do {
            completion(.success(try JSONDecoder().decode(T.self, from: data)))
        } catch {
            completion(.failure(error))
        }
    }

    public func clearCachedData() {
        // no-op
    }
}

#endif
