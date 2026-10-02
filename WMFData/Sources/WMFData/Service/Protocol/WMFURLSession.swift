import Foundation

// Sendable: session abstractions back WMFService implementations, which are
// themselves Sendable. URLSession already satisfies this.
public protocol WMFURLSession: Sendable {
    func wmfDataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> WMFURLSessionDataTask
    func clearCachedData()
}

public protocol WMFURLSessionDataTask {
    func resume()

    /// Stops the request. URLSessionDataTask supplies this method. A mock task that does no
    /// work gets the default, which does nothing.
    func cancel()
}

public extension WMFURLSessionDataTask {
    func cancel() {
    }
}

extension URLSession: WMFURLSession {
    public func wmfDataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> WMFURLSessionDataTask {
        return self.dataTask(with: request, completionHandler: completionHandler)
    }
    
    public func clearCachedData() {
        configuration.urlCache?.removeAllCachedResponses()
    }
}

extension URLSessionDataTask: WMFURLSessionDataTask {

}
