import Foundation

@objc
public protocol Cancellable {
    func cancel()
}

extension Operation: Cancellable {}

extension NSURLConnection: Cancellable {}

extension URLSessionTask: Cancellable {}
