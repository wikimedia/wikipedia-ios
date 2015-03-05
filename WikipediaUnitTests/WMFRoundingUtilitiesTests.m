//
//  WMFRoundingUtilitiesTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 3/6/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "WMFRoundingUtilities.h"

@interface WMFRoundingUtilitiesTests : XCTestCase

@end

@implementation WMFRoundingUtilitiesTests

- (void)testSomeExamples {
    XCTAssertEqual(0.5, FlooredPercentage(0.5));
    XCTAssertEqual(0.0, FlooredPercentage(0.0));
    XCTAssertEqual(0.59, FlooredPercentage(0.59));
    XCTAssertEqual(0.59, FlooredPercentage(0.599));
}

@end
