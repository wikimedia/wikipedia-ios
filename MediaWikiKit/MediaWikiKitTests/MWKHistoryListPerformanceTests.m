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
        [entries addObject:@{
             @"language": @"en",
             @"domain": @"wikipedia.org",
             @"title": [[NSUUID UUID] UUIDString],
             @"date": [[NSDateFormatter wmf_iso8601Formatter] stringFromDate:[NSDate date]],
             @"scrollPosition": @0,
             @"discoveryMethod": [MWKHistoryEntry stringForDiscoveryMethod:MWKHistoryDiscoveryMethodLink]
         }];
    }

    [self measureBlock:^{
        MWKHistoryList* list = [[MWKHistoryList alloc] initWithDict:NSDictionaryOfVariableBindings(entries)];
        XCTAssertEqual(list.length, [entries count]);
    }];
}

@end
