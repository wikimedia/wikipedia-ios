//
//  NSArray+BKIndexTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/12/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "NSArray+BKIndex.h"
#import <XCTest/XCTest.h>
#import "WikipediaAppUtils.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface NSArray_BKIndexTests : XCTestCase

@end

@implementation NSArray_BKIndexTests

- (void)testEmpty {
    assertThat([@[] bk_indexWithKeypath:WMF_SAFE_KEYPATH([NSString new], lowercaseString)], isEmpty());
}

- (void)testExamples {
    assertThat(([@[ @"foo", @"Foo", @"bar" ] bk_indexWithKeypath:WMF_SAFE_KEYPATH([NSString new], lowercaseString)]),
               hasEntries(
                   @"foo", @"Foo",
                   @"bar", @"bar", nil));
}

@end
