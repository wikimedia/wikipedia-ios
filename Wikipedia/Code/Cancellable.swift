import Foundation

@objc
public protocol Cancellable {
    func cancel() -> Void
}

extension Operation: Cancellable {}

extension NSURLConnection: Cancellable {}

extension URLSessionTask: Cancellable {}
