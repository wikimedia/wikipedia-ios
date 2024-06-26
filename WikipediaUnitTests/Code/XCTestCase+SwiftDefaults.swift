import Foundation
import XCTest

let defaultHandler: XCWaitCompletionHandler = { (err: Error?) in
    if let e = err {
        print("Timeout expired with error \(e)")
    }
}

extension XCTestCase {
    public func wmf_waitForExpectations(_ timeout: TimeInterval = WMFDefaultExpectationTimeout,
                                        handler: XCWaitCompletionHandler? = nil) {
        self.waitForExpectations(timeout: timeout, handler: handler != nil ? handler : defaultHandler)
    }
}
