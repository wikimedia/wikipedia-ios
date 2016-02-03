//
//  MWKHistoryListCorruptDataTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 6/29/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "MWKHistoryList.h"
#import "MWKHistoryEntry.h"
#import "MWKSite.h"
#import "MWKTitle.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface MWKHistoryListCorruptDataTests : XCTestCase
@property (strong, nonatomic) MWKHistoryList* historyList;

@end

@implementation MWKHistoryListCorruptDataTests

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"

- (void)testPrunesEntriesWithEmptyTitles {
    MWKHistoryList* list = [[MWKHistoryList alloc] initWithEntries:nil];
    [list addPageToHistoryWithTitle:[[MWKSite siteWithCurrentLocale] titleWithString:@"Foo"]];
    assertThat(@([list countOfEntries]), is(@1));

    [list addPageToHistoryWithTitle:[[MWKSite siteWithCurrentLocale] titleWithString:@""]];
    assertThat(@([list countOfEntries]), is(@1));
}

#pragma clang diagnostic pop


@end
