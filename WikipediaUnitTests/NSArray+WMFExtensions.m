//  Created by Monte Hurd on 8/11/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "Wikipedia-Swift.h"

@interface NSArray_WMFExtensions : XCTestCase

@end

@implementation NSArray_WMFExtensions

- (void)test_wmf_safeObjectAtIndex_findExpectedObject {
    NSArray* a = @[@"one", @"two"];
    XCTAssert([[a wmf_safeObjectAtIndex:0] isEqualToString:@"one"], @"Found expected object");
}

- (void)test_wmf_safeObjectAtIndex_outOfRangeReturnsNil {
    NSArray* a = @[@"one"];
    XCTAssertNil([a wmf_safeObjectAtIndex:1], @"Out of range returned nil properly.");
}

- (void)test_wmf_safeObjectAtIndex_emptyOutOfRangeReturnsNil {
    NSArray* a = @[];
    XCTAssertNil([a wmf_safeObjectAtIndex:1], @"Empty array returned nil properly.");
}

- (void)test_wmf_arrayByTrimmingToLength_countZeroReturnsSelf {
    NSArray* a = @[];
    XCTAssertEqualObjects(a, [a wmf_arrayByTrimmingToLength:5], @"Returned self on empty array.");
}

- (void)test_wmf_arrayByTrimmingToLength_arraySmallerThanRequestedLength {
    NSArray* a = @[@"one", @"two"];
    XCTAssertEqualObjects(a, [a wmf_arrayByTrimmingToLength:3], @"Returned self on too small length request.");
}

- (void)test_wmf_arrayByTrimmingToLength_trimToCount {
    NSArray* a  = @[@"one", @"two"];
    NSArray* a2 = [a wmf_arrayByTrimmingToLength:1];
    XCTAssert(a2.count == 1, @"Returned array of expected count.");
}

- (void)test_wmf_arrayByTrimmingToLength_trimToExpectedResult {
    NSArray* a = @[@"one", @"two"];
    XCTAssert([[a wmf_arrayByTrimmingToLength:1][0] isEqualToString:@"one"], @"Returned array containing expected object.");
}

- (void)test_wmf_reverseArray {
    NSArray* a  = @[@"one", @"two"];
    NSArray* a2 = [a wmf_reverseArray];

    XCTAssert([a2[0] isEqualToString:@"two"], @"Returned reversed array containing expected object.");
    XCTAssert([a2[1] isEqualToString:@"one"], @"Returned reversed array containing expected object.");
}

@end
