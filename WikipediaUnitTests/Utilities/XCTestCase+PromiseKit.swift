//
//  XCTestCase+PromiseKit.swift
//  Wikipedia
//
//  Created by Brian Gerstle on 7/8/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

import Foundation
import PromiseKit
import XCTest

public func descriptionfromFunction(fn: StaticString, line: UInt) -> String {
    return "\(fn):L\(line)"
}

func toResolve<T>() -> (Promise<T>) -> ((T) -> Void) -> Promise<Void> {
    return Promise.thenInBackground
}

func toReport<T>(policy: ErrorPolicy = ErrorPolicy.AllErrorsExceptCancellation) -> (Promise<T>) -> ((ErrorType) -> Void) -> Void {
    return { p in { errF in Promise<T>.error(p)(policy: policy, errF) } }
}

extension XCTestCase {
    public func wmf_fulfillExpectation<T>(function: StaticString = __FUNCTION__,
                                          line: UInt = __LINE__,
                                          pipe: ((T) -> Void)? = nil) -> (T) -> Void {
        return wmf_fulfillExpectation(descriptionfromFunction(function, line: line), pipe: pipe)
    }

    public func wmf_fulfillExpectation<T>(description: String,
                                          pipe: ((T) -> Void)? = nil) -> (T) -> Void {
        let promiseExpectation = self.expectationWithDescription(description)
        return {
            pipe?($0)
            promiseExpectation.fulfill()
        }
    }

    public func expectPromise<T, U, V>(
        callback: (Promise<T>) -> ((U) -> Void) -> V,
        timeout: NSTimeInterval = WMFDefaultExpectationTimeout,
        expirationHandler: XCWaitCompletionHandler? = nil,
        function: StaticString = __FUNCTION__,
        line: UInt = __LINE__,
        pipe: ((U) -> Void)? = nil,
        test: () -> Promise<T>) {
        expectPromise(
            callback,
            description: descriptionfromFunction(function, line: line),
            timeout: timeout,
            expirationHandler: expirationHandler,
            pipe: pipe,
            test: test)
    }

    public func expectPromise<T, U, V>(callback: (Promise<T>) -> ((U) -> Void) -> V,
                                       description: String,
                                       timeout: NSTimeInterval = WMFDefaultExpectationTimeout,
                                       expirationHandler: XCWaitCompletionHandler? = nil,
                                       pipe: ((U) -> Void)? = nil,
                                       test: () -> Promise<T>) {
        expectPromise(
            callback(test()),
            description: description,
            timeout: timeout,
            expirationHandler: expirationHandler,
            pipe: pipe)
    }

    private func expectPromise<T, U>(callback: ((T) -> Void) -> U,
                                     timeout: NSTimeInterval = WMFDefaultExpectationTimeout,
                                     expirationHandler: XCWaitCompletionHandler? = nil,
                                     function: StaticString = __FUNCTION__,
                                     line: UInt = __LINE__,
                                     pipe: ((T) -> Void)? = nil) {
        expectPromise(
            callback,
            description: descriptionfromFunction(function, line: line),
            timeout: timeout,
            expirationHandler: expirationHandler,
            pipe: pipe)
    }

     private func expectPromise<T, U>(callback: ((T) -> Void) -> U,
                                      description: String,
                                      timeout: NSTimeInterval = WMFDefaultExpectationTimeout,
                                      expirationHandler: XCWaitCompletionHandler? = nil,
                                      pipe: ((T) -> Void)? = nil) {
        callback(wmf_fulfillExpectation(description, pipe: pipe))
        wmf_waitForExpectations(timeout, handler: expirationHandler)
    }
}
