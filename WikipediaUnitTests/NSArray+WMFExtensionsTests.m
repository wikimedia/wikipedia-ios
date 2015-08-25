//  Created by Monte Hurd on 8/11/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "Wikipedia-Swift.h"
#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface NSArray_WMFExtensionsTests : XCTestCase

@property (strong, nonatomic) NSArray* array;

@end

@implementation NSArray_WMFExtensionsTests

- (void)setUp {
    [super setUp];
    self.array = @[@"one", @"two"];
}

- (void)tearDown {
    self.array = nil;
    [super tearDown];
}

- (void)test_wmf_safeObjectAtIndex_findExpectedObject {
    assertThat([self.array wmf_safeObjectAtIndex:0], is(@"one"));
}

- (void)test_wmf_safeObjectAtIndex_outOfRangeReturnsNil {
    assertThat([self.array wmf_safeObjectAtIndex:2], is(nilValue()));
}

- (void)test_wmf_safeObjectAtIndex_emptyOutOfRangeReturnsNil {
    assertThat([@[] wmf_safeObjectAtIndex: 1], is(nilValue()));
}

- (void)test_wmf_arrayByTrimmingToLength_countZeroReturnsSelf {
    NSArray* emptyArray = @[];
    assertThat([emptyArray wmf_arrayByTrimmingToLength:5], is(emptyArray));
}

- (void)test_wmf_arrayByTrimmingToLength_arraySmallerThanRequestedLength {
    assertThat([self.array wmf_arrayByTrimmingToLength:3], is(self.array));
}

- (void)test_wmf_arrayByTrimmingToLength_trimToCount {
    assertThat([self.array wmf_arrayByTrimmingToLength:1], hasCountOf(1));
}

- (void)test_wmf_arrayByTrimmingToLength_trimToExpectedResult {
    assertThat([self.array wmf_arrayByTrimmingToLength:1][0], is(@"one"));
}

- (void)test_wmf_reverseArray {
    assertThat([self.array wmf_reverseArray], is(@[@"two", @"one"]));
}

- (void)testSafeSubarrayShouldLimitToCount {
    NSArray* original = @[@0, @1];
    assertThat([original wmf_safeSubarrayWithRange:NSMakeRange(0, 5)], is(original));
}

- (void)testSafeSubarrayShouldReturnEmptyArrayIfRangeLocationOutOfBounds {
    assertThat(([@[@0, @1] wmf_safeSubarrayWithRange: NSMakeRange(2, 1)]), isEmpty());
}

- (void)testSafeSubarrayShouldReturnEmptyIfRangeIsNotFound {
    assertThat(([@[@0, @1] wmf_safeSubarrayWithRange: NSMakeRange(NSNotFound, 1)]), isEmpty());
}

- (void)testSafeSubarrayShouldReturnEmptyIfRangeIsEmpty {
    assertThat(([@[@0, @1] wmf_safeSubarrayWithRange: NSMakeRange(0, 0)]), isEmpty());
}

- (void)testSafeSubarrayShouldReturnEmptyFromEmptyList {
    assertThat(([@[] wmf_safeSubarrayWithRange: NSMakeRange(0, 1)]), isEmpty());
}

- (void)testTailShouldReturnAllButTheFirstElement {
    assertThat(([@[@0, @1] wmf_tail]), is(equalTo(@[@1])));
}

- (void)testTailShouldReturnEmptyArrayFromSingletonList {
    assertThat(([@[@1] wmf_tail]), isEmpty());
}

- (void)testTailShouldReturnEmptyArrayFromEmptyList {
    assertThat(([@[] wmf_tail]), isEmpty());
}

@end
