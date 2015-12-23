//
//  XCTestCase+SwiftDefaults.swift
//  Wikipedia
//
//  Created by Brian Gerstle on 7/8/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

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
        self.waitForExpectationsWithTimeout(timeout, handler: handler == nil ? handler : defaultHandler)
    }
}
