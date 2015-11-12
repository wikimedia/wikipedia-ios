//
//  XCTestCase+PromiseKit.m
//  Wikipedia
//
//  Created by Brian Gerstle on 7/29/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "XCTestCase+PromiseKit.h"
#import "WMFAsyncTestCase.h"

@interface XCTestCase (Util)

- (XCTestExpectation*)expectationForMethod:(SEL)method line:(NSUInteger)line;

@end

@implementation XCTestCase (Util)

- (XCTestExpectation*)expectationForMethod:(SEL)method line:(NSUInteger)line; {
    return [self expectationWithDescription:[NSString stringWithFormat:@"%@:L%lu", NSStringFromSelector(method), line]];
}

@end

@implementation XCTestCase (PromiseKit)

- (void)expectAnyPromiseToResolve:(AnyPromise*(^)(void))testBlock
                          timeout:(NSTimeInterval)timeout
                       testMethod:(SEL)method
                             line:(NSUInteger)line {
    XCTestExpectation* expectation = [self expectationForMethod:method line:line];
    AnyPromise* promise            = testBlock();
    promise.then(^{
        [expectation fulfill];
    }).catchWithPolicy(PMKCatchPolicyAllErrors, ^(NSError* e) {
        XCTFail(@"Unexpected error: %@", e);
    });
    [self waitForExpectationsWithTimeout:timeout handler:nil];
}

- (void)expectAnyPromiseToCatch:(AnyPromise*(^)(void))testBlock
                        timeout:(NSTimeInterval)timeout
                     testMethod:(SEL)method
                           line:(NSUInteger)line {
    return [self expectAnyPromiseToCatch:testBlock
                              withPolicy:PMKCatchPolicyAllErrorsExceptCancellation
                                 timeout:timeout
                              testMethod:method
                                    line:line];
}

- (void)expectAnyPromiseToCatch:(AnyPromise*(^)(void))testBlock
                     withPolicy:(PMKCatchPolicy)policy
                        timeout:(NSTimeInterval)timeout
                     testMethod:(SEL)method
                           line:(NSUInteger)line {
    XCTestExpectation* expectation = [self expectationForMethod:method line:line];
    AnyPromise* promise            = testBlock();
    promise.then(^(id val){
        XCTFail(@"Unexpected resolution: %@", val);
    }).catchWithPolicy(policy, ^{
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:timeout handler:nil];
}

@end
