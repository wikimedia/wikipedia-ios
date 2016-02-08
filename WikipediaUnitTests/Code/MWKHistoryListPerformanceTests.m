//
//  MWKHistoryListPerformanceTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 6/29/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "NSDateFormatter+WMFExtensions.h"
#import "WMFTestFixtureUtilities.h"
#import "MWKHistoryList.h"

@interface MWKHistoryListPerformanceTests : XCTestCase

@end

@implementation MWKHistoryListPerformanceTests

- (void)testReadPerformance {
    NSMutableArray* entries = [NSMutableArray arrayWithCapacity:1000];
    for (int i = 0; i < 1000; i++) {
        MWKHistoryEntry* entry = [[MWKHistoryEntry alloc] initWithTitle:[MWKTitle random]];
        [entries addObject:entry];
    }

    [self measureBlock:^{
        MWKHistoryList* list = [[MWKHistoryList alloc] initWithEntries:entries];
        XCTAssertEqual([list countOfEntries], [entries count]);
    }];
}

@end
