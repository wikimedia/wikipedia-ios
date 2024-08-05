import Foundation

public protocol WMFURLSession {
    func wmfDataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> WMFURLSessionDataTask
}

public protocol WMFURLSessionDataTask {
    func resume()
}

extension URLSession: WMFURLSession {
    public func wmfDataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> WMFURLSessionDataTask {
        return self.dataTask(with: request, completionHandler: completionHandler)
    }
}

extension URLSessionDataTask: WMFURLSessionDataTask {

}
