#import "XCTestCase+PromiseKit.h"
#import "WMFAsyncTestCase.h"

@interface XCTestCase (Util)

- (XCTestExpectation *)expectationForMethod:(SEL)method line:(NSUInteger)line;

@end

@implementation XCTestCase (Util)

- (XCTestExpectation *)expectationForMethod:(SEL)method line:(NSUInteger)line {
    return [self expectationWithDescription:[NSString stringWithFormat:@"%@:L%lu", NSStringFromSelector(method), (unsigned long)line]];
}

@end

@implementation XCTestCase (PromiseKit)

- (void)expectAnyPromiseToResolve:(AnyPromise * (^)(void))testBlock
                          timeout:(NSTimeInterval)timeout
                       testMethod:(SEL)method
                             line:(NSUInteger)line {
    __block XCTestExpectation *expectation = [self expectationForMethod:method line:line];
    AnyPromise *promise = testBlock();
    promise.then(^{
               [expectation fulfill];
           })
        .catchWithPolicy(PMKCatchPolicyAllErrors, ^(NSError *e) {
            XCTFail(@"Unexpected error: %@", e);
        });
    [self waitForExpectationsWithTimeout:timeout
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         // don't fulfill the expectation after the timeout expires, XCTest will raise an assertion and wreak all sorts of havoc
                                         DDLogError(@"Timeout expired with error: %@", error);
                                         expectation = nil;
                                     }
                                 }];
}

- (void)expectAnyPromiseToCatch:(AnyPromise * (^)(void))testBlock
                        timeout:(NSTimeInterval)timeout
                     testMethod:(SEL)method
                           line:(NSUInteger)line {
    return [self expectAnyPromiseToCatch:testBlock
                              withPolicy:PMKCatchPolicyAllErrorsExceptCancellation
                                 timeout:timeout
                              testMethod:method
                                    line:line];
}

- (void)expectAnyPromiseToCatch:(AnyPromise * (^)(void))testBlock
                     withPolicy:(PMKCatchPolicy)policy
                        timeout:(NSTimeInterval)timeout
                     testMethod:(SEL)method
                           line:(NSUInteger)line {
    __block XCTestExpectation *expectation = [self expectationForMethod:method line:line];
    AnyPromise *promise = testBlock();
    promise.then(^(id val) {
               XCTFail(@"Unexpected resolution: %@", val);
           })
        .catchWithPolicy(policy, ^{
            [expectation fulfill];
        });
    [self waitForExpectationsWithTimeout:timeout
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         // don't fulfill the expectation after the timeout expires, XCTest will raise an assertion and wreak all sorts of havoc
                                         DDLogError(@"Timeout expired with error: %@", error);
                                         expectation = nil;
                                     }
                                 }];
}

@end
