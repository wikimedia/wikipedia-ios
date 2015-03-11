//
//  WMFAsyncTestCase.h
//  Wikipedia
//
//  Created by Brian Gerstle on 3/13/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <XCTest/XCTest.h>

#define PushExpectation() ([self pushExpectation:__FILE__ line:__LINE__])

extern float const WMFDefaultExpectationTimeout;

#define WaitForExpectations() ([self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout handler:nil])

@interface WMFAsyncTestCase : XCTestCase

- (void)popExpectationAfter:(dispatch_block_t)block;

- (void)pushExpectation:(const char*)file line:(int)line;

@end
