//
//  XCTestCase+PromiseKitTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 11/20/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "XCTestCase+PromiseKit.h"
#import "NSProcessInfo+WMFOperatingSystemVersionChecks.h"

@interface XCTestCase_PromiseKitTests : XCTestCase
@end

@implementation XCTestCase_PromiseKitTests

- (void)recordFailureWithDescription:(NSString*)description
                              inFile:(NSString*)filePath
                              atLine:(NSUInteger)lineNumber
                            expected:(BOOL)expected {
    if (![description hasPrefix:@"Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: \"testShouldNotFulfillExpectationWhenTimeoutExpires"]) {
        // recorded failure wasn't the expected timeout
        [super recordFailureWithDescription:description inFile:filePath atLine:lineNumber expected:expected];
    }
}

- (void)testShouldNotFulfillExpectationWhenTimeoutExpiresForResolution {
    if ([[NSProcessInfo processInfo] wmf_isOperatingSystemVersionLessThan9_0_0]) {
        return;
    }

    __block PMKResolver resolve;
    expectResolution(^{
        return [AnyPromise promiseWithResolverBlock:^(PMKResolver _Nonnull aResolve) {
            resolve = aResolve;
        }];
    });
    // Resolve after wait context, and which we should handle internally so it doesn't throw an assertion.
    resolve(nil);
}

- (void)testShouldNotFulfillExpectationWhenTimeoutExpiresForError {
    if ([[NSProcessInfo processInfo] wmf_isOperatingSystemVersionLessThan9_0_0]) {
        return;
    }

    __block PMKResolver resolve;
    [self expectAnyPromiseToCatch:^AnyPromise*{
        return [AnyPromise promiseWithResolverBlock:^(PMKResolver _Nonnull aResolve) {
            resolve = aResolve;
        }];
    } withPolicy:PMKCatchPolicyAllErrors timeout:1  WMFExpectFromHere];
    // Resolve after wait context, and which we should handle internally so it doesn't throw an assertion.
    resolve([NSError cancelledError]);
}

@end
