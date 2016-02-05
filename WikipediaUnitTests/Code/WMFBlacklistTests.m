////
////  WMFBlacklistTests.m
////  Wikipedia
////
////  Created by Corey Floyd on 1/21/16.
////  Copyright © 2016 Wikimedia Foundation. All rights reserved.
////
//
//#import <XCTest/XCTest.h>
//#import "WMFAsyncTestCase.h"
//#import "WMFRelatedSectionBlackList.h"
//#import "MWKTitle.h"
//
//@interface WMFRelatedSectionBlackList (WMFTesting)
//
//+ (instancetype)loadFromDisk;
//
//@end
//
//
//@interface WMFBlacklistTests : WMFAsyncTestCase
//
//@end
//
//@implementation WMFBlacklistTests
//
//- (void)tearDown {
//    WMFRelatedSectionBlackList* bl = [[WMFRelatedSectionBlackList alloc] init];
//    [bl removeAllEntries];
//    [bl save];
//    [super tearDown];
//}
//
//- (void)testPersistsToDisk {
//    PushExpectation();
//    MWKTitle* title                = [[MWKTitle alloc] initWithString:@"some-title" site:[MWKSite siteWithCurrentLocale]];
//    WMFRelatedSectionBlackList* bl = [[WMFRelatedSectionBlackList alloc] init];
//    [bl addEntry:title];
//    [bl save].then(^(){
//        [self popExpectationAfter:nil];
//    }).catch(^(NSError* error){
//        XCTFail(@"Error callback erroneously called with error %@", error);
//    });
//    WaitForExpectations();
//
//    bl = [WMFRelatedSectionBlackList loadFromDisk];
//    MWKTitle* first = [[bl entries] firstObject];
//
//    XCTAssertTrue([title isEqual:first],
//                  @"Title persisted should be equal to the title loaded from disk");
//}
//
//@end
