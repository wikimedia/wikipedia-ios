//
//  XCTestCase+SwiftDefaults.swift
//  Wikipedia
//
//  Created by Brian Gerstle on 7/8/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

import Foundation
import XCTest

extension XCTestCase {
    public func wmf_waitForExpectations(timeout: NSTimeInterval = WMFDefaultExpectationTimeout,
                                        handler: XCWaitCompletionHandler? = nil) {
        self.waitForExpectationsWithTimeout(timeout, handler: handler)
    }
}
