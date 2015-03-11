//
//  WMFAsyncTestCase.m
//  Wikipedia
//
//  Created by Brian Gerstle on 3/13/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFAsyncTestCase.h"

float const WMFDefaultExpectationTimeout = 0.1;

@interface WMFAsyncTestCase ()
@property NSMutableArray* expectations;
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

- (void)pushExpectation:(const char*)file line:(int)line {
    [self.expectations addObject:
     [self expectationWithDescription:
      [NSString stringWithFormat:@"%s:L%d", file, line]]];
}

- (void)popExpectationAfter:(dispatch_block_t)block {
    XCTestExpectation* expectation = [self.expectations lastObject];
    [self.expectations removeLastObject];
    if (block) {
        block();
    }
    [expectation fulfill];
}

@end
