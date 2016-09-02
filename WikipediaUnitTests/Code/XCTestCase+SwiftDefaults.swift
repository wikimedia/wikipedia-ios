import Foundation
import XCTest

let defaultHandler: XCWaitCompletionHandler = { (err: NSError?) -> Void in
    if let e = err {
        print("Timeout expired with error \(e)")
    }
}

extension XCTestCase {
    public func wmf_waitForExpectations(timeout: NSTimeInterval = WMFDefaultExpectationTimeout,
                                        handler: XCWaitCompletionHandler? = nil) {
        self.waitForExpectationsWithTimeout(timeout, handler: handler != nil ? handler : defaultHandler)
    }
}
