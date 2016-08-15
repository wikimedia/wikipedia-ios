//
//  NSIndexSet+BKReduceTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 4/1/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

#import "NSIndexSet+BKReduce.h"

@interface NSIndexSet_BKReduceTests : XCTestCase

@end

@implementation NSIndexSet_BKReduceTests

- (void)testReduce {
    NSIndexSet *indexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 10)];
    assertThat([indexes bk_reduce:[NSMutableArray new]
                        withBlock:^id(NSMutableArray *acc, NSUInteger idx) {
                          [acc addObject:@(idx)];
                          return acc;
                        }],
               is(@[ @0, @1, @2, @3, @4, @5, @6, @7, @8, @9 ]));
}

- (void)testBadInput {
    assertThat([[NSIndexSet indexSet] bk_reduce:nil
                                      withBlock:^id(id _, NSUInteger __) {
                                        return nil;
                                      }],
               is(nilValue()));

    id input = [NSMutableArray new];
    assertThat([[NSIndexSet indexSet] bk_reduce:input withBlock:nil], is(input));
}

@end
