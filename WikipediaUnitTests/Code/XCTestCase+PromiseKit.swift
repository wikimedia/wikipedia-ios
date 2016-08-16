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

public func descriptionfromFunction(_ fn: StaticString, line: Int) -> String {
    return "\(fn):L\(line)"
}

func toResolve<T>() -> (Promise<T>) -> ((T) -> Void) -> Promise<Void> {
    return Promise.thenInBackground
}

func toReport<T>(_ policy: ErrorPolicy = ErrorPolicy.AllErrorsExceptCancellation) -> (Promise<T>) -> ((ErrorType) -> Void) -> Void {
    return { p in { errF in Promise<T>.error(p)(policy: policy, errF) } }
}

extension XCTestCase {
    public func expectPromise<T, U, V>(
        _ callback: (Promise<T>) -> ((U) -> Void) -> V,
        timeout: TimeInterval = WMFDefaultExpectationTimeout,
        expirationHandler: XCWaitCompletionHandler? = nil,
        function: StaticString = #function,
        line: Int = #line,
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

    public func expectPromise<T, U, V>(_ callback: (Promise<T>) -> ((U) -> Void) -> V,
                                       description: String,
                                       timeout: TimeInterval = WMFDefaultExpectationTimeout,
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

    fileprivate func expectPromise<T, U>(_ callback: ((T) -> Void) -> U,
                                     timeout: TimeInterval = WMFDefaultExpectationTimeout,
                                     expirationHandler: XCWaitCompletionHandler? = nil,
                                     function: StaticString = #function,
                                     line: Int = #line,
                                     pipe: ((T) -> Void)? = nil) {
        expectPromise(
            callback,
            description: descriptionfromFunction(function, line: line),
            timeout: timeout,
            expirationHandler: expirationHandler,
            pipe: pipe)
    }

    fileprivate func expectPromise<T, U>(_ callback: ((T) -> Void) -> U,
                                     description: String,
                                     timeout: TimeInterval = WMFDefaultExpectationTimeout,
                                     expirationHandler: XCWaitCompletionHandler? = nil,
                                     pipe: ((T) -> Void)? = nil) {
            var pendingExpectation: XCTestExpectation? = expectation(description: description)
            callback() { x in
                guard let expectation = pendingExpectation else {
                    return
                }
                pipe?(x)
                expectation.fulfill()
            }
            wmf_waitForExpectations(timeout) { error in
                guard error != nil else {
                    return
                }
                print("Timeout expired with error: \(error)")
                expirationHandler?(error)
                // nullify pending expectation to prevent fulfilling it after timeout has expired
                pendingExpectation = nil
            }
    }
}
