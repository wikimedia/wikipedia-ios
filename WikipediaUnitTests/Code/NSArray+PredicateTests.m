//
//  NSArray+PredicateTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 1/30/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

#import "Wikipedia-Swift.h"

@interface NSArray_PredicateTests : XCTestCase

@end

@implementation NSArray_PredicateTests

- (void)testEmptyArray {
    assertThat([@[] wmf_firstMatchForPredicate:[NSPredicate predicateWithValue:YES]], is(nilValue()));
    assertThat([@[] wmf_firstMatchForPredicate:[NSPredicate predicateWithValue:NO]], is(nilValue()));
}

- (void)testFindsCorrectObject {
    NSArray *testArray = @[ @"foo", @"bar", @"baz" ];
    for (id element in testArray) {
        NSPredicate *isElement = [NSPredicate predicateWithBlock:^BOOL(id obj, NSDictionary *bindings) {
          return [obj isEqual:element];
        }];
        assertThat([testArray wmf_firstMatchForPredicate:isElement], is(element));
    }
}

- (void)testFalsePredicate {
    assertThat(([@[ @1, @2, @3 ] wmf_firstMatchForPredicate:[NSPredicate predicateWithValue:NO]]), is(nilValue()));
}

- (void)testPerformance {
    static const NSUInteger N = 1e5;
    NSNumber *worstCase = @(N - 1);
    NSMutableArray *testArray = [NSMutableArray arrayWithCapacity:N];
    for (NSUInteger i = 0; i < N; i++) {
        [testArray addObject:@(i)];
    }
    [self measureBlock:^{
      [testArray wmf_firstMatchForPredicate:[NSPredicate predicateWithBlock:^BOOL(NSNumber *x, NSDictionary *bindings) {
                   return [x isEqualToNumber:worstCase];
                 }]];
    }];
}

@end
