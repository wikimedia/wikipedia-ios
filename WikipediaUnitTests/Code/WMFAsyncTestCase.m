#import "WMFAsyncTestCase.h"

#if DEBUG
NSTimeInterval const WMFDefaultExpectationTimeout = 1000.0;
#else
NSTimeInterval const WMFDefaultExpectationTimeout = 10.0;
#endif

@interface WMFAsyncTestCase ()
@property NSMutableArray *expectations;
@end

@implementation WMFAsyncTestCase

- (void)setUp {
    [super setUp];
    self.expectations = [NSMutableArray new];
}

- (void)tearDown {
    XCTAssertEqual(self.expectations.count, 0,
                   @"Not all expectations were fulfilled: %@", self.expectations);
    [super tearDown];
}

- (void)pushExpectation:(const char *)file line:(int)line {
    [self.expectations addObject:
                           [self expectationWithDescription:
                                     [NSString stringWithFormat:@"%s:L%d", file, line]]];
}

- (void)popExpectationAfter:(dispatch_block_t)block {
    XCTestExpectation *expectation = [self.expectations lastObject];
    [self.expectations removeLastObject];
    if (block) {
        block();
    }
    [expectation fulfill];
}

- (void)popExpectation {
    [self popExpectationAfter:nil];
}

@end
