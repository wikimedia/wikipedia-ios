import Foundation

public protocol WKURLSession {
    func wkDataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> WKURLSessionDataTask
}

public protocol WKURLSessionDataTask {
    func resume()
}

extension URLSession: WKURLSession {
    public func wkDataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> WKURLSessionDataTask {
        return self.dataTask(with: request, completionHandler: completionHandler)
    }
}

extension URLSessionDataTask: WKURLSessionDataTask {

}
