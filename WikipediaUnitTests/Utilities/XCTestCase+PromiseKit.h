//
//  XCTestCase+PromiseKit.h
//  Wikipedia
//
//  Created by Brian Gerstle on 7/29/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <PromiseKit/PromiseKit.h>
#import "WMFAsyncTestCase.h"

/// Macro to make passing the last to arguments easier
#define WMFExpectFromHere testMethod : _cmd line : __LINE__

/// Shorthand macro to expect a promise to resolve within the default timeout.
#define expectResolution(promiseBlock) expectResolutionWithTimeout(WMFDefaultExpectationTimeout, (promiseBlock))

/// Shorthand macro to expect a promise to resolve with the given timeout.
#define expectResolutionWithTimeout(timeoutSecs, promiseBlock) \
    [self expectAnyPromiseToResolve : (promiseBlock)timeout : (timeoutSecs)WMFExpectFromHere]

/**
 * Utility for testing promises in ObjC.
 *
 * @note It's preferred to write tests involving promises in Swift, but when that's not feasible,
 *       use these utilities.
 */
@interface XCTestCase (PromiseKit)

- (void)expectAnyPromiseToResolve:(AnyPromise*(^)(void))testBlock
                          timeout:(NSTimeInterval)timeout
                       testMethod:(SEL)method
                             line:(NSUInteger)line;

- (void)expectAnyPromiseToCatch:(AnyPromise*(^)(void))testBlock
                        timeout:(NSTimeInterval)timeout
                     testMethod:(SEL)method
                           line:(NSUInteger)line;

- (void)expectAnyPromiseToCatch:(AnyPromise*(^)(void))testBlock
                     withPolicy:(PMKCatchPolicy)policy
                        timeout:(NSTimeInterval)timeout
                     testMethod:(SEL)method
                           line:(NSUInteger)line;

@end
