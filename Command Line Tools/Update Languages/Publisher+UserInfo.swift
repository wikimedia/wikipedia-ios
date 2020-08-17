import Combine

extension Publisher {
    /// Add userInfo to a publisher as a tuple
    ///
    /// - Parameter userInfo: the userInfo value to include with the output
    /// - Returns: A publisher that emits the upstream values along with the provided userInfo
    public func add<T>(userInfo: T) -> AnyPublisher<(Output, T), Failure> {
        combineLatest(Future<T, Failure> { promise in
            promise(.success(userInfo))
        }).eraseToAnyPublisher()
    }
}
