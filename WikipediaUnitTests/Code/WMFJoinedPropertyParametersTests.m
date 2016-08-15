//
//  WMFNetworkUtilitiesTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/5/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "WMFNetworkUtilities.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface WMFJoinedPropertyParametersTests : XCTestCase

@end

@implementation WMFJoinedPropertyParametersTests

- (void)testNonEmptyArray {
    assertThat(WMFJoinedPropertyParameters(@[ @"foo", @"bar", @"baz" ]), is(@"foo|bar|baz"));
}

- (void)testUnaryArray {
    assertThat(WMFJoinedPropertyParameters(@[ @"foo" ]), is(@"foo"));
}

- (void)testEmptyArray {
    assertThat(WMFJoinedPropertyParameters(@[]), is(@""));
}

- (void)testNil {
    assertThat(WMFJoinedPropertyParameters(nil), is(@""));
}

@end
