#import <XCTest/XCTest.h>

#define PushExpectation() ([self pushExpectation:__FILE__ line:__LINE__])

extern NSTimeInterval const WMFDefaultExpectationTimeout;

#define WaitForExpectations() ([self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout handler:nil])
#define WaitForExpectationsWithTimeout(timeout) ([self waitForExpectationsWithTimeout:timeout handler:nil])

@interface WMFAsyncTestCase : XCTestCase

- (void)popExpectation;

- (void)popExpectationAfter:(dispatch_block_t)block;

- (void)pushExpectation:(const char *)file line:(int)line;

@end
