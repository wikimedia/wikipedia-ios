//
//  WMFMathTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 3/6/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <XCTest/XCTest.h>

// Redefine assert macro for testing WMFStrictClamp
#undef assert
#define assert(...) (void)(didAssert = YES)
#import "WMFMath.h"

static BOOL didAssert = NO;

@interface WMFMathTests : XCTestCase

@end

@implementation WMFMathTests

- (void)setUp {
    [super setUp];
    didAssert = NO;
}

- (void)testRounding {
    XCTAssertEqual(0.5, WMFFlooredPercentage(0.5));
    XCTAssertEqual(0.0, WMFFlooredPercentage(0.0));
    XCTAssertEqual(0.59, WMFFlooredPercentage(0.59));
    XCTAssertEqual(0.59, WMFFlooredPercentage(0.599));
}

- (void)testStrictClampReturnsValueIfWithinBounds {
    XCTAssertEqual(WMFStrictClamp(0, 1, 2), 1);
}

- (void)testStrictClampReturnsMinWhenOutsideLowerBound {
    XCTAssertEqual(WMFStrictClamp(0, -1, 2), 0);
}

- (void)testStrictClampReturnsMaxWhenOutsideUpperBound {
    XCTAssertEqual(WMFStrictClamp(0, 3, 2), 2);
}

- (void)testStrictClampAssertsWhenGivenInvalidBounds {
    WMFStrictClamp(2, 1, 0);
    XCTAssertTrue(didAssert);
}

- (void)testClampReturnsSameResultWhenBoundsAreReversed {
    XCTAssertEqual(WMFClamp(2, 1, 0), WMFClamp(0, 1, 2));
}

@end
