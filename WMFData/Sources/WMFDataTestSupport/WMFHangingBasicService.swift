import Foundation
import os
import WMFData

/// A service whose requests never answer on their own. A test uses it to hold a run open, see
/// that the run started, and then stop it: a cancelled request fails with `URLError.cancelled`,
/// like a `URLSessionDataTask` does.
public final class WMFHangingBasicService: WMFService {

    private struct State {
        var requestCount = 0
        var firstRequestWaiters: [CheckedContinuation<Void, Never>] = []
    }

    private let state = OSAllocatedUnfairLock(initialState: State())

    public init() {}

    /// The number of requests that started so far.
    public var requestCount: Int {
        state.withLock { $0.requestCount }
    }

    /// Returns once the first request has started. Returns at once when it did already.
    public func waitForFirstRequest() async {
        await withCheckedContinuation { continuation in
            let startedAlready = state.withLock { state in
                if state.requestCount > 0 {
                    return true
                }
                state.firstRequestWaiters.append(continuation)
                return false
            }
            if startedAlready {
                continuation.resume()
            }
        }
    }

    private func recordRequest() {
        let waiters = state.withLock { state in
            state.requestCount += 1
            let waiters = state.firstRequestWaiters
            state.firstRequestWaiters = []
            return waiters
        }
        for waiter in waiters {
            waiter.resume()
        }
    }

    // MARK: - WMFService

    public func perform<R: WMFServiceRequest>(request: R, completion: @escaping @Sendable (Result<Data, Error>) -> Void) {
        recordRequest()
    }

    public func perform<R: WMFServiceRequest>(request: R, completion: @escaping @Sendable (Result<[String: Any]?, Error>) -> Void) {
        recordRequest()
    }

    public func performDecodableGET<R: WMFServiceRequest, T: Decodable & Sendable>(request: R, completion: @escaping @Sendable (Result<T, Error>) -> Void) {
        recordRequest()
    }

    public func performCancellableDecodableGET<R: WMFServiceRequest, T: Decodable & Sendable>(request: R, completion: @escaping @Sendable (Result<T, Error>) -> Void) -> WMFURLSessionDataTask? {
        recordRequest()
        return WMFHangingDataTask {
            completion(.failure(URLError(.cancelled)))
        }
    }

    public func performDecodablePOST<R: WMFServiceRequest, T: Decodable & Sendable>(request: R, completion: @escaping @Sendable (Result<T, Error>) -> Void) {
        recordRequest()
    }

    public func clearCachedData() {}
}

/// The task of one hanging request. Only `cancel()` ends the request.
private final class WMFHangingDataTask: WMFURLSessionDataTask {

    private let onCancel: @Sendable () -> Void

    init(onCancel: @escaping @Sendable () -> Void) {
        self.onCancel = onCancel
    }

    func resume() {}

    func cancel() {
        onCancel()
    }
}
