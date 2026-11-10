import Foundation
import os
import WMFData

/// A service whose requests never answer on their own. A test uses it to hold a run open, see
/// that the run started, and then stop it: a cancelled request fails with `URLError.cancelled`,
/// like a `URLSessionDataTask` does. With `stopsOnCancel` false the request stays open after a
/// cancel, like a request already handed to the network, until `failPendingRequests()`.
public final class WMFHangingBasicService: WMFService {

    private struct State {
        var requestCount = 0
        /// The failure closure of each open request, by request number.
        var openRequests: [Int: @Sendable (Error) -> Void] = [:]
        var failsNewRequests = false
        /// The number of open requests when each request started, in request order.
        var openRequestCountsAtStart: [Int] = []
        var requestCountWaiters: [(count: Int, continuation: CheckedContinuation<Void, Never>)] = []
    }

    private let state = OSAllocatedUnfairLock(initialState: State())
    private let stopsOnCancel: Bool

    public init(stopsOnCancel: Bool = true) {
        self.stopsOnCancel = stopsOnCancel
    }

    /// The number of requests that started so far.
    public var requestCount: Int {
        state.withLock { $0.requestCount }
    }

    /// The number of requests open now.
    public var openRequestCount: Int {
        state.withLock { $0.openRequests.count }
    }

    /// The number of requests still open when the request with this one-based number started.
    public func openRequestCount(whenRequestStarted requestNumber: Int) -> Int? {
        state.withLock { state in
            guard requestNumber >= 1, requestNumber <= state.openRequestCountsAtStart.count else {
                return nil
            }
            return state.openRequestCountsAtStart[requestNumber - 1]
        }
    }

    /// Returns once the first request has started. Returns at once when it did already.
    public func waitForFirstRequest() async {
        await waitForRequest(count: 1)
    }

    /// Returns once `count` requests have started. Returns at once when they did already.
    public func waitForRequest(count: Int) async {
        await withCheckedContinuation { continuation in
            let startedAlready = state.withLock { state in
                if state.requestCount >= count {
                    return true
                }
                state.requestCountWaiters.append((count, continuation))
                return false
            }
            if startedAlready {
                continuation.resume()
            }
        }
    }

    /// Fails every open request with `URLError.cancelled`, and every request that starts later
    /// fails at once.
    public func failPendingRequests() {
        let failures = state.withLock { state in
            state.failsNewRequests = true
            let failures = Array(state.openRequests.values)
            state.openRequests = [:]
            return failures
        }
        for failure in failures {
            failure(URLError(.cancelled))
        }
    }

    /// Records the request. Returns the closure that fails it, or nil when the request failed at once.
    private func recordRequest(failure: @escaping @Sendable (Error) -> Void) -> (@Sendable () -> Void)? {
        let (requestNumber, waiters, failsAtOnce) = state.withLock { state in
            state.requestCount += 1
            let requestNumber = state.requestCount
            state.openRequestCountsAtStart.append(state.openRequests.count)
            if !state.failsNewRequests {
                state.openRequests[requestNumber] = failure
            }
            let reached = state.requestCountWaiters.filter { $0.count <= requestNumber }
            state.requestCountWaiters.removeAll { $0.count <= requestNumber }
            return (requestNumber, reached, state.failsNewRequests)
        }
        for waiter in waiters {
            waiter.continuation.resume()
        }
        if failsAtOnce {
            failure(URLError(.cancelled))
            return nil
        }
        return { [weak self] in
            self?.failRequest(number: requestNumber)
        }
    }

    /// Fails one open request. Does nothing when the request failed already.
    private func failRequest(number requestNumber: Int) {
        let failure = state.withLock { state in
            state.openRequests.removeValue(forKey: requestNumber)
        }
        failure?(URLError(.cancelled))
    }

    // MARK: - WMFService

    public func perform<R: WMFServiceRequest>(request: R, completion: @escaping @Sendable (Result<Data, Error>) -> Void) {
        _ = recordRequest { completion(.failure($0)) }
    }

    public func perform<R: WMFServiceRequest>(request: R, completion: @escaping @Sendable (Result<[String: Any]?, Error>) -> Void) {
        _ = recordRequest { completion(.failure($0)) }
    }

    public func performDecodableGET<R: WMFServiceRequest, T: Decodable & Sendable>(request: R, completion: @escaping @Sendable (Result<T, Error>) -> Void) {
        _ = recordRequest { completion(.failure($0)) }
    }

    public func performCancellableDecodableGET<R: WMFServiceRequest, T: Decodable & Sendable>(request: R, completion: @escaping @Sendable (Result<T, Error>) -> Void) -> WMFURLSessionDataTask? {
        guard let cancel = recordRequest(failure: { completion(.failure($0)) }) else {
            return nil
        }
        guard stopsOnCancel else {
            return WMFHangingDataTask(onCancel: {})
        }
        return WMFHangingDataTask(onCancel: cancel)
    }

    public func performDecodablePOST<R: WMFServiceRequest, T: Decodable & Sendable>(request: R, completion: @escaping @Sendable (Result<T, Error>) -> Void) {
        _ = recordRequest { completion(.failure($0)) }
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
