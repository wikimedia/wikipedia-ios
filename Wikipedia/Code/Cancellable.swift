import Foundation

@objc
public protocol Cancellable {
    func cancel() -> Void
}

extension NSOperation: Cancellable {}

extension NSURLConnection: Cancellable {}

extension NSURLSessionTask: Cancellable {}
